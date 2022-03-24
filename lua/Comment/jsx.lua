local J = {
    comment = '{/*%s*/}',
    valid = { 'jsx_element', 'jsx_fragment', 'jsx_text', '<', '>' },
}

local function is_jsx_tree(lang)
    -- Name of the treesitter parsers that supports jsx syntax
    return lang == 'tsx' or lang == 'javascript'
end

local function is_jsx_node(node)
    if not node then
        return false
    end
    return vim.tbl_contains(J.valid, node:type())
end

local function capture(child, range)
    local lang = child:lang()

    local rng = {
        range.srow - 1,
        range.scol,
        range.erow - 1,
        range.ecol,
    }

    if not (is_jsx_tree(lang) and child:contains(rng)) then
        return
    end

    for _, tree in ipairs(child:trees()) do
        local root = tree:root()
        local node = root:descendant_for_range(unpack(rng))
        local srow, _, erow = node:range()
        if srow <= range.srow - 1 and erow >= range.erow - 1 then
            local nxt, prev = node:next_sibling(), node:prev_sibling()
            if is_jsx_node(prev) or is_jsx_node(node) or is_jsx_node(nxt) then
                return J.comment
            end
        end
    end
end

function J.calculate(ctx)
    local ok, P = pcall(vim.treesitter.get_parser)

    if not ok then
        return
    end

    for _, child in pairs(P:children()) do
        local captured = capture(child, ctx.range)
        if captured then
            return captured
        end
    end

    return capture(P, ctx.range)
end

return J
