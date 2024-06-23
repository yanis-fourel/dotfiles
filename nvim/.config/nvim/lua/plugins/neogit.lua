return {
	"NeogitOrg/neogit",
	dependencies = {
		"nvim-lua/plenary.nvim", -- required
		{ "sindrets/diffview.nvim", opt = { enhanced_diff_hl = true } }, -- optional - Diff integration
		"tummychow/git-absorb", -- optional

		-- Only one of these is needed, not both.
		"nvim-telescope/telescope.nvim", -- optional
		-- "ibhagwan/fzf-lua", -- optional
	},
	config = true,
	init = function()
		local neogit = require("neogit")

		vim.keymap.set("n", "<leader>gs", neogit.open, { desc = "[G]it [S]tatus (and more)" })
	end,
}
