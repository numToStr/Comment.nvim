local U = require('Comment.utils')
local Op = require('Comment.opfunc')
local A = vim.api

local E = {}

---Toggle line comment with count
---Example: `10gl` will comment 10 lines
---@param cfg Config
function E.count(cfg)
    ---@type Ctx
    local ctx = {
        cmode = U.cmode.toggle,
        cmotion = U.cmotion.line,
        ctype = U.ctype.line,
    }
    local lcs, rcs = U.parse_cstr(cfg, ctx)
    local scol, ecol, lines = U.get_count_lines(vim.v.count)
    ctx.cmode = Op.linewise({
        cfg = cfg,
        cmode = ctx.cmode,
        lines = lines,
        lcs = lcs,
        rcs = rcs,
        scol = scol,
        ecol = ecol,
    })
    U.is_fn(cfg.post_hook, ctx, scol, ecol)
end

---@param count number Line index
---@param ctype CType
---@param cfg Config
local function ins_on_line(count, ctype, cfg)
    ---@type Ctx
    local ctx = {
        cmode = U.cmode.comment,
        cmotion = U.cmotion.line,
        ctype = ctype,
    }

    local pos = A.nvim_win_get_cursor(0)
    local scol, srow = pos[1] + count, pos[2]
    local line = A.nvim_get_current_line()
    local indent = U.grab_indent(line)
    local lcs, rcs = U.parse_cstr(cfg, ctx)
    local padding = U.get_padding(cfg.padding)

    -- We need RHS of cstr, if we are doing block comments or if RHS exists
    -- because even in line comment RHS do exists for some filetypes like jsx_element, ocaml
    local if_rcs = (ctype == U.ctype.block or rcs) and padding .. rcs or ''

    local ll = indent .. lcs .. padding
    A.nvim_buf_set_lines(0, scol, scol, false, { ll .. if_rcs })
    local ecol, erow = scol + 1, #ll - 1
    U.move_n_insert(ecol, erow)
    U.is_fn(cfg.post_hook, ctx, scol, ecol, srow, erow)
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

    -- I am assuming that the users wants a space b/w the end of line and start of the comment
    local ll = line .. ' ' .. lcs .. padding

    -- We need RHS of cstr, if we are doing block comments or if RHS exists
    -- because even in line comment RHS do exists for some filetypes like jsx_element, ocaml
    local if_rcs = (ctype == U.ctype.block or rcs) and padding .. rcs or ''

    local scol, srow = pos[1], pos[2]
    local ecol, erow = scol - 1, #ll - 1
    A.nvim_buf_set_lines(0, ecol, scol, false, { ll .. if_rcs })
    U.move_n_insert(scol, erow)
    U.is_fn(cfg.post_hook, ctx, scol, ecol, srow, erow)
end

return E
