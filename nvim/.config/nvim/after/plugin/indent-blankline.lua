vim.cmd(
[[
	let g:indent_blankline_show_first_indent_level = v:true
	let g:indent_blankline_use_treesitter = v:true
	let g:indent_blankline_use_treesitter_scope = v:true
	let g:indent_blankline_show_trailing_blankline_indent = v:false

	highlight IndentBlanklineContextChar guifg=#66FF66 gui=nocombine
	highlight IndentBlanklineSpaceChar   guifg=#303030 gui=nocombine
]])


vim.opt.list = true
vim.opt.listchars:append('space:⋅')
vim.opt.listchars:append('trail:⋅')
vim.opt.listchars:append('tab:▷ ')

require('indent_blankline').setup {
	show_current_context = false,
	space_char_blankline = ' ',
}

