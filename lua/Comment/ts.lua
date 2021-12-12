local U = require('Comment.utils')
local A = vim.api
local ts = vim.treesitter

local TS = {}

function TS:new()
    local buf = A.nvim_get_current_buf()
    local ft = A.nvim_buf_get_option(buf, 'filetype')
    local query = ts.parse_query(
        ft,
        [[
            (
                (comment) @comment
                ; (#lua-match? @comment "^--%s")
            )
            ; (line_comment) @comment
            ; (block_comment) @comment
        ]]
    )

    return setmetatable({ query = query, buf = buf, ft = ft }, { __index = self })
end

function TS.in_range(row, col, srow, scol, erow, ecol)
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

function TS:get_root()
    local parser = ts.get_parser(self.buf, self.ft)
    local _, tree = next(parser:parse())
    if not tree then
        return
    end
    return tree:root()
end

function TS:find_comments(root)
    local row, col = unpack(A.nvim_win_get_cursor(0))
    for _, captures in self.query:iter_matches(root, self.buf) do
        local _, node = next(captures)
        local range = { node:range() }
        local ctype = self.in_range(row, col, unpack(range))
        if ctype == U.ctype.block then
            A.nvim_buf_set_mark(self.buf, '<', range[1] + 1, range[2], {})
            A.nvim_buf_set_mark(self.buf, '>', range[3] + 1, range[4] - 1, {})
            vim.cmd('norm! gv')
            -- vim.highlight.range(self.buf, 1, 'Visual', { range[1], range[2] }, { range[3], range[4] })
            -- else
            dump(ctype, ' ', node:range())

            -- dump('current', ts.query.get_node_text(node, 0))
            -- local next_sibling = node:next_sibling()
            -- dump(next_sibling:range())
            -- dump('next:', ts.query.get_node_text(next_sibling, 0))
        end
    end
end

function _G.__find_comments()
    local t = TS:new()
    local root = t:get_root()
    t:find_comments(root)
end

vim.cmd([[command! FindComment lua __find_comments()]])

return TS
