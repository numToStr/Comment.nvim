---@mod comment.config Configuration

---@class CommentConfig Plugin's configuration
---Controls space between the comment
---and the line (default: 'true')
---@field padding boolean
---Whether cursor should stay at the
---same position. Only works with NORMAL
---mode mappings (default: 'true')
---@field sticky boolean
---Lua pattern used to ignore lines
---during (un)comment (default: 'nil')
---@field ignore string|fun():string
---@field mappings Mappings|boolean
---@field toggler Toggler
---@field opleader Opleader
---@field extra ExtraMapping
---Function to call before (un)comment
---(default: 'nil')
---@field pre_hook fun(ctx):string
---Function to call after (un)comment
---(default: 'nil')
---@field post_hook fun(ctx)

---@class Mappings Create default mappings
---Enables operator-pending mapping; `gcc`, `gbc`,
---`gc{motion}` and `gb{motion}` (default: 'true')
---@field basic boolean
---Enable extra mapping; `gco`, `gcO` and `gcA`
---(default: 'true')
---@field extra boolean
---Enable extended mapping; `g>`, `g<c`, 'g<b',
---'g<', 'g<c', 'g<b', `g>{motion}` and `g<{motion}`
---(default: 'false')
---@field extended boolean

---@class Toggler LHS of toggle mappings in NORMAL
---@field line string Linewise comment (default: 'gcc')
---@field block string Blockwise comment (default: 'gbc')

---@class Opleader LHS of operator-mode mappings in NORMAL and VISUAL mode
---@field line string Linewise comment (default: 'gc')
---@field block string Blockwise comment (default: 'gb')

---@class ExtraMapping LHS of extra mappings
---@field below string Inserts comment below (default: 'gco')
---@field above string Inserts comment above (default: 'gcO')
---@field eol string Inserts comment at the end of line (default: 'gcA')

---@private
---@class RootConfig
---@field config CommentConfig
---@field position? integer[] To be used to restore cursor position
---@field count integer Helps with dot-repeat support for count prefix
local Config = {
    state = {},
    config = {
        padding = true,
        sticky = true,
        mappings = {
            basic = true,
            extra = true,
            extended = false,
        },
        toggler = {
            line = 'gcc',
            block = 'gbc',
        },
        opleader = {
            line = 'gc',
            block = 'gb',
        },
        extra = {
            above = 'gcO',
            below = 'gco',
            eol = 'gcA',
        },
    },
}

---@private
---Updates the default config
---@param cfg? CommentConfig
---@return RootConfig
---@see comment.usage.setup
---@usage `require('Comment.config'):set({config})`
function Config:set(cfg)
    if cfg then
        self.config = vim.tbl_deep_extend('force', self.config, cfg)
    end
    return self
end

---Get the config
---@return CommentConfig
---@usage `require('Comment.config'):get()`
function Config:get()
    return self.config
end

---@export Config
return setmetatable(Config, {
    __index = function(this, k)
        return this.state[k]
    end,
    __newindex = function(this, k, v)
        this.state[k] = v
    end,
})
