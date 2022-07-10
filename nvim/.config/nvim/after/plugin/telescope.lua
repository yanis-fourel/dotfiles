local actions = require('telescope.actions')

require('telescope').load_extension('fzf')

require('telescope').setup {
	defaults = {
		mappings = {
			i = {
				['<C-q>'] = actions.smart_add_to_qflist + actions.open_qflist,
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

vim.api.nvim_set_keymap("n", "<leader>ff"        , ":Telescope find_files<CR>"               , { noremap = true})
vim.api.nvim_set_keymap("n", "<leader>fr"        , ":Telescope registers<CR>"                , { noremap = true})
vim.api.nvim_set_keymap("n", "<leader>fg"        , ":Telescope live_grep<CR>"                , { noremap = true})
vim.api.nvim_set_keymap("n", "<leader>fh"        , ":Telescope help_tags<CR>"                , { noremap = true})
vim.api.nvim_set_keymap("n", "<leader><leader>ff", ":Telescope current_buffer_fuzzy_find<CR>", { noremap = true})
