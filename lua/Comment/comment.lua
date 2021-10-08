local U = require('Comment.utils')

local A = vim.api
local bo = vim.bo

local C = {
    ---@type Config|nil
    config = nil,
}

---Unwraps the commentstring by taking it from the following places in the respective order.
---1. pre_hook (optionally a string can be returned)
---2. lang_table (extra commentstring table in the plugin)
---3. commentstring (already set or added in pre_hook)
---@param ctype CType (optional) Type of commentstring ie. line | block
---@return string string Left side of the commentstring
---@return string string Right side of the commentstring
local function unwrap_cstr(ctype)
    local cstr = pcall(C.config.pre_hook)
        or require('Comment.lang').get(bo.filetype, ctype or U.ctype.line)
        or bo.commentstring

    if U.is_empty(cstr) then
        return U.errprint("Empty commentstring. Run ':h commentstring' for help.")
    end

    local lcs, rcs = cstr:match('(.*)%%s(.*)')
    if not (lcs or rcs) then
        return U.errprint('Invalid commentstring: ' .. cstr .. ". Run ':h commentstring' for help.")
    end

    -- Return false if a part is empty, otherwise trim it
    -- Bcz it is better to deal with boolean rather than checking empty string length everywhere
    return not U.is_empty(lcs) and U.trim(lcs), not U.is_empty(rcs) and U.trim(rcs)
end

---Common fn to comment and set the current line
---@param ln string Line that needs to be commented
---@param lcs string Left side of the commentstring
---@param rcs string Right side of the commentstring
local function comment_ln(ln, lcs, rcs)
    A.nvim_set_current_line(U.comment_str(ln, lcs, rcs, C.config.padding))
end

---Common fn to uncomment and set the current line
---@param ln string Line that needs to be uncommented
---@param lcs_esc string (Escaped) Left side of the commentstring
---@param rcs_esc string (Escaped) Right side of the commentstring
local function uncomment_ln(ln, lcs_esc, rcs_esc)
    A.nvim_set_current_line(U.uncomment_str(ln, lcs_esc, rcs_esc, C.config.padding))
end

---Comments the current line
function C.comment()
    local line = A.nvim_get_current_line()

    if not U.ignore(line, C.config.ignore) then
        local lcs, rcs = unwrap_cstr()
        comment_ln(line, lcs, rcs)
    end

    pcall(C.config.post_hook, -1)
end

---Uncomments the current line
function C.uncomment()
    local line = A.nvim_get_current_line()

    if not U.ignore(line, C.config.ignore) then
        local lcs, rcs = unwrap_cstr()
        uncomment_ln(line, U.escape(lcs), U.escape(rcs))
    end

    pcall(C.config.post_hook, -1)
end

---Toggle comment of the current line
function C.toggle()
    local line = A.nvim_get_current_line()

    if not U.ignore(line, C.config.ignore) then
        local lcs, rcs = unwrap_cstr()
        local lcs_esc = U.escape(lcs)
        local is_cmt = U.is_commented(line, lcs_esc, nil, C.config.padding)

        if is_cmt then
            uncomment_ln(line, lcs_esc, U.escape(rcs))
        else
            comment_ln(line, lcs, rcs)
        end
    end

    pcall(C.config.post_hook, -1)
end

---Configures the whole plugin
---@param opts Config
function C.setup(opts)
    ---@class Config
    C.config = {
        ---Add a space b/w comment and the line
        ---@type boolean
        padding = true,
        ---Line which should be ignored while comment/uncomment
        ---Example: Use '^$' to ignore empty lines
        ---@type string Lua regex
        ignore = nil,
        ---Whether to create basic (operator-pending) and extra mappings
        ---@type table
        mappings = {
            ---operator-pending mapping
            basic = true,
            ---extended mapping
            extra = false,
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
        local Op = require('Comment.opfunc')

        ---Common operatorfunc callback
        ---@param vmode string VIM mode - line|char
        ---@param cmode CMode Comment mode
        ---@param ctype CType Type of the commentstring (line/block)
        ---@param cmotion CMotion Motion type
        local function opfunc(vmode, cmode, ctype, cmotion)
            -- comment/uncomment logic
            --
            -- 1. type == line
            --      * decide whether to comment or not, if all the lines are commented then uncomment otherwise comment
            --      * also, store the minimum indent from all the lines (exclude empty line)
            --      * if comment the line, use cstr LHS and also considering the min indent
            --      * if uncomment the line, remove cstr LHS from lines
            --      * update the lines
            -- 2. type == block
            --      * check if the first and last is commented or not with cstr LHS and RHS respectively.
            --      * if both lines commented
            --          - remove cstr LHS from the first line
            --          - remove cstr RHS to end of the last line
            --      * if both lines uncommented
            --          - add cstr LHS after the leading whitespace and before the first char of the first line
            --          - add cstr RHS to end of the last line
            --      * update the lines

            cmotion = cmotion == U.cmotion._ and U.cmotion[vmode] or cmotion

            local scol, ecol, lines, srow, erow = U.get_lines(vmode, ctype)
            local len = #lines

            local block_x = (cmotion == U.cmotion.char or cmotion == U.cmotion.v) and len == 1
            local lcs, rcs = unwrap_cstr(block_x and U.ctype.block or ctype)

            if block_x then
                Op.blockwise_x({
                    cfg = cfg,
                    cmode = cmode,
                    lines = lines,
                    lcs = lcs,
                    rcs = rcs,
                    scol = scol,
                    ecol = ecol,
                }, srow, erow)
            elseif ctype == U.ctype.block then
                Op.blockwise({
                    cfg = cfg,
                    cmode = cmode,
                    lines = lines,
                    lcs = lcs,
                    rcs = rcs,
                    scol = scol,
                    ecol = ecol,
                })
            else
                Op.linewise({
                    cfg = cfg,
                    cmode = cmode,
                    lines = lines,
                    lcs = lcs,
                    rcs = rcs,
                    scol = scol,
                    ecol = ecol,
                })
            end

            pcall(cfg.post_hook, scol, ecol)
        end

        local map = A.nvim_set_keymap
        local mopts = { noremap = true, silent = true }

        if cfg.mappings.basic then
            -- OperatorFunc main
            function _G.___opfunc_gcc(vmode)
                opfunc(vmode, U.cmode.toggle, U.ctype.line, U.cmotion.line)
            end
            function _G.___opfunc_gbc(vmode)
                opfunc(vmode, U.cmode.toggle, U.ctype.block, U.cmotion.line)
            end
            function _G.___opfunc_gc(vmode)
                opfunc(vmode, U.cmode.toggle, U.ctype.line, U.cmotion._)
            end
            function _G.___opfunc_gb(vmode)
                opfunc(vmode, U.cmode.toggle, U.ctype.block, U.cmotion._)
            end

            -- NORMAL mode mappings
            map('n', cfg.toggler.line, '<CMD>set operatorfunc=v:lua.___opfunc_gcc<CR>g@$', mopts)
            map('n', cfg.toggler.block, '<CMD>set operatorfunc=v:lua.___opfunc_gbc<CR>g@$', mopts)
            map('n', cfg.opleader.line, '<CMD>set operatorfunc=v:lua.___opfunc_gc<CR>g@', mopts)
            map('n', cfg.opleader.block, '<CMD>set operatorfunc=v:lua.___opfunc_gb<CR>g@', mopts)

            -- VISUAL mode mappings
            map('x', cfg.opleader.line, '<ESC><CMD>lua ___opfunc_gc(vim.fn.visualmode())<CR>', mopts)
            map('x', cfg.opleader.block, '<ESC><CMD>lua ___opfunc_gb(vim.fn.visualmode())<CR>', mopts)

            -- INSERT mode mappings
            -- map('i', '<C-_>', '<CMD>lua require("Comment").toggle()<CR>', opts)
        end

        if cfg.mappings.extra then
            -- OperatorFunc extra
            function _G.___opfunc_ggt(vmode)
                opfunc(vmode, U.cmode.comment, U.ctype.line, U.cmotion._)
            end
            function _G.___opfunc_ggtc(vmode)
                opfunc(vmode, U.cmode.comment, U.ctype.line, U.cmotion.line)
            end
            function _G.___opfunc_ggtb(vmode)
                opfunc(vmode, U.cmode.comment, U.ctype.block, U.cmotion.line)
            end

            function _G.___opfunc_glt(mode)
                opfunc(mode, U.cmode.uncomment, U.ctype.line, U.cmotion._)
            end
            function _G.___opfunc_gltc(mode)
                opfunc(mode, U.cmode.uncomment, U.ctype.line, U.cmotion.line)
            end
            function _G.___opfunc_gltb(vmode)
                opfunc(vmode, U.cmode.uncomment, U.ctype.block, U.cmotion.line)
            end

            -- NORMAL mode extra
            map('n', 'g>', '<CMD>set operatorfunc=v:lua.___opfunc_ggt<CR>g@', mopts)
            map('n', 'g>c', '<CMD>set operatorfunc=v:lua.___opfunc_ggtc<CR>g@$', mopts)
            map('n', 'g>b', '<CMD>set operatorfunc=v:lua.___opfunc_ggtb<CR>g@$', mopts)

            map('n', 'g<', '<CMD>set operatorfunc=v:lua.___opfunc_glt<CR>g@', mopts)
            map('n', 'g<c', '<CMD>set operatorfunc=v:lua.___opfunc_gltc<CR>g@$', mopts)
            map('n', 'g<b', '<CMD>set operatorfunc=v:lua.___opfunc_gltb<CR>g@$', mopts)

            -- VISUAL mode extra
            map('x', 'g>', '<ESC><CMD>lua ___opfunc_ggt(vim.fn.visualmode())<CR>', mopts)
            map('x', 'g<', '<ESC><CMD>lua ___opfunc_glt(vim.fn.visualmode())<CR>', mopts)
        end
    end
end

return C
