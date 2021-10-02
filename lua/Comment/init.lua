local U = require('Comment.utils')
local C = require('Comment.comment')

local M = {
    setup = C.setup,
    toggle = C.toggle_ln,
}

function M.comment()
    local r_cs, l_cs = C.unwrap_cstr()
    local l = vim.api.nvim_get_current_line()

    C.comment_ln(l, r_cs, l_cs)
    U.is_hook(C.config.post_hook, -1)
end

function M.uncomment()
    local r_cs, l_cs = C.unwrap_cstr()
    local r_cs_esc = vim.pesc(r_cs)
    local line = vim.api.nvim_get_current_line()

    if U.is_commented(line, r_cs_esc) then
        C.uncomment_ln(line, r_cs_esc, vim.pesc(l_cs))
        U.is_hook(C.config.post_hook, -1)
    end
end

return M
