---LHS of toggle mappings in NORMAL + VISUAL mode
---@class Toggler
---@field line string Linewise comment keymap
---@field block string Blockwise comment keymap

---LHS of operator-pending mappings in NORMAL + VISUAL mode
---@class Opleader
---@field line string Linewise comment keymap
---@field block string Blockwise comment keymap

---LHS of extra mappings
---@class ExtraMapping
---@field above string Mapping to add comment on the line above
---@field below string Mapping to add comment on the line below
---@field eol string Mapping to add comment at the end of line

---Whether to create basic (operator-pending) and extended mappings
---@class Mappings
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

---Plugin's config
---@class Config
---@field padding boolean Add a space b/w comment and the line
---Whether the cursor should stay at its position
---NOTE: This only affects NORMAL mode mappings and doesn't work with dot-repeat
---@field sticky boolean
---Lines to be ignored while comment/uncomment.
---Could be a regex string or a function that returns a regex string.
---Example: Use '^$' to ignore empty lines
---@field ignore string|fun():string
---@field mappings Mappings
---@field toggler Toggler
---@field opleader Opleader
---@field extra ExtraMapping
---@field pre_hook fun(ctx: Ctx):string Function to be called before comment/uncomment
---@field post_hook fun(ctx:Ctx) Function to be called after comment/uncomment

---@class RootConfig
---@field config Config
local Config = {}

function Config.default()
    return {
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
    }
end

---Creates a new config instance
---@return RootConfig
function Config:new()
    return setmetatable({ config = self.default() }, { __index = self })
end

---Set/Update the config
---@private
---@param cfg Config
function Config:set(cfg)
    if cfg then
        self.config = vim.tbl_deep_extend('force', self.config, cfg)
    end
    return self
end

---Get the config
---@return Config
function Config:get()
    return self.config
end

return Config
