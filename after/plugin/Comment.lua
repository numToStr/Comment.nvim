local K = vim.keymap.set

-- Count mappings
K(
    'n',
    '<Plug>(comment_toggle_linewise_count)',
    '<CMD>lua require("Comment.api").call("toggle_linewise_count_op")<CR>g@$',
    { desc = 'Comment toggle linewise with count' }
)
K(
    'n',
    '<Plug>(comment_toggle_blockwise_count)',
    '<CMD>lua require("Comment.api").call("toggle_blockwise_count_op")<CR>g@$',
    { desc = 'Comment toggle blockwise with count' }
)

-- Toggle mappings
K(
    'n',
    '<Plug>(comment_toggle_current_linewise)',
    '<CMD>lua require("Comment.api").call("toggle_current_linewise_op")<CR>g@$',
    { desc = 'Comment toggle current line' }
)
K(
    'n',
    '<Plug>(comment_toggle_current_blockwise)',
    '<CMD>lua require("Comment.api").call("toggle_current_blockwise_op")<CR>g@$',
    { desc = 'Comment toggle current block' }
)

-- Operator-Pending mappings
K(
    'n',
    '<Plug>(comment_toggle_linewise)',
    '<CMD>lua require("Comment.api").call("toggle_linewise_op")<CR>g@',
    { desc = 'Comment toggle linewise' }
)
K(
    'n',
    '<Plug>(comment_toggle_blockwise)',
    '<CMD>lua require("Comment.api").call("toggle_blockwise_op")<CR>g@',
    { desc = 'Comment toggle blockwise' }
)

-- Visual-Mode mappings
K(
    'x',
    '<Plug>(comment_toggle_linewise_visual)',
    '<ESC><CMD>lua require("Comment.api").locked.toggle_linewise_op(vim.fn.visualmode())<CR>',
    { desc = 'Comment toggle linewise (visual)' }
)
K(
    'x',
    '<Plug>(comment_toggle_blockwise_visual)',
    '<ESC><CMD>lua require("Comment.api").locked.toggle_blockwise_op(vim.fn.visualmode())<CR>',
    { desc = 'Comment toggle blockwise (visual)' }
)
