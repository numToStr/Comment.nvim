---@mod comment.opfunc Operator-mode

local U = require('Comment.utils')
local Config = require('Comment.config')
local A = vim.api

local Op = {}

---@alias OpMode 'line'|'char'|'v'|'V' Vim operator-mode motions. Read `:h map-operator`

---@class CommentCtx Comment context
---@field ctype number CommentType
---@field cmode number CommentMode
---@field cmotion number CommentMotion
---@field range CommentRange

---@class OpFnParams Operator-mode function parameters
---@field cfg CommentConfig
---@field cmode number See |comment.utils.cmode|
---@field lines table List of lines
---@field rcs string RHS of commentstring
---@field lcs string LHS of commentstring
---@field range CommentRange

---Common operatorfunc callback
---This function contains the core logic for comment/uncomment
---@param opmode OpMode
---@param cfg CommentConfig
---@param cmode number CommentMode
---@param ctype number CommentType
---@param cmotion number CommentMotion
function Op.opfunc(opmode, cfg, cmode, ctype, cmotion)
    -- comment/uncomment logic
    --
    -- 1. type == line
    --      * decide whether to comment or not, if all the lines are commented then uncomment otherwise comment
    --      * also, store the minimum indent from all the lines (exclude empty line)
    --      * if comment the line, use cstr LHS and also considering the min indent
    --      * if uncomment the line, remove cstr LHS from lines
    --      * update the lines
    -- 2. type == block
    --      * check if the first and last is commented or not with cstr LHS and RHS respectively.
    --      * if both lines commented
    --          - remove cstr LHS from the first line
    --          - remove cstr RHS to end of the last line
    --      * if both lines uncommented
    --          - add cstr LHS after the leading whitespace and before the first char of the first line
    --          - add cstr RHS to end of the last line
    --      * update the lines

    cmotion = cmotion == U.cmotion._ and U.cmotion[opmode] or cmotion

    local range = U.get_region(opmode)
    local same_line = range.srow == range.erow
    local partial_block = cmotion == U.cmotion.char or cmotion == U.cmotion.v
    local block_x = partial_block and same_line

    local lines = U.get_lines(range)

    -- sometimes there might be a case when there are no lines
    -- like, executing a text object returns nothing
    if U.is_empty(lines) then
        return
    end

    ---@type CommentCtx
    local ctx = {
        cmode = cmode,
        cmotion = cmotion,
        ctype = block_x and U.ctype.block or ctype,
        range = range,
    }

    local lcs, rcs = U.parse_cstr(cfg, ctx)

    ---@type OpFnParams
    local params = {
        cfg = cfg,
        lines = lines,
        lcs = lcs,
        rcs = rcs,
        cmode = cmode,
        range = range,
    }

    if block_x then
        ctx.cmode = Op.blockwise_x(params)
    elseif ctype == U.ctype.block and not same_line then
        ctx.cmode = Op.blockwise(params, partial_block)
    else
        ctx.cmode = Op.linewise(params)
    end

    -- We only need to restore cursor if both sticky and position are available
    -- As this function is also called for visual mapping where we are not storing the position
    --
    -- And I found out that if someone presses `gc` but doesn't provide operators and
    -- does visual comments then cursor jumps to previous stored position. Thus the check for visual modes
    if cfg.sticky and Config.position and cmotion ~= U.cmotion.v and cmotion ~= U.cmotion.V then
        A.nvim_win_set_cursor(0, Config.position)
        Config.position = nil
    end

    U.is_fn(cfg.post_hook, ctx)
end

---Line commenting
---@param param OpFnParams
---@return number
function Op.linewise(param)
    local pattern = U.is_fn(param.cfg.ignore)
    local padding, pp = U.get_padding(param.cfg.padding)
    local check = U.is_commented(param.lcs, param.rcs, param.cfg.padding)

    -- While commenting a region, there could be lines being both commented and non-commented
    -- So, if any line is uncommented then we should comment the whole block or vise-versa
    local cmode = U.cmode.uncomment

    ---When commenting multiple line, it is to be expected that indentation should be preserved
    ---So, When looping over multiple lines we need to store the indentation of the mininum length (except empty line)
    ---Which will be used to semantically comment rest of the lines
    ---@type integer
    local min_indent = nil

    -- If the given cmode is uncomment then we actually don't want to compute the cmode or min_indent
    if param.cmode ~= U.cmode.uncomment then
        for _, line in ipairs(param.lines) do
            -- I wish lua had `continue` statement [sad noises]
            if not U.ignore(line, pattern) then
                if cmode == U.cmode.uncomment and param.cmode == U.cmode.toggle and (not check(line)) then
                    cmode = U.cmode.comment
                end

                -- If local `cmode` == comment or the given cmode ~= uncomment, then only calculate min_indent
                -- As calculating min_indent only makes sense when we actually want to comment the lines
                if not U.is_empty(line) and (cmode == U.cmode.comment or param.cmode == U.cmode.comment) then
                    local len = U.indent_len(line)
                    if not min_indent or min_indent > len then
                        min_indent = len
                    end
                end
            end
        end
    end

    if cmode == U.cmode.uncomment then
        local uncomment = U.uncommenter(param.lcs, param.rcs, nil, nil, pp)
        for i, line in ipairs(param.lines) do
            if not U.ignore(line, pattern) then
                param.lines[i] = uncomment(line)
            end
        end
    else
        local comment = U.commenter(param.lcs, param.rcs, min_indent, nil, padding)
        for i, line in ipairs(param.lines) do
            if not U.ignore(line, pattern) then
                param.lines[i] = comment(line)
            end
        end
    end

    A.nvim_buf_set_lines(0, param.range.srow - 1, param.range.erow, false, param.lines)

    return cmode
end

-- FIXME: merge blockwise an blockwise_x

---Full/Partial Block commenting
---@param param OpFnParams
---@param partial? boolean Comment the partial region (visual mode)
---@return number
function Op.blockwise(param, partial)
    local sln, eln = param.lines[1], param.lines[#param.lines]

    local padding, pp = U.get_padding(param.cfg.padding)
    local scol, ecol = nil, nil
    if partial then
        scol, ecol = param.range.scol, param.range.ecol
    end

    -- If given mode is toggle then determine whether to comment or not
    local cmode = param.cmode
    if cmode == U.cmode.toggle then
        local s_cmt = U.is_commented(param.lcs, '', param.cfg.padding)(sln, scol, -1)
        local e_cmt = U.is_commented('', param.rcs, param.cfg.padding)(eln, 0, ecol)
        cmode = (s_cmt and e_cmt) and U.cmode.uncomment or U.cmode.comment
    end

    local l1, l2
    if cmode == U.cmode.uncomment then
        l1, l2 = U.uncommenter(param.lcs, param.rcs, scol, ecol, pp)({ sln, eln })
    else
        l1, l2 = U.commenter(param.lcs, param.rcs, scol, ecol, padding)({ sln, eln })
    end

    A.nvim_buf_set_lines(0, param.range.srow - 1, param.range.srow, false, { l1 })
    A.nvim_buf_set_lines(0, param.range.erow - 1, param.range.erow, false, { l2 })

    return cmode
end

---Block (left-right motion) commenting
---@param param OpFnParams
---@return number
function Op.blockwise_x(param)
    local line = param.lines[1]

    local padding, pp = U.get_padding(param.cfg.padding)
    local scol, ecol = param.range.scol, param.range.ecol

    local cmode = param.cmode
    if cmode == U.cmode.toggle then
        local is_cmt = U.is_commented(param.lcs, param.rcs, param.cfg.padding)(line, scol, ecol)
        cmode = is_cmt and U.cmode.uncomment or U.cmode.comment
    end

    if cmode == U.cmode.uncomment then
        local uncommented = U.uncommenter(param.lcs, param.rcs, scol, ecol, pp)(line)
        A.nvim_set_current_line(uncommented)
    else
        local commented = U.commenter(param.lcs, param.rcs, scol, ecol, padding)(line)
        A.nvim_set_current_line(commented)
    end

    return cmode
end

---Toggle line comment with count i.e vim.v.count
---Example: `10gl` will comment 10 lines
---@param count number Number of lines
---@param cfg CommentConfig
---@param ctype number CommentType
function Op.count(count, cfg, ctype)
    local lines, range = U.get_count_lines(count)

    ---@type CommentCtx
    local ctx = {
        cmode = U.cmode.toggle,
        cmotion = U.cmotion.line,
        ctype = ctype,
        range = range,
    }
    local lcs, rcs = U.parse_cstr(cfg, ctx)

    ---@type OpFnParams
    local params = {
        cfg = cfg,
        cmode = ctx.cmode,
        lines = lines,
        lcs = lcs,
        rcs = rcs,
        range = range,
    }

    if ctype == U.ctype.block then
        ctx.cmode = Op.blockwise(params)
    else
        ctx.cmode = Op.linewise(params)
    end

    U.is_fn(cfg.post_hook, ctx)
end

return Op
