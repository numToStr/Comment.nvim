local U = require('Comment.utils')
local A = vim.api
local op = {}

---Opfunc options
---@class OfnOpts
---@field cfg Config
---@field cmode CMode
---@field lines table
---@field rcs string
---@field lcs string
---@field scol number
---@field ecol number

---Linewise commenting
---@param ctx Ctx
---@param p OfnOpts
---@return integer CMode
function op.linewise(ctx, p)
    local lcs_esc, rcs_esc = U.escape(p.lcs), U.escape(p.rcs)

    -- While commenting a block of text, there is a possiblity of lines being both commented and non-commented
    -- In that case, we need to figure out that if any line is uncommented then we should comment the whole block or vise-versa
    local cmode = U.cmode.uncomment

    -- When commenting multiple line, it is to be expected that indentation should be preserved
    -- So, When looping over multiple lines we need to store the indentation of the mininum length (except empty line)
    -- Which will be used to semantically comment rest of the lines
    local min_indent = nil

    -- Computed ignore pattern
    local pattern = U.get_pattern(p.cfg.ignore, ctx)

    -- If the given comde is uncomment then we actually don't want to compute the cmode or min_indent
    if ctx.cmode ~= U.cmode.uncomment then
        for _, line in ipairs(p.lines) do
            -- I wish lua had `continue` statement [sad noises]
            if not U.ignore(line, pattern) then
                if cmode == U.cmode.uncomment and ctx.cmode == U.cmode.toggle then
                    local is_cmt = U.is_commented(line, lcs_esc, nil, p.cfg.padding)
                    if not is_cmt then
                        cmode = U.cmode.comment
                    end
                end

                -- If the internal cmode changes to comment or the given cmode is not uncomment, then only calculate min_indent
                -- As calculating min_indent only makes sense when we actually want to comment the lines
                if not U.is_empty(line) and (cmode == U.cmode.comment or ctx.cmode == U.cmode.comment) then
                    local indent = line:match('^(%s*).*')
                    if not min_indent or #min_indent > #indent then
                        min_indent = indent
                    end
                end
            end
        end
    end

    -- If the comment mode given is not toggle than force that mode
    if ctx.cmode ~= U.cmode.toggle then
        cmode = ctx.cmode
    end

    local repls = {}
    local uncomment = cmode == U.cmode.uncomment

    for _, line in ipairs(p.lines) do
        if U.ignore(line, pattern) then
            table.insert(repls, line)
        else
            if uncomment then
                table.insert(repls, U.uncomment_str(line, lcs_esc, rcs_esc, p.cfg.padding))
            else
                table.insert(repls, U.comment_str(line, p.lcs, p.rcs, p.cfg.padding, min_indent))
            end
        end
    end
    A.nvim_buf_set_lines(0, p.scol, p.ecol, false, repls)

    return cmode
end

---Blockwise commenting
---@param p OfnOpts
---@return integer CMode
function op.blockwise(p)
    -- Block wise, only when there are more than 1 lines
    local sln, eln = p.lines[1], p.lines[2]
    local lcs_esc, rcs_esc = U.escape(p.lcs), U.escape(p.rcs)

    -- If given mode is toggle then determine whether to comment or not
    local cmode
    if p.cmode == U.cmode.toggle then
        local s_cmt = U.is_commented(sln, lcs_esc, nil, p.cfg.padding)
        local e_cmt = U.is_commented(eln, nil, rcs_esc, p.cfg.padding)
        cmode = (s_cmt and e_cmt) and U.cmode.uncomment or U.cmode.comment
    else
        cmode = p.cmode
    end

    local l1, l2
    if cmode == U.cmode.uncomment then
        l1 = U.uncomment_str(sln, lcs_esc, nil, p.cfg.padding)
        l2 = U.uncomment_str(eln, nil, rcs_esc, p.cfg.padding)
    else
        l1 = U.comment_str(sln, p.lcs, nil, p.cfg.padding)
        l2 = U.comment_str(eln, nil, p.rcs, p.cfg.padding)
    end
    A.nvim_buf_set_lines(0, p.scol, p.scol + 1, false, { l1 })
    A.nvim_buf_set_lines(0, p.ecol - 1, p.ecol, false, { l2 })

    return cmode
end

---Blockwise (left-right motion) commenting
---@param p OfnOpts
---@param srow number
---@param erow number
---@return integer CMode
function op.blockwise_x(p, srow, erow)
    local line = p.lines[1]
    local srow1, erow1, erow2 = srow + 1, erow + 1, erow + 2
    local first = line:sub(0, srow)
    local mid = line:sub(srow1, erow1)
    local last = line:sub(erow2)

    local yes, _, stripped = U.is_commented(mid, U.escape(p.lcs), U.escape(p.rcs), p.cfg.padding)

    local cmode
    if p.cmode == U.cmode.toggle then
        cmode = yes and U.cmode.uncomment or U.cmode.comment
    else
        cmode = p.cmode
    end

    if cmode == U.cmode.uncomment then
        A.nvim_set_current_line(first .. (stripped or mid) .. last)
    else
        local pad = p.cfg.padding and ' ' or ''
        local lcs = p.lcs and p.lcs .. pad or ''
        local rcs = p.rcs and pad .. p.rcs or ''
        A.nvim_set_current_line(first .. lcs .. mid .. rcs .. last)
    end

    return cmode
end

return op
