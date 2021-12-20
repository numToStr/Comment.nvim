local K = require('Comment.utils').K

-- Count mappings
K.n('<Plug>(comment_toggle_linewise_count)', '<CMD>lua require("Comment.api").toggle_linewise_count()<CR>')
K.n('<Plug>(comment_toggle_blockwise_count)', '<CMD>lua require("Comment.api").toggle_blockwise_count()<CR>')

-- Toggle mappings
K.n(
    '<Plug>(comment_toggle_current_linewise)',
    '<CMD>lua require("Comment.api").call("toggle_current_linewise_op")<CR>g@$'
)
K.n(
    '<Plug>(comment_toggle_current_blockwise)',
    '<CMD>lua require("Comment.api").call("toggle_current_blockwise_op")<CR>g@$'
)

-- Operator-Pending mappings
K.n('<Plug>(comment_toggle_linewise)', '<CMD>lua require("Comment.api").call("toggle_linewise_op")<CR>g@')
K.n('<Plug>(comment_toggle_blockwise)', '<CMD>lua require("Comment.api").call("toggle_blockwise_op")<CR>g@')

-- Visual-Mode mappings
K.x(
    '<Plug>(comment_toggle_linewise_visual)',
    '<ESC><CMD>lua require("Comment.api").toggle_linewise_op(vim.fn.visualmode())<CR>'
)
K.x(
    '<Plug>(comment_toggle_blockwise_visual)',
    '<ESC><CMD>lua require("Comment.api").toggle_blockwise_op(vim.fn.visualmode())<CR>'
)
