return {
    ---Setup the plugin
    ---@param config Config
    ---@return Config
    setup = function(config)
        return require('Comment.api').setup(config)
    end,
}
