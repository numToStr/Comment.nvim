---@mod comment.api API functions

local U = require('Comment.utils')
local Ex = require('Comment.extra')
local Op = require('Comment.opfunc')
local Config = require('Comment.config')
local A = vim.api

local api = {}

--====================================
--============ CORE API ==============
--====================================

--######### LINEWISE #########--

---Toggle linewise-comment on the current line
---@param cfg? CommentConfig
function api.toggle_current_linewise(cfg)
    api.toggle_current_linewise_op(nil, cfg)
end

---(Operator-Pending) Toggle linewise-comment on the current line
---@param opmode OpMode
---@param cfg? CommentConfig
function api.toggle_current_linewise_op(opmode, cfg)
    Op.opfunc(opmode, cfg or Config:get(), U.cmode.toggle, U.ctype.line, U.cmotion.line)
end

---(Operator-Pending) Toggle linewise-comment over multiple lines
---@param opmode OpMode
---@param cfg? CommentConfig
function api.toggle_linewise_op(opmode, cfg)
    Op.opfunc(opmode, cfg or Config:get(), U.cmode.toggle, U.ctype.line, U.cmotion._)
end

---Toggle linewise-comment over multiple lines using `vim.v.count`
---@param cfg? CommentConfig
function api.toggle_linewise_count(cfg)
    Op.count(Config.count or vim.v.count, cfg or Config:get(), U.ctype.line)
end

---@private
---(Operator-Pending) Toggle linewise-comment over using `vim.v.count`
---@param cfg? CommentConfig
function api.toggle_linewise_count_op(_, cfg)
    api.toggle_linewise_count(cfg)
end

--######### BLOCKWISE #########--

---Toggle blockwise comment on the current line
---@param cfg? CommentConfig
function api.toggle_current_blockwise(cfg)
    api.toggle_current_blockwise_op(nil, cfg)
end

---(Operator-Pending) Toggle blockwise comment on the current line
---@param opmode OpMode
---@param cfg? CommentConfig
function api.toggle_current_blockwise_op(opmode, cfg)
    Op.opfunc(opmode, cfg or Config:get(), U.cmode.toggle, U.ctype.block, U.cmotion.line)
end

---(Operator-Pending) Toggle blockwise-comment over multiple lines
---@param opmode OpMode
---@param cfg? CommentConfig
function api.toggle_blockwise_op(opmode, cfg)
    Op.opfunc(opmode, cfg or Config:get(), U.cmode.toggle, U.ctype.block, U.cmotion._)
end

---Toggle blockwise-comment over multiple lines using `vim.v.count`
---@param cfg? CommentConfig
function api.toggle_blockwise_count(cfg)
    Op.count(Config.count or vim.v.count, cfg or Config:get(), U.ctype.block)
end

---@private
---(Operator-Pending) Toggle blockwise-comment over `vim.v.count`
---@param cfg? CommentConfig
function api.toggle_blockwise_count_op(_, cfg)
    api.toggle_blockwise_count(cfg)
end

--=====================================
--============ EXTRA API ==============
--=====================================

--######### LINEWISE #########--

---Insert a linewise-comment below
---@param cfg? CommentConfig
function api.insert_linewise_below(cfg)
    Ex.insert_below(U.ctype.line, cfg or Config:get())
end

---Insert a linewise-comment above
---@param cfg? CommentConfig
function api.insert_linewise_above(cfg)
    Ex.insert_above(U.ctype.line, cfg or Config:get())
end

---Insert a linewise-comment at the end-of-line
---@param cfg? CommentConfig
function api.insert_linewise_eol(cfg)
    Ex.insert_eol(U.ctype.line, cfg or Config:get())
end

--######### BLOCKWISE #########--

---Insert a blockwise-comment below
---@param cfg? CommentConfig
function api.insert_blockwise_below(cfg)
    Ex.insert_below(U.ctype.block, cfg or Config:get())
end

---Insert a blockwise-comment above
---@param cfg? CommentConfig
function api.insert_blockwise_above(cfg)
    Ex.insert_above(U.ctype.block, cfg or Config:get())
end

---Insert a blockwise-comment at the end-of-line
---@param cfg? CommentConfig
function api.insert_blockwise_eol(cfg)
    Ex.insert_eol(U.ctype.block, cfg or Config:get())
end

--========================================
--============ EXTENDED API ==============
--========================================

--######### LINEWISE #########--

---Comment current line using linewise-comment
---@param cfg? CommentConfig
function api.comment_current_linewise(cfg)
    api.comment_current_linewise_op(nil, cfg)
end

---(Operator-Pending) Comment current line using linewise-comment
---@param opmode OpMode
---@param cfg? CommentConfig
function api.comment_current_linewise_op(opmode, cfg)
    Op.opfunc(opmode, cfg or Config:get(), U.cmode.comment, U.ctype.line, U.cmotion.line)
end

---(Operator-Pending) Comment multiple line using linewise-comment
---@param opmode OpMode
---@param cfg? CommentConfig
function api.comment_linewise_op(opmode, cfg)
    Op.opfunc(opmode, cfg or Config:get(), U.cmode.comment, U.ctype.line, U.cmotion._)
end

---Uncomment current line using linewise-comment
---@param cfg? CommentConfig
function api.uncomment_current_linewise(cfg)
    api.uncomment_current_linewise_op(nil, cfg)
end

---(Operator-Pending) Uncomment current line using linewise-comment
---@param opmode OpMode
---@param cfg? CommentConfig
function api.uncomment_current_linewise_op(opmode, cfg)
    Op.opfunc(opmode, cfg or Config:get(), U.cmode.uncomment, U.ctype.line, U.cmotion.line)
end

---(Operator-Pending) Uncomment multiple line using linewise-comment
---@param opmode OpMode
---@param cfg? CommentConfig
function api.uncomment_linewise_op(opmode, cfg)
    Op.opfunc(opmode, cfg or Config:get(), U.cmode.uncomment, U.ctype.line, U.cmotion._)
end

--######### BLOCKWISE #########--

---Comment current line using linewise-comment
---@param cfg? CommentConfig
function api.comment_current_blockwise(cfg)
    api.comment_current_blockwise_op(nil, cfg)
end

---(Operator-Pending) Comment current line using blockwise-comment
---@param opmode OpMode
---@param cfg? CommentConfig
function api.comment_current_blockwise_op(opmode, cfg)
    Op.opfunc(opmode, cfg or Config:get(), U.cmode.comment, U.ctype.block, U.cmotion.line)
end

---Uncomment current line using blockwise-comment
---@param cfg? CommentConfig
function api.uncomment_current_blockwise(cfg)
    api.uncomment_current_blockwise_op(nil, cfg)
end

---(Operator-Pending) Uncomment current line using blockwise-comment
---@param opmode OpMode
---@param cfg? CommentConfig
function api.uncomment_current_blockwise_op(opmode, cfg)
    Op.opfunc(opmode, cfg or Config:get(), U.cmode.uncomment, U.ctype.block, U.cmotion.line)
end

--==========================================
--============ ADDITIONAL API ==============
--==========================================

---Wraps all the functions with `lockmarks` to preserve marks/jumps
---@type table
---@usage `require('Comment.api').locked.toggle_current_linewise()`
api.locked = setmetatable({}, {
    __index = function(_, cb)
        ---Actual function which will be attached to operatorfunc
        ---@param opmode OpMode
        return function(opmode)
            return A.nvim_command(
                ('lockmarks lua require("Comment.api").%s(%s)'):format(cb, opmode and ('%q'):format(opmode))
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
    A.nvim_set_option('operatorfunc', ("v:lua.require'Comment.api'.locked.%s"):format(cb))
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
                { expr = true, remap = true, replace_keycodes = false, desc = 'Comment toggle current line' }
            )
            K(
                'n',
                cfg.toggler.block,
                "v:count == 0 ? '<Plug>(comment_toggle_current_blockwise)' : '<Plug>(comment_toggle_blockwise_count)'",
                { expr = true, remap = true, replace_keycodes = false, desc = 'Comment toggle current block' }
            )

            K('n', cfg.opleader.line, '<Plug>(comment_toggle_linewise)', { desc = 'Comment toggle linewise' })
            K('n', cfg.opleader.block, '<Plug>(comment_toggle_blockwise)', { desc = 'Comment toggle blockwise' })

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
            K(
                'n',
                cfg.extra.below,
                '<CMD>lua require("Comment.api").locked.insert_linewise_below()<CR>',
                { desc = 'Comment insert below' }
            )
            K(
                'n',
                cfg.extra.above,
                '<CMD>lua require("Comment.api").locked.insert_linewise_above()<CR>',
                { desc = 'Comment insert above' }
            )
            K(
                'n',
                cfg.extra.eol,
                '<CMD>lua require("Comment.api").locked.insert_linewise_eol()<CR>',
                { desc = 'Comment insert end of line' }
            )
        end

        -- Extended Mappings
        if cfg.mappings.extended then
            -- NORMAL mode extended
            K(
                'n',
                'g>',
                '<CMD>lua require("Comment.api").call("comment_linewise_op")<CR>g@',
                { desc = 'Comment region linewise' }
            )
            K(
                'n',
                'g>c',
                '<CMD>lua require("Comment.api").call("comment_current_linewise_op")<CR>g@$',
                { desc = 'Comment current line' }
            )
            K(
                'n',
                'g>b',
                '<CMD>lua require("Comment.api").call("comment_current_blockwise_op")<CR>g@$',
                { desc = 'Comment current block' }
            )

            K(
                'n',
                'g<',
                '<CMD>lua require("Comment.api").call("uncomment_linewise_op")<CR>g@',
                { desc = 'Uncomment region linewise' }
            )
            K(
                'n',
                'g<c',
                '<CMD>lua require("Comment.api").call("uncomment_current_linewise_op")<CR>g@$',
                { desc = 'Uncomment current line' }
            )
            K(
                'n',
                'g<b',
                '<CMD>lua require("Comment.api").call("uncomment_current_blockwise_op")<CR>g@$',
                { desc = 'Uncomment current block' }
            )

            -- VISUAL mode extended
            K(
                'x',
                'g>',
                '<ESC><CMD>lua require("Comment.api").locked.comment_linewise_op(vim.fn.visualmode())<CR>',
                { desc = 'Comment region linewise (visual)' }
            )
            K(
                'x',
                'g<',
                '<ESC><CMD>lua require("Comment.api").locked.uncomment_linewise_op(vim.fn.visualmode())<CR>',
                { desc = 'Uncomment region linewise (visual)' }
            )
        end
    end

    return cfg
end

return api
