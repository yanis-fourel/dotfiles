vim.g.mapleader = ' '

require('options')
require('maps')
require('plugins')

require('ui')
require('lsp')


--[[
TODOS:

* fix last bindings
* make telescope preview wider
* check the rust capabilities for LSP, and maybe fix the 'receive end before begin' error
* sexy code_action with telescope
* check out treesitter extensions https://github.com/nvim-treesitter/nvim-treesitter/wiki/Extra-modules-and-plugins
* nvim-treesitter/nvim-treesitter-context
* different color of highlight for luasnip ? + cool luasnip config additons ?

* which-key (and integrate with telescope, see https://github.com/nvim-telescope/telescope.nvim#telescope-setup-structure)

* custom plugins (see tw)

]]--

