-- 5. Conflict when uncommenting interchangebly with line/block wise comment
-- 6. `ignore` is missing in blockwise and blockwise_x but on the other hand this doesn't make much sense

local TS = vim.treesitter
local A = vim.api
local bo = vim.bo

local T = {
    tree = {},
}

function T.get_parser()
    local ft = bo.filetype
    if not T.tree[ft] then
        local parser = TS.get_parser(0, ft)
        T.tree[ft] = parser
    end

    return T.tree[ft]
end

function T.get_tree(parser)
    local coords = A.nvim_win_get_cursor(0)
    local x, y = coords[1] - 1, coords[2]
    local p = parser or T.get_parser()
    return p:language_for_range({ x, y, x, y }):trees()[1], coords
end

function T.query()
    return TS.parse_query(bo.ft, [[(comment) @comment]])
end

local setup = { --[[ {
    pre_hook = function(ctx)
        print(ctx)
    end,
} --]]
}

-- local ts_utils = require('nvim-treesitter.ts_utils')

local parser = T.get_parser()
local tree = T.get_tree(parser)
local root = tree:root()

local query = T.query()

for _, captures in query:iter_matches(root, 0) do
    local node = captures[1]
    print(node:range())
    -- print(ts.query.get_node_text(node, 0))
end
