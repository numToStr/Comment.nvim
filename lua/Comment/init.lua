local U = require('Comment.utils')
local C = require('Comment.comment')

local M = {
    setup = C.setup,
    toggle = C.toggle_ln,
}

---Comments the current line
function M.comment()
    local rcs, lcs = C.unwrap_cstr()
    local l = vim.api.nvim_get_current_line()

    C.comment_ln(l, rcs, lcs)
    U.is_hook(C.config.post_hook, -1)
end

---Unomments the current line
function M.uncomment()
    local rcs, lcs = C.unwrap_cstr()
    local line = vim.api.nvim_get_current_line()

    C.uncomment_ln(line, vim.pesc(rcs), vim.pesc(lcs))
    U.is_hook(C.config.post_hook, -1)
end

return M
