---Common commentstring shared b/w mutliple languages
local M = {
    cxx_l = '//%s',
    cxx_b = '/*%s*/',
    hash = '#%s',
    dash = '--%s',
    haskell_b = '{-%s-}',
    fsharp_b = '(*%s*)',
}

---Lang table that contains commentstring (linewise/blockwise) for mutliple filetypes
---@type table { filetype = { linewise, blockwise } }
local L = {
    c = { M.cxx_l, M.cxx_b },
    cpp = { M.cxx_l, M.cxx_b },
    lua = { M.dash, '--[[%s--]]' },
    javascript = { M.cxx_l, M.cxx_b },
    javascriptreact = { M.cxx_l, M.cxx_b },
    typescript = { M.cxx_l, M.cxx_b },
    typescriptreact = { M.cxx_l, M.cxx_b },
    rust = { M.cxx_l, M.cxx_b },
    go = { M.cxx_l, M.cxx_b },
    toml = { M.hash },
    yaml = { M.hash },
    graphql = { M.hash },
    haskell = { M.dash, M.haskell_b },
    purescript = { M.dash, M.haskell_b },
    idris = { M.dash, M.haskell_b },
    lidris = { M.dash, M.haskell_b },
    elm = { M.dash, M.haskell_b },
    dhall = { M.dash, M.haskell_b },
    fsharp = { M.cxx_l, M.fsharp_b },
    ocaml = { M.fsharp_b, M.fsharp_b },
    zig = { M.cxx_l }, -- Zig doesn't have block comments. waaaattttt!
}

return setmetatable({}, {
    __index = {
        set = function(k, v)
            L[k] = type(v) == 'string' and { v } or v
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
