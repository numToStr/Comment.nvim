<h1 align="center">// Comment.nvim </h1>
<p align="center"><sup>⚡ Smart and Powerful commenting plugin for neovim ⚡</sup></p>

![Comment.nvim](https://user-images.githubusercontent.com/42532967/136532939-926a8350-84b7-4e78-b045-fe21b5947388.gif "Commenting go brrrr")

### ✨ Features

-   Supports `commentstring`. [Read more](#commentstring)
-   Prefers single-line/linewise comments
-   Supports line (`//`) and block (`/* */`) comments
-   Left-right (`gcw` `gc$`) and Up-Down motions (`gc2j` `gc4k`)
-   Use with text-objects (`gci{` `gcat`)
-   Dot (`.`) repeat support for `gcc`, `gbc` and friends
-   Supports pre and post hooks
-   Custom language/commentstring support
-   Ignore certain lines, powered by Lua regex

### 🚀 Installation

-   With [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
    'numToStr/Comment.nvim',
    config = function()
        require('Comment').setup()
    end
}
```

-   With [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'numToStr/Comment.nvim'

" Somewhere after plug#end()
lua require('Comment').setup()
```

<a id="setup"></a>

### ⚒️ Setup

First you need to call the `setup()` method to create the default mappings.

-   Lua

```lua
require('Comment').setup()
```

-   VimL

```vim
lua << EOF
require('Comment').setup()
EOF
```

#### Configuration (optional)

Following are the **default** config for the [`setup()`](#setup). If you want to override, just modify the option that you want then it will be merged with the default config.

```lua
{
    ---Add a space b/w comment and the line
    ---@type boolean
    padding = true,

    ---Line which should be ignored while comment/uncomment
    ---Example: Use '^$' to ignore empty lines
    ---@type string Lua regex
    ignore = nil,

    ---Whether to create basic (operator-pending) and extra mappings for NORMAL/VISUAL mode
    ---@type table
    mappings = {
        ---operator-pending mapping
        ---Includes `gcc`, `gcb`, `gc[count]{motion}` and `gb[count]{motion}`
        basic = true,
        ---extended mapping
        ---Includes `g>`, `g<`, `g>[count]{motion}` and `g<[count]{motion}`
        extra = false,
    },

    ---LHS of line and block comment toggle mapping in NORMAL/VISUAL mode
    ---@type table
    toggler = {
        ---line-comment toggle
        line = 'gcc',
        ---block-comment toggle
        block = 'gbc',
    },

    ---LHS of line and block comment operator-mode mapping in NORMAL/VISUAL mode
    ---@type table
    opleader = {
        ---line-comment opfunc mapping
        line = 'gc',
        ---block-comment opfunc mapping
        block = 'gb',
    },

    ---Pre-hook, called before commenting the line
    ---@type function|nil
    pre_hook = nil,

    ---Post-hook, called after commenting is done
    ---@type function|nil
    post_hook = nil,
}
```

### 🔥 Usage

When you call [`setup()`](#setup) method, `Comment.nvim` sets up some basic mapping which can used in _NORMAL_ and _VISUAL_ mode to get you started with the pleasure of commenting stuff out.

<a id="mappings"></a>

#### Mappings

-   Basic/Toggle mappings (enabled by `config.mappings.basic`)

> _NORMAL_ mode

```help
`gc[count]{motion}` - (Operator mode) Toggles the region using linewise comment

`gb[count]{motion}` - (Operator mode) Toggles the region using linewise comment

`gcc` - Toggles the current line using linewise comment

`gbc` - Toggles the current line using blockwise comment
```

> _VISUAL_ mode

```help
`gc` - Toggles the region using linewise comment

`gb` - Toggles the region using blockwise comment
```

-   Extra/Explicit mappings (enabled by `config.mappings.extra`)

> _NORMAL_ mode

```help
`g>[count]{motion}` - (Operator Mode) Comments the region using linewise comment

`g>c` - Comments the current line using linewise comment

`g>b` - Comments the current line using blockwise comment

`g<[count]{motion}` - (Operator mode) Uncomments the region using linewise comment

`g<c` - Uncomments the current line using linewise comment

`g<b`- Uncomments the current line using blockwise comment
```

> _VISUAL_ mode

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
`gc5l` - Toggle 5 lines after the current cursor
`gc8k` - Toggle 8 lines before the current cursor
`gcip` - Toggle inside of paragraph
`gca}` - Toggle around curly brackets

# Blockwise

`gb2}` - Toggle until the 2 next blank line
`gbaf` - Toggle comment around a function (w/ LSP/treesitter support)
`gbac` - Toggle comment around a class (w/ LSP/treesitter support)
```

#### Methods

`Comment.nvim` also provides some methods apart from the [mappings](#mappings). Also note that these methods only do linewise commenting and only on the current line.

```lua
-- Comments the current line
require('Comment').comment()

-- Uncomments the current lines
require('Comment').uncomment()

-- Toggles the current lines
require('Comment').toggle()
```

<a id="hooks"></a>

### 🎣 Hooks

There are two hook methods i.e `pre_hook` and `post_hook` which are called before comment and after comment respectively. Both should be provided during [`setup()`](#setup).

-   `pre_hook` - This method is called with a [`ctx`](#comment-context) argument before comment/uncomment is started. It can be used to return a custom `commentstring` which will be used for comment/uncomment the lines. You can use something like [nvim-ts-context-commentstring](https://github.com/JoosepAlviste/nvim-ts-context-commentstring) to compute the commentstring using treesitter.

```lua

{
    ---@param ctx Ctx
    pre_hook = function(ctx)
        return require('ts_context_commentstring.internal').calculate_commentstring()
    end
}

-- or with some spicy logic
{
    ---@param ctx Ctx
    pre_hook = function(ctx)
        local u = require('Comment.utils')
        if ctx.ctype == u.ctype.line then
            -- Only comment when we are doing linewise comment
            return require('ts_context_commentstring.internal').calculate_commentstring()
        end
    end
}
```

Also, you can set the `commentstring` from here but [**i won't recommend it**](#commentstring-caveat) for now.

```lua
{
    ---@param ctx Ctx
    pre_hook = function(ctx)
        -- Only update commentstring for tsx filetypes
        if vim.bo.filetype == 'typescriptreact' then
            require('ts_context_commentstring.internal').update_commentstring()
        end
    end
}
```

-   `post_hook` - This method is called after commenting is done. It receives the same 1) [`ctx`](#comment-context), the lines range 2) `start_col` 3) `end_col` 4) `start_row` 5) `end_row`.

> NOTE: If [methods](#methods) are used, then `post_hook` will receives only two arguments 1) [`ctx`](#comment-context) and 2) `-1` indicating the current line

```lua
{
    ---@param ctx Ctx
    ---@param start_col integar
    ---@param end_col integar
    ---@param start_row integar
    ---@param end_row integar
    post_hook = function(ctx, start_col, end_col, start_row, end_row)
        if start_col == -1 then
            -- do something with the current line
        else
            -- do something with lines range
        end
    end
}
```

> NOTE: When pressing `gc`, `gb` and friends, `cmode` (Comment mode) inside `pre_hook` will always be toggle because when pre-hook is called, in that moment we don't know whether `gc` or `gb` will comment or uncomment the lines. But luckily, we do know this before `post_hook` and this will always receive either comment or uncomment status

### 🚫 Ignoring lines

You can use `ignore` to ignore certain lines during comment/uncomment. It takes a lua regex string and should be provided during [`setup()`](#setup).

```lua
-- ignores empty lines
ignore = '^$'

-- ignores line that starts with `local` (excluding any leading whitespace)
ignore = '^(%s*)local'

-- ignores any lines similar to arrow function
ignore = '^const(.*)=(%s?)%((.*)%)(%s?)=>'
```

<a id="languages"></a>

### 🗨️ Languages

Most languages have support for comments via `commentstring` but there might be a language that is not supported. There are two ways to enable commenting for unsupported languages:

1.  You can set `commentstring` for that language like the following

```lua
vim.bo.commentstring = '//%s'

-- or
vim.api.nvim_command('set commentstring=//%s')
```

> Run `:h commentstring` for more help

2. You can also use this plugin interface to store both line and block commentstring. You can treat this as a more powerful version of the `commentstring`

```lua
local lang = require('Comment.lang')

-- 1. Using set function

-- set both line and block commentstring
lang.set('javascript', {'//%s', '/*%*/'})

-- Just set only line comment
lang.set('yaml', '#%s')

-- 2. Metatable magic

-- One lang at a time
lang.javascript = {'//%s', '/*%*/'}
lang.yaml = '#%s'

-- Multiple langs
lang({'go', 'rust'}, {'//%s', '/*%*/'})
lang({'toml', 'graphql'}, '#%s')
```

> PR(s) are welcome to add more commentstring inside the plugin

<a id="commentstring"></a>

### 🧵 Comment String

Although, `Comment.nvim` supports neovim's `commentstring` but unfortunately it has the least priority. The commentstring is taken from the following place in the respective order.

-   [`pre_hook`](#hooks) - If a string is returned from this method then it will be used for commenting.

-   [`lang_table`](#languages) - If the current filetype is found in the table, then the string there will be used.

-   `commentstring` - Neovim's native commentstring for the filetype

<a id="commentstring-caveat"></a>

> There is one caveat with this approach. If someone sets the `commentstring` (w/o returning a string) from the `pre_hook` method and if the current filetype also exists in the `lang_table` then the commenting will be done using the string in `lang_table` instead of using `commentstring`

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
```

`CType` (Comment type), `CMode` (Comment mode) and `CMotion` (Comment motion) all of them are exported from the plugin's utils for reuse

```lua
require('Comment.utils').ctype.{line,block}

require('Comment.utils').cmode.{toggle,comment,uncomment}

require('Comment.utils').cmotion.{line,char,v}
```

### 🤝 Contributing

There are multiple ways to contribute reporting/fixing bugs, feature requests. You can also submit commentstring to this plugin by updating [lang.lua](./lua/Comment/lang.lua) and sending PR.

### 💐 Credits

-   [tcomment]() - To be with me forever and motivated me to write this.
-   [nvim-comment](https://github.com/terrortylor/nvim-comment) - Little and less powerful cousin. Also I took some code from it.
-   [kommentary](https://github.com/b3nj5m1n/kommentary) - Nicely done plugin but lacks some features. But it helped me to design this plugin.

### 🚗 Roadmap

-   Live upto the expectation of `tcomment`
-   Basic INSERT mode mappings
-   Doc comment i.e `/**%s*/` (js), `///%s` (rust)

-   Inbuilt context commentstring using treesitter

```lua
{
    pre_hook = function()
        return require('Comment.ts').commentstring()
    end
}
```

-   Header comment

```lua
----------------------
-- This is a header --
----------------------
```
