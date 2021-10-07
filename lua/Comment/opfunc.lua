local U = require('Comment.utils')
local A = vim.api
local op = {}

-- Two types of commenting
-- char, block
-- line

-- Visual mode commenting
--
-- V-BLOCK: block comment
--      - LHS cstr in every line before the first char (excluding whitespace)
--      - RHS cstr in every line after erow
--
-- V-LINE: line comment
-- VISUAL: line comment
--      - LHS cstr in every line before the first char (excluding whitespace)

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
---@param p OfnOpts
function op.linewise(p)
    local lcs_esc, rcs_esc = vim.pesc(p.lcs), vim.pesc(p.rcs)

    -- While commenting a block of text, there is a possiblity of lines being both commented and non-commented
    -- In that case, we need to figure out that if any line is uncommented then we should comment the whole block or vise-versa
    local _cmode = U.cmode.uncomment

    -- When commenting multiple line, it is to be expected that indentation should be preserved
    -- So, When looping over multiple lines we need to store the indentation of the mininum length (except empty line)
    -- Which will be used to semantically comment rest of the lines
    local min_indent = nil

    -- If the given comde is uncomment then we actually don't want to compute the cmode or min_indent
    if p.cmode ~= U.cmode.uncomment then
        for _, line in ipairs(p.lines) do
            -- I wish lua had `continue` statement [sad noises]
            if not U.ignore(line, p.cfg.ignore) then
                if _cmode == U.cmode.uncomment and p.cmode == U.cmode.toggle then
                    local is_cmt = U.is_commented(line, lcs_esc)
                    if not is_cmt then
                        _cmode = U.cmode.comment
                    end
                end

                -- If the internal cmode changes to comment or the given cmode is not uncomment, then only calculate min_indent
                -- As calculating min_indent only makes sense when we actually want to comment the lines
                if _cmode == U.cmode.comment or p.cmode == U.cmode.comment then
                    local indent, ln = U.split_half(line)
                    if not min_indent or (#min_indent > #indent) and #ln > 0 then
                        min_indent = indent
                    end
                end
            end
        end
    end

    -- If the comment mode given is not toggle than force that mode
    if p.cmode ~= U.cmode.toggle then
        _cmode = p.cmode
    end

    local repls = {}
    local uncomment = _cmode == U.cmode.uncomment

    for _, line in ipairs(p.lines) do
        if U.ignore(line, p.cfg.ignore) then
            table.insert(repls, line)
        else
            if uncomment then
                table.insert(repls, U.uncomment_str(line, lcs_esc, rcs_esc, p.cfg.padding))
            else
                table.insert(repls, U.comment_str(line, p.lcs, p.rcs, p.cfg.padding, min_indent or ''))
            end
        end
    end
    A.nvim_buf_set_lines(0, p.scol, p.ecol, false, repls)
end

---Blockwise commenting
---@param p OfnOpts
---@param len number
function op.blockwise(p, len)
    -- Block wise, only when there are more than 1 lines
    local start_ln, end_ln = p.lines[1], p.lines[len]
    local lcs_esc, rcs_esc = vim.pesc(p.lcs), vim.pesc(p.rcs)

    -- If given mode is toggle then determine whether to comment or not
    local _cmode
    if p.cmode == U.cmode.toggle then
        local is_start_commented = U.is_commented(start_ln, lcs_esc)
        local is_end_commented = end_ln:find(rcs_esc .. '$')
        _cmode = (is_start_commented and is_end_commented) and U.cmode.uncomment or U.cmode.comment
    else
        _cmode = p.cmode
    end

    local l1, l2
    if _cmode == U.cmode.uncomment then
        l1 = U.uncomment_str(start_ln, lcs_esc, '', p.cfg.padding)
        l2 = U.uncomment_str(end_ln, '', rcs_esc, p.cfg.padding)
    else
        l1 = U.comment_str(start_ln, p.lcs, '', p.cfg.padding)
        l2 = U.comment_str(end_ln, '', p.rcs, p.cfg.padding)
    end
    A.nvim_buf_set_lines(0, p.scol, p.scol + 1, false, { l1 })
    A.nvim_buf_set_lines(0, p.ecol - 1, p.ecol, false, { l2 })
end

---Blockwise (left-right motion) commenting
---@param p OfnOpts
---@param srow number
---@param erow number
function op.blockwise_x(p, srow, erow)
    local line = p.lines[1]
    local srow1, erow1, erow2 = srow + 1, erow + 1, erow + 2
    local first = line:sub(0, srow)
    local mid = line:sub(srow1, erow1)
    local last = line:sub(erow2)

    local stripped = U.is_block_commented(mid, vim.pesc(p.lcs), vim.pesc(p.rcs))

    local _cmode
    if p.cmode == U.cmode.toggle then
        _cmode = stripped and U.cmode.uncomment or U.cmode.comment
    else
        _cmode = p.cmode
    end

    if _cmode == U.cmode.uncomment then
        A.nvim_set_current_line(first .. (stripped or mid) .. last)
    else
        A.nvim_set_current_line(first .. p.lcs .. mid .. p.rcs .. last)
    end
end

return op
