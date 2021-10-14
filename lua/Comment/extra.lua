local U = require('Comment.utils')
local Op = require('Comment.opfunc')
local A = vim.api

local E = {}

---Toggle line comment with count
---Example: `10gl` will comment 10 lines
---@param cfg Config
function E.count(cfg)
    cfg = cfg or {}
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
local function base_o(count, ctype, cfg)
    cfg = cfg or {}
    ---@type Ctx
    local ctx = {
        cmode = U.cmode.comment,
        cmotion = U.cmotion.line,
        ctype = ctype,
    }

    -- Computing the new line and setting it up
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

    -- From here cursor starts to dance :)
    local ecol, erow = scol + 1, #ll - 1
    A.nvim_win_set_cursor(0, { ecol, erow })
    U.ins_mode()

    U.is_fn(cfg.post_hook, ctx, scol, ecol, srow, erow)
end

---Add a comment below the current line and goes to INSERT mode
---@param ctype CType
---@param cfg Config
function E.o(ctype, cfg)
    base_o(0, ctype, cfg)
end

---Add a comment above the current line and goes to INSERT mode
---@param ctype CType
---@param cfg Config
function E.O(ctype, cfg)
    base_o(-1, ctype, cfg)
end

return E
