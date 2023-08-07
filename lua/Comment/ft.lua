---@mod comment.ft Language/Filetype detection
---@brief [[
---This module is the core of filetype and commentstring detection and uses the
---|lua-treesitter| APIs to accurately detect filetype and gives the corresponding
---commentstring, stored inside the plugin, for the filetype/langauge.
---
---Compound (dot-separated) filetypes are also supported i.e. 'ansible.yaml',
---'ios.swift' etc. The commentstring resolution will be done from left to right.
---For example, If the filetype is 'ansible.yaml' then 'ansible' commenstring will
---be used if found otherwise it'll fallback to 'yaml'. Read `:h 'filetype'`
---@brief ]]

local A = vim.api

---Common commentstring shared b/w multiple languages
local M = {
    cxx_l = '//%s',
    cxx_b = '/*%s*/',
    dbl_hash = '##%s',
    dash = '--%s',
    dash_bracket = '--[[%s]]',
    handlebars = '{{!--%s--}}',
    hash = '#%s',
    hash_bracket = '#[[%s]]',
    haskell_b = '{-%s-}',
    fsharp_b = '(*%s*)',
    html = '<!--%s-->',
    latex = '%%s',
    semicolon = ';%s',
    lisp_l = ';;%s',
    lisp_b = '#|%s|#',
    twig = '{#%s#}',
    vim = '"%s',
    lean_b = '/-%s-/',
}

---Lang table that contains commentstring (linewise/blockwise) for multiple filetypes
---Structure = { filetype = { linewise, blockwise } }
---@type table<string,string[]>
local L = setmetatable({
    arduino = { M.cxx_l, M.cxx_b },
    applescript = { M.hash },
    astro = { M.html },
    autohotkey = { M.semicolon, M.cxx_b },
    bash = { M.hash },
    beancount = { M.semicolon },
    bib = { M.latex },
    c = { M.cxx_l, M.cxx_b },
    cabal = { M.dash },
    cmake = { M.hash, M.hash_bracket },
    conf = { M.hash },
    conkyrc = { M.dash, M.dash_bracket },
    coq = { M.fsharp_b },
    cpp = { M.cxx_l, M.cxx_b },
    cs = { M.cxx_l, M.cxx_b },
    css = { M.cxx_b, M.cxx_b },
    cuda = { M.cxx_l, M.cxx_b },
    dart = { M.cxx_l, M.cxx_b },
    dhall = { M.dash, M.haskell_b },
    dosbatch = { 'REM%s' },
    dot = { M.cxx_l, M.cxx_b },
    dts = { M.cxx_l, M.cxx_b },
    editorconfig = { M.hash },
    eelixir = { M.html, M.html },
    elixir = { M.hash },
    elm = { M.dash, M.haskell_b },
    elvish = { M.hash },
    faust = { M.cxx_l, M.cxx_b },
    fennel = { M.semicolon },
    fish = { M.hash },
    func = { M.lisp_l },
    fsharp = { M.cxx_l, M.fsharp_b },
    gdb = { M.hash },
    gdscript = { M.hash },
    gitignore = { M.hash },
    gleam = { M.cxx_l },
    glsl = { M.cxx_l, M.cxx_b },
    gnuplot = { M.hash, M.hash_bracket },
    go = { M.cxx_l, M.cxx_b },
    gomod = { M.cxx_l },
    graphql = { M.hash },
    groovy = { M.cxx_l, M.cxx_b },
    handlebars = { M.handlebars, M.handlebars },
    haskell = { M.dash, M.haskell_b },
    haxe = { M.cxx_l, M.cxx_b },
    heex = { M.html, M.html },
    html = { M.html, M.html },
    htmldjango = { M.html, M.html },
    idris = { M.dash, M.haskell_b },
    idris2 = { M.dash, M.haskell_b },
    ini = { M.hash },
    java = { M.cxx_l, M.cxx_b },
    javascript = { M.cxx_l, M.cxx_b },
    javascriptreact = { M.cxx_l, M.cxx_b },
    jsonc = { M.cxx_l },
    jsonnet = { M.cxx_l, M.cxx_b },
    julia = { M.hash, '#=%s=#' },
    kotlin = { M.cxx_l, M.cxx_b },
    lean = { M.dash, M.lean_b },
    lean3 = { M.dash, M.lean_b },
    lidris = { M.dash, M.haskell_b },
    lilypond = { M.latex, '%{%s%}' },
    lisp = { M.lisp_l, M.lisp_b },
    lua = { M.dash, M.dash_bracket },
    luau = { M.dash, M.dash_bracket },
    markdown = { M.html, M.html },
    make = { M.hash },
    mbsyncrc = { M.dbl_hash },
    mermaid = { '%%%s' },
    meson = { M.hash },
    nextflow = { M.cxx_l, M.cxx_b },
    nim = { M.hash, '#[%s]#' },
    nix = { M.hash, M.cxx_b },
    nu = { M.hash },
    ocaml = { M.fsharp_b, M.fsharp_b },
    odin = { M.cxx_l, M.cxx_b },
    plantuml = { "'%s", "/'%s'/" },
    purescript = { M.dash, M.haskell_b },
    python = { M.hash }, -- Python doesn't have block comments
    php = { M.cxx_l, M.cxx_b },
    prisma = { M.cxx_l },
    proto = { M.cxx_l, M.cxx_b },
    quarto = { M.html, M.html },
    r = { M.hash }, -- R doesn't have block comments
    racket = { M.lisp_l, M.lisp_b },
    rasi = { M.cxx_l, M.cxx_b },
    readline = { M.hash },
    rego = { M.hash },
    remind = { M.hash },
    rescript = { M.cxx_l, M.cxx_b },
    robot = { M.hash }, -- Robotframework doesn't have block comments
    ron = { M.cxx_l, M.cxx_b },
    ruby = { M.hash },
    rust = { M.cxx_l, M.cxx_b },
    sbt = { M.cxx_l, M.cxx_b },
    scala = { M.cxx_l, M.cxx_b },
    scheme = { M.lisp_l, M.lisp_b },
    sh = { M.hash },
    solidity = { M.cxx_l, M.cxx_b },
    supercollider = { M.cxx_l, M.cxx_b },
    sql = { M.dash, M.cxx_b },
    stata = { M.cxx_l, M.cxx_b },
    svelte = { M.html, M.html },
    swift = { M.cxx_l, M.cxx_b },
    sxhkdrc = { M.hash },
    tablegen = { M.cxx_l, M.cxx_b },
    teal = { M.dash, M.dash_bracket },
    terraform = { M.hash, M.cxx_b },
    tex = { M.latex },
    template = { M.dbl_hash },
    tmux = { M.hash },
    toml = { M.hash },
    twig = { M.twig, M.twig },
    typescript = { M.cxx_l, M.cxx_b },
    typescriptreact = { M.cxx_l, M.cxx_b },
    typst = { M.cxx_l, M.cxx_b },
    v = { M.cxx_l, M.cxx_b },
    verilog = { M.cxx_l },
    vhdl = { M.dash },
    vim = { M.vim },
    vifm = { M.vim },
    vue = { M.html, M.html },
    xdefaults = { '!%s' },
    xml = { M.html, M.html },
    xonsh = { M.hash }, -- Xonsh doesn't have block comments
    yaml = { M.hash },
    yuck = { M.lisp_l },
    zig = { M.cxx_l }, -- Zig doesn't have block comments
}, {
    -- Support for compound filetype i.e. 'ios.swift', 'ansible.yaml' etc.
    __index = function(this, k)
        local base, fallback = string.match(k, '^(.-)%.(.*)')
        if not (base or fallback) then
            return nil
        end
        return this[base] or this[fallback]
    end,
})

local ft = {}

---Sets a commentstring(s) for a filetype/language
---@param lang string Filetype/Language of the buffer
---@param val string|string[]
---@return table self Returns itself
---@usage [[
---local ft = require('Comment.ft')
---
-----1. Using method signature
----- Set only line comment or both
----- You can also chain the set calls
---ft.set('yaml', '#%s').set('javascript', {'//%s', '/*%s*/'})
---
----- 2. Metatable magic
---ft.javascript = {'//%s', '/*%s*/'}
---ft.yaml = '#%s'
---
----- 3. Multiple filetypes
---ft({'go', 'rust'}, {'//%s', '/*%s*/'})
---ft({'toml', 'graphql'}, '#%s')
---@usage ]]
function ft.set(lang, val)
    L[lang] = type(val) == 'string' and { val } or val --[[ @as string[] ]]
    return ft
end

---Get line/block/both commentstring(s) for a given filetype
---@param lang string Filetype/Language of the buffer
---@param ctype? integer See |comment.utils.ctype|. If given `nil`, it'll
---return a copy of { line, block } commentstring.
---@return nil|string|string[] #Returns stored commentstring
---@usage [[
---local ft = require('Comment.ft')
---local U = require('Comment.utils')
---
----- 1. Primary filetype
---ft.get('rust', U.ctype.linewise) -- `//%s`
---ft.get('rust') -- `{ '//%s', '/*%s*/' }`
---
----- 2. Compound filetype
----- NOTE: This will return `yaml` commenstring(s),
-----       as `ansible` commentstring is not found.
---ft.get('ansible.yaml', U.ctype.linewise) -- `#%s`
---ft.get('ansible.yaml') -- { '#%s' }
---@usage ]]
function ft.get(lang, ctype)
    local tuple = L[lang]
    if not tuple then
        return nil
    end
    if not ctype then
        return vim.deepcopy(tuple)
    end
    return tuple[ctype]
end

---Get a language tree for a given range by walking the parse tree recursively.
---This uses 'lua-treesitter' API under the hood. This can be used to calculate
---language of a particular region which embedded multiple filetypes like html,
---vue, markdown etc.
---
---NOTE: This ignores `tree-sitter-comment` parser, if installed.
---@param tree userdata Parse tree to be walked
---@param range integer[] Range to check
---{start_row, start_col, end_row, end_col}
---@return userdata #Returns a |treesitter-languagetree|
---@see treesitter-languagetree
---@see lua-treesitter-core
---@usage [[
---local ok, parser = pcall(vim.treesitter.get_parser, 0)
---assert(ok, "No parser found!")
---local tree = require('Comment.ft').contains(parser, {0, 0, -1, 0})
---print('Lang:', tree:lang())
---@usage ]]
function ft.contains(tree, range)
    for lang, child in pairs(tree:children()) do
        if lang ~= 'comment' and child:contains(range) then
            return ft.contains(child, range)
        end
    end

    return tree
end

---Calculate commentstring with the power of treesitter
---@param ctx CommentCtx
---@return nil|string #Commentstring
---@see comment.utils.CommentCtx
function ft.calculate(ctx)
    local ok, parser = pcall(vim.treesitter.get_parser, A.nvim_get_current_buf())

    if not ok then
        return ft.get(vim.bo.filetype, ctx.ctype) --[[ @as string ]]
    end

    local lang = ft.contains(parser, {
        ctx.range.srow - 1,
        ctx.range.scol,
        ctx.range.erow - 1,
        ctx.range.ecol,
    }):lang()

    return ft.get(lang, ctx.ctype) or ft.get(vim.bo.filetype, ctx.ctype) --[[ @as string ]]
end

---@export ft
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
