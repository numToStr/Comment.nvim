local U = require('Comment.utils')
local C = require('Comment.comment')

local M = {
    setup = C.setup,
    toggle = C.toggle_ln,
}

function M.comment()
    local cstr = U.is_hook(C.config.pre_hook)
    local r_cs, l_cs = C.unwrap_cstring(cstr)
    local l = vim.api.nvim_get_current_line()

    C.comment_ln(l, r_cs, l_cs)
    U.is_hook(C.config.post_hook, -1)
end

function M.uncomment()
    local cstr = U.is_hook(C.config.pre_hook)
    local r_cs, l_cs = C.unwrap_cstring(cstr)
    local l = vim.api.nvim_get_current_line()

    C.uncomment_ln(l, vim.pesc(r_cs), vim.pesc(l_cs))
    U.is_hook(C.config.post_hook, -1)
end

return M
