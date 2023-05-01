local K = vim.keymap.set
local call = require('Comment.api').call

---@mod comment.keybindings Keybindings
---@brief [[
---Comment.nvim provides default keybindings for (un)comment your code. These
---keybinds are enabled upon calling |comment.usage.setup| and can be configured
---or disabled, if desired.
---
---Basic: ~
---
---  *gc*
---  *gb*
---  *gc[count]{motion}*
---  *gb[count]{motion}*
---
---      Toggle comment on a region using linewise/blockwise comment. In 'NORMAL'
---      mode, it uses 'Operator-Pending' mode to listen for an operator/motion.
---      In 'VISUAL' mode it simply comment the selected region.
---
---  *gcc*
---  *gbc*
---  *[count]gcc*
---  *[count]gbc*
---
---      Toggle comment on the current line using linewise/blockwise comment. If
---      prefixed with a 'v:count' then it will comment over the number of lines
---      corresponding to the {count}. These are only available in 'NORMAL' mode.
---
---
---Extra: ~
---
---  *gco* - Inserts comment below and enters INSERT mode
---  *gcO* - Inserts comment above and enters INSERT mode
---  *gcA* - Inserts comment at the end of line and enters INSERT mode
---@brief ]]

---@mod comment.plugmap Plug Mappings
---@brief [[
---Comment.nvim provides <Plug> mappings for most commonly used actions. These
---are enabled by default and can be used to make custom keybindings. All plug
---mappings have support for dot-repeat except VISUAL mode keybindings. To create
---custom comment function, check out 'comment.api' section.
---
---  *<Plug>(comment_toggle_linewise)*
---  *<Plug>(comment_toggle_blockwise)*
---
---     Toggle comment on a region with linewise/blockwise comment in NORMAL mode.
---     using |Operator-Pending| mode (or |g@|) to get the region to comment.
---     These powers the |gc| and |gb| keybindings.
---
---  *<Plug>(comment_toggle_linewise_current)*
---  *<Plug>(comment_toggle_blockwise_current)*
---
---     Toggle comment on the current line with linewise/blockwise comment in
---     NORMAL mode. These powers the |gcc| and 'gbc' keybindings.
---
---  *<Plug>(comment_toggle_linewise_count)*
---  *<Plug>(comment_toggle_blockwise_count)*
---
---     Toggle comment on a region using 'v:count' with linewise/blockwise comment
---     in NORMAL mode. These powers the |[count]gcc| and |[count]gbc| keybindings.
---
---  *<Plug>(comment_toggle_linewise_visual)*
---  *<Plug>(comment_toggle_blockwise_visual)*
---
---     Toggle comment on the selected region with linewise/blockwise comment in
---     NORMAL mode. These powers the |{visual}gc| and |{visual}gb| keybindings.
---
---Usage: ~
--->lua
---    -- Toggle current line or with count
---    vim.keymap.set('n', 'gcc', function()
---        return vim.v.count == 0
---            and '<Plug>(comment_toggle_linewise_current)'
---            or '<Plug>(comment_toggle_linewise_count)'
---    end, { expr = true })
---
---    -- Toggle in Op-pending mode
---    vim.keymap.set('n', 'gc', '<Plug>(comment_toggle_linewise)')
---
---    -- Toggle in VISUAL mode
---    vim.keymap.set('x', 'gc', '<Plug>(comment_toggle_linewise_visual)')
---<
---@brief ]]
---@export plugs

-- Operator-Pending mappings
K(
    'n',
    '<Plug>(comment_toggle_linewise)',
    call('toggle.linewise', 'g@'),
    { expr = true, desc = 'Comment toggle linewise' }
)
K(
    'n',
    '<Plug>(comment_toggle_blockwise)',
    call('toggle.blockwise', 'g@'),
    { expr = true, desc = 'Comment toggle blockwise' }
)

-- Toggle mappings
K(
    'n',
    '<Plug>(comment_toggle_linewise_current)',
    call('toggle.linewise.current', 'g@$'),
    { expr = true, desc = 'Comment toggle current line' }
)
K(
    'n',
    '<Plug>(comment_toggle_blockwise_current)',
    call('toggle.blockwise.current', 'g@$'),
    { expr = true, desc = 'Comment toggle current block' }
)

-- Count mappings
K(
    'n',
    '<Plug>(comment_toggle_linewise_count)',
    call('toggle.linewise.count_repeat', 'g@$'),
    { expr = true, desc = 'Comment toggle linewise with count' }
)
K(
    'n',
    '<Plug>(comment_toggle_blockwise_count)',
    call('toggle.blockwise.count_repeat', 'g@$'),
    { expr = true, desc = 'Comment toggle blockwise with count' }
)

-- Visual-Mode mappings
K(
    'x',
    '<Plug>(comment_toggle_linewise_visual)',
    '<ESC><CMD>lua require("Comment.api").locked("toggle.linewise")(vim.fn.visualmode())<CR>',
    { desc = 'Comment toggle linewise (visual)' }
)
K(
    'x',
    '<Plug>(comment_toggle_blockwise_visual)',
    '<ESC><CMD>lua require("Comment.api").locked("toggle.blockwise")(vim.fn.visualmode())<CR>',
    { desc = 'Comment toggle blockwise (visual)' }
)
