local K = vim.keymap.set
local call = require('Comment.api').call

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
