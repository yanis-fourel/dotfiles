vim.o.encoding       = 'utf-8'
vim.o.relativenumber = true
vim.o.number         = true
vim.o.scrolloff      = 8
vim.o.shiftwidth     = 4
vim.o.tabstop        = 4
vim.o.expandtab      = false
vim.o.list           = true
vim.o.title          = true
vim.o.ignorecase     = true
vim.o.smartcase      = true
vim.o.clipboard      = 'unnamed'
vim.o.path           = vim.o.path .. '**'
vim.o.wildignore     = vim.o.wildignore .. '**/node_modules/*'
vim.o.history        = 200
vim.o.wrap           = false
vim.o.linebreak      = true
vim.o.undodir        = os.getenv("HOME") .. '/.nvim_undodir'
vim.o.undofile       = true
vim.o.guifont        = 'FiraCode:h16'
vim.o.mouse          = 'a'
vim.o.laststatus     = 3
vim.o.termguicolors  = true

-- Compiling file: obj/encode/json/print.o -> src/encode/json/print.c:186:78: error: format sp
vim.o.errorformat = vim.o.errorformat .. '%.%#Compiling file%.%# -> %f:%l:%c%.%#'



local dirtyfix_group = vim.api.nvim_create_augroup('dirtyfix_group', { clear = true })
vim.api.nvim_create_autocmd('BufEnter', { pattern = '*', command = "set noexpandtab", group = dirtyfix_group })
