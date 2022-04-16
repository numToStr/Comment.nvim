## 🔌 Plug Mappings

Following are the `<Plug>` mappings which you can use to quickly setup your custom keybindings

- `<Plug>(comment_toggle_linewise_count)` - Toggles line comment with count
- `<Plug>(comment_toggle_blockwise_count)` - Toggles block comment with count
- `<Plug>(comment_toggle_current_linewise)` - Toggles line comment on the current line
- `<Plug>(comment_toggle_current_blockwise)` - Toggles block comment on the current line
- `<Plug>(comment_toggle_linewise)` - Toggles line comment via Operator pending mode
- `<Plug>(comment_toggle_blockwise)` - Toggles block comment via Operator pending mode
- `<Plug>(comment_toggle_linewise_visual)` - Toggles line comment in VISUAL mode
- `<Plug>(comment_toggle_blockwise_visual)` - Toggles block comment in VISUAL mode

> NOTE: There are only meant for custom keybindings but If you want to create a custom comment function then be sure to check out all the [API](./API.md).

#### Usage

Following snippets is same as the default mappings set by the plugin.

```lua
local K = vim.keymap.set
local E = { expr = true, remap = true }

-- Toggle using count
K('n', 'gcc', "v:count == 0 ? '<Plug>(comment_toggle_current_linewise)' : '<Plug>(comment_toggle_linewise_count)'", E)
K('n', 'gbc', "v:count == 0 ? '<Plug>(comment_toggle_current_blockwise)' : '<Plug>(comment_toggle_blockwise_count)'", E)

-- Toggle in Op-pending mode
K('n', 'gc', '<Plug>(comment_toggle_linewise)')
K('n', 'gb', '<Plug>(comment_toggle_blockwise)')

-- Toggle in VISUAL mode
K('x', 'gc', '<Plug>(comment_toggle_linewise_visual)')
K('x', 'gb', '<Plug>(comment_toggle_blockwise_visual)')
```
