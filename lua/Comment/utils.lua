local A = vim.api
local U = {}

local function get_mark(m)
    return A.nvim_buf_get_mark(0, m)[1]
end

local function get_mark_pos(mode)
    local start_ln, end_ln

    if mode:match('[vV]') then
        start_ln = get_mark('<')
        end_ln = get_mark('>')
    else
        start_ln = get_mark('[')
        end_ln = get_mark(']')
    end

    return start_ln - 1, end_ln
end

local function fit_cstring(pos, str, r)
    return str:sub(0, pos) .. r .. str:sub(pos + 1)
end

function U.errprint(msg)
    vim.notify('Comment.nvim: ' .. msg, vim.log.levels.ERROR)
end

function U.strip_space(s)
    return s:gsub('%s+', '')
end

function U.get_lines(mode)
    local s_ln, e_ln = get_mark_pos(mode)

    -- If starting and ending is same, then just return the line
    -- Also for some reason get_lines doesn't return empty line, if called on single empty line
    -- if s_ln == e_ln then
    --     return s_ln, e_ln, { A.nvim_get_current_line() }
    -- end

    return s_ln, e_ln, A.nvim_buf_get_lines(0, s_ln, e_ln, false)
end

function U.comment_str(str, r_cs, l_cs, is_pad, spacing)
    local indent, ln = str:match('(%s*)(.*)')
    local s = spacing or ''

    -- if line is empty then use the space argument
    -- this is required if you are to comment multiple lines
    -- and the starting line has indentation
    local is_empty = #indent == 0 and #ln == 0
    local idnt = is_empty and s or indent

    if is_pad then
        -- If the rhs of cstring exists and the line is not empty then only add padding
        -- Bcz if we were to comment multiple lines and there are some empty lines in b/w
        -- then adding space to the them is not expected
        local new_r_cs = (#r_cs > 0 and not is_empty) and r_cs .. ' ' or r_cs

        local new_l_cs = #l_cs > 0 and ' ' .. l_cs or l_cs
        return fit_cstring(#s, idnt, new_r_cs) .. ln .. new_l_cs
    end

    return fit_cstring(#s, idnt, r_cs) .. ln .. l_cs
end

function U.uncomment_str(str, r_cs_esc, l_cs_esc, is_pad)
    local indent, _, ln = str:match('(%s*)(' .. r_cs_esc .. '%s?)(.*)(' .. l_cs_esc .. ')')

    -- When padding is enabled then trim one trailing space char
    local tail = is_pad and ln:gsub('%s?$', '') or ln

    -- If the line (after cstring) is empty then just return ''
    -- bcz when uncommenting multiline this also doesn't preserve leading whitespace as the line was previously empty
    return #ln == 0 and '' or indent .. tail
end

function U.is_hook(hook, ...)
    return type(hook) == 'function' and hook(...)
end

return U
