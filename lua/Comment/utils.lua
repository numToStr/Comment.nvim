local A = vim.api

local U = {}

---Range of the selection that needs to be commented
---@class CRange
---@field srow number Starting row
---@field scol number Starting column
---@field erow number Ending row
---@field ecol number Ending column

---@alias CLines string[] List of lines inside the start and end index

---Comment modes
---@class CMode
U.cmode = {
    toggle = 0,
    comment = 1,
    uncomment = 2,
}

---Comment types
---@class CType
U.ctype = {
    line = 1,
    block = 2,
}

---Motion types
---@class CMotion
U.cmotion = {
    ---Compute from vmode
    _ = 0,
    ---line
    line = 1,
    ---char/left-right
    char = 2,
    ---visual operator-pending
    block = 3,
    ---visual
    v = 4,
    ---visual-line
    V = 5,
}

---Print a msg on stderr
---@param msg string
function U.eprint(msg)
    vim.notify('Comment :: ' .. msg, vim.log.levels.ERROR)
end

---Check whether the line is empty
---@param ln string
---@return boolean
function U.is_empty(ln)
    return #ln == 0
end

---Takes out the leading indent from lines
---@param s string
---@return string string Indent chars
---@return number string Length of the indent chars
function U.grab_indent(s)
    local _, len, indent = s:find('^(%s*)')
    return indent, len
end

---Helper to get padding (I was tired to check this everywhere)
---NOTE: We can also use function to calculate padding if someone wants more spacing
---@param flag boolean
---@return string string Padding chars
---@return string string Padding pattern
function U.get_padding(flag)
    if not flag then
        return '', ''
    end
    return ' ', '%s?'
end

-- FIXME This prints `a` in i_CTRL-o
---Moves the cursor and enters INSERT mode
---@param row number Starting row
---@param col number Ending column
function U.move_n_insert(row, col)
    A.nvim_win_set_cursor(0, { row, col })
    A.nvim_feedkeys('a', 'n', true)
end

---Convert the string to a escaped string, if given
---@param str string
---@return string|boolean
function U.escape(str)
    return str and vim.pesc(str)
end

---Call a function if exists
---@param fn function Hook function
---@return boolean|string
function U.is_fn(fn, ...)
    return type(fn) == 'function' and fn(...)
end

---Helper to compute the ignore pattern
---@param ig string|function
---@return boolean|string
function U.get_pattern(ig)
    return ig and (type(ig) == 'string' and ig or U.is_fn(ig))
end

---Check if the given line is ignored or not with the given pattern
---@param ln string Line to be ignored
---@param pat string Lua regex
---@return boolean
function U.ignore(ln, pat)
    return pat and ln:find(pat) ~= nil
end

---Get region for vim mode
---@param vmode string VIM mode
---@return CRange
function U.get_region(vmode)
    local m = A.nvim_buf_get_mark
    local buf = 0
    local sln, eln

    if vmode:match('[vV]') then
        sln = m(buf, '<')
        eln = m(buf, '>')
    else
        sln = m(buf, '[')
        eln = m(buf, ']')
    end

    return {
        srow = sln[1],
        scol = sln[2],
        erow = eln[1],
        ecol = eln[2],
    }
end

---Get lines from the current position to the given count
---@param count number
---@return CLines
---@return CRange
function U.get_count_lines(count)
    local pos = A.nvim_win_get_cursor(0)
    local srow = pos[1]
    local erow = (srow + count) - 1
    local lines = A.nvim_buf_get_lines(0, srow - 1, erow, false)

    return lines, {
        srow = srow,
        scol = 0,
        erow = erow,
        ecol = 0,
    }
end

---Get lines from a NORMAL/VISUAL mode
---@param vmode string VIM mode
---@param ctype CType
---@return CLines
---@return CRange
function U.get_lines(vmode, ctype)
    local range = U.get_region(vmode)

    -- If start and end is same, then just return the current line
    local lines
    if range.srow == range.erow then
        lines = { A.nvim_get_current_line() }
    elseif ctype == U.ctype.block then
        -- In block we only need the starting and endling line
        lines = {
            A.nvim_buf_get_lines(0, range.srow - 1, range.srow, false)[1],
            A.nvim_buf_get_lines(0, range.erow - 1, range.erow, false)[1],
        }
    else
        -- decrementing `scol` by one bcz marks are 1 based but lines are 0 based
        lines = A.nvim_buf_get_lines(0, range.srow - 1, range.erow, false)
    end

    return lines, range
end

---Validates and unwraps the given commentstring
---@param cstr string
---@return string|boolean
---@return string|boolean
function U.unwrap_cstr(cstr)
    if U.is_empty(cstr) then
        return U.eprint("Empty commentstring. Run ':h commentstring' for help.")
    end

    local lcs, rcs = cstr:match('(.*)%%s(.*)')
    if not (lcs or rcs) then
        return U.eprint('Invalid commentstring ' .. cstr .. ". Run ':h commentstring' for help.")
    end

    -- Return false if a part is empty, otherwise trim it
    -- Bcz it is better to deal with boolean rather than checking empty string length everywhere
    return not U.is_empty(lcs) and vim.trim(lcs), not U.is_empty(rcs) and vim.trim(rcs)
end

---Unwraps the commentstring by taking it from the following places in the respective order.
---1. pre_hook (optionally a string can be returned)
---2. ft_table (extra commentstring table in the plugin)
---3. commentstring (already set or added in pre_hook)
---@param cfg Config Context
---@param ctx Ctx Context
---@return string string Left side of the commentstring
---@return string string Right side of the commentstring
function U.parse_cstr(cfg, ctx)
    local cstr = U.is_fn(cfg.pre_hook, ctx)
        -- calculate from ft if possible
        or require('Comment.ft').calculate(ctx)
        -- last resort use comentstring
        or vim.bo.commentstring

    return U.unwrap_cstr(cstr)
end

---Converts the given string into a commented string
---@param ln string String that needs to be commented
---@param lcs string Left side of the commentstring
---@param rcs string Right side of the commentstring
---@param padding string Padding chars b/w comment and line
---@param min_indent string|nil Pre-determine indentation (useful) when dealing w/ multiple lines
---@return string string Commented string
function U.comment_str(ln, lcs, rcs, padding, min_indent)
    if U.is_empty(ln) then
        return (min_indent or '') .. (lcs or rcs)
    end

    local indent, chars = ln:match('^(%s*)(.*)')

    local lcs_new = lcs and lcs .. padding or ''
    local rcs_new = rcs and padding .. rcs or ''

    local pos = #(min_indent or indent)
    local l_indent = indent:sub(0, pos) .. lcs_new .. indent:sub(pos + 1)

    return l_indent .. chars .. rcs_new
end

---Converts the given string into a uncommented string
---@param ln string Line that needs to be uncommented
---@param lcs_esc string (Escaped) Left side of the commentstring
---@param rcs_esc string (Escaped) Right side of the commentstring
---@param pp string Padding pattern (@see U.get_padding)
---@return string string Uncommented string
function U.uncomment_str(ln, lcs_esc, rcs_esc, pp)
    local ll = lcs_esc and lcs_esc .. pp or ''
    local rr = rcs_esc and rcs_esc .. '$?' or ''

    local indent, chars = ln:match('(%s*)' .. ll .. '(.*)' .. rr)

    -- If the line (after cstring) is empty then just return ''
    -- bcz when uncommenting multiline this also doesn't preserve leading whitespace as the line was previously empty
    if U.is_empty(chars) then
        return ''
    end

    -- When padding is enabled then trim one trailing space char
    return indent .. chars:gsub(pp .. '$', '')
end

---Check if the given string is commented or not
---@param lcs_esc string (Escaped) Left side of the commentstring
---@param rcs_esc string (Escaped) Right side of the commentstring
---@param pp string Padding pattern (@see U.get_padding)
---@return function function Function to call
function U.is_commented(lcs_esc, rcs_esc, pp)
    local ll = lcs_esc and '^%s*' .. lcs_esc .. pp or ''
    local rr = rcs_esc and pp .. rcs_esc .. '$' or ''

    return function(line)
        return line:find(ll .. '(.-)' .. rr)
    end
end

return U
