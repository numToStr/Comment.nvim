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
---@return string string Right side of the commentstring
---@return string string Left side of the commentstring
function C.unwrap_cstr(ctype)
    local cstr = U.is_hook(C.config.pre_hook)
        or require('Comment.lang').get(bo.filetype, ctype or U.ctype.line)
        or bo.commentstring

    if not cstr or #cstr == 0 then
        return U.errprint("'commentstring' not found")
    end

    local rhs, lhs = cstr:match('(.*)%%s(.*)')
    if not rhs then
        return U.errprint("Invalid 'commentstring': " .. cstr)
    end

    return U.trim(rhs), U.trim(lhs)
end

---Common fn to comment and set the current line
---@param ln string Line that needs to be commented
---@param rcs string Right side of the commentstring
---@param lcs string Left side of the commentstring
function C.comment_ln(ln, rcs, lcs)
    A.nvim_set_current_line(U.comment_str(ln, rcs, lcs, C.config.padding))
end

---Common fn to uncomment and set the current line
---@param ln string Line that needs to be uncommented
---@param rcs_esc string (Escaped) Right side of the commentstring
---@param lcs_esc string (Escaped) Left side of the commentstring
function C.uncomment_ln(ln, rcs_esc, lcs_esc)
    A.nvim_set_current_line(U.uncomment_str(ln, rcs_esc, lcs_esc, C.config.padding))
end

---Comments the current line
function C.comment()
    local line = A.nvim_get_current_line()

    if not U.ignore(line, C.config.ignore) then
        local rcs, lcs = C.unwrap_cstr()
        C.comment_ln(line, rcs, lcs)
    end

    U.is_hook(C.config.post_hook, -1)
end

---Uncomments the current line
function C.uncomment()
    local line = A.nvim_get_current_line()

    if not U.ignore(line, C.config.ignore) then
        local rcs, lcs = C.unwrap_cstr()
        C.uncomment_ln(line, vim.pesc(rcs), vim.pesc(lcs))
    end

    U.is_hook(C.config.post_hook, -1)
end

---Toggle comment of the current line
function C.toggle()
    local line = A.nvim_get_current_line()

    if not U.ignore(line, C.config.ignore) then
        local rcs, lcs = C.unwrap_cstr()
        local rcs_esc = vim.pesc(rcs)
        local is_commented = U.is_commented(line, rcs_esc)

        if is_commented then
            C.uncomment_ln(line, rcs_esc, vim.pesc(lcs))
        else
            C.comment_ln(line, rcs, lcs)
        end
    end

    U.is_hook(C.config.post_hook, -1)
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
        ---Common operatorfunc callback
        ---@param vmode string VIM mode - line|char
        ---@param cmode CMode Comment mode
        ---@param ctype CType Type of the commentstring (line/block)
        local function opfunc(vmode, cmode, ctype)
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

            local rcs, lcs = C.unwrap_cstr(ctype)
            local scol, ecol, lines = U.get_lines(vmode, ctype)
            local rcs_esc = vim.pesc(rcs)

            local len = #lines

            -- Block wise, only when there are more than 1 lines
            if ctype == U.ctype.block and len > 1 then
                local start_ln = lines[1]
                local end_ln = lines[len]
                local lcs_esc = vim.pesc(lcs)

                local _cmode

                -- If given mode is toggle then determine whether to comment or not
                if cmode == U.cmode.toggle then
                    local is_start_commented = U.is_commented(start_ln, rcs_esc)
                    local is_end_commented = end_ln:find(lcs_esc .. '$')
                    _cmode = (is_start_commented and is_end_commented) and U.cmode.uncomment or U.cmode.comment
                else
                    _cmode = cmode
                end

                local l1, l2
                if _cmode == U.cmode.uncomment then
                    l1 = U.uncomment_str(start_ln, rcs_esc, '', C.config.padding)
                    l2 = U.uncomment_str(end_ln, '', lcs_esc, C.config.padding)
                else
                    l1 = U.comment_str(start_ln, rcs, '', C.config.padding)
                    l2 = U.comment_str(end_ln, '', lcs, C.config.padding)
                end
                A.nvim_buf_set_lines(0, scol, scol + 1, false, { l1 })
                A.nvim_buf_set_lines(0, ecol - 1, ecol, false, { l2 })
            else
                -- While commenting a block of text, there is a possiblity of lines being both commented and non-commented
                -- In that case, we need to figure out that if any line is uncommented then we should comment the whole block or vise-versa
                local _cmode = U.cmode.uncomment

                -- When commenting multiple line, it is to be expected that indentation should be preserved
                -- So, When looping over multiple lines we need to store the indentation of the mininum length (except empty line)
                -- Which will be used to semantically comment rest of the lines
                local min_indent = nil

                -- If the given comde is uncomment then we actually don't want to compute the cmode or min_indent
                if cmode ~= U.cmode.uncomment then
                    for _, line in ipairs(lines) do
                        -- I wish lua had `continue` statement [sad noises]
                        if not U.ignore(line, cfg.ignore) then
                            if _cmode == U.cmode.uncomment and cmode == U.cmode.toggle then
                                local is_cmt = U.is_commented(line, rcs_esc)
                                if not is_cmt then
                                    _cmode = U.cmode.comment
                                end
                            end

                            -- If the internal cmode changes to comment or the given cmode is not uncomment, then only calculate min_indent
                            -- As calculating min_indent only makes sense when we actually want to comment the lines
                            if _cmode == U.cmode.comment or cmode == U.cmode.comment then
                                local indent, ln = U.split_half(line)
                                if not min_indent or (#min_indent > #indent) and #ln > 0 then
                                    min_indent = indent
                                end
                            end
                        end
                    end
                end

                -- If the comment mode given is not toggle than force that mode
                if cmode ~= U.cmode.toggle then
                    _cmode = cmode
                end

                local repls = {}
                local uncomment = _cmode == U.cmode.uncomment

                for _, line in ipairs(lines) do
                    if U.ignore(line, cfg.ignore) then
                        table.insert(repls, line)
                    else
                        if uncomment then
                            table.insert(repls, U.uncomment_str(line, rcs_esc, vim.pesc(lcs), C.config.padding))
                        else
                            table.insert(repls, U.comment_str(line, rcs, lcs, C.config.padding, min_indent or ''))
                        end
                    end
                end
                A.nvim_buf_set_lines(0, scol, ecol, false, repls)
            end

            U.is_hook(C.config.post_hook, scol, ecol)
        end

        local map = A.nvim_set_keymap
        local mopts = { noremap = true, silent = true }

        if cfg.mappings.basic then
            -- OperatorFunc main
            function _G.___opfunc_toggle_line(vmode)
                opfunc(vmode, U.cmode.toggle, U.ctype.line)
            end
            function _G.___opfunc_toggle_block(vmode)
                opfunc(vmode, U.cmode.toggle, U.ctype.block)
            end

            -- NORMAL mode mappings
            map('n', cfg.toggler.line, '<CMD>set operatorfunc=v:lua.___opfunc_toggle_line<CR>g@$', mopts)
            map('n', cfg.toggler.block, '<CMD>set operatorfunc=v:lua.___opfunc_toggle_block<CR>g@$', mopts)
            map('n', cfg.opleader.line, '<CMD>set operatorfunc=v:lua.___opfunc_toggle_line<CR>g@', mopts)
            map('n', cfg.opleader.block, '<CMD>set operatorfunc=v:lua.___opfunc_toggle_block<CR>g@', mopts)

            -- VISUAL mode mappings
            map('v', cfg.opleader.line, '<CMD>set operatorfunc=v:lua.___opfunc_toggle_line<CR>g@$', mopts)
            map('v', cfg.opleader.block, '<CMD>set operatorfunc=v:lua.___opfunc_toggle_block<CR>g@$', mopts)

            -- INSERT mode mappings
            -- map('i', '<C-_>', '<CMD>lua require("Comment").toggle()<CR>', opts)
        end

        if cfg.mappings.extra then
            -- OperatorFunc extra
            function _G.___opfunc_comment_line(vmode)
                opfunc(vmode, U.cmode.comment, U.ctype.line)
            end
            function _G.___opfunc_uncomment_line(mode)
                opfunc(mode, U.cmode.uncomment, U.ctype.line)
            end
            function _G.___opfunc_comment_block(vmode)
                opfunc(vmode, U.cmode.comment, U.ctype.block)
            end
            function _G.___opfunc_uncomment_block(vmode)
                opfunc(vmode, U.cmode.uncomment, U.ctype.block)
            end

            -- NORMAL mode extra
            map('n', 'g>', '<CMD>set operatorfunc=v:lua.___opfunc_comment_line<CR>g@', mopts)
            map('n', 'g>c', '<CMD>set operatorfunc=v:lua.___opfunc_comment_line<CR>g@$', mopts)
            map('n', 'g>b', '<CMD>set operatorfunc=v:lua.___opfunc_comment_block<CR>g@$', mopts)

            map('n', 'g<', '<CMD>set operatorfunc=v:lua.___opfunc_uncomment_line<CR>g@', mopts)
            map('n', 'g<c', '<CMD>set operatorfunc=v:lua.___opfunc_uncomment_line<CR>g@$', mopts)
            map('n', 'g<b', '<CMD>set operatorfunc=v:lua.___opfunc_uncomment_block<CR>g@$', mopts)

            -- VISUAL mode extra
            map('v', 'g>', '<CMD>set operatorfunc=v:lua.___opfunc_comment_line<CR>g@$', mopts)
            map('v', 'g<', '<CMD>set operatorfunc=v:lua.___opfunc_uncomment_line<CR>g@$', mopts)
        end
    end
end

return C
