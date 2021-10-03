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
---@param ty string Type of commentstring ie. line | block
---@return string Right side of the commentstring
---@return string Left side of the commentstring
function C.unwrap_cstr(ty)
    local cmstr = U.is_hook(C.config.pre_hook)
        or require('Comment.lang').get(bo.filetype, ty or U.ctype.line)
        or bo.commentstring

    if not cmstr or #cmstr == 0 then
        return U.errprint("'commentstring' not found")
    end

    local rhs, lhs = cmstr:match('(.*)%%s(.*)')
    if not rhs then
        return U.errprint("Invalid 'commentstring': " .. cmstr)
    end

    return U.trim(rhs), U.trim(lhs)
end

---Comments a single line
---@param ln string Line that needs to be commented
---@param rcs string Right side of the commentstring
---@param lcs string Left side of the commentstring
function C.comment_ln(ln, rcs, lcs)
    A.nvim_set_current_line(U.comment_str(ln, rcs, lcs, C.config.padding))
end

---Uncomments a single line
---@param ln string Line that needs to be uncommented
---@param rcs_esc string (Escaped) Right side of the commentstring
---@param lcs_esc string (Escaped) Left side of the commentstring
function C.uncomment_ln(ln, rcs_esc, lcs_esc)
    A.nvim_set_current_line(U.uncomment_str(ln, rcs_esc, lcs_esc, C.config.padding))
end

---Toggle comment of the current line
function C.toggle_ln()
    local r_cs, l_cs = C.unwrap_cstr()
    local line = A.nvim_get_current_line()

    local r_cs_esc = vim.pesc(r_cs)
    local is_commented = U.is_commented(line, r_cs_esc)

    if is_commented then
        C.uncomment_ln(line, r_cs_esc, vim.pesc(l_cs))
    else
        C.comment_ln(line, r_cs, l_cs)
    end

    U.is_hook(C.config.post_hook, -1)
end

---Configures the whole plugin
---@param opts Config|nil
function C.setup(opts)
    ---@class Config
    C.config = {
        ---Add a space b/w comment and the line
        ---@type boolean
        padding = true,
        ---Whether to create basic (operator-pending) and extra mappings
        ---@type table
        mappings = {
            ---operator-pending mapping
            basic = true,
            ---extended mapping
            extra = true,
        },
        ---LHS of toggle mapping in NORMAL mode for line and block comment
        ---@type table
        toggler = {
            ---LHS of line comment toggle
            line = 'gcc',
            ---LHS of block comment toggle
            block = 'gcb',
        },
        ---LHS of operator-mode mapping in NORMAL/VISUAL mode for line and block comment
        ---@type table
        opleader = {
            ---LHS of line comment opfunc mapping
            line = 'gc',
            ---LHS of block comment opfunc mapping
            block = 'gb',
        },
        -- Pre-hook, called before commenting the line
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
        function _G.__c_opfunc(vmode, cmode, ctype)
            -- comment/uncomment logic
            --
            -- 1. type == line
            --      * decide whether to comment or not
            --      * store the minimum indent from all the lines (exclude empty line)
            -- 2. type == block
            --      * check if the first and last is commented or not with cstr LHS and RHS respectively.
            --      * add cstr LHS after the leading whitespace and before the first char of the first line
            --      * add cstr RHS to end of the last line
            --
            -- # common action
            --      * comment/uncomment the lines
            --      * update the lines

            local rcs, lcs = C.unwrap_cstr(ctype)
            local s_pos, e_pos, lines = U.get_lines(vmode, ctype)
            local rcs_esc = vim.pesc(rcs)

            local len = #lines

            -- Block wise, this only be applicable when there are more than 1 lines
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
                A.nvim_buf_set_lines(0, s_pos, s_pos + 1, false, { l1 })
                A.nvim_buf_set_lines(0, e_pos - 1, e_pos, false, { l2 })
            else
                -- While commenting a block of text, there is a possiblity of lines being both commented and non-commented
                -- In that case, we need to figure out that if any line is uncommented then we should comment the whole block or vise-versa
                local _cmode = U.cmode.uncomment

                -- When commenting multiple line, it is to be expected that indentation should be preserved
                -- So, When looping over multiple lines we need to store the indentation of the mininum length (except empty line)
                -- Which will be used to semantically comment rest of the lines
                local min_indent = nil

                for _, line in ipairs(lines) do
                    if _cmode == U.cmode.uncomment and cmode == U.cmode.toggle then
                        local is_cmt = U.is_commented(line, rcs_esc)
                        if not is_cmt then
                            _cmode = U.cmode.comment
                        end
                    end

                    local spc, ln = U.split_half(line)
                    if not min_indent or (#min_indent > #spc) and #ln > 0 then
                        min_indent = spc
                    end
                end

                -- If the comment mode given is not toggle than force that mode
                if cmode ~= U.cmode.toggle then
                    _cmode = cmode
                end

                local repls = {}
                for _, line in ipairs(lines) do
                    if _cmode == U.cmode.uncomment then
                        table.insert(repls, U.uncomment_str(line, rcs_esc, vim.pesc(lcs), C.config.padding))
                    else
                        table.insert(repls, U.comment_str(line, rcs, lcs, C.config.padding, min_indent or ''))
                    end
                end
                A.nvim_buf_set_lines(0, s_pos, e_pos, false, repls)
            end

            U.is_hook(C.config.post_hook, s_pos, e_pos)
        end

        local map = A.nvim_set_keymap
        local mopts = { noremap = true, silent = true }

        if cfg.mappings.basic then
            -- OperatorFunc main
            function _G.___opfunc_toggle_line(vmode)
                __c_opfunc(vmode, U.cmode.toggle, U.ctype.line)
            end
            function _G.___opfunc_toggle_block(vmode)
                __c_opfunc(vmode, U.cmode.toggle, U.ctype.block)
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
                __c_opfunc(vmode, U.cmode.comment, U.ctype.line)
            end
            function _G.___opfunc_uncomment_line(mode)
                __c_opfunc(mode, U.cmode.uncomment, U.ctype.line)
            end
            function _G.___opfunc_comment_block(vmode)
                __c_opfunc(vmode, U.cmode.comment, U.ctype.block)
            end
            function _G.___opfunc_uncomment_block(vmode)
                __c_opfunc(vmode, U.cmode.uncomment, U.ctype.block)
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
