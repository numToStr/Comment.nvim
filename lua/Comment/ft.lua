---Common commentstring shared b/w mutliple languages
local M = {
    cxx_l = '//%s',
    cxx_b = '/*%s*/',
    hash = '#%s',
    dash = '--%s',
    haskell_b = '{-%s-}',
    fsharp_b = '(*%s*)',
    html_b = '<!--%s-->',
    latex = '%%s',
    jsx = '{/*%s*/}',
}

local javascript_special_nodes = {
    comment = { M.cxx_l, M.cxx_b },
    jsx_attribute = { M.cxx_l, M.cxx_b },
    jsx_element = { M.jsx, M.jsx },
    jsx_fragment = { M.jsx, M.jsx },
    jsx_opening_element = { M.jsx, M.jsx },
    call_expression = { M.cxx_l, M.cxx_b },
    statement_block = { M.cxx_l, M.cxx_b },
}

---Lang table that contains commentstring (linewise/blockwise) for mutliple filetypes
---@type table { filetype = { linewise, blockwise } }
local L = {
    bib = { M.latex },
    c = { M.cxx_l, M.cxx_b },
    cmake = { M.hash, '#[[%s]]' },
    cpp = { M.cxx_l, M.cxx_b },
    css = { M.cxx_b, M.cxx_b },
    dhall = { M.dash, M.haskell_b },
    dot = { M.cxx_l, M.cxx_b },
    elm = { M.dash, M.haskell_b },
    fsharp = { M.cxx_l, M.fsharp_b },
    go = { M.cxx_l, M.cxx_b },
    graphql = { M.hash },
    groovy = { M.cxx_l, M.cxx_b },
    haskell = { M.dash, M.haskell_b },
    html = { M.html_b, M.html_b },
    idris = { M.dash, M.haskell_b },
    java = { M.cxx_l, M.cxx_b },
    javascript = vim.tbl_deep_extend('keep', { M.cxx_l, M.cxx_b }, javascript_special_nodes),
    julia = { M.hash, '#=%s=#' },
    lidris = { M.dash, M.haskell_b },
    lua = { M.dash, '--[[%s--]]' },
    nix = { M.hash, M.cxx_b },
    ocaml = { M.fsharp_b, M.fsharp_b },
    plantuml = { "'%s", "/'%s'/" },
    purescript = { M.dash, M.haskell_b },
    python = { M.hash }, -- Python doesn't have block comments
    php = { M.cxx_l, M.cxx_b },
    rust = { M.cxx_l, M.cxx_b },
    scala = { M.cxx_l, M.cxx_b },
    sh = { M.hash },
    sql = { M.dash, M.cxx_b },
    swift = { M.cxx_l, M.cxx_b },
    terraform = { M.hash, M.cxx_b },
    tex = { M.latex },
    toml = { M.hash },
    tsx = vim.tbl_deep_extend('keep', { M.cxx_l, M.cxx_b }, javascript_special_nodes),
    typescript = { M.cxx_l, M.cxx_b },
    vim = { '"%s' },
    vue = { M.html_b, M.html_b },
    xml = { M.html_b, M.html_b },
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
    local buf = vim.api.nvim_get_current_buf()
    local langtree = vim.treesitter.get_parser(buf)

    local range = {
        ctx.range.srow - 1,
        ctx.range.scol,
        ctx.range.erow - 1,
        ctx.range.ecol,
    }

    local found
    for lang, tree in pairs(langtree:children()) do
        if found then
            break
        end
        if tree:contains(range) then
            found = ft.get(lang, ctx.ctype)
        end
    end

    return found or ft.get(vim.bo.filetype, ctx.ctype)
end

return setmetatable(ft, {
    __newindex = function(this, k, v)
        this.set(k, v)
    end,
    __call = function(this, langs, spec)
        for _, lang in ipairs(langs) do
            this.set(lang, spec)
        end
    end,
})
