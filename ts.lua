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

function T.get_text(node)
    return node and ts.query.get_node_text(node, 0)
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

local _ = { --[[ {
    pre_hook = function(ctx)
        print(ctx)
    end,
} --]]
}

local function last_comment_node(node)
    local next = node:next_sibling()
    if not next then
        return node
    end

    local curr_row = node:range()
    local next_row = next:range()
    if (curr_row + 1 ~= next_row) or next:type() ~= 'comment' then
        return node
    end

    return last_comment_node(next)
end

local function first_comment_node(node)
    local prev = node:prev_sibling()
    if not prev then
        return node
    end

    local curr_row = node:range()
    local prev_row = prev:range()
    if (prev_row + 1 ~= curr_row) or prev:type() ~= 'comment' then
        return node
    end

    return first_comment_node(prev)
end

local parser = T.get_parser()
local root = T.get_root(parser)

local query = T.query()
local curr_node, ctype = T.get_node_at_cursor(query, root)

if curr_node then
    -- print(T.get_text(curr_node), ctype)

    -- FIXME: this is broken for subline block comment
    --
    -- PROBLEM
    -- Bcz they both exists on a single line, identifying them different is hard in the sense of treesitter.
    -- We should work on subline block comment if we are inside it
    --
    -- WORKAROUND
    -- 1. get_text and test it against subline block comment
    -- 2. if match, then treat it as a subline block comment

    -- NOTE: When a region only consists of a single line comment then first/last node both will be same
    if ctype == U.ctype.line then
        local first_node = first_comment_node(curr_node)
        local last_node --[[ hello --]] = last_comment_node(curr_node)
        print(1, T.get_text(first_node))
        print(2, T.get_text(last_node))
        -- print(first_node:range())
        -- print(last_node:range())
    else
        print(curr_node:range())
        print(T.get_text(curr_node) or 'block')
    end
end

-- Hello treesitter
-- bunch of comment

-- stack together
-- so we can catch
-- them at once

--[[
    One block comment
--]]
