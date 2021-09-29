" TODO: UNDERSTAND THAT
if has("nvim")
	let g:plug_home = stdpath('data') . '/plugged'
endif

call plug#begin(stdpath('data') . '/plugged')

Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-rhubarb'
" Plug 'neoclide/coc.nvim', {'branch': 'release'}

" Theme
Plug 'morhetz/gruvbox'

if has("nvim")
		Plug 'neovim/nvim-lspconfig'
		Plug 'glepnir/lspsaga.nvim'
		Plug 'folke/lsp-colors.nvim'
		Plug 'hrsh7th/nvim-compe'
endif

call plug#end()
