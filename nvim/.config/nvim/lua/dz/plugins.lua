local ensure_packer = function()
	local fn = vim.fn
	local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
	if fn.empty(fn.glob(install_path)) > 0 then
		vim.print('bootstraping packer')
		fn.system({'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path})
		vim.cmd [[packadd packer.nvim]]
		return true
	end
	return false
end
local packer_bootstrap = ensure_packer()

require('packer').startup(function(use)

	-- Core
	use  'wbthomason/packer.nvim'
	use {'nvim-treesitter/nvim-treesitter', run = ':TSUpdate' }
	use  'nvim-treesitter/playground'
	use { "luckasRanarison/tree-sitter-hypr" }


	-- Telescope

	use {'nvim-telescope/telescope.nvim', requires = 'nvim-lua/plenary.nvim' }
	use  'BurntSushi/ripgrep'
	use {'nvim-telescope/telescope-fzf-native.nvim', run = 'make' }
	use  'LinArcX/telescope-env.nvim'
	-- check out https://github.com/nvim-telescope/telescope.nvim/wiki/Extensions lol

	-- Navigation
	use  'ThePrimeagen/harpoon'

	-- LSP + autocomplete
	use  'neovim/nvim-lspconfig'
	use  'williamboman/mason.nvim'

	use  'hrsh7th/nvim-cmp'
	use  'hrsh7th/cmp-nvim-lsp'
	use  'hrsh7th/cmp-nvim-lua'
	use  'hrsh7th/cmp-buffer'
	use  'hrsh7th/cmp-path'
	use  'hrsh7th/cmp-cmdline'
	use  'onsails/lspkind.nvim' -- icons in the completion list
	use  'ray-x/lsp_signature.nvim'
	use {'L3MON4D3/LuaSnip', tag = 'v2.*', run = 'make install_jsregexp' }
	use {'j-hui/fidget.nvim', tag = 'legacy', config = function() require('fidget').setup({}) end }

	use  'zbirenbaum/copilot.lua'
	use  'zbirenbaum/copilot-cmp'


	-- Language specific
	use  'euclidianAce/BetterLua.vim'
	use  'simrat39/rust-tools.nvim'
	-- use 'tjdevries/nlua.nvim' -- check if hrsh7th/cmp-nvim-lua isn't enough
	use  'folke/neodev.nvim'
	use  'Saecki/crates.nvim'
	use  'tigion/nvim-asciidoc-preview'
	use {
		'iamcco/markdown-preview.nvim',
		run = 'cd app && npm install',
		setup = function() vim.g.mkdp_filetypes = { 'markdown' } end,
		ft = { 'markdown' },
	}


	-- Git
	use {'lewis6991/gitsigns.nvim', config = function() require('gitsigns').setup() end }
	use {'tpope/vim-fugitive', requires = 'tpope/vim-rhubarb' }
	use {'rbong/vim-flog'}

	-- look
	use  'ellisonleao/gruvbox.nvim'
	use {'kyazdani42/nvim-web-devicons', config = function() require('nvim-web-devicons').setup() end }
	use {'lukas-reineke/indent-blankline.nvim', tag = 'v2.20.8' }
	use 'nvim-treesitter/nvim-treesitter-context'
	use 'rcarriga/nvim-notify'
	use  'feline-nvim/feline.nvim'
	use  'mbbill/undotree'
	use  'simrat39/symbols-outline.nvim'
	use {'norcalli/nvim-colorizer.lua', config = function() require('colorizer').setup() end }


	-- Debug
	use {'mfussenegger/nvim-dap'}
	use {'mfussenegger/nvim-dap-python'}
	use {'theHamsta/nvim-dap-virtual-text', config = function() require('nvim-dap-virtual-text').setup({}) end }
	use {'nvim-telescope/telescope-dap.nvim'}
	use {'rcarriga/nvim-dap-ui', requires = {'mfussenegger/nvim-dap'} }
	use {'leoluz/nvim-dap-go'}



	-- misc
	use {'rmagatti/auto-session', config = function() require('auto-session').setup({}) end }
	use  'numToStr/Comment.nvim'
	use  'godlygeek/tabular'
	use  'romainl/vim-cool'
	use  'mg979/vim-visual-multi'
	use  'preservim/nerdtree'
	use {'kylechui/nvim-surround', config = function() require("nvim-surround").setup({}) end }
	use  'tpope/vim-abolish'
	use  'tpope/vim-eunuch'
	use  'tpope/vim-unimpaired'
	use  'jinh0/eyeliner.nvim'
	use  'mechatroner/rainbow_csv'
	use {'nvim-pack/nvim-spectre', config = function() require('spectre').setup({}) end }
	use {'Wansmer/treesj', requires = { 'nvim-treesitter' }}
	use {'jose-elias-alvarez/null-ls.nvim'}

	use {'windwp/nvim-autopairs', config = function() require('nvim-autopairs').setup({}) end }

	use { 'nvim-neorg/neorg', run = ':Neorg sync-parsers', requires = "nvim-lua/plenary.nvim" }


	if packer_bootstrap then
		require('packer').sync()
	end
end)

