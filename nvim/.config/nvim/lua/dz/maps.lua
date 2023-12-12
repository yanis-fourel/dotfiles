vim.keymap.set('n', '<leader><leader>cs', 'aDZ_COMMIT_STOP<ESC>')
vim.keymap.set('i', '<C-c><C-s>', 'DZ_COMMIT_STOP')

vim.keymap.set('n','<leader>>>', '>i{')
vim.keymap.set('n','<leader><<', '<i{')

vim.keymap.set('n','<leader><leader>s', '<cmd>silent! source %<CR>')

vim.keymap.set('n','/', '/\\v')

vim.keymap.set('n','^', '0^', { noremap = true })


vim.keymap.set('t','<Esc>', '<C-\\><C-n>')

vim.keymap.set('x','<leader>p', '"_dP')

vim.keymap.set('n','<leader>yq', '<cmd>%!yq<CR>')
vim.keymap.set('n','<leader>jq', '<cmd>%!jq --tab<CR>')
vim.keymap.set('v','<leader>jq', "<cmd>'<,'>!jq --tab<CR>")
vim.keymap.set('n','<leader><leader>jq', '<cmd>%!jq --tab -c<CR>')
vim.keymap.set('v','<leader><leader>jq', "<cmd>'<,'>!jq --tab -c<CR>")

-- {{{ hjkl

-- Map j and k to gj/gk, but only when no count is given
-- However, for larger jumps like 6j add the current position to the jump list
local function vertical_move(motion)
	local BIG = 5

	return function ()
		local count = vim.v.count or 1
		if count > BIG then
			vim.cmd("mark '")
		end
		if count == 0 then
			return 'g' .. motion
		end
		return motion
	end
end
vim.keymap.set('n','<Up>', vertical_move('k'), { remap = true, expr = true })
vim.keymap.set('n','<Down>', vertical_move('j'), { remap = true, expr = true })
vim.keymap.set('n','<Left>', 'h', { remap = true })
vim.keymap.set('n','<Right>', 'l', { remap = true})


vim.keymap.set('n', '<M-S-m>', '<C-w><Left>')
vim.keymap.set('n', '<M-S-n>', '<C-w><Down>')
vim.keymap.set('n', '<M-S-e>', '<C-w><Up>')
vim.keymap.set('n', '<M-S-i>', '<C-w><Right>')

-- }}}

-- Don't jump to next match on * press
vim.keymap.set('n','*', '*``')


-- {{{ Go to tab by number 

vim.keymap.set('n','<leader>1', '1gt')
vim.keymap.set('n','<leader>2', '2gt')
vim.keymap.set('n','<leader>3', '3gt')
vim.keymap.set('n','<leader>4', '4gt')
vim.keymap.set('n','<leader>5', '5gt')
vim.keymap.set('n','<leader>6', '6gt')
vim.keymap.set('n','<leader>7', '7gt')
vim.keymap.set('n','<leader>8', '8gt')
vim.keymap.set('n','<leader>9', '9gt')

-- }}}

-- rename with substitute cmd
vim.keymap.set('n','<leader><leader>re', 'yiw:%s///g<c-F>hhhhpla')

vim.keymap.set('n','<leader><leader>x', '<cmd>source %<CR>')
-- }}}


--
-- TODO luafy: vim.keymap.set('c','<expr>', '%% getcmdtype() == ':' ? expand('%:h').'/' : '%%'')
vim.cmd([[ cnoremap <expr> %% getcmdtype() == ':' ? expand('%:h').'/' : '%%' ]])




local mydap = require('dz.mydap')


function inspect_symbol()
	if vim.fn.expand('%:t') == 'Cargo.toml' and require('crates').popup_available() then
		require('crates').show_popup()
	elseif mydap.is_debugging() then
		mydap.inspect_symbol()
	else
		vim.lsp.buf.hover()
	end
end
vim.keymap.set('n', 'K', inspect_symbol)
vim.keymap.set('v', 'K', inspect_symbol)

vim.keymap.set('i', '<C-z>', '<cmd>normal zz<CR>')

vim.keymap.set('n', '<leader><leader>w', function ()
	if vim.fn.expand('%:e') == 'rs' then
		vim.cmd('silent !cargo fmt')
	end
end)

vim.api.nvim_create_user_command('FixUnicode', [[%s/\\u\(\x\{4\}\)/\=nr2char('0x'.submatch(1),1)/g]], {})
