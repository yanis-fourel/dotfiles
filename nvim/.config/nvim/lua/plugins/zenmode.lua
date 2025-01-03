return {
	"folke/zen-mode.nvim",
	requirements = {
		"folke/twilight.nvim",
	},
	opts = {},
	init = function()
		vim.keymap.set("n", "<leader>zm", ":ZenMode<CR>", { desc = "[Z]en [M]ode" })
	end,
}
