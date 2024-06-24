-- Neo-tree is a Neovim plugin to browse the file system
-- https://github.com/nvim-neo-tree/neo-tree.nvim

return {
	"nvim-neo-tree/neo-tree.nvim",
	version = "*",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
		"MunifTanjim/nui.nvim",
	},
	cmd = "Neotree",
	opts = {
		filesystem = {
			window = {
				mappings = {
					["\\"] = "close_window",
				},
			},
		},
	},
	init = function()
		vim.keymap.set("n", "<leader>pl", function()
			local glob = vim.fn.stdpath("config") .. "**/plugins/"
			local plugindir = vim.fn.glob(glob)
			vim.cmd(":Neotree dir=" .. plugindir)
		end, { desc = "Open [PL]ugin dir" })
		vim.keymap.set("n", "<leader>e", function()
			local curr_buf = vim.fn.expand("%")
			if vim.fn.filereadable(curr_buf) == 1 then
				vim.cmd(":Neotree reveal_file=" .. curr_buf)
			else
				vim.cmd(":Neotree toggle")
			end
		end, { desc = "Toggle neo-tree" })
	end,
}
