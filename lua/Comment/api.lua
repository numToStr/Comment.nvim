local U = require('Comment.utils')
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

---Toggle comment using linewise comment
---@param vmode VMode
---@param cfg Config
function C.gcc(vmode, cfg)
    Op.opfunc(vmode, cfg or Config:get(), U.cmode.toggle, U.ctype.line, U.cmotion.line)
end

---Toggle comment using blockwise comment
---@param vmode VMode
---@param cfg Config
function C.gbc(vmode, cfg)
    Op.opfunc(vmode, cfg or Config:get(), U.cmode.toggle, U.ctype.block, U.cmotion.line)
end

---(Operator-Pending) Toggle comment using linewise comment
---@param vmode VMode
---@param cfg Config
function C.gc(vmode, cfg)
    Op.opfunc(vmode, cfg or Config:get(), U.cmode.toggle, U.ctype.line, U.cmotion._)
end

---(Operator-Pending) Toggle comment using blockwise comment
---@param vmode VMode
---@param cfg Config
function C.gb(vmode, cfg)
    Op.opfunc(vmode, cfg or Config:get(), U.cmode.toggle, U.ctype.block, U.cmotion._)
end

---Configures the whole plugin
---@param config Config
---@return table Config Updated config
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
                [[v:count == 0 ? '<CMD>lua require("Comment.api").call("gcc")<CR>g@$' : '<CMD>lua require("Comment.api").gcc_count()<CR>']],
                { noremap = true, silent = true, expr = true }
            )
            map('n', cfg.toggler.block, '<CMD>lua require("Comment.api").call("gbc")<CR>g@$', map_opt)
            map('n', cfg.opleader.line, '<CMD>lua require("Comment.api").call("gc")<CR>g@', map_opt)
            map('n', cfg.opleader.block, '<CMD>lua require("Comment.api").call("gb")<CR>g@', map_opt)

            -- VISUAL mode mappings
            map('x', cfg.opleader.line, '<ESC><CMD>lua require("Comment.api").gc(vim.fn.visualmode())<CR>', map_opt)
            map('x', cfg.opleader.block, '<ESC><CMD>lua require("Comment.api").gb(vim.fn.visualmode())<CR>', map_opt)
        end

        -- Extra Mappings
        if cfg.mappings.extra then
            local E = require('Comment.extra')

            function C.gco()
                E.norm_o(U.ctype.line, cfg)
            end
            function C.gcO()
                E.norm_O(U.ctype.line, cfg)
            end
            function C.gcA()
                E.norm_A(U.ctype.line, cfg)
            end

            map('n', cfg.extra.below, '<CMD>lua require("Comment.api").gco()<CR>', map_opt)
            map('n', cfg.extra.above, '<CMD>lua require("Comment.api").gcO()<CR>', map_opt)
            map('n', cfg.extra.eol, '<CMD>lua require("Comment.api").gcA()<CR>', map_opt)
        end

        -- Extended Mappings
        if cfg.mappings.extended then
            function C.ggt(vmode)
                Op.opfunc(vmode, cfg, U.cmode.comment, U.ctype.line, U.cmotion._)
            end
            function C.ggtc(vmode)
                Op.opfunc(vmode, cfg, U.cmode.comment, U.ctype.line, U.cmotion.line)
            end
            function C.ggtb(vmode)
                Op.opfunc(vmode, cfg, U.cmode.comment, U.ctype.block, U.cmotion.line)
            end

            function C.glt(vmode)
                Op.opfunc(vmode, cfg, U.cmode.uncomment, U.ctype.line, U.cmotion._)
            end
            function C.gltc(vmode)
                Op.opfunc(vmode, cfg, U.cmode.uncomment, U.ctype.line, U.cmotion.line)
            end
            function C.gltb(vmode)
                Op.opfunc(vmode, cfg, U.cmode.uncomment, U.ctype.block, U.cmotion.line)
            end

            -- NORMAL mode extended
            map('n', 'g>', '<CMD>lua require("Comment.api").call("ggt")<CR>g@', map_opt)
            map('n', 'g>c', '<CMD>lua require("Comment.api").call("ggtc")<CR>g@$', map_opt)
            map('n', 'g>b', '<CMD>lua require("Comment.api").call("ggtb")<CR>g@$', map_opt)

            map('n', 'g<', '<CMD>lua require("Comment.api").call("glt")<CR>g@', map_opt)
            map('n', 'g<c', '<CMD>lua require("Comment.api").call("gltc")<CR>g@$', map_opt)
            map('n', 'g<b', '<CMD>lua require("Comment.api").call("gltb")<CR>g@$', map_opt)

            -- VISUAL mode extended
            map('x', 'g>', '<ESC><CMD>lua require("Comment.api").ggt(vim.fn.visualmode())<CR>', map_opt)
            map('x', 'g<', '<ESC><CMD>lua require("Comment.api").glt(vim.fn.visualmode())<CR>', map_opt)
        end
    end

    return cfg
end

return C
