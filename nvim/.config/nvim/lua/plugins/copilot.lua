return {
	"zbirenbaum/copilot.lua",
	cmd = "Copilot",
	event = "InsertEnter",
	opts = {
		filetypes = {
			["*"] = true,
			markdown = false,
		},
		suggestion = {
			auto_trigger = true,
			keymap = {
				accept = "<Right>",
			},
		},
		-- panel = {
		-- 	keymap = {
		-- 		accept = "<Right>",
		-- 	},
		-- },
	},
}
