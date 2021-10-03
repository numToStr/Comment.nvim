---Common commentstring used in mutliple languages
local M = {
    cxx_ln = '//%s',
    cxx_bl = '/*%s*/',
    hash = '#%s',
}

---Lang table that contains commentstring (linewise/blockwise) for mutliple filetypes
---@type table { filetype = { linewise = string, blockwise = string|nil } }
local L = {
    toml = { M.hash },
    javascript = { M.cxx_ln, M.cxx_bl },
}

return setmetatable({}, {
    __index = {
        set = function(k, v)
            if type(v) == 'string' then
                v = { v }
            end
            L[k] = v
        end,
        get = function(lang)
            local l = L[lang]
            return l and l[1]
        end,
        get_bl = function(lang)
            local l = L[lang]
            return l and l[2]
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
