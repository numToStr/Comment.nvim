<h1 align="center">// Comment.nvim </h1>
<p align="center"><sup>⚡ Smart and Powerful commenting plugin for neovim ⚡</sup></p>

![Comment.nvim](https://user-images.githubusercontent.com/42532967/136532939-926a8350-84b7-4e78-b045-fe21b5947388.gif "Commenting go brrrr")

### ✨ Features

- Supports treesitter. [Read more](#treesitter)
- Supports `commentstring`. [Read more](#commentstring)
- Prefers single-line/linewise comments
- Supports line (`//`) and block (`/* */`) comments
- Dot (`.`) repeat support for `gcc`, `gbc` and friends
- Count support for `[count]gcc` and `[count]gbc`
- Left-right (`gcw` `gc$`) and Up-Down (`gc2j` `gc4k`) motions
- Use with text-objects (`gci{` `gbat`)
- Supports pre and post hooks
- Ignore certain lines, powered by Lua regex

### 🚀 Installation

- With [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
    'numToStr/Comment.nvim',
    config = function()
        require('Comment').setup()
    end
}
```

- With [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'numToStr/Comment.nvim'

" Somewhere after plug#end()
lua require('Comment').setup()
```

<a id="setup"></a>

### ⚒️ Setup

First you need to call the `setup()` method to create the default mappings.

- Lua

```lua
require('Comment').setup()
```

- VimL

```vim
lua << EOF
require('Comment').setup()
EOF
```

<a id="config"></a>

#### Configuration (optional)

Following are the **default** config for the [`setup()`](#setup). If you want to override, just modify the option that you want then it will be merged with the default config.

```lua
{
    ---Add a space b/w comment and the line
    ---@type boolean|fun():boolean
    padding = true,

    ---Whether the cursor should stay at its position
    ---NOTE: This only affects NORMAL mode mappings and doesn't work with dot-repeat
    ---@type boolean
    sticky = true,

    ---Lines to be ignored while comment/uncomment.
    ---Could be a regex string or a function that returns a regex string.
    ---Example: Use '^$' to ignore empty lines
    ---@type string|fun():string
    ignore = nil,

    ---LHS of toggle mappings in NORMAL + VISUAL mode
    ---@type table
    toggler = {
        ---Line-comment toggle keymap
        line = 'gcc',
        ---Block-comment toggle keymap
        block = 'gbc',
    },

    ---LHS of operator-pending mappings in NORMAL + VISUAL mode
    ---@type table
    opleader = {
        ---Line-comment keymap
        line = 'gc',
        ---Block-comment keymap
        block = 'gb',
    },

    ---LHS of extra mappings
    ---@type table
    extra = {
        ---Add comment on the line above
        above = 'gcO',
        ---Add comment on the line below
        below = 'gco',
        ---Add comment at the end of line
        eol = 'gcA',
    },

    ---Create basic (operator-pending) and extended mappings for NORMAL + VISUAL mode
    ---NOTE: If `mappings = false` then the plugin won't create any mappings
    ---@type boolean|table
    mappings = {
        ---Operator-pending mapping
        ---Includes `gcc`, `gbc`, `gc[count]{motion}` and `gb[count]{motion}`
        ---NOTE: These mappings can be changed individually by `opleader` and `toggler` config
        basic = true,
        ---Extra mapping
        ---Includes `gco`, `gcO`, `gcA`
        extra = true,
        ---Extended mapping
        ---Includes `g>`, `g<`, `g>[count]{motion}` and `g<[count]{motion}`
        extended = false,
    },

    ---Pre-hook, called before commenting the line
    ---@type fun(ctx: Ctx):string
    pre_hook = nil,

    ---Post-hook, called after commenting is done
    ---@type fun(ctx: Ctx)
    post_hook = nil,
}
```

### 🔥 Usage

When you call [`setup()`](#setup) method, `Comment.nvim` sets up some basic mapping which can used in NORMAL and VISUAL mode to get you started with the pleasure of commenting stuff out.

<a id="basic-mappings"></a>

#### Basic mappings

These mappings are enabled by default. (config: `mappings.basic`)

- NORMAL mode

```help
`gcc` - Toggles the current line using linewise comment
`gbc` - Toggles the current line using blockwise comment
`[count]gcc` - Toggles the number of line given as a prefix-count using linewise
`[count]gbc` - Toggles the number of line given as a prefix-count using blockwise
`gc[count]{motion}` - (Op-pending) Toggles the region using linewise comment
`gb[count]{motion}` - (Op-pending) Toggles the region using blockwise comment
```

- VISUAL mode

```help
`gc` - Toggles the region using linewise comment
`gb` - Toggles the region using blockwise comment
```

<a id="extra-mappings"></a>

#### Extra mappings

These mappings are enabled by default. (config: `mappings.extra`)

- NORMAL mode

```help
`gco` - Insert comment to the next line and enters INSERT mode
`gcO` - Insert comment to the previous line and enters INSERT mode
`gcA` - Insert comment to end of the current line and enters INSERT mode
```

<a id="extended-mappings"></a>

#### Extended mappings

These mappings are disabled by default. (config: `mappings.extended`)

- NORMAL mode

```help
`g>[count]{motion}` - (Op-pending) Comments the region using linewise comment
`g>c` - Comments the current line using linewise comment
`g>b` - Comments the current line using blockwise comment
`g<[count]{motion}` - (Op-pending) Uncomments the region using linewise comment
`g<c` - Uncomments the current line using linewise comment
`g<b`- Uncomments the current line using blockwise comment
```

- VISUAL mode

```help
`g>` - Comments the region using single line
`g<` - Unomments the region using single line
```

##### Examples

```help
# Linewise

`gcw` - Toggle from the current cursor position to the next word
`gc$` - Toggle from the current cursor position to the end of line
`gc}` - Toggle until the next blank line
`gc5j` - Toggle 5 lines after the current cursor position
`gc8k` - Toggle 8 lines before the current cursor position
`gcip` - Toggle inside of paragraph
`gca}` - Toggle around curly brackets

# Blockwise

`gb2}` - Toggle until the 2 next blank line
`gbaf` - Toggle comment around a function (w/ LSP/treesitter support)
`gbac` - Toggle comment around a class (w/ LSP/treesitter support)
```

<a id="api"></a>

### ⚙️ API

- [Plug Mappings](./doc/plugs.md) - Excellent for creating custom keybindings

- [Lua API](./doc/API.md) - Details the Lua API. Great for making custom comment function.

<a id="treesitter"></a>

### 🌳 Treesitter

This plugin has native **treesitter** support for calculating `commentstring` which works for multiple (injected/embedded) languages like Vue or Markdown. But due to the nature of the parsed tree, this implementation has some known limitations.

1. No `jsx/tsx` support. Its implementation was quite complicated.
2. Invalid comment on the region where one language ends and the other starts. [Read more](https://github.com/numToStr/Comment.nvim/pull/62#issuecomment-972790418)

For advance use cases, use [nvim-ts-context-commentstring](https://github.com/JoosepAlviste/nvim-ts-context-commentstring). See [`pre_hook`](#pre-hook) section for the integration.

<a id="hooks"></a>

### 🎣 Hooks

There are two hook methods i.e `pre_hook` and `post_hook` which are called before comment and after comment respectively. Both should be provided during [`setup()`](#setup).

<a id="pre-hook"></a>

- `pre_hook` - This method is called with a [`ctx`](#comment-context) argument before comment/uncomment is started. It can be used to return a custom `commentstring` which will be used for comment/uncomment the lines. You can use something like [nvim-ts-context-commentstring](https://github.com/JoosepAlviste/nvim-ts-context-commentstring) to compute the commentstring using treesitter.

```lua
-- NOTE: The example below is a proper integration and it is RECOMMENDED.
{
    ---@param ctx Ctx
    pre_hook = function(ctx)
        -- Only calculate commentstring for tsx filetypes
        if vim.bo.filetype == 'typescriptreact' then
            local U = require('Comment.utils')

            -- Determine whether to use linewise or blockwise commentstring
            local type = ctx.ctype == U.ctype.line and '__default' or '__multiline'

            -- Determine the location where to calculate commentstring from
            local location = nil
            if ctx.ctype == U.ctype.block then
                location = require('ts_context_commentstring.utils').get_cursor_location()
            elseif ctx.cmotion == U.cmotion.v or ctx.cmotion == U.cmotion.V then
                location = require('ts_context_commentstring.utils').get_visual_start_location()
            end

            return require('ts_context_commentstring.internal').calculate_commentstring({
                key = type,
                location = location,
            })
        end
    end,
}
```

<a id="post-hook"></a>

- `post_hook` - This method is called after commenting is done. It receives the same [`ctx`](#comment-context) argument as [`pre_hook`](#pre_hook).

```lua
{
    ---@param ctx Ctx
    post_hook = function(ctx)
        if ctx.range.srow == ctx.range.erow then
            -- do something with the current line
        else
            -- do something with lines range
        end
    end
}
```

The `post_hook` can be implemented to cover some niche use cases like the following:

- Using newlines instead of padding e.g. for commenting out code in C with `#if 0`. See an example [here](https://github.com/numToStr/Comment.nvim/issues/38#issuecomment-945082507).
- Duplicating the commented block (using `pre_hook`) and moving the cursor to the next block (using `post_hook`). See [this](https://github.com/numToStr/Comment.nvim/issues/70).

> NOTE: When pressing `gc`, `gb` and friends, `cmode` (Comment mode) inside `pre_hook` will always be toggle because when pre-hook is called, in that moment we don't know whether `gc` or `gb` will comment or uncomment the lines. But luckily, we do know this before `post_hook` and this will always receive either comment or uncomment status

### 🚫 Ignoring lines

You can use `ignore` to ignore certain lines during comment/uncomment. It can takes lua regex string or a function that returns a regex string and should be provided during [`setup()`](#setup).

> NOTE: Ignore only works when with linewise comment. This is by design. As ignoring lines in block comments doesn't make that much sense.

- With `string`

```lua
-- ignores empty lines
ignore = '^$'

-- ignores line that starts with `local` (excluding any leading whitespace)
ignore = '^(%s*)local'

-- ignores any lines similar to arrow function
ignore = '^const(.*)=(%s?)%((.*)%)(%s?)=>'
```

- With `function`

```lua
{
    ignore = function()
        -- Only ignore empty lines for lua files
        if vim.bo.filetype == 'lua' then
            return '^$'
        end
    end,
}
```

<a id="languages"></a>

### 🗨️ Filetypes + Languages

Most languages/filetypes have native support for comments via `commentstring` but there might be a filetype that is not supported. There are two ways to enable commenting for unsupported filetypes:

1.  You can set `commentstring` for that particular filetype like the following

```lua
vim.bo.commentstring = '//%s'

-- or
vim.api.nvim_command('set commentstring=//%s')
```

> Run `:h commentstring` for more help

2. You can also use this plugin interface to store both line and block commentstring for the filetype. You can treat this as a more powerful version of the `commentstring`

```lua
local ft = require('Comment.ft')

-- 1. Using set function

-- Just set only line comment
ft.set('yaml', '#%s')

-- Or set both line and block commentstring
-- You can also chain the set calls
ft.set('javascript', {'//%s', '/*%s*/'}).set('conf', '#%s')

-- 2. Metatable magic

-- One filetype at a time
ft.javascript = {'//%s', '/*%s*/'}
ft.yaml = '#%s'

-- Multiple filetypes
ft({'go', 'rust'}, {'//%s', '/*%s*/'})
ft({'toml', 'graphql'}, '#%s')

-- 3. Get the whole set of commentstring
ft.lang('lua') -- { '--%s', '--[[%s]]' }
ft.lang('javascript') -- { '//%s', '/*%s*/' }
```

> PR(s) are welcome to add more commentstring inside the plugin

<a id="commentstring"></a>

### 🧵 Comment String

Although, `Comment.nvim` supports neovim's `commentstring` but unfortunately it has the least priority. The commentstring is taken from the following place in the respective order.

- [`pre_hook`](#hooks) - If a string is returned from this method then it will be used for commenting.

- [`ft_table`](#languages) - If the current filetype is found in the table, then the string there will be used.

- `commentstring` - Neovim's native commentstring for the filetype

<a id="commentstring-caveat"></a>

> There is one caveat with this approach. If someone sets the `commentstring` (w/o returning a string) from the `pre_hook` method and if the current filetype also exists in the `ft_table` then the commenting will be done using the string in `ft_table` instead of using `commentstring`

<a id="comment-context"></a>

### 🧠 Comment Context

The following object is provided as an argument to `pre_hook` and `post_hook` functions.

> I am just placing it here just for documentation purpose

```lua
---Comment context
---@class Ctx
---@field ctype CType
---@field cmode CMode
---@field cmotion CMotion
---@field range CRange

---Range of the selection that needs to be commented
---@class CRange
---@field srow number Starting row
---@field scol number Starting column
---@field erow number Ending row
---@field ecol number Ending column
```

`CType` (Comment type), `CMode` (Comment mode) and `CMotion` (Comment motion) all of them are exported from the plugin's utils for reuse

```lua
require('Comment.utils').ctype.{line,block}

require('Comment.utils').cmode.{toggle,comment,uncomment}

require('Comment.utils').cmotion.{line,char,v,V}
```

### 🤝 Contributing

There are multiple ways to contribute reporting/fixing bugs, feature requests. You can also submit commentstring to this plugin by updating [ft.lua](./lua/Comment/ft.lua) and sending PR.

### 📺 Videos

- [TakeTuesday E02: Comment.nvim](https://www.youtube.com/watch?v=-InmtHhk2qM) by [TJ DeVries](https://github.com/tjdevries)

### 💐 Credits

- [tcomment](https://github.com/tomtom/tcomment_vim) - To be with me forever and motivated me to write this.
- [nvim-comment](https://github.com/terrortylor/nvim-comment) - Little and less powerful cousin. Also I took some code from it.
- [kommentary](https://github.com/b3nj5m1n/kommentary) - Nicely done plugin but lacks some features. But it helped me to design this plugin.

### 🚗 Roadmap

- Doc comment i.e `/**%s*/` (js), `///%s` (rust)
- Header comment

```lua
----------------------
-- This is a header --
----------------------
```
