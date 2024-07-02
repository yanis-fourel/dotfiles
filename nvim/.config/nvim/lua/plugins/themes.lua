return {
	"ellisonleao/gruvbox.nvim",
	priority = 1000,
	dependencies = {
		"sainnhe/everforest",
		"folke/tokyonight.nvim",
		"EdenEast/nightfox.nvim",
		"sainnhe/sonokai",
		{ "navarasu/onedark.nvim", opts = { style = "darker" } },
		{ "catppuccin/nvim", name = "catppuccin", opts = { integrations = { diffview = true } } },
	},
	init = function()
		vim.keymap.set("n", "<leader>fc", function()
			require("telescope.builtin").colorscheme({ enable_preview = true })
		end, { desc = "[F]ind [C]olorscheme" })

		vim.g.backround = "dark"
		vim.g.everforest_background = "hard"

		vim.cmd.colorscheme("tokyonight-storm")
	end,
}
