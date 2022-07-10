vim.o.encoding       = 'utf-8'
vim.o.relativenumber = true
vim.o.number         = true
vim.o.scrolloff      = 8
vim.o.shiftwidth     = 4
vim.o.tabstop        = 4
vim.o.list           = true
vim.o.title          = true
vim.o.ignorecase     = true
vim.o.smartcase      = true
vim.o.path           = vim.o.path .. '**'
vim.o.wildignore     = vim.o.wildignore .. '**/node_modules/*'
vim.o.history        = 200
vim.o.wrap           = true
vim.o.linebreak      = true
vim.o.undodir        = os.getenv("HOME") .. '/.nvim_undodir'
vim.o.undofile       = true
vim.o.guifont        = 'FiraCode:h16'
vim.o.mouse          = 'a'
vim.o.laststatus     = 3
vim.o.termguicolors  = true

-- Compiling file: obj/encode/json/print.o -> src/encode/json/print.c:186:78: error: format sp
vim.o.errorformat = vim.o.errorformat .. '%.%#Compiling file%.%# -> %f:%l:%c%.%#'
