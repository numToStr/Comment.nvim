-- TODO
-- [-] Handle Tabs
-- [x] Dot repeat
-- [x] Comment multiple line.
-- [x] Hook support
--      [x] pre
--      [x] post
-- [x] Custom (language) commentstring support
-- [ ] Block comment ie. /* */ (for js)
-- [ ] Doc comment ie. /** */ (for js)
-- [ ] Treesitter context commentstring
-- [ ] Insert mode mapping (also move the cursor after commentstring)
-- [ ] Port `commentstring` from tcomment

-- FIXME
-- [x] visual mode not working correctly
-- [x] space after and before of commentstring
-- [x] multiple line behavior to tcomment
--      [x] preserve indent
--      [x] determine comment status (to comment or not)
-- [x] prevent uncomment on uncommented line
-- [x] `comment` and `toggle` misbehaving when there is leading space
-- [x] messed up indentation, if the first line has greater indentation than next line (calc min indendation)
-- [x] `gcc` empty line not toggling comment
-- [ ] dot repeat support for visual mode mappings
-- [ ] conflict when uncommenting interchangebly with line/block wise comment

-- THINK:
-- 1. Should i return the operator's starting and ending position in pre-hook
-- 2. Fix cursor position in motion operator (try `gcip`)
-- 3. It is possible that, commentstring is updated inside pre-hook as we want to use it but we can't
--    bcz the filetype is also present in the lang-table (and it has high priority than bo.commentstring)
