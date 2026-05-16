return {
	"epwalsh/obsidian.nvim",
	version = "*", -- recommended, use latest release instead of latest commit
	lazy = true,
	ft = "markdown",
	cmd = { "ObsidianDailies", "ObsidianToday", "ObsidianQuickSwitch" },
	dependencies = {
		-- Required.
		"nvim-lua/plenary.nvim",
	},
	keys = {
		{ "<leader>f<leader>", "<cmd>ObsidianDailies<CR>", desc = "Obsidian [D]ailies" },
		{ "<leader>fo", "<cmd>ObsidianQuickSwitch<CR>", desc = "Find [O]bsidian notes" },
	},
	opts = {
		workspaces = {
			{
				name = "vault",
				path = "~/vault",
			},
		},
		ui = {
			enable = false, -- already have nice markdown preview
		},
		daily_notes = {
			folder = "daily/",
			date_format = "%Y-%m-%d",
			default_tags = { "daily" },
			template = nil,
		},
	},
}
