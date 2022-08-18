local actions = require('telescope.actions')
local tele_builtin = require('telescope.builtin')


require('telescope').load_extension('fzf')

require('telescope').setup {
	defaults = {
		mappings = {
			i = {
				['<C-q>'] = actions.smart_add_to_qflist + actions.open_qflist,
			},
		},
		path_display = { truncate = 2 } ,
		dynamic_preview_title = true,

		winblend = 0,

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
		file_sorter = require('telescope.sorters').get_fzf_sorter,

		file_previewer   = require('telescope.previewers') .vim_buffer_cat.new,
		grep_previewer   = require('telescope.previewers') .vim_buffer_vimgrep.new,
		qflist_previewer = require('telescope.previewers') .vim_buffer_qflist.new,
	},
	extensions = {
		fzf = {
			fuzzy = true,                    -- false will only do exact matching
			override_generic_sorter = true,  -- override the generic sorter
			override_file_sorter = true,     -- override the file sorter
			case_mode = "smart_case",        -- or "ignore_case" or "respect_case"
			-- the default case_mode is "smart_case"
		}
	}
}

vim.keymap.set("n", "<leader>ff"        , function() tele_builtin.find_files() end)
vim.keymap.set("n", "<leader>fp"        , function() tele_builtin.oldfiles() end)
vim.keymap.set("n", "<leader>fr"        , function() tele_builtin.registers() end)
vim.keymap.set("n", "<leader>fg"        , function() tele_builtin.live_grep() end)
vim.keymap.set("n", "<leader>fh"        , ":Telescope help_tags<CR>"                , { noremap = true})
vim.keymap.set("n", "<leader><leader>ff", ":Telescope current_buffer_fuzzy_find<CR>", { noremap = true})
