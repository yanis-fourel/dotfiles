return {
	"zbirenbaum/copilot.lua",
	event = "InsertEnter",
	dependencies = {
		"zbirenbaum/copilot-cmp",
	},
	opts = {
		panel = {
			enabled = false,
		},
		suggestion = {
			enabled = true,
			auto_trigger = true,
			debounce = 0,
			keymap = {
				accept = "<Right>",
				-- accept_word = false,
				-- accept_line = false,
				-- next = "<C-Enter>",
				-- prev = "<C-[>",
				-- dismiss = "<C-]>",
			},
		},
		filetypes = {
			yaml = true,
			markdown = false,
			help = false,
			gitcommit = false,
			gitrebase = true,
			hgcommit = true,
			svn = false,
			cvs = false,
			["."] = false,
		},
		copilot_node_command = "node", -- Node.js version must be > 16.x
		server_opts_overrides = {},
	},
}
