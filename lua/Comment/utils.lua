local A = vim.api
local mark = A.nvim_buf_get_mark

local U = {}

---Replace some char in the give string
---@param pos number
---@param str string
---@param r string
---@return string
function U.replace(pos, str, r)
    return str:sub(0, pos) .. r .. str:sub(pos + 1)
end

---Print a msg on stderr
---@param msg string
function U.errprint(msg)
    vim.notify('Comment.nvim: ' .. msg, vim.log.levels.ERROR)
end

---Trim leading/trailing whitespace from the given string
---@param str string
---@return string
function U.trim(str)
    return str:gsub('%s+', '')
end

---Get lines from a NORMAL/VISUAL mode
---@param mode string
---@return number
---@return number
---@return table
function U.get_lines(mode)
    local s_ln, e_ln

    local buf = 0
    if mode:match('[vV]') then
        s_ln = mark(buf, '<')[1]
        e_ln = mark(buf, '>')[1]
    else
        s_ln = mark(buf, '[')[1]
        e_ln = mark(buf, ']')[1]
    end

    -- decrementing `s_ln` by one bcz marks are 1 based but lines are 0 based
    -- and `e_ln` is the last line index (exclusive)
    s_ln = s_ln - 1

    -- If starting and ending is same, then just return the line
    -- Also for some reason get_lines doesn't return empty line, if called on single empty line
    -- if s_ln == e_ln then
    --     return s_ln, e_ln, { A.nvim_get_current_line() }
    -- end

    return s_ln, e_ln, A.nvim_buf_get_lines(0, s_ln, e_ln, false)
end

---Separate the given line into two parts ie. indentation, chars
---@param ln string|table
---@return string|nil
---@return string|nil
function U.split_half(ln)
    return ln:match('(%s*)(.*)')
end

---Converts the given line into a commented line
---@param str string
---@param r_cs string
---@param l_cs string
---@param is_pad boolean
---@param spacing string|nil
---@return string
function U.comment_str(str, r_cs, l_cs, is_pad, spacing)
    local indent, ln = U.split_half(str)

    -- if line is empty then use the space argument
    -- this is required if you are to comment multiple lines
    -- and the starting line has indentation
    local is_empty = #indent == 0 and #ln == 0
    local idnt = is_empty and (spacing or '') or indent

    if is_pad then
        -- If the rhs of cstring exists and the line is not empty then only add padding
        -- Bcz if we were to comment multiple lines and there are some empty lines in b/w
        -- then adding space to the them is not expected
        local new_r_cs = (#r_cs > 0 and not is_empty) and r_cs .. ' ' or r_cs

        local new_l_cs = #l_cs > 0 and ' ' .. l_cs or l_cs

        -- (spacing or indent) this is bcz of single `comment` and `uncomment`
        -- In these case, current line might be indented and we don't have spacing
        -- So we can use the original indentation of the line
        return U.replace(#(spacing or indent), idnt, new_r_cs) .. ln .. new_l_cs
    end

    return U.replace(#(spacing or indent), idnt, r_cs) .. ln .. l_cs
end

---Converts the given commented line into uncommented line
---@param str string
---@param r_cs_esc string
---@param l_cs_esc string
---@param is_pad boolean
---@return string
function U.uncomment_str(str, r_cs_esc, l_cs_esc, is_pad)
    local indent, _, ln = str:match('(%s*)(' .. r_cs_esc .. '%s?)(.*)(' .. l_cs_esc .. ')')

    -- FIXME: better check for is_commented
    if not ln then
        return str
    end

    -- If the line (after cstring) is empty then just return ''
    -- bcz when uncommenting multiline this also doesn't preserve leading whitespace as the line was previously empty
    if #ln == 0 then
        return ''
    end

    -- When padding is enabled then trim one trailing space char
    return indent .. (is_pad and ln:gsub('%s?$', '') or ln)
end

---Check if {pre,post}_hook is present then call it
---@param hook function|nil
---@return boolean|nil|string
function U.is_hook(hook, ...)
    return type(hook) == 'function' and hook(...)
end

---Check whether the given line is commented or not
---@param line string
---@param r_cs_esc string
---@return number|nil
function U.is_commented(line, r_cs_esc)
    return line:find('^%s*' .. r_cs_esc)
end

return U
