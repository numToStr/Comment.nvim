-- TODO
-- [-] Handle Tabs
-- [ ] Dot repeat
-- [ ] Comment multiple line. In this case comment status and indentation of first line will be applied to the rest of the lines
-- [ ] Hook support
-- [ ] Doc comments ie. /** */ (for js)
-- [ ] Multi-line comment ie. /* */ (for js)
-- [ ] Treesitter context commentstring

local u = require("Comment.utils")

local api = vim.api

local C = {}

function C.setup()
	-- local cmd = api.nvim_command
	local map = api.nvim_set_keymap

	vim.cmd([[
        function! CommentOperator(type) abort
            let reg_save = @@
            exec "lua require('Comment').operator('" . a:type. "')"
            let @@ = reg_save
        endfunction
    ]])

	local opts = { noremap = true, silent = true }
	map("n", "gc", "<CMD>set operatorfunc=CommentOperator<CR>g@", opts)
	map("n", "gcc", "<CMD>set operatorfunc=CommentOperator<CR>g@j", opts)
end

function C.operator(type)
	print(type)
end

function C.unwrap_cstring()
	-- local cs = '<!-- %s -->'
	local cs = vim.bo.commentstring
	if not cs then
		return u.errprint("'commentstring' not found")
	end

	local rhs, lhs = cs:match("(.*)%%s(.*)")
	if not rhs then
		return u.errprint("Invalid commentstring: " .. cs)
	end

	-- return rhs, lhs
	return u.strip_space(rhs), u.strip_space(lhs)
end

function C.comment_ln(l, r_cs, l_cs)
	local indent, ln = l:match("(%s*)(.*)")
	api.nvim_set_current_line(indent .. r_cs .. ln .. l_cs)
end

function C.uncomment_ln(l, r_cs_esc, l_cs_esc)
	local indent, _, ln = l:match("(%s*)(" .. r_cs_esc .. "%s?)(.*)(%s?" .. l_cs_esc .. ")$")
	api.nvim_set_current_line(indent .. ln)
end

function C.toggle_comment()
	local r_cs, l_cs = C.unwrap_cstring()
	local line = api.nvim_get_current_line()

	local r_cs_esc = vim.pesc(r_cs)
	local is_commented = line:find("^%s*" .. r_cs_esc)

	if is_commented then
		C.uncomment_ln(line, r_cs_esc, vim.pesc(l_cs))
	else
		C.comment_ln(line, r_cs, l_cs)
	end
end

return C
