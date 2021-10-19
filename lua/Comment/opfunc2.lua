local U2 = require('Comment.utils2')
local U = require('Comment.utils')

local O = {}

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
    local _, space_len = U.grab_indent(sln)

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
