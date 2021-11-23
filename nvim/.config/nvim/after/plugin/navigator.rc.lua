require'navigator'.setup({
	lsp = {
		format_on_save = false
	},
	default_mapping = false,
	keymaps = {
		{key = "gr", func = "require('navigator.reference').reference()"},
		{key = "gd", func = "require('navigator.definition').definition()"},
		{key = "ca", mode = "n", func = "require('navigator.codeAction').code_action()"},
		{key = "ca", mode = "v", func = "range_code_action()"},
		{key = "<Leader>re", func = "rename()"},
		{key = "gL", func = "require('navigator.diagnostics').show_diagnostics()"},
		{key = "g0", func = "require('navigator.symbols').document_symbols()"},
		{key = "gW", func = "workspace_symbol()"},

		{key = "<F9>d", func = "diagnostic.goto_next({ border = 'rounded', max_width = 80})"},
		{key = "<F8>d", func = "diagnostic.goto_prev({ border = 'rounded', max_width = 80})"},
		{key = "<F9>r", func = "require('navigator.treesitter').goto_next_usage()"},
		{key = "<F8>r", func = "require('navigator.treesitter').goto_previous_usage()"},
	}
})
