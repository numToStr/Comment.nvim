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

---API metamethods
---@param that table
---@param ctype CommentType
---@return table
function core.__index(that, ctype)
    local idxd = {}
    local mode, type = that.cmode, U.ctype[ctype]

    ---To comment the current-line
    ---NOTE:
    ---In current-line linewise method, 'opmode' is not useful which is always equals to `char`
    ---but we need 'nil' here which is used for current-line
    function idxd.current(_, cfg)
        U.catch(Op.opfunc, nil, cfg or Config:get(), mode, type)
    end

    ---To comment lines with a count
    function idxd.count(count, cfg)
        U.catch(Op.count, count or A.nvim_get_vvar('count'), cfg or Config:get(), mode, type)
    end

    ---@private
    ---To comment lines with a count, also dot-repeatable
    ---WARN: This is not part of the API but anyone case use it, if they want
    function idxd.count_repeat(_, count, cfg)
        idxd.count(count, cfg)
    end

    return setmetatable({}, {
        __index = idxd,
        __call = function(_, motion, cfg)
            U.catch(Op.opfunc, motion, cfg or Config:get(), mode, type)
        end,
    })
end

---@tag comment.api.toggle.linewise
---@tag comment.api.toggle.blockwise
---Provides API to toggle comments over a region, on current-line, or with a
---count using line or block comment string.
---
---Every function takes a {motion} argument, except '*.count()' function which
---takes an {count} argument, and an optional {config} parameter.
---@type table A metatable containing API functions
---@see comment.opfunc.OpMotion
---@see comment.config
---@usage [[
---local api = require('Comment.api')
---local config = require('Comment.config'):get()
---
---api.toggle.linewise(motion, config?)
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
---Every function takes a {motion} argument, except '*.count()' function which
---takes an {count} argument, and an optional {config} parameter.
---@type table A metatable containing API functions
---@see comment.opfunc.OpMotion
---@see comment.config
---@usage [[
---local api = require('Comment.api')
---local config = require('Comment.config'):get()
---
---api.comment.linewise(motion, config?)
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
---Every function takes a {motion} argument, except '*.count()' function which
---takes an {count} argument, and an optional {config} parameter.
---@type table A metatable containing API functions
---@see comment.opfunc.OpMotion
---@see comment.config
---@usage [[
---local api = require('Comment.api')
---local config = require('Comment.config'):get()
---
---api.uncomment.linewise(motion, config?)
---api.uncomment.linewise.current(motion?, config?)
---api.uncomment.linewise.count(count, config?)
---
---api.uncomment.blockwise(motion, config?)
---api.uncomment.blockwise.current(motion?, config?)
---api.uncomment.blockwise.count(count, config?)
---@usage ]]
api.uncomment = setmetatable({ cmode = U.cmode.uncomment }, core)

---Provides API to to insert comment on previous, next or at the end-of-line.
---Every function takes an optional {config} parameter.
---@type table A metatable containing API functions
---@see comment.config
---@usage [[
---local api = require('Comment.api')
---local config = require('Comment.config'):get()
---
---api.insert.linewise.above(config?)
---api.insert.linewise.below(config?)
---api.insert.linewise.eol(config?)
---
---api.insert.blockwise.above(config?)
---api.insert.blockwise.below(config?)
---api.insert.blockwise.eol(config?)
---@usage ]]
api.insert = setmetatable({}, {
    __index = function(_, ctype)
        return {
            above = function(cfg)
                U.catch(Ex.insert_above, U.ctype[ctype], cfg or Config:get())
            end,
            below = function(cfg)
                U.catch(Ex.insert_below, U.ctype[ctype], cfg or Config:get())
            end,
            eol = function(cfg)
                U.catch(Ex.insert_eol, U.ctype[ctype], cfg or Config:get())
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
---@param op '"g@"'|'"g@$"' Operator-mode expression
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

return api
