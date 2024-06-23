return {
	"nvim-telescope/telescope.nvim",
	event = "VimEnter",
	branch = "0.1.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		{ -- If encountering errors, see telescope-fzf-native README for installation instructions
			"nvim-telescope/telescope-fzf-native.nvim",
			build = "make",
			cond = function()
				return vim.fn.executable("make") == 1
			end,
		},
		{ "nvim-telescope/telescope-ui-select.nvim" },
		{ "nvim-tree/nvim-web-devicons", enabled = vim.g.have_nerd_font },
	},
	config = function()
		-- [[ Configure Telescope ]]
		-- See `:help telescope` and `:help telescope.setup()`
		require("telescope").setup({
			defaults = {
				layout_strategy = "horizontal",
				layout_config = {
					width = 0.95,
					height = 0.85,
					-- preview_cutoff = 120,
					prompt_position = "top",

					horizontal = {
						preview_width = function(_, cols, _)
							if cols > 200 then
								return math.floor(cols * 0.4)
							else
								return math.floor(cols * 0.6)
							end
						end,
					},

					vertical = {
						width = 0.9,
						height = 0.95,
						preview_height = 0.5,
					},

					flex = {
						horizontal = {
							preview_width = 0.9,
						},
					},
				},

				sorting_strategy = "ascending",
				file_sorter = require("telescope.sorters").get_fzf_sorter,

				file_previewer = require("telescope.previewers").vim_buffer_cat.new,
				grep_previewer = require("telescope.previewers").vim_buffer_vimgrep.new,
				qflist_previewer = require("telescope.previewers").vim_buffer_qflist.new,
			},
			extensions = {
				["ui-select"] = {
					require("telescope.themes").get_dropdown(),
				},
			},
		})

		-- Enable Telescope extensions if they are installed
		pcall(require("telescope").load_extension, "fzf")
		pcall(require("telescope").load_extension, "ui-select")

		-- See `:help telescope.builtin`
		local builtin = require("telescope.builtin")

		vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "[F]ind [F]iles" })
		vim.keymap.set("n", "<leader>fr", builtin.registers, { desc = "[F]ind [R]egister" })
		vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "[Find] with [G]rep" })
		vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "[F]ind [H]elp" })
		vim.keymap.set("n", "<leader>fk", builtin.keymaps, { desc = "[F]ind [K]eymaps" })
		vim.keymap.set("n", "<leader>fb", builtin.builtin, { desc = "[F]ind Telescope [Builtin]" })
		vim.keymap.set("n", "<leader>fw", builtin.grep_string, { desc = "[F]ind current [W]ord" })
		vim.keymap.set("n", "<leader>fd", builtin.diagnostics, { desc = "[F]ind [D]iagnostics" })
		vim.keymap.set("n", "<leader>fs", builtin.resume, { desc = "[F]ind re[S]ume" })
		vim.keymap.set("n", "<leader>f.", builtin.oldfiles, { desc = "[F]ind Recent Files" })
		vim.keymap.set("n", "<leader><leader>", builtin.buffers, { desc = "[ ] Find existing buffers" })
		vim.keymap.set(
			"n",
			"<leader>/",
			builtin.current_buffer_fuzzy_find,
			{ desc = "[/] Fuzzily search in current buffer" }
		)
		-- TODO: add pluging for that
		-- vim.keymap.set('n', '<leader>fe', '<cmd>Telescope env<CR>')

		vim.keymap.set("n", "<leader>f/", function()
			builtin.live_grep({
				grep_open_files = true,
				prompt_title = "Live Grep in Open Files",
			})
		end, { desc = "[F]ind [/] in Open Files" })

		vim.keymap.set("n", "<leader>fn", function()
			builtin.find_files({ cwd = vim.fn.stdpath("config") })
		end, { desc = "[F]earch [N]eovim files" })
	end,
}
