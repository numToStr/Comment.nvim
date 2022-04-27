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
    html = '<!--%s-->',
    latex = '%%s',
    lisp_l = ';;%s',
    lisp_b = '#|%s|#',
}

---Lang table that contains commentstring (linewise/blockwise) for mutliple filetypes
---@type table { filetype = { linewise, blockwise } }
local L = {
    bash = { M.hash },
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
    eelixir = { M.html, M.html },
    elixir = { M.hash },
    elm = { M.dash, M.haskell_b },
    fennel = { M.lisp_l },
    fish = { M.hash },
    fsharp = { M.cxx_l, M.fsharp_b },
    gdb = { M.hash },
    gdscript = { M.hash },
    gleam = { M.cxx_l },
    go = { M.cxx_l, M.cxx_b },
    graphql = { M.hash },
    groovy = { M.cxx_l, M.cxx_b },
    haskell = { M.dash, M.haskell_b },
    heex = { M.html, M.html },
    html = { M.html, M.html },
    htmldjango = { M.html, M.html },
    idris = { M.dash, M.haskell_b },
    ini = { M.hash },
    java = { M.cxx_l, M.cxx_b },
    javascript = { M.cxx_l, M.cxx_b },
    javascriptreact = { M.cxx_l, M.cxx_b },
    jsonc = { M.cxx_l },
    julia = { M.hash, '#=%s=#' },
    kotlin = { M.cxx_l, M.cxx_b },
    lidris = { M.dash, M.haskell_b },
    lisp = { M.lisp_l, M.lisp_b },
    lua = { M.dash, M.dash_bracket },
    markdown = { M.html, M.html },
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
    ruby = { M.hash },
    rust = { M.cxx_l, M.cxx_b },
    scala = { M.cxx_l, M.cxx_b },
    scheme = { M.lisp_l, M.lisp_b },
    sh = { M.hash },
    sql = { M.dash, M.cxx_b },
    svelte = { M.html, M.html },
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
    vue = { M.html, M.html },
    xml = { M.html, M.html },
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

---Get a commentstring from the filtype list
---@param lang Lang
---@param ctype CType
---@return string
function ft.get(lang, ctype)
    local l = ft.lang(lang)
    return l and l[ctype]
end

---Get the commentstring(s) from the filtype list
---@param lang Lang
---@return string
function ft.lang(lang)
    return L[lang]
end

---Get the commenstring by walking the tree recursively
---NOTE: This ignores `comment` parser as this is useless
---@param tree userdata Tree to be walked
---@param range number[] Range to check for
---@return userdata
function ft.contains(tree, range)
    for lang, child in pairs(tree:children()) do
        if lang ~= 'comment' and child:contains(range) then
            return ft.contains(child, range)
        end
    end

    return tree
end

---Calculate commentstring w/ the power of treesitter
---@param ctx Ctx
---@return string
function ft.calculate(ctx)
    local buf = A.nvim_get_current_buf()
    local ok, parser = pcall(vim.treesitter.get_parser, buf)
    local default = ft.get(A.nvim_buf_get_option(buf, 'filetype'), ctx.ctype)

    if not ok then
        return default
    end

    local lang = ft.contains(parser, {
        ctx.range.srow - 1,
        ctx.range.scol,
        ctx.range.erow - 1,
        ctx.range.ecol,
    }):lang()

    return ft.get(lang, ctx.ctype) or default
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
