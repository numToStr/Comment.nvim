local ts = require('Comment.ts')

--- Comment context
---@class Ctx
---@field lang string: The name of the language where the cursor is
---@field contained table: The containing node of where the cursor is
---@field ctype CType
---@field cmode CMode
---@field cmotion CMotion
local Ctx = {}

--- Create a new Ctx
---@return Ctx
function Ctx:new(opts)
    assert(opts.cmode, 'Must have a cmode')
    assert(opts.cmotion, 'Must have a cmotion')
    assert(opts.ctype, 'Must have a ctype')

    opts.lang = ts.get_lang()
    opts.contained = ts.get_containing_node()

    return setmetatable(opts, self)
end

return Ctx
