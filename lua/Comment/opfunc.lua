---@mod comment.opfunc Operator-mode

local U = require('Comment.utils')
local Config = require('Comment.config')
local A = vim.api

local Op = {}

---Vim operator-mode motions.
---Read `:h :map-operator`
---@alias OpMode
---| 'line' # Vertical motion
---| 'char' # Horizontal motion
---| 'v' # Visual Block motion
---| 'V' # Visual Line motion

---@class CommentCtx Comment context
---@field ctype integer See |comment.utils.ctype|
---@field cmode integer See |comment.utils.cmode|
---@field cmotion integer See |comment.utils.cmotion|
---@field range CommentRange

---@class OpFnParams Operator-mode function parameters
---@field cfg CommentConfig
---@field cmode integer See |comment.utils.cmode|
---@field lines string[] List of lines
---@field rcs string RHS of commentstring
---@field lcs string LHS of commentstring
---@field range CommentRange

---Common operatorfunc callback
---This function contains the core logic for comment/uncomment
---@param opmode OpMode
---@param cfg CommentConfig
---@param cmode integer See |comment.utils.cmode|
---@param ctype integer See |comment.utils.ctype|
---@param cmotion integer See |comment.utils.cmotion|
function Op.opfunc(opmode, cfg, cmode, ctype, cmotion)
    cmotion = cmotion == U.cmotion._ and U.cmotion[opmode] or cmotion

    local range = U.get_region(opmode)
    local partial = cmotion == U.cmotion.char or cmotion == U.cmotion.v
    local block_x = partial and range.srow == range.erow

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

    if block_x or ctype == U.ctype.block then
        ctx.cmode = Op.blockwise(params, partial)
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
---@return integer _ Returns a calculated comment mode
function Op.linewise(param)
    local pattern = U.is_fn(param.cfg.ignore)
    local padding = U.is_fn(param.cfg.padding)
    local check_comment = U.is_commented(param.lcs, param.rcs, padding)

    -- While commenting a region, there could be lines being both commented and non-commented
    -- So, if any line is uncommented then we should comment the whole block or vise-versa
    local cmode = U.cmode.uncomment

    ---When commenting multiple line, it is to be expected that indentation should be preserved
    ---So, When looping over multiple lines we need to store the indentation of the mininum length (except empty line)
    ---Which will be used to semantically comment rest of the lines
    ---@type integer
    local min_indent = -1

    -- If the given cmode is uncomment then we actually don't want to compute the cmode or min_indent
    if param.cmode ~= U.cmode.uncomment then
        for _, line in ipairs(param.lines) do
            -- I wish lua had `continue` statement [sad noises]
            if not U.ignore(line, pattern) then
                if cmode == U.cmode.uncomment and (not check_comment(line)) then
                    cmode = U.cmode.comment
                end

                -- If local `cmode` == comment or the given cmode ~= uncomment, then only calculate min_indent
                -- As calculating min_indent only makes sense when we actually want to comment the lines
                if not U.is_empty(line) and (cmode == U.cmode.comment or param.cmode == U.cmode.comment) then
                    local len = U.indent_len(line)
                    if min_indent == -1 or min_indent > len then
                        min_indent = len
                    end
                end
            end
        end
    end

    if cmode == U.cmode.uncomment then
        local uncomment = U.uncommenter(param.lcs, param.rcs, padding)
        for i, line in ipairs(param.lines) do
            if not U.ignore(line, pattern) then
                param.lines[i] = uncomment(line)
            end
        end
    else
        local comment = U.commenter(param.lcs, param.rcs, padding, min_indent)
        for i, line in ipairs(param.lines) do
            if not U.ignore(line, pattern) then
                param.lines[i] = comment(line)
            end
        end
    end

    A.nvim_buf_set_lines(0, param.range.srow - 1, param.range.erow, false, param.lines)

    return cmode
end

---Full/Partial/Current-Line Block commenting
---@param param OpFnParams
---@param partial? boolean Comment the partial region (visual mode)
---@return integer _ Returns a calculated comment mode
function Op.blockwise(param, partial)
    local is_x = #param.lines == 1 -- current-line blockwise
    local lines = is_x and param.lines[1] or param.lines

    local padding = U.is_fn(param.cfg.padding)

    local scol, ecol = nil, nil
    if is_x or partial then
        scol, ecol = param.range.scol, param.range.ecol
    end

    -- If given mode is toggle then determine whether to comment or not
    local cmode = param.cmode
    if cmode == U.cmode.toggle then
        local is_cmt = U.is_commented(param.lcs, param.rcs, padding, scol, ecol)(lines)
        cmode = is_cmt and U.cmode.uncomment or U.cmode.comment
    end

    if cmode == U.cmode.uncomment then
        lines = U.uncommenter(param.lcs, param.rcs, padding, scol, ecol)(lines)
    else
        lines = U.commenter(param.lcs, param.rcs, padding, scol, ecol)(lines)
    end

    if is_x then
        A.nvim_set_current_line(lines)
    else
        A.nvim_buf_set_lines(0, param.range.srow - 1, param.range.erow, false, lines)
    end

    return cmode
end

---Line commenting with count i.e vim.v.count
---Example: '10gl' will comment 10 lines
---@param count integer Number of lines
---@param cfg CommentConfig
---@param ctype integer See |comment.utils.ctype|
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
