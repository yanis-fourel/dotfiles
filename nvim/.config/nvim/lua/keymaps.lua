-- TODO: That plugin to automatically toggle
-- Set highlight on search, but clear on pressing <Esc> in normal mode
vim.opt.hlsearch = true
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Diagnostic keymaps
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Go to previous [D]iagnostic message" })
vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Go to next [D]iagnostic message" })
vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Show diagnostic [E]rror messages" })
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostic [Q]uickfix list" })

vim.keymap.set("n", "<leader><leader>x", ":source %<CR>", { desc = "Sources current file" })
vim.keymap.set("n", "/", "/\\v")
vim.keymap.set("n", "^", "0^", { noremap = true })

vim.keymap.set("x", "<leader>p", '"_dP')

vim.keymap.set("n", "<leader>yq", "<cmd>%!yq<CR>")
vim.keymap.set("n", "<leader>jq", "<cmd>%!jq --tab<CR>")
vim.keymap.set("v", "<leader>jq", "<cmd>'<,'>!jq --tab<CR>")
vim.keymap.set("n", "<leader><leader>jq", "<cmd>%!jq --tab -c<CR>")
vim.keymap.set("v", "<leader><leader>jq", "<cmd>'<,'>!jq --tab -c<CR>")

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- Map j and k to gj/gk, but only when no count is given
-- However, for larger jumps like 6j add the current position to the jump list
local function vertical_move(motion)
	local BIG = 5

	return function()
		local count = vim.v.count or 1
		if count > BIG then
			vim.cmd("mark '")
		end
		if count == 0 then
			return "g" .. motion
		end
		return motion
	end
end
vim.keymap.set("n", "<Up>", vertical_move("k"), { remap = true, expr = true })
vim.keymap.set("n", "<Down>", vertical_move("j"), { remap = true, expr = true })
vim.keymap.set("n", "<Left>", "h", { remap = true })
vim.keymap.set("n", "<Right>", "l", { remap = true })

vim.keymap.set("n", "<M-S-m>", "<C-w><Left>", { desc = "Move focus to the left window" })
vim.keymap.set("n", "<M-S-n>", "<C-w><Down>", { desc = "Move focus to the right window" })
vim.keymap.set("n", "<M-S-e>", "<C-w><Up>", { desc = "Move focus to the lower window" })
vim.keymap.set("n", "<M-S-i>", "<C-w><Right>", { desc = "Move focus to the upper window" })

-- TODO luafy: vim.keymap.set('c','<expr>', '%% getcmdtype() == ':' ? expand('%:h').'/' : '%%'')
vim.cmd([[ cnoremap <expr> %% getcmdtype() == ':' ? expand('%:h').'/' : '%%' ]])

vim.keymap.set("n", "<leader>1", "1gt")
vim.keymap.set("n", "<leader>2", "2gt")
vim.keymap.set("n", "<leader>3", "3gt")
vim.keymap.set("n", "<leader>4", "4gt")
vim.keymap.set("n", "<leader>5", "5gt")
vim.keymap.set("n", "<leader>6", "6gt")
vim.keymap.set("n", "<leader>7", "7gt")
vim.keymap.set("n", "<leader>8", "8gt")
vim.keymap.set("n", "<leader>9", "9gt")

-- Rename all occurences of the word under cursor
vim.keymap.set("n", "<leader><leader>re", "yiw:%s///g<c-F>hhhhpla")

vim.keymap.set("i", "<C-z>", "<cmd>normal zz<CR>")

vim.api.nvim_create_user_command("UnicodeFix", [[%s/\\u\(\x\{4\}\)/\=nr2char('0x'.submatch(1),1)/g]], {})
