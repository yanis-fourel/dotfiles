require('neorg').setup {
	load = {
		["core.defaults"] = {}, -- Loads default behaviour
		["core.concealer"] = {}, -- Adds pretty icons to your documents
		["core.dirman"] = { -- Manages Neorg workspaces
			config = {
				workspaces = {
					mega = "~/MEGA/neorg/",
				},
			},
		},
		["core.journal"] = {
			config = {
				workspace = "mega"
			}
		}
	},
}

vim.keymap.set('n', '<leader>td', function ()
	vim.cmd("Neorg journal today")
	vim.api.nvim_set_current_dir("~/MEGA/neorg/journal/")
	local win = vim.api.nvim_get_current_win()
	vim.cmd("NERDTreeFind")
	vim.api.nvim_set_current_win(win)
	vim.cmd("NERDTreeCWD")
	vim.api.nvim_set_current_win(win)
end)
