local op = {}

-- If cmotion == char | block
function op.block()
    -- `vmode` values
    -- char - use block comment
    -- line - use line comment
    -- visual - use line comment for now
end

-- Two types of commenting
-- char, block
-- line

-- Visual mode commenting
--
-- V-BLOCK: block comment
--      - LHS cstr in every line before the first char (excluding whitespace)
--      - RHS cstr in every line after erow
--
-- V-LINE: line comment
-- VISUAL: line comment
--      - LHS cstr in every line before the first char (excluding whitespace)

return op
