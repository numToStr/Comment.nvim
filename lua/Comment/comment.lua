local U = require('Comment.utils')

local A = vim.api

local C = {
    ---@type Config|nil
    config = nil,
}

---Comments the current line
function C.comment()
    local line = A.nvim_get_current_line()

    local pattern = U.get_pattern(C.config.ignore)
    if not U.ignore(line, pattern) then
        local srow, scol = unpack(A.nvim_win_get_cursor(0))
        ---@type Ctx
        local ctx = {
            cmode = U.cmode.comment,
            cmotion = U.cmotion.line,
            ctype = U.ctype.line,
            range = { srow = srow, scol = scol, erow = srow, ecol = scol },
        }
        local lcs, rcs = U.parse_cstr(C.config, ctx)

        local padding, _ = U.get_padding(C.config.padding)
        A.nvim_set_current_line(U.comment_str(line, lcs, rcs, padding))
        U.is_fn(C.config.post_hook, ctx)
    end
end

---Uncomments the current line
function C.uncomment()
    local line = A.nvim_get_current_line()

    local pattern = U.get_pattern(C.config.ignore)
    if not U.ignore(line, pattern) then
        local srow, scol = unpack(A.nvim_win_get_cursor(0))
        ---@type Ctx
        local ctx = {
            cmode = U.cmode.uncomment,
            cmotion = U.cmotion.line,
            ctype = U.ctype.line,
            range = { srow = srow, scol = scol, erow = srow, ecol = scol },
        }
        local lcs, rcs = U.parse_cstr(C.config, ctx)

        local _, pp = U.get_padding(C.config.padding)
        local lcs_esc, rcs_esc = U.escape(lcs), U.escape(rcs)

        if U.is_commented(lcs_esc, rcs_esc, pp)(line) then
            A.nvim_set_current_line(U.uncomment_str(line, lcs_esc, rcs_esc, pp))
        end

        U.is_fn(C.config.post_hook, ctx)
    end
end

---Toggle comment of the current line
function C.toggle()
    local line = A.nvim_get_current_line()

    local pattern = U.get_pattern(C.config.ignore)
    if not U.ignore(line, pattern) then
        local srow, scol = unpack(A.nvim_win_get_cursor(0))
        ---@type Ctx
        local ctx = {
            cmode = U.cmode.toggle,
            cmotion = U.cmotion.line,
            ctype = U.ctype.line,
            range = { srow = srow, scol = scol, erow = srow, ecol = scol },
        }
        local lcs, rcs = U.parse_cstr(C.config, ctx)

        local lcs_esc, rcs_esc = U.escape(lcs), U.escape(rcs)
        local padding, pp = U.get_padding(C.config.padding)
        local is_cmt = U.is_commented(lcs_esc, rcs_esc, pp)(line)

        if is_cmt then
            A.nvim_set_current_line(U.uncomment_str(line, lcs_esc, rcs_esc, pp))
            ctx.cmode = U.cmode.uncomment
        else
            A.nvim_set_current_line(U.comment_str(line, lcs, rcs, padding))
            ctx.cmode = U.cmode.comment
        end

        U.is_fn(C.config.post_hook, ctx)
    end
end

function C.count_gcc(cfg)
    require('Comment.opfunc').count(cfg or C.config)
end

function C.gcc(vmode, cfg)
    require('Comment.opfunc').opfunc(vmode, cfg or C.config, U.cmode.toggle, U.ctype.line, U.cmotion.line)
end

function C.gbc(vmode, cfg)
    require('Comment.opfunc').opfunc(vmode, cfg or C.config, U.cmode.toggle, U.ctype.block, U.cmotion.line)
end

function C.gc(vmode, cfg)
    require('Comment.opfunc').opfunc(vmode, cfg or C.config, U.cmode.toggle, U.ctype.line, U.cmotion._)
end

function C.gb(vmode, cfg)
    require('Comment.opfunc').opfunc(vmode, cfg or C.config, U.cmode.toggle, U.ctype.block, U.cmotion._)
end

---Configures the whole plugin
---@param opts Config
function C.setup(opts)
    ---@class Config
    C.config = {
        ---Add a space b/w comment and the line
        ---@type boolean
        padding = true,
        ---Whether the cursor should stay at its position
        ---This only affects NORMAL mode mappings
        ---@type boolean
        sticky = true,
        ---Line which should be ignored while comment/uncomment
        ---Example: Use '^$' to ignore empty lines
        ---@type string|function Lua regex
        ignore = nil,
        ---Whether to create basic (operator-pending) and extended mappings
        ---@type table
        mappings = {
            ---operator-pending mapping
            basic = true,
            ---extra mapping
            extra = true,
            ---extended mapping
            extended = false,
        },
        ---LHS of toggle mapping in NORMAL mode for line and block comment
        ---@type table
        toggler = {
            ---LHS of line-comment toggle
            line = 'gcc',
            ---LHS of block-comment toggle
            block = 'gbc',
        },
        ---LHS of operator-mode mapping in NORMAL/VISUAL mode for line and block comment
        ---@type table
        opleader = {
            ---LHS of line-comment opfunc mapping
            line = 'gc',
            ---LHS of block-comment opfunc mapping
            block = 'gb',
        },
        ---Pre-hook, called before commenting the line
        ---@type function|nil
        pre_hook = nil,
        ---Post-hook, called after commenting is done
        ---@type function|nil
        post_hook = nil,
    }

    if opts ~= nil then
        C.config = vim.tbl_deep_extend('force', C.config, opts)
    end

    local cfg = C.config

    if cfg.mappings then
        local map = A.nvim_set_keymap
        local map_opt = { noremap = true, silent = true }

        -- Callback function to save cursor position and set operatorfunc
        -- NOTE: We are using cfg to store the position as the cfg is tossed around in most places
        function C.call(cb)
            cfg.___pos = cfg.sticky and A.nvim_win_get_cursor(0)
            vim.o.operatorfunc = "v:lua.require'Comment.comment'." .. cb
        end

        -- Basic Mappings
        if cfg.mappings.basic then
            -- NORMAL mode mappings
            map(
                'n',
                cfg.toggler.line,
                [[v:count == 0 ? '<CMD>lua require("Comment.comment").call("gcc")<CR>g@$' : '<CMD>lua require("Comment.comment").count_gcc()<CR>']],
                { noremap = true, silent = true, expr = true }
            )
            map('n', cfg.toggler.block, '<CMD>lua require("Comment.comment").call("gbc")<CR>g@$', map_opt)
            map('n', cfg.opleader.line, '<CMD>lua require("Comment.comment").call("gc")<CR>g@', map_opt)
            map('n', cfg.opleader.block, '<CMD>lua require("Comment.comment").call("gb")<CR>g@', map_opt)

            -- VISUAL mode mappings
            map('x', cfg.opleader.line, '<ESC><CMD>lua require("Comment.comment").gc(vim.fn.visualmode())<CR>', map_opt)
            map(
                'x',
                cfg.opleader.block,
                '<ESC><CMD>lua require("Comment.comment").gb(vim.fn.visualmode())<CR>',
                map_opt
            )
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

            map('n', 'gco', '<CMD>lua require("Comment.comment").gco()<CR>', map_opt)
            map('n', 'gcO', '<CMD>lua require("Comment.comment").gcO()<CR>', map_opt)
            map('n', 'gcA', '<CMD>lua require("Comment.comment").gcA()<CR>', map_opt)
        end

        -- Extended Mappings
        if cfg.mappings.extended then
            local Op = require('Comment.opfunc')

            function _G.___comment_ggt(vmode)
                Op.opfunc(cfg, vmode, U.cmode.comment, U.ctype.line, U.cmotion._)
            end
            function _G.___comment_ggtc(vmode)
                Op.opfunc(cfg, vmode, U.cmode.comment, U.ctype.line, U.cmotion.line)
            end
            function _G.___comment_ggtb(vmode)
                Op.opfunc(cfg, vmode, U.cmode.comment, U.ctype.block, U.cmotion.line)
            end

            function _G.___comment_glt(vmode)
                Op.opfunc(cfg, vmode, U.cmode.uncomment, U.ctype.line, U.cmotion._)
            end
            function _G.___comment_gltc(vmode)
                Op.opfunc(cfg, vmode, U.cmode.uncomment, U.ctype.line, U.cmotion.line)
            end
            function _G.___comment_gltb(vmode)
                Op.opfunc(cfg, vmode, U.cmode.uncomment, U.ctype.block, U.cmotion.line)
            end

            -- NORMAL mode extended
            map('n', 'g>', '<CMD>lua ___comment_call("ggt")<CR>g@', map_opt)
            map('n', 'g>c', '<CMD>lua ___comment_call("ggtc")<CR>g@$', map_opt)
            map('n', 'g>b', '<CMD>lua ___comment_call("ggtb")<CR>g@$', map_opt)

            map('n', 'g<', '<CMD>lua ___comment_call("glt")<CR>g@', map_opt)
            map('n', 'g<c', '<CMD>lua ___comment_call("gltc")<CR>g@$', map_opt)
            map('n', 'g<b', '<CMD>lua ___comment_call("gltb")<CR>g@$', map_opt)

            -- VISUAL mode extended
            map('x', 'g>', '<ESC><CMD>lua ___comment_ggt(vim.fn.visualmode())<CR>', map_opt)
            map('x', 'g<', '<ESC><CMD>lua ___comment_glt(vim.fn.visualmode())<CR>', map_opt)
        end
    end
end

return C
