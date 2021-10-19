local A = vim.api

local U = {}

---Check if the start of string is commented
---@param str string String to be checked
---@param lcs_esc string Escaped LHS of commentring
---@return number number Start index of the match (Mostly will be 1)
---@return number number End index of the match
function U.is_start_commented(str, lcs_esc)
    return str:find('^%s*' .. lcs_esc)
end

---Check if the end of string is commented
---@param str string String to be checked
---@param rcs_esc string Escaped LHS of commentring
---@return number number Start index of the match
---@return number number End index of the match
function U.is_end_commented(str, rcs_esc)
    return str:find(rcs_esc .. '$')
end

---Removes the comment chars from the string
---@param row number Row/Line number
---@param start_idx number Start index of column
---@param end_idx number End index of column
function U.rm_comment(row, start_idx, end_idx)
    A.nvim_buf_set_text(0, row, start_idx, row, end_idx, {})
end

---Adds the comment chars from the string
---@param row number Row/Line number
---@param start_idx number Start index of column
---@param end_idx number End index of column
---@param chars string LHS/RHS of commentring
function U.add_comment(row, start_idx, end_idx, chars)
    A.nvim_buf_set_text(0, row, start_idx, row, end_idx, { chars })
end

return U
