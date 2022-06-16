local J = {
    comment = '{/*%s*/}',
}

local query = [[
    (jsx_opening_element [(jsx_attribute) (comment)] @nojsx)

    (jsx_self_closing_element [(jsx_attribute) (comment)] @nojsx)

    ((jsx_expression (comment)) @jsx)

    (jsx_expression
        [(object) (call_expression)] @nojsx)

    (parenthesized_expression
        [(jsx_fragment) (jsx_element)] @jsx)

    (return_statement
        [(jsx_fragment) (jsx_element)] @jsx)
]]

local trees = {
    typescriptreact = 'tsx',
    javascriptreact = 'javascript',
}

---Checks whether parser's language matches the filetype that supports jsx syntax
---@param lang string
---@return boolean
local function is_jsx(lang)
    return lang == trees.typescriptreact or lang == trees.javascriptreact
end

-- This function is a workaround for `+` treesitter quantifier
-- which is currently not supported by neovim (wip: https://github.com/neovim/neovim/pull/15330)
-- because of this we can't query consecutive comment or attributes nodes,
-- and group them as single range, hence this function
---@param q table
---@param tree table
---@param parser table
---@param range CRange
---@return table
local function normalize(q, tree, parser, range)
    local prev, section, sections = nil, 0, {}

    for id, node in q:iter_captures(tree:root(), parser:source(), range.srow - 1, range.erow) do
        if id ~= prev then
            section = section + 1
        end

        local srow, _, erow = node:range()
        local key = string.format('%s.%s', id, section)
        if sections[key] == nil then
            sections[key] = { id = id, range = { srow = srow, erow = erow } }
        else
            -- storing the smallest starting row and biggest ending row
            local r = sections[key].range
            if srow < r.srow then
                sections[key].range.srow = srow
            end
            if erow > r.erow then
                sections[key].range.erow = erow
            end
        end

        prev = id
    end

    return sections
end

---Runs the query and returns the commentstring by checking the cursor range
---@param parser table
---@param range CRange
---@return boolean
local function capture(parser, range)
    local lang = parser:lang()

    if not is_jsx(lang) then
        return
    end

    local Q = vim.treesitter.query.parse_query(lang, query)

    local id, lnum, lines = 0, nil, nil

    for _, tree in ipairs(parser:trees()) do
        for _, section in pairs(normalize(Q, tree, parser, range)) do
            if section.range.srow <= range.srow - 1 and section.range.erow >= range.erow - 1 then
                local region = section.range.erow - section.range.srow
                if not lines or region < lines then
                    id, lnum, lines = section.id, section.range.srow, region
                end
            end
        end
    end

    -- NOTE:
    -- This is for the case when the opening element and attributes are on the same line,
    -- so to prevent invalid comment, we can check if the line looks like an element
    if lnum ~= nil and string.match(vim.fn.getline(lnum + 1), '%s+<%w+%s.*>$') then
        return true
    end

    return Q.captures[id] == 'jsx'
end

---Calculates the `jsx` commentstring
---@param ctx Ctx
---@return string?
function J.calculate(ctx)
    local buf = vim.api.nvim_get_current_buf()
    local filetype = vim.api.nvim_buf_get_option(buf, 'filetype')

    -- NOTE:
    -- `get_parser` panics for `{type,java}scriptreact` filetype
    -- bcz their parser's name is different from their filetype
    -- Maybe report the issue to `nvim-treesitter` or core(?)
    local ok, tree = pcall(vim.treesitter.get_parser, buf, trees[filetype] or filetype)

    if not ok then
        return
    end

    local range = {
        ctx.range.srow - 1,
        ctx.range.scol,
        ctx.range.erow - 1,
        ctx.range.ecol,
    }

    -- This is for `markdown` which embeds multiple `tsx` blocks
    for _, child in pairs(tree:children()) do
        if child:contains(range) and capture(child, ctx.range) then
            return J.comment
        end
    end

    -- This is for `tsx` itself
    return (tree:contains(range) and capture(tree, ctx.range)) and J.comment
end

return J
