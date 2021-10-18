local U = require('Comment.utils')
local E = require('Comment.extra')

local function tagger(tag, cb)
    return function(ctype)
        cb(ctype or U.ctype.line, { padding = true }, tag .. ' ')
    end
end

return setmetatable({}, {
    __index = function(_, tag)
        return {
            up = tagger(tag, E.norm_O),
            down = tagger(tag, E.norm_o),
            eol = tagger(tag, E.norm_A),
        }
    end,
})
