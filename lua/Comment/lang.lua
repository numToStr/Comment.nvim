---Common commentstring shared b/w mutliple languages
local M = {
    cxx_l = '//%s',
    cxx_b = '/*%s*/',
    hash = '#%s',
}

---Lang table that contains commentstring (linewise/blockwise) for mutliple filetypes
---@type table { filetype = { linewise, blockwise } }
local L = {
    c = { M.cxx_l, M.cxx_b },
    cpp = { M.cxx_l, M.cxx_b },
    lua = { '--%s', '--[[%s--]]' },
    javascript = { M.cxx_l, M.cxx_b },
    javascriptreact = { M.cxx_l, M.cxx_b },
    typescript = { M.cxx_l, M.cxx_b },
    typescriptreact = { M.cxx_l, M.cxx_b },
    rust = { M.cxx_l, M.cxx_b },
    go = { M.cxx_l, M.cxx_b },
    toml = { M.hash },
    yaml = { M.hash },
    graphql = { M.hash },
}

return setmetatable({}, {
    __index = {
        set = function(k, v)
            if type(v) == 'string' then
                v = { v }
            end
            L[k] = v
        end,
        get = function(lang, ctype)
            local l = L[lang]
            return l and l[ctype]
        end,
    },
    __newindex = function(this, k, v)
        this.set(k, v)
    end,
    __call = function(this, langs, spec)
        for _, lang in ipairs(langs) do
            this.set(lang, spec)
        end
    end,
})
