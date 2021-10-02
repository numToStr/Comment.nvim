-- TODO
-- [-] Handle Tabs
-- [x] Dot repeat
-- [x] Comment multiple line.
-- [x] Hook support
--      [x] pre
--      [x] post
-- [x] Custom (language) commentstring support
-- [ ] Block comment ie. /* */ (for js)
-- [ ] Doc comment ie. /** */ (for js)
-- [ ] Treesitter context commentstring

-- FIXME
-- [x] visual mode not working correctly
-- [x] space after and before of commentstring
-- [x] multiple line behavior to tcomment
--      [x] preserve indent
--      [x] determine comment status (to comment or not)
-- [x] prevent uncomment on uncommented line
-- [x] `comment` and `toggle` misbehaving when there is leading space
-- [x] messed up indentation, if the first line has greater indentation than next line (calc min indendation)
-- [ ] `gcc` empty line not toggling comment

-- THINK:
-- 1. Should i return the operator's starting and ending position in pre-hook
-- 2. Fix cursor position in motion operator (try `gcip`)
-- 3. It is possible that, commentstring is updated inside pre-hook as we want to use it but we can't
--    bcz the filetype is also present in the lang-table (and it has high priority than bo.commentstring)

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
---@return string
---@return string
function C.unwrap_cstr()
    local cstr = U.is_hook(C.config.pre_hook) or require('Comment.lang').get(bo.filetype) or bo.commentstring

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
---@param ln string
---@param r_cs string
---@param l_cs string
function C.comment_ln(ln, r_cs, l_cs)
    A.nvim_set_current_line(U.comment_str(ln, r_cs, l_cs, C.config.padding))
end

---Uncomments a single line
---@param ln string
---@param r_cs_esc string
---@param l_cs_esc string
function C.uncomment_ln(ln, r_cs_esc, l_cs_esc)
    A.nvim_set_current_line(U.uncomment_str(ln, r_cs_esc, l_cs_esc, C.config.padding))
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
        function _G.__comment_operator(mode)
            -- `mode` can be
            -- line: use single line comment
            -- char: use block comment

            local r_cs, l_cs = C.unwrap_cstr()
            local s_pos, e_pos, lines = U.get_lines(mode)
            local r_cs_esc = vim.pesc(r_cs)
            local repls = {}

            -- While commenting a block of text, there is a possiblity of lines being both commented and non-commented
            -- In that case, we need to figure out that if any line is uncommented then we should comment the whole block or vise-versa
            local is_commented = true

            -- When commenting multiple line, it is to be expected that indentation should be preserved
            -- So, When looping over multiple lines we need to store the indentation of the mininum length (except empty line)
            -- Which will be used to semantically comment rest of the lines
            local min_indent = nil

            for _, line in ipairs(lines) do
                local is_cmt = U.is_commented(line, r_cs_esc)
                if is_commented and not is_cmt then
                    is_commented = false
                end
                local spc, ln = U.split_half(line)
                if not min_indent or (#min_indent > #spc) and #ln > 0 then
                    min_indent = spc
                end
            end

            for _, line in ipairs(lines) do
                if is_commented then
                    table.insert(repls, U.uncomment_str(line, r_cs_esc, vim.pesc(l_cs), C.config.padding))
                else
                    table.insert(repls, U.comment_str(line, r_cs, l_cs, C.config.padding, min_indent or ''))
                end
            end

            A.nvim_buf_set_lines(0, s_pos, e_pos, false, repls)
            U.is_hook(C.config.post_hook, s_pos, e_pos)
        end

        local map = A.nvim_set_keymap
        local opts = { noremap = true, silent = true }

        map('n', C.config.toggler, '<CMD>set operatorfunc=v:lua.__comment_operator<CR>g@l', opts)
        map('n', C.config.opleader, '<CMD>set operatorfunc=v:lua.__comment_operator<CR>g@', opts)
        map('v', C.config.opleader, '<ESC><CMD>lua __comment_operator(vim.fn.visualmode())<CR>', opts)
    end
end

return C
