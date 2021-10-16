local U = require('Comment.utils')
local ts = vim.treesitter
local A = vim.api
local bo = vim.bo

local T = {
    tree = {},
}

function T.get_parser()
    local ft = bo.filetype
    if not T.tree[ft] then
        local parser = ts.get_parser(0, ft)
        T.tree[ft] = parser
    end

    return T.tree[ft]
end

function T.get_root(parser)
    local p = parser or T.get_parser()
    local tree = p:parse()[1]
    return tree:root()
end

function T.get_sub_tree(parser)
    local coords = A.nvim_win_get_cursor(0)
    local x, y = coords[1] - 1, coords[2]
    local p = parser or T.get_parser()
    return p:language_for_range({ x, y, x, y }):trees()[1], coords
end

function T.query()
    return ts.parse_query(bo.ft, [[(comment) @comment]])
end

function T.comment_in_range(row, col, srow, scol, erow, ecol)
    row = row - 1

    -- This has to be mean linewise comment
    local same_line = srow == erow and srow == row
    if same_line then
        return U.ctype.line
    end

    -- Cursor is inside the block comment
    local inside_rows = srow < row and row < erow
    if inside_rows then
        return U.ctype.block
    end

    -- Cursor is on the starting row and is inside the node
    local on_start_row = srow == row and col >= scol and srow < erow
    if on_start_row then
        return U.ctype.block
    end

    -- Cursor is on the ending row and is inside the node
    local on_end_row = erow == row and col < ecol
    if on_end_row then
        return U.ctype.block
    end

    return false
end

function T.get_node_at_cursor(query, root)
    local pos = A.nvim_win_get_cursor(0)
    local row, col = pos[1], pos[2]
    for _, captures in query:iter_matches(root, 0) do
        local node = captures[1]
        local ctype = T.comment_in_range(row, col, node:range())
        if ctype then
            return node, ctype
        end
    end
end

local setup = { --[[ {
    pre_hook = function(ctx)
        print(ctx)
    end,
} --]]
}

local function walk_ahead(node)
    local curr = node:next_sibling()
    if not curr or curr:type() ~= 'comment' then
        return node
    end
    return walk_ahead(curr)
end

local function walk_back(node)
    local curr = node:prev_sibling()
    if not curr or curr:type() ~= 'comment' then
        return node
    end
    return walk_back(curr)
end

local parser = T.get_parser()
local root = T.get_root(parser)

local query = T.query()
local cur_node, ctype = T.get_node_at_cursor(query, root)

if cur_node then
    if ctype == U.ctype.line then
        local first_node = walk_back(cur_node)
        local last_node = walk_ahead(cur_node)
        print(ts.query.get_node_text(first_node, 0))
        print(ts.query.get_node_text(last_node, 0))
        -- print(first_node:range())
        -- print(last_node:range())
    else
        print(ts.query.get_node_text(cur_node, 0) or 'block')
    end
end

-- Hello treesitter
-- bunch of comment

-- stack together
-- so we can catch
-- them at once

-- --[[
--     One block comment
-- --]]
