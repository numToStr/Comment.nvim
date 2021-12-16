--[[ local U = require('Comment.utils')
local Ex = require('Comment.extra')
local Op = require('Comment.opfunc')
local Config = require('Comment.config'):new() ]]

-- local U = require('Comment.utils')
-- local Ex = require('Comment.extra')
-- local Op = require('Comment.opfunc')
-- local Config = require('Comment.config'):new()

-- 1
-- 2
-- 3
-- 4

local a = --[[ 124 ]]
    124

local function hello_world()
    -- print(123)
    -- print(123)
    print(123)
    --[[ print(123)
    print(123) ]]
end

-- ;; Write your query here like `(node) @capture`,
-- ;; put the cursor under the capture to highlight the matches.
--
-- (
--     (comment) @l_comment (#lua-match? @l_comment "^--%s")
-- )
-- (
--     (comment) @b_comment (#lua-match? @b_comment "^--%[%[%s")
-- )

-- ('h:1,i:2'):gsub(',', function(n)
--     print(n)
-- end)
-- string.gsub('home = $HOME, user = $USER', '%$(%w+)', function(...)
--     dump(...)
-- end)
-- s0:/*!,m: ,ex:*/,s1:/*,mb:*,ex:*/,:///,://!,://

-- local escaped = vim.pesc('s0:/*!')
local escaped = 's0:/*!,m: ,ex:*/,s1:/*,mb:*,ex:*/,:///,://!,://'

print(escaped)

-- string.gsub(escaped, '(%w-):(.-),?', function(k, v)
--     dump(k, v)
-- end)
