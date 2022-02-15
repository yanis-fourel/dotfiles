if vim.g.vscode then return end

require'navigator'.setup({
	lsp = {
		format_on_save = false
	},
	default_mapping = false,
	keymaps = {
		{key = "gr", func = "require('navigator.reference').reference()"},
		{key = "gd", func = "require('navigator.definition').definition()"},
		{key = "<leader>ca", mode = "n", func = "require('navigator.codeAction').code_action()"},
		{key = "<leader>ca", mode = "v", func = "range_code_action()"},
		{key = "<Leader>re", func = "rename()"},
		{key = "gL", func = "require('navigator.diagnostics').show_diagnostics()"},
		{key = "g0", func = "require('navigator.symbols').document_symbols()"},
		{key = "gW", func = "workspace_symbol()"},
		{key = "gh", func = "vim.lsp.buf.hover()"},

		{key = "}d", func = "diagnostic.goto_next({ border = 'rounded', max_width = 80})"},
		{key = "{d", func = "diagnostic.goto_prev({ border = 'rounded', max_width = 80})"},
		{key = "}r", func = "require('navigator.treesitter').goto_next_usage()"},
		{key = "{r", func = "require('navigator.treesitter').goto_previous_usage()"},
		{key = "<leader>l", func = "require('navigator.dochighlight').hi_symbol()"},
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
