---@mod comment.nvim Welcome to Comment.nvim

local C = {}

---Configures the plugin
---@param config? CommentConfig
---@return CommentConfig
function C.setup(config)
    return require('Comment.api').setup(config)
end

return C
