---@mod comment.utils Utilities

local A = vim.api

local U = {}

---@alias CommentLines string[] List of lines inside the start and end index

---@class CommentRange Range of the selection that needs to be commented
---@field srow integer Starting row
---@field scol integer Starting column
---@field erow integer Ending row
---@field ecol integer Ending column

---@class CommentMode Comment modes - Can be manual or computed via operator-mode
---@field toggle integer Toggle action
---@field comment integer Comment action
---@field uncomment integer Uncomment action

---An object containing comment modes
---@type CommentMode
U.cmode = {
    toggle = 0,
    comment = 1,
    uncomment = 2,
}

---@class CommentType Comment types
---@field line integer Use linewise commentstring
---@field block integer Use blockwise commentstring

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
---@param iter string|string[]
---@return boolean
function U.is_empty(iter)
    return #iter == 0
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

    local marks = string.match(opmode, '[vV]') and { '<', '>' } or { '[', ']' }
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
---If given {string[]} to the closure then it will do blockwise
---else it will do linewise
---@param left string Left side of the commentstring
---@param right string Right side of the commentstring
---@param scol? integer Starting column
---@param ecol? integer Ending column
---@param padding string Padding between comment chars and line
---@return fun(line:string|string[]):string
function U.commenter(left, right, scol, ecol, padding)
    local ll = U.is_empty(left) and left or (left .. padding)
    local rr = U.is_empty(right) and right or (padding .. right)
    local empty = string.rep(' ', scol or 0) .. left .. right
    local is_lw = scol and not ecol

    return function(line)
        ------------------
        -- for linewise --
        ------------------
        if U.is_empty(line) then
            return empty
        end
        if is_lw then
            -- line == 0 -> start from 0 col
            if scol == 0 then
                return (ll .. line .. rr)
            end
            local first = string.sub(line, 0, scol)
            local last = string.sub(line, scol + 1, -1)
            return table.concat({ first, ll, last, rr })
        end

        -------------------
        -- for blockwise --
        -------------------
        if type(line) == 'table' then
            local first, last = unpack(line)
            -- If both columns are given then we can assume it's a partial block
            if scol and ecol then
                local sfirst = string.sub(first, 0, scol)
                local slast = string.sub(first, scol + 1, -1)
                local efirst = string.sub(last, 0, ecol + 1)
                local elast = string.sub(last, ecol + 2, -1)
                return (sfirst .. ll .. slast), (efirst .. rr .. elast)
            end
            first = U.is_empty(first) and left or string.gsub(first, '^(%s*)', '%1' .. ll)
            last = U.is_empty(last) and right or (last .. rr)
            return first, last
        end

        --------------------------------
        -- for current-line blockwise --
        --------------------------------
        local first = string.sub(line, 0, scol)
        local mid = string.sub(line, scol + 1, ecol + 1)
        local last = string.sub(line, ecol + 2, -1)
        return table.concat({ first, ll, mid, rr, last })
    end
end

---Returns a closure which is used to uncomment a line
---@param left string Left side of the commentstring
---@param right string Right side of the commentstring
---@param scol? integer Starting column
---@param ecol? integer Ending column
---@param pp string Padding pattern. See |U.get_padding|
---@return fun(line:string|string[]):string
function U.uncommenter(left, right, scol, ecol, pp)
    local ll = U.is_empty(left) and left or vim.pesc(left) .. pp
    local rr = U.is_empty(right) and right or pp .. vim.pesc(right)

    -- FIXME: padding len
    local lll, rrr = #left + 1, #right + 1
    local is_lw = not (scol and scol)
    local pattern = is_lw and '^(%s*)' .. ll .. '(.-)' .. rr .. '$' or ''

    return function(line)
        -------------------
        -- for blockwise --
        -------------------
        if type(line) == 'table' then
            local first, last = unpack(line)
            -- If both columns are given then we can assume it's a partial block
            if scol and ecol then
                local sfirst = string.sub(first, 0, scol)
                local slast = string.sub(first, scol + lll + 1, -1)
                local efirst = string.sub(last, 0, ecol - rrr + 1)
                local elast = string.sub(last, ecol + 2, -1)
                return (sfirst .. slast), (efirst .. elast)
            end
            return string.gsub(first, '^(%s*)' .. ll, '%1'), string.gsub(last, rr .. '$', '')
        end

        ------------------
        -- for linewise --
        ------------------
        if is_lw then
            local a, b, c = string.match(line, pattern)
            -- If the line (before LHS) is just whitespace then just return ''
            -- bcz the line previously (before comment) was empty
            return string.find(a, '^%s$') and a or a .. b .. (c or '')
        end

        --------------------------------
        -- for current-line blockwise --
        --------------------------------
        local first = string.sub(line, 0, scol)
        local mid = string.sub(line, scol + lll + 1, ecol - rrr + 1)
        local last = string.sub(line, ecol + 2, -1)
        return first .. mid .. last
    end
end

---Check if the given string is commented or not
---@param left string Left side of the commentstring
---@param right string Right side of the commentstring
---@param pp string Padding pattern. See |U.get_padding|
---@return fun(line:string,scol?:integer,ecol?:integer):boolean
function U.is_commented(left, right, pp)
    local ll = U.is_empty(left) and left or '^%s*' .. vim.pesc(left) .. pp
    local rr = U.is_empty(right) and right or pp .. vim.pesc(right) .. '$'
    local pattern = ll .. '.-' .. rr

    -- TODO: take string[] for blockwise
    return function(line, scol, ecol)
        local ln = (scol == nil or ecol == nil) and line or string.sub(line, scol + 1, ecol == -1 and ecol or ecol + 1)
        return string.find(ln, pattern)
    end
end

return U
