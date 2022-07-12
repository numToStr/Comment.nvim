---@mod comment.config Configuration

---@class Toggler LHS of toggle mappings in NORMAL + VISUAL mode
---@field line string Linewise comment keymap
---@field block string Blockwise comment keymap

---@class Opleader LHS of operator-mode mappings in NORMAL + VISUAL mode
---@field line string Linewise comment keymap
---@field block string Blockwise comment keymap

---@class ExtraMapping LHS of extra mappings
---@field above string Mapping to add comment on the line above
---@field below string Mapping to add comment on the line below
---@field eol string Mapping to add comment at the end of line

---@class Mappings Create default mappings
---Enable operator-pending mapping
---Includes `gcc`, `gbc`, `gc[count]{motion}` and `gb[count]{motion}`
---NOTE: These mappings can be changed individually by `opleader` and `toggler` config
---@field basic boolean
---Enable extra mapping
---Includes `gco`, `gcO`, `gcA`
---@field extra boolean
---Enable extended mapping
---Includes `g>`, `g<`, `g>[count]{motion}` and `g<[count]{motion}`
---@field extended boolean

---@class CommentConfig Plugin's configuration
---@field padding boolean Add a space b/w comment and the line
---Whether the cursor should stay at its position
---NOTE: This only affects NORMAL mode mappings and doesn't work with dot-repeat
---@field sticky boolean
---Lines to be ignored while comment/uncomment.
---Could be a regex string or a function that returns a regex string.
---Example: Use '^$' to ignore empty lines
---@field ignore string|fun():string
---@field mappings boolean|Mappings
---@field toggler Toggler
---@field opleader Opleader
---@field extra ExtraMapping
---@field pre_hook fun(ctx:CommentCtx):string Function to be called before comment/uncomment
---@field post_hook fun(ctx:CommentCtx) Function to be called after comment/uncomment

---@private
---@class RootConfig
---@field config CommentConfig
---@field position integer[] To be used to restore cursor position
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

---Update the config
---@param cfg? CommentConfig
---@return RootConfig
function Config:set(cfg)
    if cfg then
        self.config = vim.tbl_deep_extend('force', self.config, cfg)
    end
    return self
end

---Get the config
---@return CommentConfig
function Config:get()
    return self.config
end

---@export ft
return setmetatable(Config, {
    __index = function(this, k)
        return this.state[k]
    end,
    __newindex = function(this, k, v)
        this.state[k] = v
    end,
})
