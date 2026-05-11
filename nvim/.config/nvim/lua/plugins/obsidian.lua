return {
	"epwalsh/obsidian.nvim",
	version = "*", -- recommended, use latest release instead of latest commit
	lazy = true,
	ft = "markdown",
	dependencies = {
		-- Required.
		"nvim-lua/plenary.nvim",
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
