---@mod comment.config Configuration
---@tag comment.config.defaults
---@brief [[
---Following is the default config for the |comment.usage.setup|. If you want to
---override, just modify the option that you want, then it will be merged with the
---default config.
--->lua
---  {
---      padding = true,
---      sticky = true,
---      ignore = nil,
---      toggler = { line = 'gcc', block = 'gbc' },
---      opleader = { line = 'gc', block = 'gb' },
---      extra = { above = 'gcO', below = 'gco', eol = 'gcA' },
---      mappings = { basic = true, extra = true },
---      pre_hook = nil,
---      post_hook = nil,
---  }
---<
---@brief ]]

---Plugin's configuration
---@class CommentConfig
---Controls space between the comment
---and the line (default: 'true')
---@field padding boolean|fun():boolean
---Whether cursor should stay at the
---same position. Only works in NORMAL
---mode mappings (default: 'true')
---@field sticky boolean
---Lua pattern used to ignore lines
---during (un)comment (default: 'nil')
---@field ignore string|fun():string
---Enables |comment.keybindings|
---NOTE: If given 'false', then the
---plugin won't create any mappings
---@field mappings Mappings|false
---@field toggler Toggler See |comment.config.Toggler|
---@field opleader Opleader See |comment.config.Opleader|
---@field extra ExtraMapping See |comment.config.ExtraMapping|
---Function to call before (un)comment.
---It is called with a {ctx} argument
---of type |comment.utils.CommentCtx|
---(default: 'nil')
---@field pre_hook fun(c: CommentCtx): string
---Function to call after (un)comment.
---It is called with a {ctx} argument
---of type |comment.utils.CommentCtx|
---(default: 'nil')
---@field post_hook fun(c: CommentCtx)

---Create default mappings
---@class Mappings
---Enables operator-pending mapping; `gcc`, `gbc`,
---`gc{motion}` and `gb{motion}` (default: 'true')
---@field basic boolean
---Enable extra mapping; `gco`, `gcO` and `gcA`
---(default: 'true')
---@field extra boolean

---LHS of toggle mappings in NORMAL
---@class Toggler
---@field line string Linewise comment (default: 'gcc')
---@field block string Blockwise comment (default: 'gbc')

---LHS of operator-mode mappings in NORMAL and VISUAL mode
---@class Opleader
---@field line string Linewise comment (default: 'gc')
---@field block string Blockwise comment (default: 'gb')

---LHS of extra mappings
---@class ExtraMapping
---@field below string Inserts comment below (default: 'gco')
---@field above string Inserts comment above (default: 'gcO')
---@field eol string Inserts comment at the end of line (default: 'gcA')

---@private
---@class RootConfig
---@field config CommentConfig
---@field position? integer[] To be used to restore cursor position
local Config = {
    state = {},
    config = {
        padding = true,
        sticky = true,
        mappings = {
            basic = true,
            extra = true,
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

---@package
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
