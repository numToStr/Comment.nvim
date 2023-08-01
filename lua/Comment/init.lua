---@brief [[
---*comment-nvim.txt*    For Neovim version 0.7           Last change: 2021 July 11
---
---     _____                                     _                _
---    / ____/                                   / /              (_)
---   / /     ___  _ __ ___  _ __ ___   ___ _ __ / /_   _ ____   ___ _ __ ___
---   / /    / _ \/ '_ ` _ \/ '_ ` _ \ / _ \ '_ \/ __/ / '_ \ \ / / / '_ ` _ \
---   / /___/ (_) / / / / / / / / / / /  __/ / / / /_ _/ / / \ V // / / / / / /
---    \_____\___//_/ /_/ /_/_/ /_/ /_/\___/_/ /_/\__(_)_/ /_/\_/ /_/_/ /_/ /_/
---
---                    · Smart and Powerful comment plugin ·
---
---@brief ]]

---@toc comment.contents

---@mod comment-nvim Introduction
---@brief [[
---Comment.nvim is a smart and powerful comment plugin for neovim. It supports
---dot-repeat, counts, line ('//') and block ('/* */') comments, and can be used
---with motion and text-objects. It has native integration with |treesitter| to
---support embedded filetypes like html, vue, markdown with codeblocks etc.
---@brief ]]
---@tag comment.dotrepeat
---@brief [[
---Comment.nvim uses |operatorfunc| combined with |g@| to support dot-repeat, and
---various marks i.e., |'[| |']| |'<| |'>| to deduce the region with the {motion}
---argument provided by 'operatorfunc'. See |comment.api.call|
---@brief ]]
---@tag comment.commentstring
---@brief [[
---Comment.nvim picks commentstring, either linewise/blockwise, from one of the
---following places
---
--- 1. 'pre_hook'
---       If a string is returned from this function then it will be used for
---       (un)commenting. See |comment.config|
---
--- 2. |comment.ft|
---       Using the commentstring table inside the plugin (using treesitter).
---       Fallback to |commentstring|, if not found.
---
--- 3. |commentstring| - Neovim's native commentstring for the filetype
---
---Although Comment.nvim supports native 'commentstring' but unfortunately it has
---the least priority. The caveat with this approach is that if someone sets the
---`commentstring`, without returning it, from the 'pre_hook' and the current
---filetype also exists in the |comment.ft| then the commenting will be done using
---the string in |comment.ft| instead of using 'commentstring'. To override this
---behavior, you have to manually return the 'commentstring' from 'pre_hook'.
---@brief ]]
---@tag comment.sourcecode
---@brief [[
---Comment.nvim is FOSS and distributed under MIT license. All the source code is
---available at https://github.com/numToStr/Comment.nvim
---@brief ]]

---@mod comment.usage Usage
---@brief [[
---Before using the plugin, you need to call the `setup()` function to create the
---default mappings. If you want, you can also override the default configuration
---by giving it a partial 'comment.config.Config' object, it will then be merged
---with the default configuration.
---@brief ]]

local C = {}

---Configures the plugin
---@param config? CommentConfig User configuration
---@return CommentConfig #Returns the modified config
---@see comment.config
---@usage [[
----- Use default configuration
---require('Comment').setup()
---
----- or with custom configuration
---require('Comment').setup({
---    ignore = '^$',
---    toggler = {
---        line = '<leader>cc',
---        block = '<leader>bc',
---    },
---    opleader = {
---        line = '<leader>c',
---        block = '<leader>b',
---    },
---})
---@usage ]]
function C.setup(config)
    local cfg = require('Comment.config'):set(config):get()

    if cfg.mappings then
        local api = require('Comment.api')
        local vvar = vim.api.nvim_get_vvar
        local K = vim.keymap.set

        -- Basic Mappings
        if cfg.mappings.basic then
            -- NORMAL mode mappings
            K('n', cfg.opleader.line, '<Plug>(comment_toggle_linewise)', { desc = 'Comment toggle linewise' })
            K('n', cfg.opleader.block, '<Plug>(comment_toggle_blockwise)', { desc = 'Comment toggle blockwise' })

            K('n', cfg.toggler.line, function()
                return vvar('count') == 0 and '<Plug>(comment_toggle_linewise_current)'
                    or '<Plug>(comment_toggle_linewise_count)'
            end, { expr = true, desc = 'Comment toggle current line' })
            K('n', cfg.toggler.block, function()
                return vvar('count') == 0 and '<Plug>(comment_toggle_blockwise_current)'
                    or '<Plug>(comment_toggle_blockwise_count)'
            end, { expr = true, desc = 'Comment toggle current block' })

            -- VISUAL mode mappings
            K(
                'x',
                cfg.opleader.line,
                '<Plug>(comment_toggle_linewise_visual)',
                { desc = 'Comment toggle linewise (visual)' }
            )
            K(
                'x',
                cfg.opleader.block,
                '<Plug>(comment_toggle_blockwise_visual)',
                { desc = 'Comment toggle blockwise (visual)' }
            )
        end

        -- Extra Mappings
        if cfg.mappings.extra then
            K('n', cfg.extra.below, api.insert.linewise.below, { desc = 'Comment insert below' })
            K('n', cfg.extra.above, api.insert.linewise.above, { desc = 'Comment insert above' })
            K('n', cfg.extra.eol, api.locked('insert.linewise.eol'), { desc = 'Comment insert end of line' })
        end
    end

    return cfg
end

return C
