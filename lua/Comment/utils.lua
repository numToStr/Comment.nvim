---@mod comment.utils Utilities

local A = vim.api

local U = {}

---@alias CommentLines string[] List of lines inside the start and end index

---@class CommentRange Range of the selection that needs to be commented
---@field srow number Starting row
---@field scol number Starting column
---@field erow number Ending row
---@field ecol number Ending column

---@class CommentMode Comment modes - Can be manual or computed via operator-mode
---@field toggle number Toggle action
---@field comment number Comment action
---@field uncomment number Uncomment action

---An object containing comment modes
---@type CommentMode
U.cmode = {
    toggle = 0,
    comment = 1,
    uncomment = 2,
}

---@class CommentType Comment types
---@field line number Use linewise commentstring
---@field block number Use blockwise commentstring

---An object containing comment types
---@type CommentType
U.ctype = {
    line = 1,
    block = 2,
}

---@class CommentMotion Comment motion types
---@field private _ number Compute from vim mode. See |OpMode|
---@field line number Line motion (ie. `gc2j`)
---@field char number Character/left-right motion (ie. `gc2j`)
---@field block number Visual operator-pending motion
---@field v number Visual motion
---@field V number Visual-line motion

---An object containing comment motions
---@type CommentMotion
U.cmotion = {
    _ = 0,
    line = 1,
    char = 2,
    block = 3,
    v = 4,
    V = 5,
}

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

---Helper to get padding character and regex pattern
---NOTE: Use a function for conditional padding
---@param flag boolean|fun():boolean
---@return string string Padding chars
---@return string string Padding pattern
function U.get_padding(flag)
    if not U.is_fn(flag) then
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
    A.nvim_feedkeys('a', 'ni', true)
end

---Convert the string to a escaped string, if given
---@param str string
---@return string|boolean
function U.escape(str)
    return str and vim.pesc(str)
end

---Call a function if exists
---@param fn function Wanna be function
---@return boolean|string
function U.is_fn(fn, ...)
    if type(fn) == 'function' then
        return fn(...)
    end
    return fn
end

---Check if the given line is ignored or not with the given pattern
---@param ln string Line to be ignored
---@param pat string Lua regex
---@return boolean
function U.ignore(ln, pat)
    return pat and ln:find(pat) ~= nil
end

---Get region for line movement or visual selection
---NOTE: Returns the current line region, if `opmode` is not given.
---@param opmode? OpMode
---@return CommentRange
function U.get_region(opmode)
    if not opmode then
        local row = unpack(A.nvim_win_get_cursor(0))
        return { srow = row, scol = 0, erow = row, ecol = 0 }
    end

    local m = A.nvim_buf_get_mark
    local buf = 0
    local sln, eln

    if string.match(opmode, '[vV]') then
        sln, eln = m(buf, '<'), m(buf, '>')
    else
        sln, eln = m(buf, '['), m(buf, ']')
    end

    return { srow = sln[1], scol = sln[2], erow = eln[1], ecol = eln[2] }
end

---Get lines from the current position to the given count
---@param count number
---@return CommentLines
---@return CommentRange
function U.get_count_lines(count)
    local pos = A.nvim_win_get_cursor(0)
    local srow = pos[1]
    local erow = (srow + count) - 1
    local lines = A.nvim_buf_get_lines(0, srow - 1, erow, false)

    return lines, { srow = srow, scol = 0, erow = erow, ecol = 0 }
end

---Get lines from a NORMAL/VISUAL mode
---@param range CommentRange
---@return CommentLines
function U.get_lines(range)
    -- If start and end is same, then just return the current line
    if range.srow == range.erow then
        return { A.nvim_get_current_line() }
    end

    return A.nvim_buf_get_lines(0, range.srow - 1, range.erow, false)
end

---Validates and unwraps the given commentstring
---@param cstr string
---@return string|boolean
---@return string|boolean
function U.unwrap_cstr(cstr)
    local lcs, rcs = cstr:match('(.*)%%s(.*)')

    if not (lcs or rcs) then
        return vim.notify(
            ("[Comment] Invalid commentstring - %q. Run ':h commentstring' for help."):format(cstr),
            vim.log.levels.ERROR
        )
    end

    -- Return false if a part is empty, otherwise trim it
    -- Bcz it is better to deal with boolean rather than checking empty string length everywhere
    return not U.is_empty(lcs) and vim.trim(lcs), not U.is_empty(rcs) and vim.trim(rcs)
end

---Unwraps the commentstring by taking it from the following places
---     1. pre_hook (optionally a string can be returned)
---     2. ft_table (extra commentstring table in the plugin)
---     3. commentstring (already set or added in pre_hook)
---@param cfg CommentConfig
---@param ctx CommentCtx
---@return string string Left side of the commentstring
---@return string string Right side of the commentstring
function U.parse_cstr(cfg, ctx)
    -- 1. We ask `pre_hook` for a commentstring
    local cstr = U.is_fn(cfg.pre_hook, ctx)
        -- 2. Calculate w/ the help of treesitter
        or require('Comment.ft').calculate(ctx)
        -- 3. Last resort to use native commentstring
        or vim.bo.commentstring

    return U.unwrap_cstr(cstr)
end

---Converts the given string into a commented string
---@param ln string String that needs to be commented
---@param lcs string Left side of the commentstring
---@param rcs string Right side of the commentstring
---@param padding string Padding chars b/w comment and line
---@param min_indent? string Minimum indent to use with multiple lines
---@return string string Commented string
function U.comment_str(ln, lcs, rcs, padding, min_indent)
    if U.is_empty(ln) then
        return (min_indent or '') .. ((lcs or '') .. (rcs or ''))
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
---@param pp string Padding pattern. See |U.get_padding|
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
---@param pp string Padding pattern. See |U.get_padding|
---@return fun(line:string):boolean
function U.is_commented(lcs_esc, rcs_esc, pp)
    local ll = lcs_esc and '^%s*' .. lcs_esc .. pp or ''
    local rr = rcs_esc and pp .. rcs_esc .. '$' or ''

    return function(line)
        return line:find(ll .. '(.-)' .. rr)
    end
end

return U
