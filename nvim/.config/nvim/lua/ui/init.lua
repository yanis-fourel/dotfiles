vim.o.background = 'dark' -- or 'light' for light mode
vim.cmd([[colorscheme gruvbox]])


local help_group = vim.api.nvim_create_augroup('help_group', { clear = true })
vim.api.nvim_create_autocmd('BufEnter', { pattern = '*.txt', command = "if &buftype == 'help' | wincmd L | endif", group = help_group })
