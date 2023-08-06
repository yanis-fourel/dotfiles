-- do return end


require('copilot').setup({
	panel = {
		enabled = false,
		auto_refresh = true,
		keymap = {
			-- jump_prev = "[[",
			-- jump_next = "]]",
			-- accept = "<C-n>",
			-- refresh = "gr",
			-- open = "<M-CR>"
		},
		layout = {
			position = "top", -- | top | left | right
			ratio = 0.4
		},
	},
	suggestion = {
		enabled = true,
		auto_trigger = true,
		debounce = 0,
		keymap = {
			-- accept = "<C-S-n>",
			-- accept_word = false,
			-- accept_line = false,
			-- next = "<C-]>",
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
	copilot_node_command = 'node', -- Node.js version must be > 16.x
	server_opts_overrides = {},
})

vim.keymap.set('i', '<C-S-n>', require('copilot.suggestion').accept)
vim.keymap.set('i', '<C-S-e>', require('copilot.suggestion').next)
