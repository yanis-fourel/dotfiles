vim.cmd(
[[
	let g:vimwiki_list = [{
				\ 'path': '~/vimwiki',
				\ 'auto_diary_index': 1,
				\ }, {
				\ 'path': '~/dev/ledr/Orchestra-AvesTerra.wiki/',
				\ 'syntax': 'markdown',
				\ 'ext': '.md'
				\ }]

	" Whether vimwiki should treat all files with given (or default .wiki) extension as wiki files.
	let g:vimwiki_global_ext = 0
]])

-- Custom 'create a link' remaps for wikipedia wiki markdown
vim.keymap.set('n', '<leader><CR>', 'gewi[[<C-[>ea]]<C-[>')
vim.keymap.set('v', '<leader><CR>', '<C-[>a]]<C-[>`<i[[<C-[>%l')


-- Custom command to open Avesterra wiki
vim.keymap.set('n', '<leader><leader>wk', ':e ~/dev/ledr/Orchestra-AvesTerra.wiki/Home.md<CR>')

