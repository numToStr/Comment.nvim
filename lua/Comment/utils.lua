local U = {}

local function get_mark(m)
    return vim.api.nvim_buf_get_mark(0, m)[1]
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

function U.errprint(msg)
    vim.notify('Comment.nvim: ' .. msg, vim.log.levels.ERROR)
end

function U.strip_space(s)
    return s:gsub('%s+', '')
end

function U.get_lines(mode)
    local s_ln, e_ln = get_mark_pos(mode)

    return s_ln, e_ln, vim.api.nvim_buf_get_lines(0, s_ln, e_ln, false)
end

function U.comment_str(str, r_cs, l_cs, padding)
    local indent, ln = str:match('(%s*)(.*)')
    if padding then
        local new_r_cs = #r_cs > 0 and r_cs .. ' ' or r_cs
        local new_l_cs = #l_cs > 0 and ' ' .. l_cs or l_cs
        return indent .. new_r_cs .. ln .. new_l_cs
    end
    return indent .. r_cs .. ln .. l_cs
end

function U.uncomment_str(str, r_cs_esc, l_cs_esc, padding)
    if padding then
        local indent, _, ln = str:match('(%s*)(' .. r_cs_esc .. '%s?)(.*)')
        return indent .. ln:gsub('%s?' .. l_cs_esc .. '$', '')
    end

    local indent, _, ln = str:match('(%s*)(' .. r_cs_esc .. ')(.*)(' .. l_cs_esc .. ')')
    return indent .. ln
end

return U
