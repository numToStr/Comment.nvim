---Common commentstring used in mutliple languages
local M = {
    cxx_ln = '//%s',
    cxx_bl = '/*%s*/',
    hash = '#%s',
}

---Lang table that contains commentstring (linewise/blockwise) for mutliple filetypes
---@type table { filetype = { linewise = string, blockwise = string|nil } }
local L = {
    lua = { '--%s', '--[[%s--]]' },
    javascript = { M.cxx_ln, M.cxx_bl },
    toml = { M.hash },
}

return setmetatable({}, {
    __index = {
        set = function(k, v)
            if type(v) == 'string' then
                v = { v }
            end
            L[k] = v
        end,
        get = function(lang, ty)
            local l = L[lang]
            return l and l[ty]
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
