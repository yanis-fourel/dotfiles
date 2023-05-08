require("gruvbox").setup({
	overrides = {
		Operator = { italic = false },
	}
});
vim.o.background = 'dark'
vim.cmd([[colorscheme gruvbox]])


local help_group = vim.api.nvim_create_augroup('help_group', { clear = true })
vim.api.nvim_create_autocmd('BufEnter', { pattern = '*.txt', command = "if &buftype == 'help' | wincmd L | endif", group = help_group })

vim.notify = require('notify')


vim.keymap.set('n', '<leader>e', function() vim.cmd("NERDTreeToggle") end)
