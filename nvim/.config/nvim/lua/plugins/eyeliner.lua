return {
	"jinh0/eyeliner.nvim",
	opts = {
		highlight_on_key = true,
	},
	init = function()
		vim.api.nvim_set_hl(0, "EyelinerPrimary", { fg = "#5fffff", underline = true })
		vim.api.nvim_set_hl(0, "EyelinerSecondary", { fg = "#999999", underline = true })
	end,
}
