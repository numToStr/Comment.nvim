local Op = require('Comment.opfunc')
local U = require('Comment.utils')
local A = vim.api

---LHS of toggle mappings in NORMAL + VISUAL mode
---@class Toggler
---@field line string Linewise comment keymap
---@field block string Blockwise comment keymap

---LHS of operator-pending mappings in NORMAL + VISUAL mode
---@class Opleader
---@field line string Linewise comment keymap
---@field block string Blockwise comment keymap

---LHS of extra mappings
---@class ExtraMapping
---@field above string Mapping to add comment on the line above
---@field below string Mapping to add comment on the line below
---@field eol string Mapping to add comment at the end of line

---Whether to create basic (operator-pending) and extended mappings
---@class Mappings
---Enable operator-pending mapping
---Includes `gcc`, `gbc`, `gc[count]{motion}` and `gb[count]{motion}`
---NOTE: These mappings can be changed individually by `opleader` and `toggler` config
---@field basic boolean
---Enable extra mapping
---Includes `gco`, `gcO`, `gcA`
---@field extra boolean
---Enable extended mapping
---Includes `g>`, `g<`, `g>[count]{motion}` and `g<[count]{motion}`
---@field extended boolean

---Plugin's config
---@class Config
---@field padding boolean Add a space b/w comment and the line
---Whether the cursor should stay at its position
---NOTE: This only affects NORMAL mode mappings and doesn't work with dot-repeat
---@field sticky boolean
---Lines to be ignored while comment/uncomment.
---Could be a regex string or a function that returns a regex string.
---Example: Use '^$' to ignore empty lines
---@field ignore string|function
---@field mappings Mappings
---@field toggler Toggler
---@field opleader Opleader
---@field extra ExtraMapping
---@field pre_hook fun(ctx: Ctx):string Function to be called before comment/uncomment
---@field post_hook fun(ctx:Ctx) Function to be called after comment/uncomment

local C = {
    ---@type Config
    config = nil,
}

---Get the plugin's config
---@return Config
function C.get_config()
    return C.config
end

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

---Toggle comment using linewise comment
---@param vmode VMode
---@param cfg Config
function C.gcc(vmode, cfg)
    Op.opfunc(vmode, cfg or C.config, U.cmode.toggle, U.ctype.line, U.cmotion.line)
end

---Toggle comment using blockwise comment
---@param vmode VMode
---@param cfg Config
function C.gbc(vmode, cfg)
    Op.opfunc(vmode, cfg or C.config, U.cmode.toggle, U.ctype.block, U.cmotion.line)
end

---(Operator-Pending) Toggle comment using linewise comment
---@param vmode VMode
---@param cfg Config
function C.gc(vmode, cfg)
    Op.opfunc(vmode, cfg or C.config, U.cmode.toggle, U.ctype.line, U.cmotion._)
end

---(Operator-Pending) Toggle comment using blockwise comment
---@param vmode VMode
---@param cfg Config
function C.gb(vmode, cfg)
    Op.opfunc(vmode, cfg or C.config, U.cmode.toggle, U.ctype.block, U.cmotion._)
end

---Configures the whole plugin
---@param opts Config
function C.setup(opts)
    ---@type Config
    C.config = {
        padding = true,
        sticky = true,
        mappings = {
            basic = true,
            extra = true,
            extended = false,
        },
        toggler = {
            line = 'gcc',
            block = 'gbc',
        },
        opleader = {
            line = 'gc',
            block = 'gb',
        },
        extra = {
            above = 'gcO',
            below = 'gco',
            eol = 'gcA',
        },
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
end

return C
