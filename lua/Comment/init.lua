local c = require('Comment.comment')

local M = {
    setup = c.setup,
    operator = c.operator,
    toggle = c.toggle_ln,
}

function M.comment()
    local l = vim.api.nvim_get_current_line()
    local r_cs, l_cs = c.unwrap_cstring()

    c.comment_ln(l, r_cs, l_cs)
end

function M.uncomment()
    local l = vim.api.nvim_get_current_line()
    local r_cs, l_cs = c.unwrap_cstring()

    c.uncomment_ln(l, vim.pesc(r_cs), vim.pesc(l_cs))
end

return M
