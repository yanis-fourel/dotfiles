
set nocompatible
set relativenumber
set number
set scrolloff=8
set shiftwidth=4
set tabstop=4
set listchars=tab:\|\ 
set list
set title
set ignorecase
set smartcase
set path+=**
set wildignore+=*/node_modules/*
set history=200
" TODO: following does not seem to work
set formatoptions-=o " don't insert current comment leader when pressing o / O in normal mode

command! MakeTags !ctags -R .



""" THEME (note: has to be before LSP initialisation for some reasons

if exists("&termguicolors") && exists("&winblend")
	syntax enable
	set termguicolors

	let g:gruvbox_invert_selection='0'
	let g:gruvbox_contrast_dark = 'hard'


	colorscheme gruvbox
	"autocmd vimenter * ++nested colorscheme gruvbox

	set background=dark

endif



runtime ./plug.vim
runtime ./maps.vim





