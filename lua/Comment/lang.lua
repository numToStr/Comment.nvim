---Lang table
---@class lang_table
local L = {
    toml = '#%s',
}

return setmetatable({}, {
    __index = {
        get = function(lang)
            return L[lang]
        end,
    },
    __newindex = function(_, k, v)
        L[k] = v
    end,
    __call = function(_, langs, spec)
        for _, lang in ipairs(langs) do
            L[lang] = spec
        end
    end,
})
