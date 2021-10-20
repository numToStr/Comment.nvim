local U = require('Comment.utils')
local tag = require('Comment.tag')

function Todo()
    tag.NOTE.eol()
end

function Issue()
    tag.ISSUE.up()
end

function Fixme()
    tag.FIXME.down(U.ctype.block)
end
