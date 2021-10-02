-- TODO
-- [-] Handle Tabs
-- [x] Dot repeat
-- [x] Comment multiple line.
-- [x] Hook support
--      [x] pre
--      [x] post
-- [ ] Block comment ie. /* */ (for js)
-- [ ] Doc comments ie. /** */ (for js)
-- [ ] Treesitter context commentstring
-- [ ] Support `unknown` language's commentstring

-- FIXME
-- [x] visual mode not working correctly
-- [x] space after and before of commentstring
-- [x] multiple line behavior to tcomment
--      [x] preserve indent
--      [x] determine comment status (to comment or not)
-- [x] prevent uncomment on uncommented line
-- [ ] `comment` and `toggle` misbehaving when there is leading space
-- [ ] `gcc` empty line not toggling comment

-- THINK:
-- should i return the operator's starting and ending position in pre_hook
-- fix cursor position in motion operator (try `gcip`)

local U = require('Comment.utils')

local A = vim.api

local C = {
    config = nil,
}

function _G.__comment_operator(mode)
    -- `mode` can be
    -- line: use single line comment
    -- char: use block comment

    local cstr = U.is_hook(C.config.pre_hook)
    local r_cs, l_cs = C.unwrap_cstring(cstr)
    local s_pos, e_pos, lines = U.get_lines(mode)
    local r_cs_esc = vim.pesc(r_cs)
    local repls = {}

    -- While commenting a block of text, there is a possiblity of lines being both commented and non-commented
    -- In that case, we need to figure out that if any line is uncommented then we should comment the whole block or vise-versa
    local is_commented = true
    for _, line in ipairs(lines) do
        local is_cmt = U.is_commented(line, r_cs_esc)
        if not is_cmt then
            is_commented = false
            break
        end
    end

    -- When commenting multiple line, it is to be expected that indentation should be preserved
    -- So, When looping over multiple lines we need to store the indentation of the first lines
    -- Which will be used to semantically comment rest of the lines
    local indent = nil
    for _, line in ipairs(lines) do
        if is_commented then
            table.insert(repls, U.uncomment_str(line, r_cs_esc, vim.pesc(l_cs), C.config.padding))
        else
            -- preserve indentation of the first line
            if not indent then
                local pad = line:match('(%s*)')
                indent = pad
            end
            table.insert(repls, U.comment_str(line, r_cs, l_cs, C.config.padding, indent))
        end
    end

    A.nvim_buf_set_lines(0, s_pos, e_pos, false, repls)
    U.is_hook(C.config.post_hook, s_pos, e_pos)
end

function C.setup(cfg)
    C.config = vim.tbl_extend('keep', cfg or {}, {
        -- Add a space b/w comment and the line
        padding = true,
        -- Whether to create operator pending mappings
        mappings = true,
        -- LHS of toggle mapping in NORMAL mode
        toggler = 'gcc',
        -- LHS of operator-mode mapping in NORMAL/VISUAL mode
        opleader = 'gc',
        -- Pre-hook, called before commenting the line
        pre_hook = nil,
        -- Post-hook, called after commenting is done
        post_hook = nil,
    })

    if C.config.mappings then
        local map = A.nvim_set_keymap
        local opts = { noremap = true, silent = true }

        map('n', C.config.toggler, '<CMD>set operatorfunc=v:lua.__comment_operator<CR>g@l', opts)
        map('n', C.config.opleader, '<CMD>set operatorfunc=v:lua.__comment_operator<CR>g@', opts)
        map('v', C.config.opleader, '<ESC><CMD>lua __comment_operator(vim.fn.visualmode())<CR>', opts)
    end
end

function C.unwrap_cstring(c_str)
    local cs = c_str or vim.bo.commentstring
    if not cs or #cs == 0 then
        return U.errprint("'commentstring' not found")
    end

    local rhs, lhs = cs:match('(.*)%%s(.*)')
    if not rhs then
        return U.errprint("Invalid 'commentstring': " .. cs)
    end

    return U.strip_space(rhs), U.strip_space(lhs)
end

function C.comment_ln(l, r_cs, l_cs)
    A.nvim_set_current_line(U.comment_str(l, r_cs, l_cs, C.config.padding))
end

function C.uncomment_ln(l, r_cs_esc, l_cs_esc)
    A.nvim_set_current_line(U.uncomment_str(l, r_cs_esc, l_cs_esc, C.config.padding))
end

function C.toggle_ln()
    local cstr = U.is_hook(C.config.pre_hook)

    local r_cs, l_cs = C.unwrap_cstring(cstr)
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

return C
