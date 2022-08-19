---@mod comment.extra Extra API
---@brief [[
---Underlying functions that powers the |comment.api.insert| lua API.
---@brief ]]

local U = require('Comment.utils')
local A = vim.api

local extra = {}

-- FIXME This prints `a` in i_CTRL-o
---Moves the cursor and enters INSERT mode
---@param row integer Starting row
---@param col integer Ending column
local function move_n_insert(row, col)
    A.nvim_win_set_cursor(0, { row, col })
    A.nvim_feedkeys('a', 'ni', true)
end

---@param lnum integer Line index
---@param ctype integer
---@param cfg CommentConfig
local function ins_on_line(lnum, ctype, cfg)
    local row, col = unpack(A.nvim_win_get_cursor(0))

    ---@type CommentCtx
    local ctx = {
        cmode = U.cmode.comment,
        cmotion = U.cmotion.line,
        ctype = ctype,
        range = { srow = row, scol = col, erow = row, ecol = col },
    }

    local srow = row + lnum
    local lcs, rcs = U.parse_cstr(cfg, ctx)
    local padding = U.get_pad(U.is_fn(cfg.padding))

    -- We need RHS of cstr, if we are doing block comments or if RHS exists
    -- because even in line comment RHS do exists for some filetypes like jsx_element, ocaml
    local if_rcs = U.is_empty(rcs) and rcs or padding .. rcs

    A.nvim_buf_set_lines(0, srow, srow, false, { lcs .. padding .. if_rcs })
    A.nvim_win_set_cursor(0, { srow + 1, 0 })
    A.nvim_command('normal! ==')
    move_n_insert(srow + 1, #A.nvim_get_current_line() - #if_rcs - 1)
    U.is_fn(cfg.post_hook, ctx)
end

---Add a comment below the current line and goes to INSERT mode
---@param ctype integer See |comment.utils.ctype|
---@param cfg CommentConfig
function extra.insert_below(ctype, cfg)
    ins_on_line(0, ctype, cfg)
end

---Add a comment above the current line and goes to INSERT mode
---@param ctype integer See |comment.utils.ctype|
---@param cfg CommentConfig
function extra.insert_above(ctype, cfg)
    ins_on_line(-1, ctype, cfg)
end

---Add a comment at the end of current line and goes to INSERT mode
---@param ctype integer See |comment.utils.ctype|
---@param cfg CommentConfig
function extra.insert_eol(ctype, cfg)
    local srow, scol = unpack(A.nvim_win_get_cursor(0))

    ---@type CommentCtx
    local ctx = {
        cmode = U.cmode.comment,
        cmotion = U.cmotion.line,
        ctype = ctype,
        range = { srow = srow, scol = scol, erow = srow, ecol = scol },
    }
    local lcs, rcs = U.parse_cstr(cfg, ctx)

    local line = A.nvim_get_current_line()
    local padding = U.get_pad(U.is_fn(cfg.padding))

    -- We need RHS of cstr, if we are doing block comments or if RHS exists
    -- because even in line comment RHS do exists for some filetypes like jsx_element, ocaml
    local if_rcs = U.is_empty(rcs) and rcs or padding .. rcs

    local ecol
    if U.is_empty(line) then
        -- If line is empty, start comment at the correct indentation level
        A.nvim_set_current_line(lcs .. padding .. if_rcs)
        A.nvim_command('normal! ==')
        ecol = #A.nvim_get_current_line() - #if_rcs - 1
    else
        -- NOTE:
        -- 1. Python is the only language that recommends 2 spaces between the statement and the comment
        -- 2. Other than that, I am assuming that the users wants a space b/w the end of line and start of the comment
        local space = vim.bo.filetype == 'python' and '  ' or ' '
        local ll = line .. space .. lcs .. padding
        A.nvim_set_current_line(ll .. if_rcs)
        ecol = #ll - 1
    end

    move_n_insert(srow, ecol)
    U.is_fn(cfg.post_hook, ctx)
end

return extra
