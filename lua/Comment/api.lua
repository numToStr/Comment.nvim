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

local api = {}

------------ OLD START ------------

local function D(name, alt)
    vim.deprecate("require('Comment.api')." .. name, "require('Comment.api')." .. alt, '0.7', 'Comment.nvim', false)
end

--====================================
--============ CORE API ==============
--====================================

--######### LINEWISE #########--

---@private
---@deprecated
---Toggle linewise-comment on the current line
---@param cfg? CommentConfig
function api.toggle_current_linewise(cfg)
    D('toggle_current_linewise({cfg})', 'toggle.linewise.current(nil, {cfg})')
    api.toggle.linewise.current(nil, cfg)
end

---@private
---@deprecated
---(Operator-Pending) Toggle linewise-comment on the current line
---@param opmode OpMotion
---@param cfg? CommentConfig
function api.toggle_current_linewise_op(opmode, cfg)
    D('toggle_current_linewise_op({opmode}, {cfg})', 'toggle.linewise.current({opmode}, {cfg})')
    api.toggle.linewise.current(opmode, cfg)
end

---@private
---@deprecated
---(Operator-Pending) Toggle linewise-comment over multiple lines
---@param opmode OpMotion
---@param cfg? CommentConfig
function api.toggle_linewise_op(opmode, cfg)
    D('toggle_linewise_op({opmode}, {cfg})', 'toggle.linewise({opmode}, {cfg})')
    api.toggle.linewise(opmode, cfg)
end

---@private
---@deprecated
---Toggle linewise-comment over multiple lines using `vim.v.count`
---@param cfg? CommentConfig
function api.toggle_linewise_count(cfg)
    D('toggle_linewise_count({cfg})', 'toggle.linewise.count(vim.v.count, {cfg})')
    api.toggle.linewise.count(vim.v.count, cfg)
end

--######### BLOCKWISE #########--

---@private
---@deprecated
---Toggle blockwise comment on the current line
---@param cfg? CommentConfig
function api.toggle_current_blockwise(cfg)
    D('toggle_current_blockwise({cfg})', 'toggle.blockwise.current(nil, {cfg})')
    api.toggle.blockwise.current(nil, cfg)
end

---@private
---@deprecated
---(Operator-Pending) Toggle blockwise comment on the current line
---@param opmode OpMotion
---@param cfg? CommentConfig
function api.toggle_current_blockwise_op(opmode, cfg)
    D('toggle_current_blockwise_op({opmode}, {cfg})', 'toggle.blockwise.current({opmode}, {cfg})')
    api.toggle.blockwise.current(opmode, cfg)
end

---@private
---@deprecated
---(Operator-Pending) Toggle blockwise-comment over multiple lines
---@param opmode OpMotion
---@param cfg? CommentConfig
function api.toggle_blockwise_op(opmode, cfg)
    D('toggle_blockwise_op({opmode}, {cfg})', 'toggle.blockwise({opmode}, {cfg})')
    api.toggle.blockwise(opmode, cfg)
end

---@private
---@deprecated
---Toggle blockwise-comment over multiple lines using `vim.v.count`
---@param cfg? CommentConfig
function api.toggle_blockwise_count(cfg)
    D('toggle_blockwise_count({cfg})', 'toggle.blockwise.count(vim.v.count, {cfg})')
    api.toggle.blockwise.count(vim.v.count, cfg)
end

--=====================================
--============ EXTRA API ==============
--=====================================

--######### LINEWISE #########--

---@private
---@deprecated
---Insert a linewise-comment below
---@param cfg? CommentConfig
function api.insert_linewise_below(cfg)
    D('insert_linewise_below({cfg})', 'insert.linewise.below({cfg})')
    api.insert.linewise.below(cfg)
end

---@private
---@deprecated
---Insert a linewise-comment above
---@param cfg? CommentConfig
function api.insert_linewise_above(cfg)
    D('insert_linewise_above({cfg})', 'insert.linewise.above({cfg})')
    api.insert.linewise.above(cfg)
end

---@private
---@deprecated
---Insert a linewise-comment at the end-of-line
---@param cfg? CommentConfig
function api.insert_linewise_eol(cfg)
    D('insert_linewise_eol({cfg})', 'insert.linewise.eol({cfg})')
    api.insert.linewise.eol(cfg)
end

--######### BLOCKWISE #########--

---@private
---@deprecated
---Insert a blockwise-comment below
---@param cfg? CommentConfig
function api.insert_blockwise_below(cfg)
    D('insert_blockwise_below({cfg})', 'insert.blockwise.below({cfg})')
    api.insert.blockwise.below(cfg)
end

---@private
---@deprecated
---Insert a blockwise-comment above
---@param cfg? CommentConfig
function api.insert_blockwise_above(cfg)
    D('insert_blockwise_above({cfg})', 'insert.blockwise.above({cfg})')
    api.insert.blockwise.above(cfg)
end

---@private
---@deprecated
---Insert a blockwise-comment at the end-of-line
---@param cfg? CommentConfig
function api.insert_blockwise_eol(cfg)
    D('insert_blockwise_eol({cfg})', 'insert.blockwise.eol({cfg})')
    api.insert.blockwise.eol(cfg)
end

--========================================
--============ EXTENDED API ==============
--========================================

--######### LINEWISE #########--

---@private
---@deprecated
---Comment current line using linewise-comment
---@param cfg? CommentConfig
function api.comment_current_linewise(cfg)
    D('comment_current_linewise({cfg})', 'comment.linewise.current(nil, {cfg})')
    api.comment.linewise.current(nil, cfg)
end

---@private
---@deprecated
---(Operator-Pending) Comment current line using linewise-comment
---@param opmode OpMotion
---@param cfg? CommentConfig
function api.comment_current_linewise_op(opmode, cfg)
    D('comment_current_linewise_op({opmode}, {cfg})', 'comment.linewise.current({opmode}, {cfg})')
    api.comment.linewise.current(opmode, cfg)
end

---@private
---@deprecated
---(Operator-Pending) Comment multiple line using linewise-comment
---@param opmode OpMotion
---@param cfg? CommentConfig
function api.comment_linewise_op(opmode, cfg)
    D('comment_linewise_op({opmode}, {cfg})', 'comment.linewise({opmode}, {cfg})')
    api.comment.linewise(opmode, cfg)
end

---@private
---@deprecated
---Uncomment current line using linewise-comment
---@param cfg? CommentConfig
function api.uncomment_current_linewise(cfg)
    D('uncomment_current_linewise({cfg})', 'uncomment.linewise.current({nil}, {cfg})')
    api.uncomment.linewise.current(nil, cfg)
end

---@private
---@deprecated
---(Operator-Pending) Uncomment current line using linewise-comment
---@param opmode OpMotion
---@param cfg? CommentConfig
function api.uncomment_current_linewise_op(opmode, cfg)
    D('uncomment_current_linewise_op({opmode}, {cfg})', 'uncomment.linewise.current({opmode}, {cfg})')
    api.uncomment.linewise.current(opmode, cfg)
end

---@private
---@deprecated
---(Operator-Pending) Uncomment multiple line using linewise-comment
---@param opmode OpMotion
---@param cfg? CommentConfig
function api.uncomment_linewise_op(opmode, cfg)
    D('uncomment_linewise_op({opmode}, {cfg})', 'uncomment.linewise({opmode}, {cfg})')
    api.uncomment.linewise(opmode, cfg)
end

--######### BLOCKWISE #########--

---@private
---@deprecated
---Comment current line using linewise-comment
---@param cfg? CommentConfig
function api.comment_current_blockwise(cfg)
    D('comment_current_blockwise({cfg})', 'comment.blockwise.current(nil, {cfg})')
    api.comment.blockwise.current(nil, cfg)
end

---@private
---@deprecated
---(Operator-Pending) Comment current line using blockwise-comment
---@param opmode OpMotion
---@param cfg? CommentConfig
function api.comment_current_blockwise_op(opmode, cfg)
    D('comment_current_blockwise_op({opmode}, {cfg})', 'comment.blockwise.current({opmode}, {cfg})')
    api.comment.blockwise.current(opmode, cfg)
end

---@private
---@deprecated
---Uncomment current line using blockwise-comment
---@param cfg? CommentConfig
function api.uncomment_current_blockwise(cfg)
    D('uncomment_current_blockwise({cfg})', 'uncomment.blockwise.current(nil, {cfg})')
    api.uncomment.blockwise.current(nil, cfg)
end

---@private
---@deprecated
---(Operator-Pending) Uncomment current line using blockwise-comment
---@param opmode OpMotion
---@param cfg? CommentConfig
function api.uncomment_current_blockwise_op(opmode, cfg)
    D('uncomment_current_blockwise_op({opmode}, {cfg})', 'uncomment.blockwise.current({opmode}, {cfg})')
    api.uncomment.blockwise.current(opmode, cfg)
end

------------ OLD END ------------

local core = {}

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
        Op.count(Config.count or count, cfg or Config:get(), that.cmode, U.ctype[ctype])
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
----- NORMAL mode
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
----- VISUAL mode
---
---local esc = vim.api.nvim_replace_termcodes(
---    '<ESC>', true, false, true
---)
---
----- Linewise toggle (linewise)
---vim.keymap.set('x', '<leader>c', function()
---    vim.api.nvim_feedkeys(esc, 'nx', false)
---    api.toggle.linewise(vim.fn.visualmode())
---end)
---
----- Blockwise toggle (blockwise)
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

-- TODO: After removing old API
-- 1. make `api.locked` a simple function call
-- 2. fix emmylua doc

---Wraps the given API function with 'lockmarks' to preserve marks/jumps
---@type fun(cb:string):fun(motion:OpMotion)
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
api.locked = setmetatable({}, {
    __index = function(this, cb)
        D(string.format('locker.%s(args...)', cb), string.format('locked(%q)(args...)', cb))
        return this(cb)
    end,
    __call = function(_, cb)
        ---operatorfunc callback
        ---@param motion OpMotion
        return function(motion)
            return A.nvim_command(
                ('lockmarks lua require("Comment.api").%s(%s)'):format(cb, motion and ('%q'):format(motion))
            )
        end
    end,
})

---@tag comment.api.dotrepeat
---Callback function which does the following
---  1. Sets 'operatorfunc' for dot-repeat
---  2. Preserves jumps and marks
---  3. Stores last cursor position
---@param cb string Name of the API function to call
---@param op 'g@'|'g@$' Operator string to execute
---@return fun():string _ Keymap RHS callback
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
        Config.count = vim.v.count
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
                return vim.v.count == 0 and '<Plug>(comment_toggle_linewise_current)'
                    or '<Plug>(comment_toggle_linewise_count)'
            end, { expr = true, desc = 'Comment toggle current line' })
            K('n', cfg.toggler.block, function()
                return vim.v.count == 0 and '<Plug>(comment_toggle_blockwise_current)'
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
            K('n', cfg.extra.below, api.locked('insert.linewise.below'), { desc = 'Comment insert below' })
            K('n', cfg.extra.above, api.locked('insert.linewise.above'), { desc = 'Comment insert above' })
            K('n', cfg.extra.eol, api.locked('insert.linewise.eol'), { desc = 'Comment insert end of line' })
        end

        -- Extended Mappings
        if cfg.mappings.extended then
            -- NORMAL mode extended
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

            -- VISUAL mode extended
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
