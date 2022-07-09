---@mod comment.utils Utilities

local A = vim.api

local U = {}

---@alias CommentLines string[] List of lines inside the start and end index

---@class CommentRange Range of the selection that needs to be commented
---@field srow number Starting row
---@field scol integer Starting column
---@field erow number Ending row
---@field ecol integer Ending column

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

---Get the length of the indentation
---@param str string
---@return integer integer Length of indent chars
function U.indent_len(str)
    local _, len = string.find(str, '^%s*')
    return len
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

---Call a function if exists
---@param fn unknown|fun():unknown Wanna be function
---@return unknown
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
    return pat and string.find(ln, pat) ~= nil
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

    local marks = string.match(opmode, '[vV]') ~= nil and { '<', '>' } or { '[', ']' }
    local sln, eln = A.nvim_buf_get_mark(0, marks[1]), A.nvim_buf_get_mark(0, marks[2])

    return { srow = sln[1], scol = sln[2], erow = eln[1], ecol = eln[2] }
end

---Get lines from the current position to the given count
---@param count number
---@return CommentLines
---@return CommentRange
function U.get_count_lines(count)
    local srow = unpack(A.nvim_win_get_cursor(0))
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
---@return string string Left side of the commentstring
---@return string string Right side of the commentstring
function U.unwrap_cstr(cstr)
    local left, right = string.match(cstr, '(.*)%%s(.*)')

    assert(
        (left or right),
        string.format("[Comment] Invalid commentstring - %q. Run ':h commentstring' for help.", cstr)
    )

    return vim.trim(left), vim.trim(right)
end

---Unwraps the commentstring by taking it from the following places
---     1. `pre_hook` (optionally a string can be returned)
---     2. `ft.lua` (extra commentstring table in the plugin)
---     3. `commentstring` (already set or added in pre_hook)
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

---Returns a closure which is used to comment a line
---@param left string Left side of the commentstring
---@param right string Right side of the commentstring
---@param padding string Padding between comment chars and line
---@param scol integer Left indentation to use with multiple lines
---@param ecol integer Left indentation to use with multiple lines
---@return fun(line:string):string
function U.commenter(left, right, scol, ecol, padding)
    local is_both = (scol > 0 and ecol > 0)
    local middle = is_both and table.concat({ '(', string.rep('.', (ecol - scol) + 1), ')' }) or ''

    local only_right = scol < 0 and ecol > 0
    local pattern = only_right and table.concat({ '^(', string.rep('.', ecol), ')', '(.*)' })
        or scol > 0 and table.concat({ '^(', string.rep('.', scol), ')', middle, '(.*)' })
        or '^(%s*)(.*)'

    local ll = U.is_empty(left) and left or table.concat({ left, padding })
    local rr = U.is_empty(right) and right or table.concat({ padding, right })
    local switch = only_right and { rr, '%2' } or { '%2', rr }
    local repl = table.concat({ '%1', ll, table.concat(switch), (scol > 0 and ecol > 0) and '%3' or '' })

    local empty = table.concat({ string.rep(' ', scol), left, right })

    return function(line)
        if U.is_empty(line) then
            return empty
        end
        return string.gsub(line, pattern, repl, 1)
    end
end

---Converts the given string into a uncommented string
---@param ln string Line that needs to be uncommented
---@param lcs_esc string (Escaped) Left side of the commentstring
---@param rcs_esc string (Escaped) Right side of the commentstring
---@param pp string Padding pattern. See |U.get_padding|
---@return string string Uncommented string
function U.uncomment_str(ln, lcs_esc, rcs_esc, pp)
    local ll = U.is_empty(lcs_esc) and lcs_esc or lcs_esc .. pp
    local rr = U.is_empty(rcs_esc) and rcs_esc or rcs_esc .. '$?'

    local indent, chars = ln:match('(%s*)' .. ll .. '(.*)' .. rr)

    -- If the line (after cstring) is empty then just return ''
    -- bcz when uncommenting multiline this also doesn't preserve leading whitespace as the line was previously empty
    if U.is_empty(chars) then
        return chars
    end

    -- When padding is enabled then trim one trailing space char
    return indent .. chars:gsub(pp .. '$', '')
end

---Check if the given string is commented or not
---@param left string Left side of the commentstring
---@param right string Right side of the commentstring
---@param pp string Padding pattern. See |U.get_padding|
---@return fun(line:string,scol?:integer,ecol?:integer):boolean
function U.is_commented(left, right, pp)
    local ll = U.is_empty(left) and left or table.concat({ '^%s*', vim.pesc(left), pp })
    local rr = U.is_empty(right) and right or table.concat({ pp, vim.pesc(right), '$' })
    local pattern = table.concat({ ll, '.-', rr })

    return function(line, scol, ecol)
        local ln = (scol == nil and ecol == nil) and line or string.sub(line, scol, ecol)
        return string.find(ln, pattern)
    end
end

return U
