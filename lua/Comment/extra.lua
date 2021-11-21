local U = require('Comment.utils')
local A = vim.api

local E = {}

---@param count number Line index
---@param ctype CType
---@param cfg Config
local function ins_on_line(count, ctype, cfg)
    local row, col = unpack(A.nvim_win_get_cursor(0))

    ---@type Ctx
    local ctx = {
        cmode = U.cmode.comment,
        cmotion = U.cmotion.line,
        ctype = ctype,
        range = { srow = row, scol = col, erow = row, ecol = col },
    }
    local lcs, rcs = U.parse_cstr(cfg, ctx)

    local line = A.nvim_get_current_line()
    local indent = U.grab_indent(line)
    local padding = U.get_padding(cfg.padding)

    -- We need RHS of cstr, if we are doing block comments or if RHS exists
    -- because even in line comment RHS do exists for some filetypes like jsx_element, ocaml
    local if_rcs = (ctype == U.ctype.block or rcs) and padding .. rcs or ''

    local srow = row + count
    local ll = indent .. lcs .. padding
    A.nvim_buf_set_lines(0, srow, srow, false, { ll .. if_rcs })
    local erow, ecol = srow + 1, #ll - 1
    U.move_n_insert(erow, ecol)
    U.is_fn(cfg.post_hook, ctx)
end

---Add a comment below the current line and goes to INSERT mode
---@param ctype CType
---@param cfg Config
function E.norm_o(ctype, cfg)
    ins_on_line(0, ctype, cfg)
end

---Add a comment above the current line and goes to INSERT mode
---@param ctype CType
---@param cfg Config
function E.norm_O(ctype, cfg)
    ins_on_line(-1, ctype, cfg)
end

---Add a comment at the end of current line and goes to INSERT mode
---@param ctype CType
---@param cfg Config
function E.norm_A(ctype, cfg)
    local srow, scol = unpack(A.nvim_win_get_cursor(0))

    ---@type Ctx
    local ctx = {
        cmode = U.cmode.comment,
        cmotion = U.cmotion.line,
        ctype = ctype,
        range = { srow = srow, scol = scol, erow = srow, ecol = scol },
    }
    local lcs, rcs = U.parse_cstr(cfg, ctx)

    local line = A.nvim_get_current_line()
    local padding = U.get_padding(cfg.padding)

    -- NOTE:
    -- 1. Python is the only language that recommends 2 spaces between the statement and the comment
    -- 2. Other than that, I am assuming that the users wants a space b/w the end of line and start of the comment
    local space = vim.bo.filetype == 'python' and '  ' or ' '
    local ll = line .. space .. lcs .. padding

    -- We need RHS of cstr, if we are doing block comments or if RHS exists
    -- because even in line comment RHS do exists for some filetypes like jsx_element, ocaml
    local if_rcs = (ctype == U.ctype.block or rcs) and padding .. rcs or ''

    local erow, ecol = srow - 1, #ll - 1
    A.nvim_buf_set_lines(0, erow, srow, false, { ll .. if_rcs })
    U.move_n_insert(srow, ecol)
    U.is_fn(cfg.post_hook, ctx)
end

return E
