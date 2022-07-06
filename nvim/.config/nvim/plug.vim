" TODO: UNDERSTAND THAT
if has("nvim")
    let g:plug_home = stdpath('data') . '/plugged'
endif

call plug#begin(stdpath('data') . '/plugged')

Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-rhubarb'

Plug 'tpope/vim-surround'
Plug 'tpope/vim-abolish'
Plug 'tpope/vim-eunuch'
Plug 'tpope/vim-unimpaired'

Plug 'godlygeek/tabular'

Plug 'tree-sitter/tree-sitter', { 'do': 'TSUpdate' }

Plug 'iamcco/markdown-preview.nvim', { 'do': 'cd app && yarn install'  }

Plug 'vimwiki/vimwiki'

Plug 'easymotion/vim-easymotion'

Plug 'unblevable/quick-scope'

Plug 'romainl/vim-cool'

Plug 'rust-lang/rust.vim'

Plug 'preservim/nerdtree'

Plug 'alx741/vinfo'

Plug 'KabbAmine/vCoolor.vim'

Plug 'mg979/vim-visual-multi'

" Theme
Plug 'morhetz/gruvbox'


if has("nvim")
    Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}

    " LSP + autocomplete
    Plug 'neovim/nvim-lspconfig'
"    Plug 'glepnir/lspsaga.nvim'
"    Plug 'folke/lsp-colors.nvim'
	Plug 'hrsh7th/nvim-cmp'
	Plug 'hrsh7th/cmp-nvim-lsp'
	Plug 'hrsh7th/cmp-buffer'
	Plug 'hrsh7th/cmp-path'
	Plug 'hrsh7th/cmp-cmdline'
	Plug 'onsails/lspkind-nvim'
	Plug 'nvim-lua/lsp_extensions.nvim'
	Plug 'ray-x/guihua.lua', {'do': 'cd lua/fzy && make' }
	Plug 'ray-x/navigator.lua'
	Plug 'ray-x/lsp_signature.nvim'

    " Telescope
    Plug 'nvim-lua/plenary.nvim'
    Plug 'nvim-telescope/telescope.nvim'
    Plug 'nvim-telescope/telescope-fzy-native.nvim'
	Plug 'nvim-lua/popup.nvim'


	Plug 'terrortylor/nvim-comment'
	Plug 'lukas-reineke/indent-blankline.nvim'

	Plug 'ThePrimeagen/harpoon'
	Plug 'ThePrimeagen/git-worktree.nvim'
	Plug 'ThePrimeagen/vim-be-good'

	" Status line
	Plug 'feline-nvim/feline.nvim'
	Plug 'kyazdani42/nvim-web-devicons'
	Plug 'lewis6991/gitsigns.nvim' " requires Plenary

	" Plug 'hoob3rt/lualine.nvim'


	Plug 'p00f/nvim-ts-rainbow'

	Plug 'rmagatti/auto-session'

	Plug 'williamboman/nvim-lsp-installer'

	Plug 'ldelossa/litee.nvim'
	Plug 'ldelossa/litee-calltree.nvim'
endif

call plug#end()
