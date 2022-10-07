---@mod comment.api Core Lua API
---@brief [[
---This module provides the core lua APIs which is used by the default keybindings
---and <Plug> (Read |comment.plugmap|) mappings. These API can be used to setup your
---own custom keybindings or to even make your (un)comment function.
---@brief ]]

local Config = require('Comment.config')
local U = require('Comment.utils')
local Op = require('Comment.opfunc')
local Ex = require('Comment.extra')
local A = vim.api

local api, core = {}, {}

function core.__index(that, ctype)
    local idxd = {}

    ---To comment the current-line
    ---NOTE:
    ---In current-line linewise method, 'opmode' is not useful which is always equals to `char`
    ---but we need 'nil' here which is used for current-line
    function idxd.current(_, cfg)
        Op.opfunc(nil, cfg or Config:get(), that.cmode, U.ctype[ctype])
    end

    ---To comment lines with a count
    function idxd.count(count, cfg)
        Op.count(count or A.nvim_get_vvar('count'), cfg or Config:get(), that.cmode, U.ctype[ctype])
    end

    ---@private
    ---To comment lines with a count, also dot-repeatable
    ---WARNING: This is not part of the API but anyone case use it, if they want
    function idxd.count_repeat(_, count, cfg)
        idxd.count(count, cfg)
    end

    return setmetatable({ cmode = that.cmode, ctype = ctype }, {
        __index = idxd,
        __call = function(this, motion, cfg)
            Op.opfunc(motion, cfg or Config:get(), this.cmode, U.ctype[this.ctype])
        end,
    })
end

---@tag comment.api.toggle.linewise
---@tag comment.api.toggle.blockwise
---Provides API to toggle comments over a region, on current-line, or with a
---count using line or block comment string.
---
---All functions takes a {motion} argument, except '*.count()' function which
---takes an {count} argument, and an optional {config} parameter.
---@type table A metatable containing API functions
---@see comment.opfunc.OpMotion
---@see comment.config
---@usage [[
---local api = require('Comment.api')
---
---api.toggle.linewise(motion, config)
---api.toggle.linewise.current(motion?, config?)
---api.toggle.linewise.count(count, config?)
---
---api.toggle.blockwise(motion, config?)
---api.toggle.blockwise.current(motion?, config?)
---api.toggle.blockwise.count(count, config?)
---
----- Toggle current line (linewise) using C-/
---vim.keymap.set('n', '<C-_>', api.toggle.linewise.current)
---
----- Toggle current line (blockwise) using C-\
---vim.keymap.set('n', '<C-\\>', api.toggle.blockwise.current)
---
----- Toggle lines (linewise) with dot-repeat support
----- Example: <leader>gc3j will comment 4 lines
---vim.keymap.set(
---    'n', '<leader>gc', api.call('toggle.linewise', 'g@'),
---    { expr = true }
---)
---
----- Toggle lines (blockwise) with dot-repeat support
----- Example: <leader>gb3j will comment 4 lines
---vim.keymap.set(
---    'n', '<leader>gb', api.call('toggle.blockwise', 'g@'),
---    { expr = true }
---)
---
---local esc = vim.api.nvim_replace_termcodes(
---    '<ESC>', true, false, true
---)
---
----- Toggle selection (linewise)
---vim.keymap.set('x', '<leader>c', function()
---    vim.api.nvim_feedkeys(esc, 'nx', false)
---    api.toggle.linewise(vim.fn.visualmode())
---end)
---
----- Toggle selection (blockwise)
---vim.keymap.set('x', '<leader>b', function()
---    vim.api.nvim_feedkeys(esc, 'nx', false)
---    api.toggle.blockwise(vim.fn.visualmode())
---end)
---@usage ]]
api.toggle = setmetatable({ cmode = U.cmode.toggle }, core)

---@tag comment.api.comment.linewise
---@tag comment.api.comment.blockwise
---Provides API to (only) comment a region, on current-line, or with a
---count using line or block comment string.
---
---All functions takes a {motion} argument, except '*.count()' function which
---takes an {count} argument, and an optional {config} parameter.
---@type table A metatable containing API functions
---@see comment.opfunc.OpMotion
---@see comment.config
---@usage [[
---local api = require('Comment.api')
---
---api.comment.linewise(motion, config)
---api.comment.linewise.current(motion?, config?)
---api.comment.linewise.count(count, config?)
---
---api.comment.blockwise(motion, config?)
---api.comment.blockwise.current(motion?, config?)
---api.comment.blockwise.count(count, config?)
---@usage ]]
api.comment = setmetatable({ cmode = U.cmode.comment }, core)

---@tag comment.api.uncomment.linewise
---@tag comment.api.uncomment.blockwise
---Provides API to (only) uncomment a region, on current-line, or with a
---count using line or block comment string.
---
---All functions takes a {motion} argument, except '*.count()' function which
---takes an {count} argument, and an optional {config} parameter.
---@type table A metatable containing API functions
---@see comment.opfunc.OpMotion
---@see comment.config
---@usage [[
---local api = require('Comment.api')
---
---api.uncomment.linewise(motion, config)
---api.uncomment.linewise.current(motion?, config?)
---api.uncomment.linewise.count(count, config?)
---
---api.uncomment.blockwise(motion, config?)
---api.uncomment.blockwise.current(motion?, config?)
---api.uncomment.blockwise.count(count, config?)
---@usage ]]
api.uncomment = setmetatable({ cmode = U.cmode.uncomment }, core)

---Provides API to to insert comment on previous, next or at the end-of-line.
---All functions takes an optional {config} parameter.
---@type table A metatable containing API functions
---@see comment.config
---@usage [[
---local api = require('Comment.api')
---
---api.insert.linewise.above(cfg?)
---api.insert.linewise.below(cfg?)
---api.insert.linewise.eol(cfg?)
---
---api.insert.blockwise.above(cfg?)
---api.insert.blockwise.below(cfg?)
---api.insert.blockwise.eol(cfg?)
---@usage ]]
api.insert = setmetatable({}, {
    __index = function(_, ctype)
        return {
            above = function(cfg)
                Ex.insert_above(U.ctype[ctype], cfg or Config:get())
            end,
            below = function(cfg)
                Ex.insert_below(U.ctype[ctype], cfg or Config:get())
            end,
            eol = function(cfg)
                Ex.insert_eol(U.ctype[ctype], cfg or Config:get())
            end,
        }
    end,
})

---Wraps the given API function with 'lockmarks' to preserve marks/jumps
---@param cb string Name of API function
---@return fun(motion:OpMotion) #Callback function
---@see lockmarks
---@see comment.opfunc.OpMotion
---@usage [[
---local api = require('Comment.api')
---
---vim.keymap.set(
---    'n', '<leader>c', api.locked('toggle.linewise.current')
---)
---
---local esc = vim.api.nvim_replace_termcodes(
---    '<ESC>', true, false, true
---)
---vim.keymap.set('x', '<leader>c', function()
---    vim.api.nvim_feedkeys(esc, 'nx', false)
---    api.locked('toggle.linewise')(vim.fn.visualmode())
---end)
---
----- NOTE: `locked` method is just a wrapper around `lockmarks`
---vim.api.nvim_command([[
---    lockmarks lua require('Comment.api').toggle.linewise.current()
---]])
---@usage ]]
function api.locked(cb)
    return function(motion)
        return A.nvim_command(
            ('lockmarks lua require("Comment.api").%s(%s)'):format(cb, motion and ('%q'):format(motion))
        )
    end
end

---Callback function which does the following
---  1. Sets 'operatorfunc' for dot-repeat
---  2. Preserves jumps and marks
---  3. Stores last cursor position
---@param cb string Name of the API function to call
---@param op 'g@'|'g@$' Operator string to execute
---@return fun():string #Keymap RHS callback
---@see g@
---@see operatorfunc
---@usage [[
---local api = require('Comment.api')
---vim.keymap.set(
---    'n', 'gc', api.call('toggle.linewise', 'g@'),
---    { expr = true }
---)
---vim.keymap.set(
---    'n', 'gcc', api.call('toggle.linewise.current', 'g@$'),
---    { expr = true }
---)
---@usage ]]
function api.call(cb, op)
    return function()
        A.nvim_set_option('operatorfunc', ("v:lua.require'Comment.api'.locked'%s'"):format(cb))
        Config.position = Config:get().sticky and A.nvim_win_get_cursor(0) or nil
        return op
    end
end

---@private
---Configures the plugin
---@param config? CommentConfig
---@return CommentConfig
function api.setup(config)
    local cfg = Config:set(config):get()

    if cfg.mappings then
        local K = vim.keymap.set

        -- Basic Mappings
        if cfg.mappings.basic then
            -- NORMAL mode mappings
            K('n', cfg.opleader.line, '<Plug>(comment_toggle_linewise)', { desc = 'Comment toggle linewise' })
            K('n', cfg.opleader.block, '<Plug>(comment_toggle_blockwise)', { desc = 'Comment toggle blockwise' })

            K('n', cfg.toggler.line, function()
                return A.nvim_get_vvar('count') == 0 and '<Plug>(comment_toggle_linewise_current)'
                    or '<Plug>(comment_toggle_linewise_count)'
            end, { expr = true, desc = 'Comment toggle current line' })
            K('n', cfg.toggler.block, function()
                return A.nvim_get_vvar('count') == 0 and '<Plug>(comment_toggle_blockwise_current)'
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

        if cfg.mappings.extended then
            vim.notify_once(
                [=[[Comment] `extendend` mappings are deprecated and will be removed on 07 Nov 2022. Please refer to https://github.com/numToStr/Comment.nvim/wiki/Extended-Keybindings on how define them manually.]=],
                vim.log.levels.WARN
            )

            K('n', 'g>', api.call('comment.linewise', 'g@'), { expr = true, desc = 'Comment region linewise' })
            K('n', 'g>c', api.call('comment.linewise.current', 'g@$'), { expr = true, desc = 'Comment current line' })
            K('n', 'g>b', api.call('comment.blockwise.current', 'g@$'), { expr = true, desc = 'Comment current block' })

            K('n', 'g<', api.call('uncomment.linewise', 'g@'), { expr = true, desc = 'Uncomment region linewise' })
            K(
                'n',
                'g<c',
                api.call('uncomment.linewise.current', 'g@$'),
                { expr = true, desc = 'Uncomment current line' }
            )
            K(
                'n',
                'g<b',
                api.call('uncomment.blockwise.current', 'g@$'),
                { expr = true, desc = 'Uncomment current block' }
            )

            K(
                'x',
                'g>',
                '<ESC><CMD>lua require("Comment.api").locked("comment.linewise")(vim.fn.visualmode())<CR>',
                { desc = 'Comment region linewise (visual)' }
            )
            K(
                'x',
                'g<',
                '<ESC><CMD>lua require("Comment.api").locked("uncomment.linewise")(vim.fn.visualmode())<CR>',
                { desc = 'Uncomment region linewise (visual)' }
            )
        end
    end

    return cfg
end

return api
