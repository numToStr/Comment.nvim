---@mod comment.api API functions

local Config = require('Comment.config')
local N = require('Comment.new')
local A = vim.api

local api = {}

local function D(name, alt)
    vim.deprecate("require('Comment.api')." .. name, "require('Comment.api')." .. alt, '0.7', 'Comment.nvim', false)
end

--====================================
--============ CORE API ==============
--====================================

--######### LINEWISE #########--

---@deprecated
---Toggle linewise-comment on the current line
---@param cfg? CommentConfig
function api.toggle_current_linewise(cfg)
    D('toggle_current_linewise({cfg})', 'toggle.linewise.current(nil, {cfg})')
    N.toggle.linewise.current(nil, cfg)
end

---@deprecated
---(Operator-Pending) Toggle linewise-comment on the current line
---@param opmode OpMode
---@param cfg? CommentConfig
function api.toggle_current_linewise_op(opmode, cfg)
    D('toggle_current_linewise_op({opmode}, {cfg})', 'toggle.linewise.current({opmode}, {cfg})')
    N.toggle.linewise.current(opmode, cfg)
end

---@deprecated
---(Operator-Pending) Toggle linewise-comment over multiple lines
---@param opmode OpMode
---@param cfg? CommentConfig
function api.toggle_linewise_op(opmode, cfg)
    D('toggle_linewise_op({opmode}, {cfg})', 'toggle.linewise({opmode}, {cfg})')
    N.toggle.linewise(opmode, cfg)
end

---@deprecated
---Toggle linewise-comment over multiple lines using `vim.v.count`
---@param cfg? CommentConfig
function api.toggle_linewise_count(cfg)
    D('toggle_linewise_count({cfg})', 'toggle.linewise.count(vim.v.count, {cfg})')
    N.toggle.linewise.count(vim.v.count, cfg)
end

--######### BLOCKWISE #########--

---@deprecated
---Toggle blockwise comment on the current line
---@param cfg? CommentConfig
function api.toggle_current_blockwise(cfg)
    D('toggle_current_blockwise({cfg})', 'toggle.blockwise.current(nil, {cfg})')
    N.toggle.blockwise.current(nil, cfg)
end

---@deprecated
---(Operator-Pending) Toggle blockwise comment on the current line
---@param opmode OpMode
---@param cfg? CommentConfig
function api.toggle_current_blockwise_op(opmode, cfg)
    D('toggle_current_blockwise_op({opmode}, {cfg})', 'toggle.blockwise.current({opmode}, {cfg})')
    N.toggle.blockwise.current(opmode, cfg)
end

---@deprecated
---(Operator-Pending) Toggle blockwise-comment over multiple lines
---@param opmode OpMode
---@param cfg? CommentConfig
function api.toggle_blockwise_op(opmode, cfg)
    D('toggle_blockwise_op({opmode}, {cfg})', 'toggle.blockwise({opmode}, {cfg})')
    N.toggle.blockwise(opmode, cfg)
end

---@deprecated
---Toggle blockwise-comment over multiple lines using `vim.v.count`
---@param cfg? CommentConfig
function api.toggle_blockwise_count(cfg)
    D('toggle_blockwise_count({cfg})', 'toggle.blockwise.count(vim.v.count, {cfg})')
    N.toggle.blockwise.count(vim.v.count, cfg)
end

--=====================================
--============ EXTRA API ==============
--=====================================

--######### LINEWISE #########--

---@deprecated
---Insert a linewise-comment below
---@param cfg? CommentConfig
function api.insert_linewise_below(cfg)
    D('insert_linewise_below({cfg})', 'insert.linewise.below({cfg})')
    N.insert.linewise.below(cfg)
end

---@deprecated
---Insert a linewise-comment above
---@param cfg? CommentConfig
function api.insert_linewise_above(cfg)
    D('insert_linewise_above({cfg})', 'insert.linewise.above({cfg})')
    N.insert.linewise.above(cfg)
end

---@deprecated
---Insert a linewise-comment at the end-of-line
---@param cfg? CommentConfig
function api.insert_linewise_eol(cfg)
    D('insert_linewise_eol({cfg})', 'insert.linewise.eol({cfg})')
    N.insert.linewise.eol(cfg)
end

--######### BLOCKWISE #########--

---@deprecated
---Insert a blockwise-comment below
---@param cfg? CommentConfig
function api.insert_blockwise_below(cfg)
    D('insert_blockwise_below({cfg})', 'insert.blockwise.below({cfg})')
    N.insert.blockwise.below(cfg)
end

---@deprecated
---Insert a blockwise-comment above
---@param cfg? CommentConfig
function api.insert_blockwise_above(cfg)
    D('insert_blockwise_above({cfg})', 'insert.blockwise.above({cfg})')
    N.insert.blockwise.above(cfg)
end

---@deprecated
---Insert a blockwise-comment at the end-of-line
---@param cfg? CommentConfig
function api.insert_blockwise_eol(cfg)
    D('insert_blockwise_eol({cfg})', 'insert.blockwise.eol({cfg})')
    N.insert.blockwise.eol(cfg)
end

--========================================
--============ EXTENDED API ==============
--========================================

--######### LINEWISE #########--

---@deprecated
---Comment current line using linewise-comment
---@param cfg? CommentConfig
function api.comment_current_linewise(cfg)
    D('comment_current_linewise({cfg})', 'comment.linewise.current(nil, {cfg})')
    N.comment.linewise.current(nil, cfg)
end

---@deprecated
---(Operator-Pending) Comment current line using linewise-comment
---@param opmode OpMode
---@param cfg? CommentConfig
function api.comment_current_linewise_op(opmode, cfg)
    D('comment_current_linewise_op({opmode}, {cfg})', 'comment.linewise.current({opmode}, {cfg})')
    N.comment.linewise.current(opmode, cfg)
end

---@deprecated
---(Operator-Pending) Comment multiple line using linewise-comment
---@param opmode OpMode
---@param cfg? CommentConfig
function api.comment_linewise_op(opmode, cfg)
    D('comment_linewise_op({opmode}, {cfg})', 'comment.linewise({opmode}, {cfg})')
    N.comment.linewise(opmode, cfg)
end

---@deprecated
---Uncomment current line using linewise-comment
---@param cfg? CommentConfig
function api.uncomment_current_linewise(cfg)
    D('uncomment_current_linewise({cfg})', 'uncomment.linewise.current({nil}, {cfg})')
    N.uncomment.linewise.current(nil, cfg)
end

---@deprecated
---(Operator-Pending) Uncomment current line using linewise-comment
---@param opmode OpMode
---@param cfg? CommentConfig
function api.uncomment_current_linewise_op(opmode, cfg)
    D('uncomment_current_linewise_op({opmode}, {cfg})', 'uncomment.linewise.current({opmode}, {cfg})')
    N.uncomment.linewise.current(opmode, cfg)
end

---@deprecated
---(Operator-Pending) Uncomment multiple line using linewise-comment
---@param opmode OpMode
---@param cfg? CommentConfig
function api.uncomment_linewise_op(opmode, cfg)
    D('uncomment_linewise_op({opmode}, {cfg})', 'uncomment.linewise({opmode}, {cfg})')
    N.uncomment.linewise(opmode, cfg)
end

--######### BLOCKWISE #########--

---@deprecated
---Comment current line using linewise-comment
---@param cfg? CommentConfig
function api.comment_current_blockwise(cfg)
    D('comment_current_blockwise({cfg})', 'comment.blockwise.current(nil, {cfg})')
    N.comment.blockwise.current(nil, cfg)
end

---@deprecated
---(Operator-Pending) Comment current line using blockwise-comment
---@param opmode OpMode
---@param cfg? CommentConfig
function api.comment_current_blockwise_op(opmode, cfg)
    D('comment_current_blockwise_op({opmode}, {cfg})', 'comment.blockwise.current({opmode}, {cfg})')
    N.comment.blockwise.current(opmode, cfg)
end

---@deprecated
---Uncomment current line using blockwise-comment
---@param cfg? CommentConfig
function api.uncomment_current_blockwise(cfg)
    D('uncomment_current_blockwise({cfg})', 'uncomment.blockwise.current(nil, {cfg})')
    N.uncomment.blockwise.current(nil, cfg)
end

---@deprecated
---(Operator-Pending) Uncomment current line using blockwise-comment
---@param opmode OpMode
---@param cfg? CommentConfig
function api.uncomment_current_blockwise_op(opmode, cfg)
    D('uncomment_current_blockwise_op({opmode}, {cfg})', 'uncomment.blockwise.current({opmode}, {cfg})')
    N.uncomment.blockwise.current(opmode, cfg)
end

--==========================================
--============ ADDITIONAL API ==============
--==========================================

---Wraps all the functions with `lockmarks` to preserve marks/jumps
---@type table
---@usage `require('Comment.api').locked.toggle_current_linewise()`
api.locked = setmetatable({}, {
    __index = function(_, cb)
        D('locker.{fn}(args...)', 'locked({fn})(args...)')
        ---Actual function which will be attached to operatorfunc
        ---@param opmode OpMode
        return function(opmode)
            return A.nvim_command(
                ('lockmarks lua require("Comment.api").%s(%s)'):format(cb, opmode and ('%q'):format(opmode))
            )
        end
    end,
    -- NOTE: After removal of the old api functions, make `api.locked` a simple function call
    __call = function(_, cb)
        ---Actual function which will be attached to operatorfunc
        ---@param opmode OpMode
        return function(opmode)
            return A.nvim_command(
                -- TODO: replace 'Comment.new' => 'Comment.api'
                ('lockmarks lua require("Comment.new").%s(%s)'):format(cb, opmode and ('%q'):format(opmode))
            )
        end
    end,
})

---Callback function which does the following
---     1. Prevides dot-repeat support
---     2. Preserves jumps and marks
---     3. Store last cursor position
---NOTE: We are using `config` to store the position as it is a kinda global
---@param cb string Name of the API function to call
function api.call(cb)
    A.nvim_set_option('operatorfunc', ("v:lua.require'Comment.api'.locked'%s'"):format(cb))
    Config.position = Config:get().sticky and A.nvim_win_get_cursor(0)
    Config.count = vim.v.count
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
            K(
                'n',
                cfg.toggler.line,
                "v:count == 0 ? '<Plug>(comment_toggle_current_linewise)' : '<Plug>(comment_toggle_linewise_count)'",
                { expr = true, remap = true, replace_keycodes = false }
            )
            K(
                'n',
                cfg.toggler.block,
                "v:count == 0 ? '<Plug>(comment_toggle_current_blockwise)' : '<Plug>(comment_toggle_blockwise_count)'",
                { expr = true, remap = true, replace_keycodes = false }
            )

            K('n', cfg.opleader.line, '<Plug>(comment_toggle_linewise)')
            K('n', cfg.opleader.block, '<Plug>(comment_toggle_blockwise)')

            -- VISUAL mode mappings
            K('x', cfg.opleader.line, '<Plug>(comment_toggle_linewise_visual)')
            K('x', cfg.opleader.block, '<Plug>(comment_toggle_blockwise_visual)')
        end

        -- Extra Mappings
        if cfg.mappings.extra then
            K('n', cfg.extra.below, '<CMD>lua require("Comment.api").locked("insert.linewise.below")()<CR>')
            K('n', cfg.extra.above, '<CMD>lua require("Comment.api").locked("insert.linewise.above")()<CR>')
            K('n', cfg.extra.eol, '<CMD>lua require("Comment.api").locked("insert.linewise.eol")()<CR>')
        end

        -- Extended Mappings
        if cfg.mappings.extended then
            -- NORMAL mode extended
            K('n', 'g>', '<CMD>lua require("Comment.api").call("comment.linewise")<CR>g@')
            K('n', 'g>c', '<CMD>lua require("Comment.api").call("comment.linewise.current")<CR>g@$')
            K('n', 'g>b', '<CMD>lua require("Comment.api").call("comment.blockwise.current")<CR>g@$')

            K('n', 'g<', '<CMD>lua require("Comment.api").call("uncomment.linewise")<CR>g@')
            K('n', 'g<c', '<CMD>lua require("Comment.api").call("uncomment.linewise.current")<CR>g@$')
            K('n', 'g<b', '<CMD>lua require("Comment.api").call("uncomment.blockwise.current")<CR>g@$')

            -- VISUAL mode extended
            K('x', 'g>', '<ESC><CMD>lua require("Comment.api").locked("comment.linewise")(vim.fn.visualmode())<CR>')
            K('x', 'g<', '<ESC><CMD>lua require("Comment.api").locked("uncomment.linewise")(vim.fn.visualmode())<CR>')
        end
    end

    return cfg
end

return api
