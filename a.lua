local U = require('Comment.utils')
local Op = require('Comment.opfunc')
local A = vim.api

function _G.___comment_count_gc()
    ---@type Ctx
    local ctx = {
        cmode = U.cmode.toggle,
        cmotion = U.cmotion.line,
        ctype = U.ctype.line,
    }

    local pos = A.nvim_win_get_cursor(0)
    local scol = pos[1]
    local ecol = (scol + vim.v.count) - 1
    local lines = A.nvim_buf_get_lines(0, scol - 1, ecol, false)

    local lcs, rcs = U.unwrap_cstr(vim.bo.commentstring)

    ctx.cmode = Op.linewise({
        cfg = { padding = true },
        cmode = ctx.cmode,
        lines = lines,
        lcs = lcs,
        rcs = rcs,
        scol = scol,
        ecol = ecol,
    })
end

A.nvim_set_keymap('n', 'gl', '<CMD>lua ___comment_count_gc()<CR>', { noremap = true, silent = true })
