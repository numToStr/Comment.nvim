local J = {
    comment = '{/*%s*/}',
}

local query = [[
    (parenthesized_expression
        [(jsx_fragment) (jsx_element)] @jsx)

    (return_statement
        [(jsx_fragment) (jsx_element)] @jsx)
]]

local function is_jsx(lang)
    -- Name of the treesitter parsers that supports jsx syntax
    return lang == 'tsx' or lang == 'javascript'
end

local function capture(child, range)
    local lang = child:lang()

    if not is_jsx(lang) then
        return
    end

    local Q = vim.treesitter.query.parse_query(lang, query)

    for _, tree in ipairs(child:trees()) do
        for _, node in Q:iter_captures(tree:root(), child:source()) do
            local srow, _, erow = node:range()
            -- Why subtracting 2?
            -- 1. Lua indexes starts from 1
            -- 2. Removing the `return` keyword from the range
            if srow <= range.srow - 2 and erow >= range.erow then
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
