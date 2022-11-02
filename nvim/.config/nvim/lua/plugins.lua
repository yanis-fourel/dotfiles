require('packer').startup(function(use)

	-- Core
	use  'wbthomason/packer.nvim'
	use {'nvim-treesitter/nvim-treesitter', run = ':TSUpdate' }
	use  'nvim-treesitter/playground'


	-- Telescope

	use {'nvim-telescope/telescope.nvim', requires = 'nvim-lua/plenary.nvim' }
	use  'BurntSushi/ripgrep'
	use {'nvim-telescope/telescope-fzf-native.nvim', run = 'make' }
	-- check out https://github.com/nvim-telescope/telescope.nvim/wiki/Extensions lol

	-- LSP + autocomplete
	use  'neovim/nvim-lspconfig'
	use  'williamboman/nvim-lsp-installer'

	use  'hrsh7th/nvim-cmp'
	use  'hrsh7th/cmp-nvim-lsp'
	use  'hrsh7th/cmp-nvim-lua'
	use  'hrsh7th/cmp-buffer'
	use  'hrsh7th/cmp-path'
	use  'hrsh7th/cmp-cmdline'
	use  'onsails/lspkind.nvim' -- icons in the completion list
	use  'ray-x/lsp_signature.nvim'
	use  'L3MON4D3/LuaSnip'

	use  'simrat39/rust-tools.nvim'

	-- LUA
	use 'euclidianAce/BetterLua.vim'
	-- use 'tjdevries/nlua.nvim' -- check if hrsh7th/cmp-nvim-lua isn't enough

	-- Git
	use {'lewis6991/gitsigns.nvim', config = function() require('gitsigns').setup() end }
	use {'tpope/vim-fugitive', requires = 'tpope/vim-rhubarb' }

	-- look
	use  'ellisonleao/gruvbox.nvim'
	use {'kyazdani42/nvim-web-devicons', config = function() require('nvim-web-devicons').setup() end }
	use  'lukas-reineke/indent-blankline.nvim'
	use {'norcalli/nvim-colorizer.lua', config = function() require('colorizer').setup() end }
	use 'nvim-treesitter/nvim-treesitter-context'


	use  'feline-nvim/feline.nvim'

	-- misc
	use {'rmagatti/auto-session', config = function() require('auto-session').setup({}) end }
	use  'numToStr/Comment.nvim'
	use  'godlygeek/tabular'
	use  'romainl/vim-cool'
	use  'mg979/vim-visual-multi'
	use  'preservim/nerdtree'
	use  'tpope/vim-surround'
	use  'tpope/vim-abolish'
	use  'tpope/vim-eunuch'
	use  'tpope/vim-unimpaired'
	-- use  'tpope/vim-sleuth'
	use  'vimwiki/vimwiki'
	use {'unblevable/quick-scope', config = function() vim.cmd( -- config doesn't work if ran in 'after/plugin'
		[[
			let g:qs_highlight_on_keys = ['f', 'F', 't', 'T']

			highlight QuickScopePrimary guifg='#5fffff' gui=underline ctermfg=155 cterm=underline
			highlight QuickScopeSecondary guifg='#999999' gui=underline ctermfg=81 cterm=underline
		]])
	end }
	use  'mechatroner/rainbow_csv'
	use  'drybalka/tree-climber.nvim'
end)

