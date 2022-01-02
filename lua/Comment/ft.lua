local A = vim.api

---Common commentstring shared b/w mutliple languages
local M = {
    cxx_l = '//%s',
    cxx_b = '/*%s*/',
    hash = '#%s',
    double_hash = '##%s',
    dash = '--%s',
    dash_bracket = '--[[%s]]',
    haskell_b = '{-%s-}',
    fsharp_b = '(*%s*)',
    html_b = '<!--%s-->',
    latex = '%%s',
}

---Lang table that contains commentstring (linewise/blockwise) for mutliple filetypes
---@type table { filetype = { linewise, blockwise } }
local L = {
    bib = { M.latex },
    c = { M.cxx_l, M.cxx_b },
    cmake = { M.hash, '#[[%s]]' },
    conf = { M.hash },
    conkyrc = { M.dash, M.dash_bracket },
    cpp = { M.cxx_l, M.cxx_b },
    cs = { M.cxx_l, M.cxx_b },
    css = { M.cxx_b, M.cxx_b },
    dhall = { M.dash, M.haskell_b },
    dot = { M.cxx_l, M.cxx_b },
    elm = { M.dash, M.haskell_b },
    fish = { M.hash },
    fsharp = { M.cxx_l, M.fsharp_b },
    gdb = { M.hash },
    go = { M.cxx_l, M.cxx_b },
    graphql = { M.hash },
    groovy = { M.cxx_l, M.cxx_b },
    haskell = { M.dash, M.haskell_b },
    html = { M.html_b, M.html_b },
    htmldjango = { M.html_b, M.html_b },
    idris = { M.dash, M.haskell_b },
    ini = { M.hash },
    java = { M.cxx_l, M.cxx_b },
    javascript = { M.cxx_l, M.cxx_b },
    javascriptreact = { M.cxx_l, M.cxx_b },
    jsonc = { M.cxx_l },
    julia = { M.hash, '#=%s=#' },
    lidris = { M.dash, M.haskell_b },
    lua = { M.dash, M.dash_bracket },
    markdown = { M.html_b, M.html_b },
    make = { M.hash },
    mbsyncrc = { M.double_hash },
    meson = { M.hash },
    nix = { M.hash, M.cxx_b },
    ocaml = { M.fsharp_b, M.fsharp_b },
    plantuml = { "'%s", "/'%s'/" },
    purescript = { M.dash, M.haskell_b },
    python = { M.hash }, -- Python doesn't have block comments
    php = { M.cxx_l, M.cxx_b },
    readline = { M.hash },
    rust = { M.cxx_l, M.cxx_b },
    scala = { M.cxx_l, M.cxx_b },
    sh = { M.hash },
    sql = { M.dash, M.cxx_b },
    swift = { M.cxx_l, M.cxx_b },
    sxhkdrc = { M.hash },
    teal = { M.dash, M.dash_bracket },
    terraform = { M.hash, M.cxx_b },
    tex = { M.latex },
    template = { M.double_hash },
    tmux = { M.hash },
    toml = { M.hash },
    typescript = { M.cxx_l, M.cxx_b },
    typescriptreact = { M.cxx_l, M.cxx_b },
    vim = { '"%s' },
    vue = { M.html_b, M.html_b },
    xml = { M.html_b, M.html_b },
    xdefaults = { '!%s' },
    yaml = { M.hash },
    zig = { M.cxx_l }, -- Zig doesn't have block comments. waaaattttt!
}

local ft = {}

---@alias Lang string Filetype/Language of the buffer

---Sets a commentstring(s) for a filetype/language
---@param lang Lang
---@param val string|string[]
function ft.set(lang, val)
    L[lang] = type(val) == 'string' and { val } or val
    return ft
end

---Get a commentstring from the filtype List
---@param lang Lang
---@param ctype CType
---@return string
function ft.get(lang, ctype)
    local l = L[lang]
    return l and l[ctype]
end

---Calculate commentstring w/ the power of treesitter
---@param ctx Ctx
---@return string
function ft.calculate(ctx)
    local buf = A.nvim_get_current_buf()
    local ok, langtree = pcall(vim.treesitter.get_parser, buf)
    local default = ft.get(A.nvim_buf_get_option(buf, 'filetype'), ctx.ctype)

    if not ok then
        return default
    end

    local range = {
        ctx.range.srow - 1,
        ctx.range.scol,
        ctx.range.erow - 1,
        ctx.range.ecol,
    }

    for lang, tree in pairs(langtree:children()) do
        if tree:contains(range) then
            -- If the language is in range but commentstring is not found, then fallback to filetype commentstring
            return ft.get(lang, ctx.ctype) or default
        end
    end

    return default
end

return setmetatable(ft, {
    __newindex = function(this, k, v)
        this.set(k, v)
    end,
    __call = function(this, langs, spec)
        for _, lang in ipairs(langs) do
            this.set(lang, spec)
        end
        return this
    end,
})
