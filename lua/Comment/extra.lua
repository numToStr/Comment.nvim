local U = require('Comment.utils')
local Op = require('Comment.opfunc')

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

return E
