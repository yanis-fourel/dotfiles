-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.highlight.on_yank()`
vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight when yanking (copying) text",
	group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
	callback = function()
		vim.highlight.on_yank()
	end,
})

-- Open help as vertical split
vim.api.nvim_create_autocmd("BufEnter", {
	pattern = "*.txt",
	group = vim.api.nvim_create_augroup("help_group", { clear = true }),
	command = "if &buftype == 'help' | wincmd L | endif",
})
