local J = {
    comment = '{/*%s*/}',
}

local query = [[
    ; If somehow we can group all the attributes into one
    (jsx_opening_element [(jsx_attribute) (comment)] @nojsx)

    ; If somehow we can group all the comments into one
    (jsx_expression (comment)) @jsx

    (jsx_expression
        [(object) (call_expression)] @nojsx)

    (parenthesized_expression
        [(jsx_fragment) (jsx_element)] @jsx)

    (return_statement
        [(jsx_fragment) (jsx_element)] @jsx)
]]

local function is_jsx(lang)
    -- Name of the treesitter parsers that supports jsx syntax
    return lang == 'tsx' or lang == 'javascript'
end

local function capture(parser, range)
    local lang = parser:lang()

    if not is_jsx(lang) then
        return
    end

    local Q = vim.treesitter.query.parse_query(lang, query)

    local lines, group

    for _, tree in ipairs(parser:trees()) do
        for id, node in Q:iter_captures(tree:root(), parser:source(), range.srow - 1, range.erow) do
            local srow, _, erow = node:range()
            -- print(Q.captures[id])
            -- print(srow, range.srow - 1)
            -- print(erow, range.erow - 1)
            -- print(srow <= range.srow - 1 and erow >= range.erow - 1)
            if srow <= range.srow - 1 and erow >= range.erow - 1 then
                local region = erow - srow
                if not lines or region < lines then
                    lines, group = region, Q.captures[id]
                end
            end
        end
    end

    return group == 'jsx' and J.comment
end

function J.calculate(ctx)
    local ok, P = pcall(vim.treesitter.get_parser)

    if not ok then
        return
    end

    local rng = {
        ctx.range.srow - 1,
        ctx.range.scol,
        ctx.range.erow - 1,
        ctx.range.ecol,
    }

    -- This is for `markdown` which embeds multiple `tsx` blocks
    for _, child in pairs(P:children()) do
        if child:contains(rng) then
            local captured = capture(child, ctx.range)
            if captured then
                return captured
            end
        end
    end

    if P:contains(rng) then
        -- This is for `tsx` itself
        return capture(P, ctx.range)
    end
end

return J
