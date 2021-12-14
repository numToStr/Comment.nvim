local U = require('Comment.utils')
local Ex = require('Comment.extra')
local Op = require('Comment.opfunc')
local Config = require('Comment.config'):new()
local A = vim.api

local C = {}

--------------------------------------
-------------- CORE API --------------
--------------------------------------

--######### LINEWISE #########--

---Toggle linewise-comment on the current line
---@param cfg? Config
function C.toggleln_linewise(cfg)
    C.toggleln_linewise_op(nil, cfg)
end

---(Operator-Pending) Toggle linewise-comment on the current line
---@param vmode VMode
---@param cfg? Config
function C.toggleln_linewise_op(vmode, cfg)
    Op.opfunc(vmode, cfg or Config:get(), U.cmode.toggle, U.ctype.line, U.cmotion.line)
end

---(Operator-Pending) Toggle linewise-comment over multiple lines
---@param vmode VMode
---@param cfg? Config
function C.toggle_linewise_op(vmode, cfg)
    Op.opfunc(vmode, cfg or Config:get(), U.cmode.toggle, U.ctype.line, U.cmotion._)
end

---Toggle linewise-comment over multiple lines using `vim.v.count`
---@param cfg Config
function C.toggle_linewise_count(cfg)
    Op.count(vim.v.count, cfg or Config:get())
end

--######### BLOCKWISE #########--

---Toggle blockwise comment on the current line
---@param cfg? Config
function C.toggleln_blockwise(cfg)
    C.toggleln_blockwise_op(nil, cfg)
end

---(Operator-Pending) Toggle blockwise comment on the current line
---@param vmode VMode
---@param cfg? Config
function C.toggleln_blockwise_op(vmode, cfg)
    Op.opfunc(vmode, cfg or Config:get(), U.cmode.toggle, U.ctype.block, U.cmotion.line)
end

---(Operator-Pending) Toggle blockwise-comment over multiple lines
---@param vmode VMode
---@param cfg? Config
function C.toggle_blockwise_op(vmode, cfg)
    Op.opfunc(vmode, cfg or Config:get(), U.cmode.toggle, U.ctype.block, U.cmotion._)
end

---------------------------------------
-------------- EXTRA API --------------
---------------------------------------

--######### LINEWISE #########--

---Insert a linewise-comment below
---@param cfg? Config
function C.insert_linewise_below(cfg)
    Ex.insert_below(U.ctype.line, cfg or Config:get())
end

---Insert a blockwise-comment below
---@param cfg? Config
function C.insert_blockwise_below(cfg)
    Ex.insert_below(U.ctype.block, cfg or Config:get())
end

---Insert a linewise-comment above
---@param cfg? Config
function C.insert_linewise_above(cfg)
    Ex.insert_above(U.ctype.line, cfg or Config:get())
end

--######### BLOCKWISE #########--

---Insert a blockwise-comment above
---@param cfg? Config
function C.insert_blockwise_above(cfg)
    Ex.insert_above(U.ctype.block, cfg or Config:get())
end

---Insert a linewise-comment at the end-of-line
---@param cfg? Config
function C.insert_linewise_eol(cfg)
    Ex.insert_eol(U.ctype.line, cfg or Config:get())
end

---Insert a blockwise-comment at the end-of-line
---@param cfg? Config
function C.insert_blockwise_eol(cfg)
    Ex.insert_eol(U.ctype.block, cfg or Config:get())
end

------------------------------------------
-------------- EXTENDED API --------------
------------------------------------------

--######### LINEWISE #########--

---Comment current line using linewise-comment
---@param cfg? Config
function C.commentln_linewise(cfg)
    C.commentln_linewise_op(nil, cfg)
end

---(Operator-Pending) Comment current line using linewise-comment
---@param vmode VMode
---@param cfg? Config
function C.commentln_linewise_op(vmode, cfg)
    Op.opfunc(vmode, cfg or Config:get(), U.cmode.comment, U.ctype.line, U.cmotion.line)
end

---(Operator-Pending) Comment multiple line using linewise-comment
---@param vmode VMode
---@param cfg? Config
function C.comment_linewise_op(vmode, cfg)
    Op.opfunc(vmode, cfg or Config:get(), U.cmode.comment, U.ctype.line, U.cmotion._)
end

---Uncomment current line using linewise-comment
---@param cfg? Config
function C.uncommentln_linewise(cfg)
    C.uncommentln_linewise_op(nil, cfg)
end

---(Operator-Pending) Uncomment current line using linewise-comment
---@param vmode VMode
---@param cfg? Config
function C.uncommentln_linewise_op(vmode, cfg)
    Op.opfunc(vmode, cfg or Config:get(), U.cmode.uncomment, U.ctype.line, U.cmotion.line)
end

---(Operator-Pending) Uncomment multiple line using linewise-comment
---@param vmode VMode
---@param cfg? Config
function C.uncomment_linewise_op(vmode, cfg)
    Op.opfunc(vmode, cfg or Config:get(), U.cmode.uncomment, U.ctype.line, U.cmotion._)
end

--######### BLOCKWISE #########--

---Comment current line using linewise-comment
---@param cfg? Config
function C.commentln_blockwise(cfg)
    C.commentln_blockwise_op(nil, cfg)
end

---(Operator-Pending) Comment current line using blockwise-comment
---@param vmode VMode
---@param cfg? Config
function C.commentln_blockwise_op(vmode, cfg)
    Op.opfunc(vmode, cfg or Config:get(), U.cmode.comment, U.ctype.block, U.cmotion.line)
end

---Uncomment current line using blockwise-comment
---@param cfg? Config
function C.uncommentln_blockwise(cfg)
    C.uncommentln_blockwise_op(nil, cfg)
end

---(Operator-Pending) Uncomment current line using blockwise-comment
---@param vmode VMode
---@param cfg? Config
function C.uncommentln_blockwise_op(vmode, cfg)
    Op.opfunc(vmode, cfg, U.cmode.uncomment, U.ctype.block, U.cmotion.line)
end

--------------------------------------------
-------------- ADDITIONAL API --------------
--------------------------------------------

-- Callback function to save cursor position and set operatorfunc
-- NOTE: We are using `config` to store the position as it is a kinda global
-- @param cb string Name of the API function to call
function C.call(cb)
    local cfg = Config:get()
    A.nvim_set_option('operatorfunc', "v:lua.require'Comment.api'." .. cb)
    cfg.__pos = cfg.sticky and A.nvim_win_get_cursor(0)
end

---Configures the whole plugin
---@param config Config
---@return Config
function C.setup(config)
    local cfg = Config:set(config):get()

    if cfg.mappings then
        local map = A.nvim_set_keymap
        local map_opt = { noremap = true, silent = true }

        -- Basic Mappings
        if cfg.mappings.basic then
            -- NORMAL mode mappings
            map(
                'n',
                cfg.toggler.line,
                [[v:count == 0 ? '<CMD>lua require("Comment.api").call("toggleln_linewise_op")<CR>g@$' : '<CMD>lua require("Comment.api").toggle_linewise_count()<CR>']],
                { noremap = true, silent = true, expr = true }
            )
            map('n', cfg.toggler.block, '<CMD>lua require("Comment.api").call("toggleln_blockwise_op")<CR>g@$', map_opt)
            map('n', cfg.opleader.line, '<CMD>lua require("Comment.api").call("toggle_linewise_op")<CR>g@', map_opt)
            map('n', cfg.opleader.block, '<CMD>lua require("Comment.api").call("toggle_blockwise_op")<CR>g@', map_opt)

            -- VISUAL mode mappings
            map(
                'x',
                cfg.opleader.line,
                '<ESC><CMD>lua require("Comment.api").toggle_linewise_op(vim.fn.visualmode())<CR>',
                map_opt
            )
            map(
                'x',
                cfg.opleader.block,
                '<ESC><CMD>lua require("Comment.api").toggle_blockwise_op(vim.fn.visualmode())<CR>',
                map_opt
            )
        end

        -- Extra Mappings
        if cfg.mappings.extra then
            map('n', cfg.extra.below, '<CMD>lua require("Comment.api").insert_linewise_below()<CR>', map_opt)
            map('n', cfg.extra.above, '<CMD>lua require("Comment.api").insert_linewise_above()<CR>', map_opt)
            map('n', cfg.extra.eol, '<CMD>lua require("Comment.api").insert_linewise_eol()<CR>', map_opt)
        end

        -- Extended Mappings
        if cfg.mappings.extended then
            -- NORMAL mode extended
            map('n', 'g>', '<CMD>lua require("Comment.api").call("comment_linewise_op")<CR>g@', map_opt)
            map('n', 'g>c', '<CMD>lua require("Comment.api").call("commentln_linewise_op")<CR>g@$', map_opt)
            map('n', 'g>b', '<CMD>lua require("Comment.api").call("commentln_blockwise_op")<CR>g@$', map_opt)

            map('n', 'g<', '<CMD>lua require("Comment.api").call("uncomment_linewise_op")<CR>g@', map_opt)
            map('n', 'g<c', '<CMD>lua require("Comment.api").call("uncommentln_linewise_op")<CR>g@$', map_opt)
            map('n', 'g<b', '<CMD>lua require("Comment.api").call("uncommentln_blockwise_op")<CR>g@$', map_opt)

            -- VISUAL mode extended
            map('x', 'g>', '<ESC><CMD>lua require("Comment.api").comment_linewise_op(vim.fn.visualmode())<CR>', map_opt)
            map(
                'x',
                'g<',
                '<ESC><CMD>lua require("Comment.api").uncomment_linewise_op(vim.fn.visualmode())<CR>',
                map_opt
            )
        end
    end

    return cfg
end

return C
