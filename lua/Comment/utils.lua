local U = {}

function U.errprint(msg)
    vim.notify('Comment.nvim: ' .. msg, vim.log.levels.ERROR)
end

function U.strip_space(s)
    return s:gsub('%s+', '')
end

return U
