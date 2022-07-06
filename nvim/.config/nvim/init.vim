if exists('g:vscode')
	runtime ./vscode.vim
	finish
endif

" {{{ set

let mapleader = " "

set encoding=utf-8
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
set wildignore+=**/node_modules/*
set history=200
set wrap
set linebreak
set undodir=~/.vimdid
set undofile
set guifont=FiraCode:h16
set mouse=a
set laststatus=3
set termguicolors

" Compiling file: obj/encode/json/print.o -> src/encode/json/print.c:186:78: error: format sp
set errorformat+=%.%#Compiling\ file%.%#\ ->\ %f:%l:%c%.%#

filetype plugin on
" }}}

command! MakeTags !ctags -R .





runtime ./plug.vim




" {{{ MAPS 


nmap <leader><leader>z i" {{{occo" }}}kkA 
nmap <leader><leader>cs aDZ_COMMIT_STOP<ESC>
imap <C-c><C-s> DZ_COMMIT_STOP

nnoremap <leader>>> >i{
nnoremap <leader><< <i{

nnoremap <leader><leader>s <cmd>silent! source %<CR>

nnoremap / /\v

cnoremap <expr> %% getcmdtype() == ':' ? expand('%:h').'/' : '%%'

tnoremap <Esc> <C-\><C-n>


" {{{ hjkl

" Map j and k to gj/gk, but only when no count is given
" However, for larger jumps like 6j add the current position to the jump list
" so that you can use <c-o>/<c-i> to jump to the previous position
nmap <expr> <Down> v:count ? (v:count > 5 ? "m'" . v:count : '') . 'j' : 'gj'
nmap <expr> <Up>   v:count ? (v:count > 5 ? "m'" . v:count : '') . 'k' : 'gk'

nmap <Left> h
nmap <Right> l

" }}}

" Don't jump to next match on * press
nnoremap * *``


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
nnoremap <leader>gg :diffget //2<CR>
nnoremap <leader>gm :diffget //3<CR>

" }}}


" rename with substitute cmd
map <leader><leader>re yiw:%s///g<c-F>hhhhpla

nnoremap <leader><leader>x <cmd>source %<CR>
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
		mappings = {
			i = {
				['<C-q>'] = actions.smart_add_to_qflist + actions.open_qflist,
			},
		},
		
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

" {{{ git-worktree

lua<<EOF
require("telescope").load_extension("git_worktree")
EOF

nnoremap <leader>gn :lua require("telescope").extensions.git_worktree.create_git_worktree()<CR>
nnoremap <leader>gw :lua require("telescope").extensions.git_worktree.git_worktrees()<CR>

" }}}

" {{{ Easymotion

" let g:EasyMotion_do_mapping = 0 " Disable default mappings
let g:EasyMotion_smartcase = 1

nmap s <Plug>(easymotion-overwin-line)

let g:EasyMotion_keys = 'neiothluydpfwqcxzmgjbkvsra'

" }}}

" {{{ QuickScope

let g:qs_highlight_on_keys = ['f', 'F', 't', 'T']

highlight QuickScopePrimary guifg='#5fffff' gui=underline ctermfg=155 cterm=underline
highlight QuickScopeSecondary guifg='#999999' gui=underline ctermfg=81 cterm=underline

" }}}

" {{{ Tabularize

nnoremap <leader>=  <cmd>Tabularize /\\(+\\)\\?=/l1r1<CR>
nnoremap <leader>/  <cmd>Tabularize /\\/\\/<CR>
nnoremap <leader>\\ <cmd>Tabularize /\\\\$/l1l0<CR>
nnoremap <leader>.  <cmd>Tabularize /\\W\\zs\\.\\w/l1l0<CR>
nnoremap <leader>:  <cmd>Tabularize /\\:\\zs\\w*[^\\s]/<CR>
nnoremap <leader>,  <cmd>Tabularize /\\
nnoremap <leader>(  <cmd>Tabularize /(/l0l0<CR>

" }}}

" {{{ Whitespace dispay

" 

let g:indent_blankline_show_first_indent_level = v:false
let g:indent_blankline_char_list_blankline     = ['|', '┆', '¦', '']
let g:indent_blankline_char_list               = ['|', '┆', '¦', '']

lua<<EOF

vim.opt.list = true
vim.opt.listchars:append("eol:↴")
vim.opt.listchars:append("space:⋅")
                        
require("indent_blankline").setup {

}

EOF

" }}}

" {{{ Hierarchy viewer (litee)

lua << EOF
require('litee.lib').setup({})
require('litee.calltree').setup({})
EOF

" }}}

" }}}


" {{{ LSP stuffs

lua<<EOF
local lsp_installer = require("nvim-lsp-installer")
local lspconfig = require("lspconfig")

local function on_attach(client)
	local opts = {}

	print("Attaching " + client + " lsp")

	client:setup(opts)

end

require "lsp_signature".on_attach({
	floating_window = false,
	hint_prefix = "",
	hi_parameter = "LspSignatureActiveParameter",
	toggle_key = "<M-x>"
})

lspconfig.clangd.setup { on_attach = on_attach }
lspconfig.rust_analyzer.setup { on_attach = on_attach }
lspconfig.tsserver.setup { on_attach = on_attach }

EOF

nnoremap K <cmd>lua vim.lsp.buf.hover()<CR>
nnoremap gd <cmd>lua vim.lsp.buf.definition()<CR>
nnoremap gi <cmd>lua vim.lsp.buf.implementation()<CR>
nnoremap ]d <cmd>lua vim.lsp.diagnostic.goto_next()<CR>
nnoremap [d <cmd>lua vim.lsp.diagnostic.goto_prev()<CR>

" overwritten 'go into insert mode at position one last left insert mode'
nnoremap <leader>gi gi

" }}}

" {{{ navigator

" TODO: This does not seem to work anymore...
lua<<EOF
require'navigator'.setup({
	lsp = {
		format_on_save = false
	},
	default_mapping = false,
	keymaps = {
		{key = "gr", func = "require('navigator.reference').reference()"},
		{key = "<leader>ca", mode = "n", func = "require('navigator.codeAction').code_action()"},
		{key = "<leader>ca", mode = "v", func = "range_code_action()"},
		{key = "<Leader>re", func = "rename()"},
		{key = "gL", func = "require('navigator.diagnostics').show_diagnostics()"},
		{key = "g0", func = "require('navigator.symbols').document_symbols()"},
		{key = "gW", func = "workspace_symbol()"},

		{key = "]d", func = "diagnostic.goto_next({ border = 'rounded', max_width = 80})"},
		{key = "[d", func = "diagnostic.goto_prev({ border = 'rounded', max_width = 80})"},
		{key = "]r", func = "require('navigator.treesitter').goto_next_usage()"},
		{key = "[r", func = "require('navigator.treesitter').goto_previous_usage()"},
		{key = "<leader>l", func = "require('navigator.dochighlight').hi_symbol()"},
	},
	lsp_signature_help = true,
	lsp_installer = true,
	icons = {
		-- TODO
	}
})


local function lspSymbol(name, icon)
	vim.fn.sign_define(
		"DiagnosticSign" .. name,
		{ text = icon, numhl = "DiagnosticDefault" .. name }
	)
end

lspSymbol("Error", "")
lspSymbol("Information", "")
lspSymbol("Hint", "")
lspSymbol("Info", "")
lspSymbol("Warning", "")
EOF

" }}}

" {{{ cmp
set completeopt=menu,menuone,noselect 


lua <<EOF
local cmp = require'cmp'
local lspkind = require('lspkind')

cmp.setup({
	mapping = {
		['<C-b>'] = cmp.mapping(cmp.mapping.scroll_docs(-4), { 'i', 'c' }),
		['<C-f>'] = cmp.mapping(cmp.mapping.scroll_docs(4), { 'i', 'c' }),
		['<C-Space>'] = cmp.mapping(cmp.mapping.complete(), { 'i', 'c' }),
		['<C-y>'] = cmp.mapping.confirm {
			behavior = cmp.ConfirmBehavior.Insert,
			select = true
		},
		['<C-e>'] = cmp.mapping({
			i = cmp.mapping.abort(),
			c = cmp.mapping.close(),
		}),

        ['<Down>'] = cmp.mapping(cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }), {'i', 'c'}),
        ['<Up>']   = cmp.mapping(cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }), {'i', 'c'}),
	},
	sources = cmp.config.sources({
		{ name = 'nvim_lsp' },
		{ name = 'path' },
		{ name = 'buffer', keyword_length=5 },
	}),
	formatting = {
		format = lspkind.cmp_format({
			mode = 'symbol', -- show only symbol annotations
			maxwidth = 50, -- prevent the popup from showing more than provided characters (e.g 50 will not show more than 50 characters)
		})
	},
})

-- Use buffer source for `/` (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline('/', {
	sources = {
		{ name = 'buffer' }
	}
})

  -- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline(':', {
	sources = cmp.config.sources({
		{ name = 'path' }
	}, {
		{ name = 'cmdline' }
	})
})

-- Setup lspconfig.
local capabilities = require('cmp_nvim_lsp').update_capabilities(vim.lsp.protocol.make_client_capabilities())

EOF
" }}}

" {{{ lsp_extensions

" TODO: make that work for rust
" autocmd InsertLeave,BufEnter,BufWinEnter,TabEnter,BufWritePost *.rs :lua require'lsp_extensions'.inlay_hints{ prefix = ' » ', highlight = "NonText", enabled = {"ChainingHint"} }

" }}}

" {{{ ts-rainbow

lua<<EOF
require("nvim-treesitter.configs").setup {
	highlight = {
		-- ...
		},
	-- ...
	rainbow = {
	enable = true,
	-- disable = { "jsx", "cpp" }, list of languages you want to disable the plugin for
	extended_mode = true, -- Also highlight non-bracket delimiters like html tags, boolean or table: lang -> boolean
	max_file_lines = nil, -- Do not enable for files with more than n lines, int
	-- colors = {}, -- table of hex strings
	-- termcolors = {} -- table of colour name strings
	}
}
EOF

" }}}

" {{{ status line

lua<<EOF

require('feline').setup()

EOF

" }}}

lua require('auto-session').setup()
lua require('gitsigns').setup()

" {{{ Theme
if exists("&termguicolors") && exists("&winblend")
	set background=dark
	syntax enable

	let g:gruvbox_invert_selection='0'
	let g:gruvbox_contrast_dark = 'hard'

	colorscheme gruvbox
endif
" }}}

"TODO:
" TAB system: (replaces Harpoon)
" 2 tab type: 1 *temporary tab*, N *permanent tabs*
"
" From a *permanent tab*:
" When following a reference, or jumping anywhere, it opens the "temporary tab".
"
" I can make this tab "permanent" with a shortcut
"
" From a *temporary tab*:
" When following a reference, or jumping anywhere, it replaces the current *temporary tab*
" Jumping back to a *permanent tab* closes the *temporary tab*
"
"
" Each *permanent tab* displays its buffer name, as well as a label (number, or a letter...) used to jump to the tab
" check https://github.com/noib3/nvim-cokeline   this may be a good 'framework' to make is happen


" vim: foldlevel=1 foldmethod=marker
