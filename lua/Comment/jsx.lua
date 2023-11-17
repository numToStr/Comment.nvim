---@mod comment.jsx JSX Integration
---@brief [[
---This module provides the jsx/tsx comment integration via `pre_hook`. The default
---treesitter integration doesn't provides tsx/jsx support as the syntax is weird
---enough to deserve its own module. Besides that not everyone is using jsx/tsx
---so it's better make it an ad-hoc integration.
---@brief ]]

local jsx = {}

local query = [[
    ;; query
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

---Checks whether parser's language matches the filetype that supports jsx syntax
---@param lang string
---@return boolean
local function is_jsx(lang)
    return lang == 'tsx' or lang == 'javascript'
end

-- This function is a workaround for `+` treesitter quantifier
-- which is currently not supported by neovim (wip: https://github.com/neovim/neovim/pull/15330)
-- because of this we can't query consecutive comment or attributes nodes,
-- and group them as single range, hence this function
---@param q table
---@param tree table
---@param parser table
---@param range CommentRange
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
---@param range CommentRange
---@return boolean
local function capture(parser, range)
    local lang = parser:lang()

    if not is_jsx(lang) then
        return false
    end

    local Q = vim.treesitter.query.parse(lang, query)

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

---Static |commentstring| for jsx/tsx
---@type string
jsx.commentstring = '{/*%s*/}'

---Calculates the `jsx/tsx` commentstring using |treesitter|
---@param ctx CommentCtx
---@return string? _ jsx/tsx commenstring
---@see comment.utils.CommentCtx
---@usage [[
---require('Comment').setup({
---    pre_hook = require('Comment.jsx').calculate
---})
---@usage ]]
function jsx.calculate(ctx)
    local ok, tree = pcall(vim.treesitter.get_parser, vim.api.nvim_get_current_buf())

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
            return jsx.commentstring
        end
    end

    -- This is for `tsx` itself
    return (tree:contains(range) and capture(tree, ctx.range)) and jsx.commentstring or nil
end

return jsx
