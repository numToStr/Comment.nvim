local U = require('Comment.utils')
local Ex = require('Comment.extra')
local Op = require('Comment.opfunc')
local Config = require('Comment.config'):new()
local A = vim.api

local C = {}

---Comments the current line
function C.comment()
    local line = A.nvim_get_current_line()

    local pattern = U.get_pattern(Config:get().ignore)
    if not U.ignore(line, pattern) then
        local srow, scol = unpack(A.nvim_win_get_cursor(0))
        ---@type Ctx
        local ctx = {
            cmode = U.cmode.comment,
            cmotion = U.cmotion.line,
            ctype = U.ctype.line,
            range = { srow = srow, scol = scol, erow = srow, ecol = scol },
        }
        local lcs, rcs = U.parse_cstr(Config:get(), ctx)

        local padding, _ = U.get_padding(Config:get().padding)
        A.nvim_set_current_line(U.comment_str(line, lcs, rcs, padding))
        U.is_fn(Config:get().post_hook, ctx)
    end
end

---Uncomments the current line
function C.uncomment()
    local line = A.nvim_get_current_line()

    local pattern = U.get_pattern(Config:get().ignore)
    if not U.ignore(line, pattern) then
        local srow, scol = unpack(A.nvim_win_get_cursor(0))
        ---@type Ctx
        local ctx = {
            cmode = U.cmode.uncomment,
            cmotion = U.cmotion.line,
            ctype = U.ctype.line,
            range = { srow = srow, scol = scol, erow = srow, ecol = scol },
        }
        local lcs, rcs = U.parse_cstr(Config:get(), ctx)

        local _, pp = U.get_padding(Config:get().padding)
        local lcs_esc, rcs_esc = U.escape(lcs), U.escape(rcs)

        if U.is_commented(lcs_esc, rcs_esc, pp)(line) then
            A.nvim_set_current_line(U.uncomment_str(line, lcs_esc, rcs_esc, pp))
        end

        U.is_fn(Config:get().post_hook, ctx)
    end
end

---Toggle comment of the current line
function C.toggle()
    local line = A.nvim_get_current_line()

    local pattern = U.get_pattern(Config:get().ignore)
    if not U.ignore(line, pattern) then
        local srow, scol = unpack(A.nvim_win_get_cursor(0))
        ---@type Ctx
        local ctx = {
            cmode = U.cmode.toggle,
            cmotion = U.cmotion.line,
            ctype = U.ctype.line,
            range = { srow = srow, scol = scol, erow = srow, ecol = scol },
        }
        local lcs, rcs = U.parse_cstr(Config:get(), ctx)

        local lcs_esc, rcs_esc = U.escape(lcs), U.escape(rcs)
        local padding, pp = U.get_padding(Config:get().padding)
        local is_cmt = U.is_commented(lcs_esc, rcs_esc, pp)(line)

        if is_cmt then
            A.nvim_set_current_line(U.uncomment_str(line, lcs_esc, rcs_esc, pp))
            ctx.cmode = U.cmode.uncomment
        else
            A.nvim_set_current_line(U.comment_str(line, lcs, rcs, padding))
            ctx.cmode = U.cmode.comment
        end

        U.is_fn(Config:get().post_hook, ctx)
    end
end

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

---Configures the whole plugin
---@param config Config
---@return Config
function C.setup(config)
    local cfg = Config:set(config):get()

    if cfg.mappings then
        local map = A.nvim_set_keymap
        local map_opt = { noremap = true, silent = true }

        -- Callback function to save cursor position and set operatorfunc
        -- NOTE: We are using cfg to store the position as the cfg is tossed around in most places
        function C.call(cb)
            cfg.___pos = cfg.sticky and A.nvim_win_get_cursor(0)
            vim.o.operatorfunc = "v:lua.require'Comment.api'." .. cb
        end

        -- Basic Mappings
        if cfg.mappings.basic then
            ---@private
            function C.gcc_count()
                Op.count(vim.v.count, cfg)
            end

            -- NORMAL mode mappings
            map(
                'n',
                cfg.toggler.line,
                [[ v:count == 0 ? '<CMD>lua require("Comment.api").call("toggleln_linewise_op")<CR>g@$' : '<CMD>lua require("Comment.api").gcc_count()<CR>']],
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
