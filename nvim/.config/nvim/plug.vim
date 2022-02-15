" TODO: UNDERSTAND THAT
if has("nvim")
    let g:plug_home = stdpath('data') . '/plugged'
endif

call plug#begin(stdpath('data') . '/plugged')

Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-rhubarb'

Plug 'godlygeek/tabular'
Plug 'romainl/vim-cool'

Plug 'tree-sitter/tree-sitter', { 'do': 'TSUpdate' }

Plug 'iamcco/markdown-preview.nvim', { 'do': 'cd app && yarn install'  }

Plug 'mhartington/formatter.nvim'

Plug 'easymotion/vim-easymotion'

Plug 'tpope/vim-surround'

Plug 'tpope/vim-abolish'

Plug 'vimwiki/vimwiki'

" Theme
Plug 'morhetz/gruvbox'

if has("nvim")
    Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}

    " LSP + autocomplete
    Plug 'neovim/nvim-lspconfig'
"    Plug 'glepnir/lspsaga.nvim'
"    Plug 'folke/lsp-colors.nvim'
	Plug 'hrsh7th/cmp-nvim-lsp'
	Plug 'hrsh7th/cmp-buffer'
	Plug 'hrsh7th/cmp-path'
	Plug 'hrsh7th/cmp-cmdline'
	Plug 'hrsh7th/nvim-cmp'
	Plug 'ray-x/guihua.lua', {'do': 'cd lua/fzy && make' }
	Plug 'ray-x/navigator.lua'
	Plug 'ray-x/lsp_signature.nvim'

    " Telescope
    Plug 'nvim-lua/plenary.nvim'
    Plug 'nvim-telescope/telescope.nvim'
    Plug 'nvim-telescope/telescope-fzy-native.nvim'


	Plug 'terrortylor/nvim-comment'
	Plug 'lukas-reineke/indent-blankline.nvim'

	Plug 'ThePrimeagen/harpoon'

endif

call plug#end()
