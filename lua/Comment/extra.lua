---@mod comment.extra Extra functions

local U = require('Comment.utils')
local A = vim.api

local extra = {}

-- FIXME This prints `a` in i_CTRL-o
---Moves the cursor and enters INSERT mode
---@param row number Starting row
---@param col number Ending column
local function move_n_insert(row, col)
    A.nvim_win_set_cursor(0, { row, col })
    A.nvim_feedkeys('a', 'ni', true)
end

---@param count number Line index
---@param ctype number See |CommentType|
---@param cfg CommentConfig
local function ins_on_line(count, ctype, cfg)
    local row, col = unpack(A.nvim_win_get_cursor(0))

    ---@type CommentCtx
    local ctx = {
        cmode = U.cmode.comment,
        cmotion = U.cmotion.line,
        ctype = ctype,
        range = { srow = row, scol = col, erow = row, ecol = col },
    }

    local srow = row + count
    local lcs, rcs = U.parse_cstr(cfg, ctx)
    local line = A.nvim_get_current_line()
    local indent = U.indent_len(line)
    local padding = U.get_padding(cfg.padding)

    -- We need RHS of cstr, if we are doing block comments or if RHS exists
    -- because even in line comment RHS do exists for some filetypes like jsx_element, ocaml
    local if_rcs = U.is_empty(rcs) and rcs or padding .. rcs

    A.nvim_buf_set_lines(0, srow, srow, false, { table.concat({ string.rep(' ', indent), lcs, padding, if_rcs }) })

    move_n_insert(srow + 1, indent + #lcs + #padding - 1)
    U.is_fn(cfg.post_hook, ctx)
end

---Add a comment below the current line and goes to INSERT mode
---@param ctype number See |CommentType|
---@param cfg CommentConfig
function extra.insert_below(ctype, cfg)
    ins_on_line(0, ctype, cfg)
end

---Add a comment above the current line and goes to INSERT mode
---@param ctype number See |CommentType|
---@param cfg CommentConfig
function extra.insert_above(ctype, cfg)
    ins_on_line(-1, ctype, cfg)
end

---Add a comment at the end of current line and goes to INSERT mode
---@param ctype number See |CommentType|
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
    local padding = U.get_padding(cfg.padding)

    -- We need RHS of cstr, if we are doing block comments or if RHS exists
    -- because even in line comment RHS do exists for some filetypes like jsx_element, ocaml
    local if_rcs = U.is_empty(rcs) and rcs or padding .. rcs

    local ecol
    if U.is_empty(line) then
        -- If line is empty, start comment at the correct indentation level
        A.nvim_buf_set_lines(0, srow - 1, srow, false, { lcs .. padding .. if_rcs })
        A.nvim_command('normal! ==')
        ecol = #A.nvim_get_current_line() - #if_rcs - 1
    else
        -- NOTE:
        -- 1. Python is the only language that recommends 2 spaces between the statement and the comment
        -- 2. Other than that, I am assuming that the users wants a space b/w the end of line and start of the comment
        local space = vim.bo.filetype == 'python' and '  ' or ' '
        local ll = line .. space .. lcs .. padding

        ecol = #ll - 1
        A.nvim_buf_set_lines(0, srow - 1, srow, false, { ll .. if_rcs })
    end

    move_n_insert(srow, ecol)
    U.is_fn(cfg.post_hook, ctx)
end

return extra
