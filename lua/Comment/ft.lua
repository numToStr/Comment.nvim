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
    cmake = { M.hash, '#[[%s]]' },
    cpp = { M.cxx_l, M.cxx_b },
    dhall = { M.dash, M.haskell_b },
    dot = { M.cxx_l, M.cxx_b },
    elm = { M.dash, M.haskell_b },
    fsharp = { M.cxx_l, M.fsharp_b },
    go = { M.cxx_l, M.cxx_b },
    graphql = { M.hash },
    groovy = { M.cxx_l, M.cxx_b },
    haskell = { M.dash, M.haskell_b },
    idris = { M.dash, M.haskell_b },
    java = { M.cxx_l, M.cxx_b },
    javascript = { M.cxx_l, M.cxx_b },
    javascriptreact = { M.cxx_l, M.cxx_b },
    julia = { M.hash, '#=%s=#' },
    lidris = { M.dash, M.haskell_b },
    lua = { M.dash, '--[[%s--]]' },
    ocaml = { M.fsharp_b, M.fsharp_b },
    plantuml = { "'%s", "/'%s'/" },
    purescript = { M.dash, M.haskell_b },
    rust = { M.cxx_l, M.cxx_b },
    swift = { M.cxx_l, M.cxx_b },
    terraform = { M.hash, M.cxx_b },
    toml = { M.hash },
    typescript = { M.cxx_l, M.cxx_b },
    typescriptreact = { M.cxx_l, M.cxx_b },
    yaml = { M.hash },
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
