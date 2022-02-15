if exists('g:vscode')
	runtime ./vscode.vim
	finish
endif
" {{{ set

set nocompatible
set relativenumber
set number
set scrolloff=8
set shiftwidth=4
set tabstop=4
" set listchars=tab:\|\ 
set list
set title
set ignorecase
set smartcase
set path+=**
set wildignore+=*/node_modules/*
set history=200
" TODO: following does not seem to work
set formatoptions-=o " don't insert current comment leader when pressing o / O in normal mode
filetype plugin on
" }}}

command! MakeTags !ctags -R .



" {{{ THEME (note: has to be before LSP initialisation for some reasons 
if exists("&termguicolors") && exists("&winblend")
	syntax enable
	set termguicolors

	let g:gruvbox_invert_selection='0'
	let g:gruvbox_contrast_dark = 'hard'

	colorscheme gruvbox
	set background=dark
endif
" }}}



runtime ./plug.vim



set guifont=FiraCode:h16

" Compiling file: obj/encode/json/print.o -> src/encode/json/print.c:186:78: error: format sp
set errorformat+=%.%#Compiling\ file%.%#\ ->\ %f:%l:%c%.%#

" {{{ MAPS 

let mapleader = " "

nmap <leader><leader>z i" {{{occo" }}}kkA 

cnoremap <expr> %% getcmdtype() == ':' ? expand('%:h').'/' : '%%'

" {{{ Map Colemak-dh movements keys

"noremap m h
"noremap n j
"noremap e k
"noremap i l
"
"noremap h m
"noremap j n
"noremap k e
"noremap l i
"
"noremap M H
"noremap N J
"noremap E K
"noremap I L
"
"noremap H M
"noremap J N
"noremap K E
"noremap L I

" }}}

noremap <Left> h
noremap <Up> k
noremap <Down> j
noremap <Right> l


" Don't jump to next match on * press
nnoremap * *``

" Quick vimrc edit
nnoremap <leader>v :e $MYVIMRC<CR>
nnoremap <leader>c :w<CR><C-^>:source $MYVIMRC<CR>

" {{{ Go to tab by number 

noremap <leader>1 1gt
noremap <leader>2 2gt
noremap <leader>3 3gt
noremap <leader>4 4gt
noremap <leader>5 5gt
noremap <leader>6 6gt
noremap <leader>7 7gt
noremap <leader>8 8gt
noremap <leader>9 9gt

" }}}


" {{{ Git remaps 

nnoremap <leader>gs :G<CR>
nnoremap <leader>gg :diffger //3<CR>
nnoremap <leader>gm :diffger //2<CR>

" }}}

" TODO: this prevents me from navigating with { and } motions...
" {{{ My version of 'unimpaired' using {} instead of [] because it's easier for me 

nnoremap {q :cprevious<CR>
nnoremap }q :cnext<CR>

" }}}

" rename with substitute cmd
map <leader><leader>re yiw:%s///g<c-F>hhhhpla

" }}}

" {{{ Plugins

" {{{ vimwiki

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

" Custom 'create a link' remaps for wikipedia wiki markdown
nnoremap <leader><CR> gewi[[<C-[>ea]]<C-[>
vnoremap <leader><CR> <C-[>a]]<C-[>`<i[[<C-[>%l


" Custom command to open Avesterra wiki
nnoremap <leader>wk :e ~/dev/ledr/Orchestra-AvesTerra.wiki/Home.md<CR>

" }}}

" {{{ Telescope

lua<<EOF
local actions = require('telescope.actions')

require('telescope').setup {
	defaults = {
		file_sorter = require('telescope.sorters').get_fzy_sorter,
		prompt_prefix = ' >',

		file_previewer   = require('telescope.previewers') .vim_buffer_cat.new,
		grep_previewer   = require('telescope.previewers') .vim_buffer_vimgrep.new,
		qflist_previewer = require('telescope.previewers') .vim_buffer_qflist.new,
		},
	extensions = {
		fzy_native = { 
			override_generic_sorter = false,
			override_file_sorter = true,
			}
		}
}

require('telescope').load_extension('fzy_native')

vim.api.nvim_set_keymap("n", "<leader>ff"        , ":Telescope find_files<CR>"               , { noremap = true})
vim.api.nvim_set_keymap("n", "<leader>fr"        , ":Telescope registers<CR>"                , { noremap = true})
vim.api.nvim_set_keymap("n", "<leader>fg"        , ":Telescope live_grep<CR>"                , { noremap = true})
vim.api.nvim_set_keymap("n", "<leader>fh"        , ":Telescope help_tags<CR>"                , { noremap = true})
vim.api.nvim_set_keymap("n", "<leader><leader>ff", ":Telescope current_buffer_fuzzy_find<CR>", { noremap = true})
EOF

" }}}

" {{{ Harpoon

lua<<EOF
require("harpoon").setup({})
require("telescope").load_extension('harpoon')

EOF

nnoremap <leader>m :lua require("harpoon.mark").add_file()<CR>
nnoremap <leader>fm :Telescope harpoon marks<CR>

" }}}

" }}}

" vim: foldlevel=1 foldmethod=marker
