function Lang()
    local A = vim.api

    local buf = A.nvim_get_current_buf()
    local win = A.nvim_get_current_win()
    local langtree = vim.treesitter.get_parser(buf)
    local row, col = unpack(A.nvim_win_get_cursor(win))
    local current_tree = langtree:language_for_range({ row - 1, col, row - 1, col })
    local lang = current_tree:lang()
    local root_node = current_tree:trees()[1]:root()

    print('Lang: ', lang)

    -- for i, tree in ipairs(langtree:trees()) do
    --     dump('Tree: ', i, getmetatable(tree))
    -- end

    -- dump('Root: ', getmetatable(root_node))

    local named_node = root_node:named_descendant_for_range(row - 1, col, row - 1, col)
    -- dump('Named: ', getmetatable(named_node))

    local node_parent = named_node:parent()
    dump('Node-Parent: ', node_parent:type())
    dump('Node-Type: ', named_node:type())

    -- local node = require('nvim-treesitter.ts_utils').get_node_at_cursor(win)
    -- print('Node: ', node:type())
end
