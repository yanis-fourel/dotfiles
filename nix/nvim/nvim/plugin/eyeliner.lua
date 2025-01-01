require("eyeliner").setup {
	highlight_on_key = true,
	dim = true,
}

vim.api.nvim_set_hl(0, "EyelinerPrimary", { fg = "#5fffff", underline = true })
vim.api.nvim_set_hl(0, "EyelinerSecondary", { fg = "#999999", underline = true })
