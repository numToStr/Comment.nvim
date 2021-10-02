-- TODO
-- [-] Handle Tabs
-- [x] Dot repeat
-- [x] Comment multiple line.
-- [ ] Hook support
-- [ ] Doc comments ie. /** */ (for js)
-- [ ] Block comment ie. /* */ (for js)
-- [ ] Treesitter context commentstring

-- FIXME
-- [x] visual mode not working correctly
-- [ ] space after and before of commentstring
-- [ ] multiple line behavior to tcomment

local U = require('Comment.utils')

local api = vim.api

local C = {}

function _G.__comment_operator(mode)
    --`mode` can be
    --line: use single line comment
    --char: use blockwise comment
    local s_pos, e_pos, lines = U.get_lines(mode)
    local r_cs, l_cs = C.unwrap_cstring()
    local r_cs_esc = vim.pesc(r_cs)
    local repls = {}
    for _, line in ipairs(lines) do
        local is_commented = line:find('^%s*' .. r_cs_esc)
        if is_commented then
            table.insert(repls, U.uncomment_str(line, r_cs_esc, vim.pesc(l_cs)))
        else
            table.insert(repls, U.comment_str(line, r_cs, l_cs))
        end
    end
    api.nvim_buf_set_lines(0, s_pos, e_pos, false, repls)
end

function C.setup()
    local map = api.nvim_set_keymap
    local opts = { noremap = true, silent = true }

    map('n', 'gcc', '<CMD>set operatorfunc=v:lua.__comment_operator<CR>g@l', opts)
    map('n', 'gc', '<CMD>set operatorfunc=v:lua.__comment_operator<CR>g@', opts)
    map('v', 'gc', '<ESC><CMD>lua __comment_operator(vim.fn.visualmode())<CR>', opts)
end

function C.unwrap_cstring()
    -- local cs = '<!-- %s -->'
    local cs = vim.bo.commentstring
    if not cs then
        return U.errprint("'commentstring' not found")
    end

    local rhs, lhs = cs:match('(.*)%%s(.*)')
    if not rhs then
        return U.errprint("Invalid 'commentstring': " .. cs)
    end

    -- return rhs, lhs
    return U.strip_space(rhs), U.strip_space(lhs)
end

function C.comment_ln(l, r_cs, l_cs)
    api.nvim_set_current_line(U.comment_str(l, r_cs, l_cs))
end

function C.uncomment_ln(l, r_cs_esc, l_cs_esc)
    api.nvim_set_current_line(U.uncomment_str(l, r_cs_esc, l_cs_esc))
end

function C.toggle_ln()
    local r_cs, l_cs = C.unwrap_cstring()
    local line = api.nvim_get_current_line()

    local r_cs_esc = vim.pesc(r_cs)
    local is_commented = line:find('^%s*' .. r_cs_esc)

    if is_commented then
        C.uncomment_ln(line, r_cs_esc, vim.pesc(l_cs))
    else
        C.comment_ln(line, r_cs, l_cs)
    end
end

return C
