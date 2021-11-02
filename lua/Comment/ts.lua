local ft = require('Comment.ft')

local ts = {}

local get_current_tree = function(bufnr, range)
    if bufnr and not range then
        error('If you pass bufnr, you must pass a range as well')
    end

    bufnr = bufnr or vim.api.nvim_get_current_buf()
    local ok, langtree = pcall(vim.treesitter.get_parser, bufnr)

    if not ok then
        return nil
    end

    if not range then
        local cursor = vim.api.nvim_win_get_cursor(0)
        range = {
            cursor[1] - 1,
            cursor[2],
            cursor[1] - 1,
            cursor[2],
        }
    end

    return langtree:language_for_range(range), range
end

--- Get the current language for bufnr and range
---@param bufnr number: The bufnr
---@param range table: See ranges for treesitter
function ts.get_lang(bufnr, range)
    local current_tree = get_current_tree(bufnr, range)
    if not current_tree then
        return
    end

    return current_tree:lang()
end

function ts.get_containing_node(bufnr, in_range)
    local current_tree, range = get_current_tree(bufnr, in_range)
    if not current_tree then
        return
    end

    local lang = current_tree:lang()

    local config = ft.lang(lang)
    if not config then
        return
    end

    local root = current_tree:trees()[1]:root()
    local contained = root:named_descendant_for_range(unpack(range))

    local original = contained
    while contained and contained:type() and not config[contained:type()] do
        contained = contained:parent()
    end

    -- Hmmm, might want this back, not sure yet.
    -- if not contained then
    --     return original
    -- end

    return contained
end

return ts
