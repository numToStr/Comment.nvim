local C = require('Comment.comment')

local M = {
    setup = C.setup,
    toggle = C.toggle_ln,
}

function M.comment()
    local l = vim.api.nvim_get_current_line()
    local r_cs, l_cs = C.unwrap_cstring()

    C.comment_ln(l, r_cs, l_cs)
end

function M.uncomment()
    local l = vim.api.nvim_get_current_line()
    local r_cs, l_cs = C.unwrap_cstring()

    C.uncomment_ln(l, vim.pesc(r_cs), vim.pesc(l_cs))
end

return M
