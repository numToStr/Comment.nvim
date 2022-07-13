local U = require('Comment.utils')
local Op = require('Comment.opfunc')
local Ex = require('Comment.extra')
local Config = require('Comment.config')

-- TODO:
-- [x] add extra API as `insert.{above,below,eol}`
-- [x] add `count_repeat` but make it private
-- [x] play nice w/ `locked`
-- [x] replace all <Plug>
-- [x] depreact old APIs
-- [ ] rename U.ctype.{line => linewise, block => blockwise}

local types = {
    linewise = U.ctype.line,
    blockwise = U.ctype.block,
}

local core = {}
local extra = {}

function core.__index(that, ctype)
    local idxd = {}

    ---To comment the current-line
    ---NOTE:
    ---In current-line linewise method, 'opmode' is not useful which is always equals to `char`
    ---but we need 'line' here because `char` is used for current-line blockwise
    function idxd.current(_, cfg)
        Op.opfunc('line', cfg or Config:get(), that.cmode, types[ctype])
    end

    ---To comment lines with a count
    function idxd.count(count, cfg)
        Op.count(Config.count or count, cfg or Config:get(), types[ctype])
    end

    ---@private
    ---To comment lines with a count, also dot-repeatable
    ---WARNING: This is not part of the API but anyone case use it, if they want
    function idxd.count_repeat(_, count, cfg)
        idxd.count(count, cfg)
    end

    return setmetatable({ cmode = that.cmode, ctype = ctype }, {
        __index = idxd,
        __call = function(this, opmode, cfg)
            Op.opfunc(opmode, cfg or Config:get(), this.cmode, types[this.ctype])
        end,
    })
end

function extra.__index(_, ctype)
    return {
        above = function(cfg)
            Ex.insert_above(types[ctype], cfg or Config:get())
        end,
        below = function(cfg)
            Ex.insert_below(types[ctype], cfg or Config:get())
        end,
        eol = function(cfg)
            Ex.insert_eol(types[ctype], cfg or Config:get())
        end,
    }
end

return {
    toggle = setmetatable({ cmode = U.cmode.toggle }, core),
    comment = setmetatable({ cmode = U.cmode.comment }, core),
    uncomment = setmetatable({ cmode = U.cmode.comment }, core),
    insert = setmetatable({}, extra),
}
