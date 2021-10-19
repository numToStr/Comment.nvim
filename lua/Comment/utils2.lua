local A = vim.api

local U = {}

function U.is_start_commented(s, lcs_esc)
    return s:find('^%s*(' .. lcs_esc .. ')')
end

function U.is_end_commented(s, rcs_esc)
    return s:find('(' .. rcs_esc .. ')$')
end

function U.rm_comment(row, start_col, end_col)
    A.nvim_buf_set_text(0, row, start_col, row, end_col, {})
end

function U.add_comment(row, start_col, end_col, cstr)
    A.nvim_buf_set_text(0, row, start_col, row, end_col, { cstr })
end

return U
