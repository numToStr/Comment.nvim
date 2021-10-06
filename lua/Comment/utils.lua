local A = vim.api

local U = {}

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
    ---visual line
    block = 3,
}

---Print a msg on stderr
---@param msg string
function U.errprint(msg)
    vim.notify('Comment.nvim: ' .. msg, vim.log.levels.ERROR)
end

---Replace some char in the give string
---@param pos number Position for the replacement
---@param str string String that needs to be modified
---@param rep string Replacement chars
---@return string string Replaced string
function U.replace(pos, str, rep)
    return str:sub(0, pos) .. rep .. str:sub(pos + 1)
end

---Trim leading/trailing whitespace from the given string
---@param str string
---@return string
function U.trim(str)
    return str:gsub('%s+', '')
end

function U.get_cmotion(vmode)
    if vmode == 'line' then
        return U.cmotion.line
    end
    if vmode == 'char' then
        return U.cmotion.char
    end
    if vmode == 'block' then
        return U.cmotion.block
    end
    return U.cmotion.line
end

---Get region for vim mode
---@param vmode string VIM mode
---@return number number start column
---@return number number end column
---@return number number start row
---@return number number end row
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

    return sln[1], eln[1], sln[2], eln[2]
end

---Get lines from a NORMAL/VISUAL mode
---@param vmode string VIM mode
---@param ctype CType Comment string type
---@return number number Start index of the lines
---@return number number End index of the lines
---@return table table List of lines inside the start and end index
---@return number number Start row
---@return number number End row
function U.get_lines(vmode, ctype)
    local scol, ecol, srow, erow = U.get_region(vmode)

    local sln = scol - 1

    -- If start and end is same, then just return the current line
    local lines
    if scol == ecol then
        lines = { A.nvim_get_current_line() }
    elseif ctype == U.ctype.block then
        -- In block we only need the starting and endling line
        lines = {
            A.nvim_buf_get_lines(0, sln, scol, false)[1],
            A.nvim_buf_get_lines(0, ecol - 1, ecol, false)[1],
        }
    else
        -- decrementing `scol` by one bcz marks are 1 based but lines are 0 based
        lines = A.nvim_buf_get_lines(0, sln, ecol, false)
    end

    return sln, ecol, lines, srow, erow
end

---Separate the given line into two parts ie. indentation, chars
---@param ln string|table Line that need to be split
---@return string string Indentation chars
---@return string string Remaining chars
function U.split_half(ln)
    return ln:match('(%s*)(.*)')
end

---Converts the given string into a commented string
---@param str string String that needs to be commented
---@param rcs string Right side of the commentstring
---@param lcs string Left side of the commentstring
---@param is_pad boolean Whether to add padding b/w comment and line
---@param spacing string|nil Pre-determine indentation (useful) when dealing w/ multiple lines
---@return string string Commented string
function U.comment_str(str, rcs, lcs, is_pad, spacing)
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
        local new_r_cs = (#rcs > 0 and not is_empty) and rcs .. ' ' or rcs

        local new_l_cs = #lcs > 0 and ' ' .. lcs or lcs

        -- (spacing or indent) this is bcz of single `comment` and `uncomment`
        -- In these case, current line might be indented and we don't have spacing
        -- So we can use the original indentation of the line
        return U.replace(#(spacing or indent), idnt, new_r_cs) .. ln .. new_l_cs
    end

    return U.replace(#(spacing or indent), idnt, rcs) .. ln .. lcs
end

---Converts the given string into a uncommented string
---@param str string Line that needs to be uncommented
---@param rcs_esc string (Escaped) Right side of the commentstring
---@param lcs_esc string (Escaped) Left side of the commentstring
---@param is_pad boolean Whether to add padding b/w comment and line
---@return string string Uncommented string
function U.uncomment_str(str, rcs_esc, lcs_esc, is_pad)
    if not U.is_commented(str, rcs_esc) then
        return str
    end

    local indent, _, ln = str:match('(%s*)(' .. rcs_esc .. '%s?)(.*)(' .. lcs_esc .. '$?)')

    -- If the line (after cstring) is empty then just return ''
    -- bcz when uncommenting multiline this also doesn't preserve leading whitespace as the line was previously empty
    if #ln == 0 then
        return ''
    end

    -- When padding is enabled then trim one trailing space char
    return indent .. (is_pad and ln:gsub('%s?$', '') or ln)
end

function U.comment_block(line, rcs, lcs, srow, erow)
    local srow1, erow1, erow2 = srow + 1, erow + 1, erow + 2
    local first = line:sub(0, srow)
    local mid = line:sub(srow1, erow1)
    local last = line:sub(erow2, #line)
    return first .. rcs .. mid .. lcs .. last
end

---Check if {pre,post}_hook is present then call it
---@param hook function Hook function
---@return boolean|string
function U.is_hook(hook, ...)
    return type(hook) == 'function' and hook(...)
end

---Check if the given string is commented or not
---@param str string Line that needs to be checked
---@param rcs_esc string (Escaped) Right side of the commentstring
---@return number
function U.is_commented(str, rcs_esc)
    return str:find('^%s*' .. rcs_esc)
end

---Check if the given line is ignored or not with the given pattern
---@param ln string Line to be ignored
---@param pat string Lua regex
---@return boolean
function U.ignore(ln, pat)
    return pat and ln:find(pat) ~= nil
end

return U
