return {
	"nvim-treesitter/nvim-treesitter",
	dependencies = {
		"luckasRanarison/tree-sitter-hypr",
	},
	build = ":TSUpdate",
	opts = {
		ensure_installed = {
			"bash",
			"c",
			"cpp",
			"diff",
			"html",
			"lua",
			"luadoc",
			"markdown",
			"vim",
			"vimdoc",
			"rust",
			"python",
			"json",
			"yaml",
		},
		auto_install = true,
		highlight = {
			enable = true,
			-- Some languages depend on vim's regex highlighting system (such as Ruby) for indent rules.
			--  If you are experiencing weird indenting issues, add the language to
			--  the list of additional_vim_regex_highlighting and disabled languages for indent.
			additional_vim_regex_highlighting = { "ruby" },
		},
		indent = { enable = true, disable = { "ruby" } },
	},
	config = function(_, opts)
		-- Prefer git instead of curl in order to improve connectivity in some environments
		require("nvim-treesitter.install").prefer_git = true
		require("nvim-treesitter.configs").setup(opts)

		require("nvim-treesitter.parsers").hypr = {
			install_info = {
				url = "https://github.com/luckasRanarison/tree-sitter-hypr",
				files = { "src/parser.c" },
				branch = "master",
			},
			filetype = "hypr",
		}

		-- There are additional nvim-treesitter modules that you can use to interact
		-- with nvim-treesitter. You should go explore a few and see what interests you:
		--
		--    - Incremental selection: Included, see `:help nvim-treesitter-incremental-selection-mod`
		--    - Show your current context: https://github.com/nvim-treesitter/nvim-treesitter-context
		--    - Treesitter + textobjects: https://github.com/nvim-treesitter/nvim-treesitter-textobjects
	end,
}
