# ⚙️ API

### Core

<!-- ---Line comment with a count -->
<!-- ---@param count integer Number of lines. (default: `vim.v.count`) -->
<!-- ---@param cfg Config If not provided, will use the default config -->
<!-- require('Comment.api').gcc_count(count, cfg) -->

```lua
---@alias VMode 'line'|'char'|'v'|'V' Vim Mode. Read `:h map-operator`
---@alias Config table Read https://github.com/numToStr/Comment.nvim/tree/master#configuration-optional

---Toggle comment on the current line (using linewise comment)
require('Comment.api').toggle()

---Comment the current line (using linewise comment)
require('Comment.api').comment()

---Uncomment the current line (using linewise comment)
require('Comment.api').uncomment()

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

> NOTE: If `cfg` argument is not provided, then the [default config](https://github.com/numToStr/Comment.nvim/tree/master#configuration-optional) will be used or the custom config provided during the [`setup()`](https://github.com/numToStr/Comment.nvim/tree/master#setup). BTW, You can also use these function without calling the `setup()` :)

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
