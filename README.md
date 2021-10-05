<h1 align="center">// Comment.nvim </h1>
<p align="center"><sup>✨ Simple and Powerful commenting plugin for neovim ✨</sup></p>

<!-- Image -->

## ✨ Features

-   Uses `commentstring`
-   Prefers single-line/linewise comments
-   Supports line (`//`) and block (`/* */`) comments
-   Supports pre and post hooks
-   Custom language/commentstring support
-   Comment lines using motions (`gc2l`) and text-objects (`gci{`)
-   Dot (`.`) repeat support for `gcc`, `gbc` and friends
-   Ignore certain lines, powered by Lua regex

## 🚀 Installation

-   With [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
    'numToStr/Comment.nvim',
    config = function()
        require('Comment').setup()
    end
}
```

<a id="setup"></a>

## ⚒️ Setup

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

#### Configuration

The [`setup()`](#setup) method (optionally) takes a configuration object for which the default values is given below.

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

## 🔥 Usage

When you call [`setup()`](#setup) method, `Comment.nvim` sets up some basic mapping which can used in NORMAL and VISUAL mode to get you started with the pleasure of commenting stuff out.

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

## 🎣 Hooks

TODO: explain pre and post hook

## 🚫 Ignoring lines

TODO: explain `ignore`

<a id="languages"></a>

## 🗨️ Languages

## 🧵 Comment-String

Although, `Comment.nvim` supports neovim's `commentstring` but unfortunately it has the least priority. The commentstring is taken from the following place in the respective order.

-   [`pre_hook`](#hooks) - If a string is returned from this method then it will be used for commenting.

-   [`lang_table`](#languages) - If the current filetype is found in the table, then the string there will be used.

-   `commentstring` - Native neovim's commentstring for the filetype

<a id="commentstring-caveat"></a>

> There is one caveat with this approach. If someone sets the `commentstring` (w/o returning a string) from the `pre_hook` method but the current filetype is present in the `lang_table` then the commenting will be done using the string in `lang_table` instead of using `commentstring`

## 🤝 Contributing

TODO: how to contribute custom commentstring

## 💐 Credits

-   [tcomment]() - To be with me forever and motivated me to write this.
-   [nvim-comment](https://github.com/terrortylor/nvim-comment) - Awesome but less powerful cousin. Also I took some code from it.
-   [kommentary](https://github.com/b3nj5m1n/kommentary) - Nicely done plugin. Helped me in design this plugin

## 🚗 Roadmap

TODO: Just paste `dump.lua`
