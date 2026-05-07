return {
	"neovim-treesitter/nvim-treesitter",
	dependencies = {
		"neovim-treesitter/treesitter-parser-registry",
		"luckasRanarison/tree-sitter-hypr",
		"lewis6991/ts-install.nvim",
	},
	lazy = false,
	build = ":TSUpdate",
	config = function()
		require("nvim-treesitter").setup({
			local_parsers = {
				hypr = {
					source = {
						type = "self_contained",
						url = "https://github.com/luckasRanarison/tree-sitter-hypr",
						queries_path = "nvim-queries/hypr",
					},
					filetypes = { "hypr" },
				},
			},
		})
		require("ts-install").setup({
			-- Automatically install missing parsers when you open a file
			auto_install = true,
			ensure_install = {
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
				"javascript", -- The three must be installed together to supress
				"typescript", -- warnings
				"jsx",
			},
		})
	end,
}
