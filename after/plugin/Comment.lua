local K = vim.keymap.set

-- Operator-Pending mappings
K(
    'n',
    '<Plug>(comment_toggle_linewise)',
    '<CMD>lua require("Comment.api").call("toggle.linewise")<CR>g@',
    { desc = 'Comment toggle linewise' }
)
K(
    'n',
    '<Plug>(comment_toggle_blockwise)',
    '<CMD>lua require("Comment.api").call("toggle.blockwise")<CR>g@',
    { desc = 'Comment toggle blockwise' }
)

-- Toggle mappings
K(
    'n',
    '<Plug>(comment_toggle_linewise_current)',
    '<CMD>lua require("Comment.api").call("toggle.linewise.current")<CR>g@$',
    { desc = 'Comment toggle current line' }
)
K(
    'n',
    '<Plug>(comment_toggle_blockwise_current)',
    '<CMD>lua require("Comment.api").call("toggle.blockwise.current")<CR>g@$',
    { desc = 'Comment toggle current block' }
)

-- Count mappings
K(
    'n',
    '<Plug>(comment_toggle_linewise_count)',
    '<CMD>lua require("Comment.api").call("toggle.linewise.count_repeat")<CR>g@$',
    { desc = 'Comment toggle linewise with count' }
)
K(
    'n',
    '<Plug>(comment_toggle_blockwise_count)',
    '<CMD>lua require("Comment.api").call("toggle.blockwise.count_repeat")<CR>g@$',
    { desc = 'Comment toggle blockwise with count' }
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
