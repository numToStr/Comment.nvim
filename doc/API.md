# ⚙️ API

### Core

```lua
---@alias VMode 'line'|'char'|'v'|'V' Vim Mode. Read `:h map-operator`
---@alias cfg table Same as `.setup({cfg})`

---Toggle comment on a line
require('Comment.api').toggle()

---Comment a line
require('Comment.api').comment()

---Uncomment a line
require('Comment.api').uncomment()

---Line comment with a count
---@param count integer Number of lines. (default: `vim.v.count`)
---@param cfg Config If not provided, will use the default config
require('Comment.api').count_gcc(count, cfg)

---Toggle comment using linewise comment. This powers the default `gcc` mapping.
---@param vmode VMode
---@param cfg Config
require('Comment.api').gcc(vmode, cfg)

---Toggle comment using blockwise comment. This powers the default `gbc` mapping.
---@param vmode VMode
---@param cfg Config
require('Comment.api').gbc(vmode, cfg)

---(Operator-Pending) Toggle comment using linewise comment. This powers the default `gc` mapping.
---@param vmode VMode
---@param cfg Config
require('Comment.api').gc(vmode, cfg)

---(Operator-Pending) Toggle comment using blockwise comment. This powers the default `gb` mapping.
---@param vmode VMode
---@param cfg Config
require('Comment.api').gb(vmode, cfg)
```

> If you enabled `config.mappings.extra` then you can get access to these

```lua
---Add comment on the line below and go to insert-mode
require('Comment.api').gco()

---Add comment on the line above and go to insert-mode
require('Comment.api').gcO()

---Add comment at the end-of-line and go to insert-mode
require('Comment.api').gcA()
```

<!-- TODO: -->
<!-- - Document `opfunc` -->
<!-- - Document `extra` -->
