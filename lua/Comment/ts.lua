local ft = require('Comment.ft')
local U = require('Comment.utils')

local ts = {}

local get_cursor_line_non_whitespace_col_location = function()
    local cursor = vim.api.nvim_win_get_cursor(0)
    local first_non_whitespace_col = vim.fn.match(vim.fn.getline('.'), '\\S')

    return {
        cursor[1] - 1,
        first_non_whitespace_col,
    }
end

--- Get the tree associated with the current comment
---@param ctx Ctx
local get_current_tree = function(ctx, bufnr, range)
    if bufnr and not range then
        error('If you pass bufnr, you must pass a range as well')
    end

    bufnr = bufnr or vim.api.nvim_get_current_buf()
    local ok, langtree = pcall(vim.treesitter.get_parser, bufnr)

    if not ok then
        return nil
    end

    if not range then
        local cursor
        if ctx.cmotion == U.cmotion.line then
            cursor = get_cursor_line_non_whitespace_col_location()
        elseif ctx.cmotion == U.cmotion.V then
            local region = { U.get_region('V') }
            cursor = { region[1] - 1, region[2] }
        elseif ctx.cmotion == U.cmotion.v then
            local region = { U.get_region('v') }
            cursor = { region[1] - 1, region[2] }
        else
            -- ctx.cmotion == U.cmotion.char
            cursor = vim.api.nvim_win_get_cursor(0)
        end

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
---@param ctx Ctx: The current content
---@param bufnr number: The bufnr
---@param range table: See ranges for treesitter
function ts.get_lang(ctx, bufnr, range)
    local current_tree = get_current_tree(ctx, bufnr, range)
    if not current_tree then
        return
    end

    return current_tree:lang()
end

--- Get corresponding node to the context
---@param ctx Ctx: The current content
---@param bufnr number: The buffer you are interested in. Generally nil
---@param in_range table: The range you are interested in. Generally nil
function ts.get_node(ctx, bufnr, in_range)
    local current_tree, range = get_current_tree(ctx, bufnr, in_range)
    if not current_tree then
        return
    end

    local lang = current_tree:lang()

    local config = ft.lang(lang)
    if not config then
        return
    end

    -- Short circuit if this ft doesn't have magical embedded languages
    -- inside of itself that randomly change just based on where you are
    -- in a syntax tree, instead of like, having the same rules everywhere.
    if vim.tbl_islist(config) then
        return nil
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
