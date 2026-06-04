return {
	"supermaven-inc/supermaven-nvim",
	event = "InsertEnter",
	opts = {
		keymaps = {
			accept_suggestion = "<Right>",
			clear_suggestion = "<C-]>",
			accept_word = "<C-j>",
		},
		ignore_filetypes = { markdown = true },
		disable_inline_completion = false,
		disable_keymaps = false,
	},
}
