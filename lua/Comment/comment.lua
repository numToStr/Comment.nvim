local U = require('Comment.utils')

local A = vim.api
local bo = vim.bo

local C = {
    ---@type config|nil
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
    local cstr = U.is_hook(C.config.pre_hook) or require('Comment.lang').get(bo.filetype, ty) or bo.commentstring

    if not cstr or #cstr == 0 then
        return U.errprint("'commentstring' not found")
    end

    local rhs, lhs = cstr:match('(.*)%%s(.*)')
    if not rhs then
        return U.errprint("Invalid 'commentstring': " .. cstr)
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
---@param cfg config|nil
function C.setup(cfg)
    ---@class config
    C.config = {
        ---Add a space b/w comment and the line
        ---@type boolean
        padding = true,
        ---Whether to create operator pending mappings
        ---@type boolean
        mappings = true,
        ---LHS of toggle mapping in NORMAL mode
        ---@type string
        toggler = 'gcc',
        ---LHS of operator-mode mapping in NORMAL/VISUAL mode
        ---@type string
        opleader = 'gc',
        -- Pre-hook, called before commenting the line
        ---@type function|nil
        pre_hook = nil,
        ---Post-hook, called after commenting is done
        ---@type function|nil
        post_hook = nil,
    }

    if cfg ~= nil then
        C.config = vim.tbl_extend('keep', cfg, C.config)
    end

    if C.config.mappings then
        ---@class opfunc_opts
        ---@field comment boolean Force comment/uncomment
        ---@field cstr_type integer Type (line/block) of the commentstring

        ---Common operatorfunc callback
        ---@param mode string
        ---@param opts opfunc_opts
        local function opfunc(mode, opts)
            -- `mode` can be
            -- line: use line comment
            -- char: use block comment

            local rcs, lcs = C.unwrap_cstr(opts.cstr_type)
            local s_pos, e_pos, lines = U.get_lines(mode)
            local rcs_esc = vim.pesc(rcs)
            local repls = {}

            -- While commenting a block of text, there is a possiblity of lines being both commented and non-commented
            -- In that case, we need to figure out that if any line is uncommented then we should comment the whole block or vise-versa
            local is_commented = true

            -- When commenting multiple line, it is to be expected that indentation should be preserved
            -- So, When looping over multiple lines we need to store the indentation of the mininum length (except empty line)
            -- Which will be used to semantically comment rest of the lines
            local min_indent = nil

            for _, line in ipairs(lines) do
                if opts.comment == nil then
                    local is_cmt = U.is_commented(line, rcs_esc)
                    if is_commented and not is_cmt then
                        is_commented = false
                    end
                end

                local spc, ln = U.split_half(line)
                if not min_indent or (#min_indent > #spc) and #ln > 0 then
                    min_indent = spc
                end
            end

            if opts.comment ~= nil then
                is_commented = opts.comment
            end

            for _, line in ipairs(lines) do
                if is_commented then
                    table.insert(repls, U.uncomment_str(line, rcs_esc, vim.pesc(lcs), C.config.padding))
                else
                    table.insert(repls, U.comment_str(line, rcs, lcs, C.config.padding, min_indent or ''))
                end
            end

            A.nvim_buf_set_lines(0, s_pos, e_pos, false, repls)
            U.is_hook(C.config.post_hook, s_pos, e_pos)
        end

        function _G.___comment_opfunc_line(mode)
            opfunc(mode, { cstr_type = 1 })
        end

        function _G.___comment_opfunc_block(mode)
            opfunc(mode, { cstr_type = 2 })
        end

        local map = A.nvim_set_keymap
        local opts = { noremap = true, silent = true }

        -- NORMAL mode mappings
        map('n', C.config.toggler, '<CMD>set operatorfunc=v:lua.___comment_opfunc_line<CR>g@$', opts)
        map('n', C.config.opleader, '<CMD>set operatorfunc=v:lua.___comment_opfunc_line<CR>g@', opts)
        map('n', 'gcb', '<CMD>set operatorfunc=v:lua.___comment_opfunc_block<CR>g@$', opts)

        -- VISUAL mode mappings
        map('v', C.config.opleader, '<ESC><CMD>lua ___comment_opfunc_line(vim.fn.visualmode())<CR>', opts)
        map('v', 'gb', '<CMD>set operatorfunc=v:lua.___comment_opfunc_block<CR>g@$', opts)

        -- INSERT mode mappings
        -- map('i', '<C-_>', '<CMD>lua require("Comment").toggle()<CR>', opts)

        -- OperatorFunc extra
        function _G.___comment_opfunc_comment(mode)
            opfunc(mode, { comment = false })
        end

        function _G.___comment_opfunc_uncomment(mode)
            opfunc(mode, { comment = true })
        end

        -- NORMAL mode extra
        map('n', 'g>', '<CMD>set operatorfunc=v:lua.___comment_opfunc_comment<CR>g@', opts)
        map('n', 'g>c', '<CMD>set operatorfunc=v:lua.___comment_opfunc_comment<CR>g@$', opts)
        map('n', 'g<', '<CMD>set operatorfunc=v:lua.___comment_opfunc_uncomment<CR>g@', opts)
        map('n', 'g<c', '<CMD>set operatorfunc=v:lua.___comment_opfunc_uncomment<CR>g@$', opts)

        -- VISUAL mode extra
        map('v', 'g>', '<ESC><CMD>lua ___comment_opfunc_comment(vim.fn.visualmode())<CR>', opts)
        map('v', 'g<', '<ESC><CMD>lua ___comment_opfunc_uncomment(vim.fn.visualmode())<CR>', opts)
    end
end

return C
