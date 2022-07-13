local K = vim.keymap.set

-- Count mappings
K(
    'n',
    '<Plug>(comment_toggle_linewise_count)',
    '<CMD>lua require("Comment.api").call("toggle.linewise.count_repeat")<CR>g@$'
)
K(
    'n',
    '<Plug>(comment_toggle_blockwise_count)',
    '<CMD>lua require("Comment.api").call("toggle.blockwise.count_repeat")<CR>g@$'
)

-- Toggle mappings
K(
    'n',
    '<Plug>(comment_toggle_current_linewise)',
    '<CMD>lua require("Comment.api").call("toggle.linewise.current")<CR>g@$'
)
K(
    'n',
    '<Plug>(comment_toggle_current_blockwise)',
    '<CMD>lua require("Comment.api").call("toggle.blockwise.current")<CR>g@$'
)

-- Operator-Pending mappings
K('n', '<Plug>(comment_toggle_linewise)', '<CMD>lua require("Comment.api").call("toggle.linewise")<CR>g@')
K('n', '<Plug>(comment_toggle_blockwise)', '<CMD>lua require("Comment.api").call("toggle.blockwise")<CR>g@')

-- Visual-Mode mappings
K(
    'x',
    '<Plug>(comment_toggle_linewise_visual)',
    '<ESC><CMD>lua require("Comment.api").locked("toggle.linewise")(vim.fn.visualmode())<CR>'
)
K(
    'x',
    '<Plug>(comment_toggle_blockwise_visual)',
    '<ESC><CMD>lua require("Comment.api").locked("toggle.blockwise")(vim.fn.visualmode())<CR>'
)
