local U2 = require('Comment.utils2')
local U = require('Comment.utils')

local O = {}

-- FIXME support RHS of commentstring
---Linewise commenting
---@param p OpFnParams
---@return integer CMode
function O.linewise(p)
    local padding = U.get_padding(p.cfg.padding)
    local lcs, rcs = p.lcs .. padding, (p.rcs and (padding .. p.rcs))
    local lcs_esc, _ = U.escape(lcs), U.escape(rcs)

    -- While commenting a block of text, there is a possiblity of lines being both commented and non-commented
    -- In that case, we need to figure out that if any line is uncommented then we should comment the whole block or vise-versa
    local cmode = U.cmode.uncomment

    -- When commenting multiple line, it is to be expected that indentation should be preserved
    -- So, When looping over multiple lines we need to store the indentation of the mininum length (except empty line)
    -- Which will be used to semantically comment rest of the lines
    local min_indent, end_of_lcs

    -- Computed ignore pattern
    local pattern = U.get_pattern(p.cfg.ignore)

    -- If the given comde is uncomment then we actually don't want to compute the cmode or min_indent
    if p.cmode ~= U.cmode.uncomment then
        for _, line in ipairs(p.lines) do
            -- I wish lua had `continue` statement [sad noises]
            if not U.ignore(line, pattern) then
                if cmode == U.cmode.uncomment and p.cmode == U.cmode.toggle then
                    local is_cmt, col_end_idx = U2.is_start_commented(line, lcs_esc)
                    if not is_cmt then
                        cmode = U.cmode.comment
                    else
                        end_of_lcs = col_end_idx
                    end
                end

                -- If the internal cmode changes to comment or the given cmode is not uncomment, then only calculate min_indent
                -- As calculating min_indent only makes sense when we actually want to comment the lines
                if not U.is_empty(line) and (cmode == U.cmode.comment or p.cmode == U.cmode.comment) then
                    local space_len = U.grab_indent(line)
                    if not min_indent or min_indent > space_len then
                        min_indent = space_len
                    end
                else
                    -- In case of uncomment we might only need indent of first line
                    min_indent = min_indent or U.grab_indent(line)
                end
            end
        end
    end

    -- If the comment mode given is not toggle than force that mode
    if p.cmode ~= U.cmode.toggle then
        cmode = p.cmode
    end

    local uncomment = cmode == U.cmode.uncomment
    for i, line in ipairs(p.lines) do
        if not U.ignore(line, pattern) then
            local srow = p.srow + i - 2
            if uncomment then
                U2.rm_comment(srow, min_indent, end_of_lcs)
            else
                U2.add_comment(srow, min_indent, min_indent, lcs)
            end
        end
    end

    return cmode
end

---FIXME support partial block
---Full/Partial Blockwise commenting
---@param p OpFnParams
---@param partial boolean Whether to do a partial or full comment
---@return integer CMode
function O.blockwise(p, partial)
    -- Block wise, only when there are more than 1 lines
    local sln, eln = p.lines[1], p.lines[2]
    local padding = U.get_padding(p.cfg.padding)
    local lcs, rcs = p.lcs .. padding, padding .. p.rcs
    local lcs_esc, rcs_esc = U.escape(lcs), U.escape(rcs)

    local cmode, scol_s, scol_e, ecol_s, ecol_e

    -- If given mode is toggle then determine whether to comment or not
    if p.cmode == U.cmode.toggle then
        scol_s, scol_e = U2.is_start_commented(sln, lcs_esc)
        ecol_s, ecol_e = U2.is_end_commented(eln, rcs_esc)

        cmode = (scol_s and ecol_s) and U.cmode.uncomment or U.cmode.comment
    else
        cmode = p.cmode
    end

    local srow, erow = p.srow - 1, p.erow - 1
    local space_len = U.grab_indent(sln)

    -- if the line is commented then we'll get the starting indexes of start and end comments
    -- if found then we'll just the remove the comment without touching the rest of the line
    if cmode == U.cmode.uncomment then
        U2.rm_comment(srow, space_len, scol_e)
        U2.rm_comment(erow, ecol_s - 1, ecol_e)

        return cmode
    end

    local eln_len = #eln
    U2.add_comment(srow, space_len, space_len, lcs)
    U2.add_comment(erow, eln_len, eln_len, rcs)

    return cmode
end

return O
