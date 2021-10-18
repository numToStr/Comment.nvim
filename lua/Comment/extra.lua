local U = require('Comment.utils')
local A = vim.api

local E = {}

---@param count number Line index
---@param ctype CType
---@param cfg Config
---@param tag string (optional) tag after start of comment
local function ins_on_line(count, ctype, cfg, tag)
    ---@type Ctx
    local ctx = {
        cmode = U.cmode.comment,
        cmotion = U.cmotion.line,
        ctype = ctype,
    }

    local pos = A.nvim_win_get_cursor(0)
    local srow, scol = pos[1] + count, pos[2]
    local line = A.nvim_get_current_line()
    local indent = U.grab_indent(line)
    local lcs, rcs = U.parse_cstr(cfg, ctx)
    local padding = U.get_padding(cfg.padding)

    -- We need RHS of cstr, if we are doing block comments or if RHS exists
    -- because even in line comment RHS do exists for some filetypes like jsx_element, ocaml
    local if_rcs = (ctype == U.ctype.block or rcs) and padding .. rcs or ''

    local ll = indent .. lcs .. padding .. (tag or '')
    A.nvim_buf_set_lines(0, srow, srow, false, { ll .. if_rcs })
    local erow, ecol = srow + 1, #ll - 1
    U.move_n_insert(erow, ecol)
    U.is_fn(cfg.post_hook, ctx, srow, erow, scol, ecol)
end

---Add a comment below the current line and goes to INSERT mode
---@param ctype CType
---@param cfg Config
function E.norm_o(ctype, cfg, tag)
    ins_on_line(0, ctype, cfg, tag)
end

---Add a comment above the current line and goes to INSERT mode
---@param ctype CType
---@param cfg Config
function E.norm_O(ctype, cfg, tag)
    ins_on_line(-1, ctype, cfg, tag)
end

---Add a comment at the end of current line and goes to INSERT mode
---@param ctype CType
---@param cfg Config
function E.norm_A(ctype, cfg, tag)
    ---@type Ctx
    local ctx = {
        cmode = U.cmode.comment,
        cmotion = U.cmotion.line,
        ctype = ctype,
    }

    local pos = A.nvim_win_get_cursor(0)
    local line = A.nvim_get_current_line()
    local lcs, rcs = U.parse_cstr(cfg, ctx)
    local padding = U.get_padding(cfg.padding)

    -- NOTE:
    -- 1. Python is the only language that recommends 2 spaces between the statement and the comment
    -- 2. Other than that, I am assuming that the users wants a space b/w the end of line and start of the comment
    local space = vim.bo.filetype == 'python' and '  ' or ' '
    local ll = line .. space .. lcs .. padding .. (tag or '')

    -- We need RHS of cstr, if we are doing block comments or if RHS exists
    -- because even in line comment RHS do exists for some filetypes like jsx_element, ocaml
    local if_rcs = (ctype == U.ctype.block or rcs) and padding .. rcs or ''

    local srow, scol = pos[1], pos[2]
    local erow, ecol = srow - 1, #ll - 1
    A.nvim_buf_set_lines(0, erow, srow, false, { ll .. if_rcs })
    U.move_n_insert(srow, ecol)
    U.is_fn(cfg.post_hook, ctx, srow, erow, scol, ecol)
end

return E
