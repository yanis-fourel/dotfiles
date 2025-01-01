local ok, retval = pcall(require("fidget").setup)
if not ok then
	vim.notify("error calling fidget.setup: " .. retval, 1, {})
end

vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
	callback = function(event)
		local map = function(keys, func, desc)
			vim.keymap.set("n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
		end

		map("ga", function()
			require("telescope.builtin").diagnostics({ severity = 1, root_dir = true })
		end, "Goto lsp error+warn list")
		map("gq", function()
			require("telescope.builtin").diagnostics({ severity = 2, root_dir = true })
		end, "Goto lsp warning list")
		map("gd", require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")
		map("gr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")
		map("gI", require("telescope.builtin").lsp_implementations, "[G]oto [I]mplementation")
		map("gt", require("telescope.builtin").lsp_type_definitions, "[G]oto [T]ype")
		map("g0", require("telescope.builtin").lsp_document_symbols, "Document Symbols")
		map("gw", require("telescope.builtin").lsp_dynamic_workspace_symbols, "Workspace [S]ymbols")
		map("<leader>r", vim.lsp.buf.rename, "[Re]name")
		map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")
		map("K", vim.lsp.buf.hover, "Hover Documentation")
		map("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")

		local client = vim.lsp.get_client_by_id(event.data.client_id)

		-- The following autocommand is used to enable inlay hints in your
		-- code, if the language server you are using supports them
		--
		-- This may be unwanted, since they displace some of your code
		if client and client.server_capabilities.inlayHintProvider and vim.lsp.inlay_hint then
			map("<leader>th", function()
				vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({}))
			end, "[T]oggle Inlay [H]ints")
		end
	end,
})

require("lspconfig.ui.windows").default_options.border = require("user.preference").border_style
vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
	border = require("user.preference").border_style,
})
vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, {
	border = require("user.preference").border_style,
})
vim.diagnostic.config({
	float = { border = require("user.preference").border_style },
})

require("lspconfig").rust_analyzer.setup({
	capabilities = require("user.lsp").make_client_capabilities(),
	settings = {
		["rust-analyzer"] = {
			diagnostics = {
				enable = true,
			},
		},
	},
})

require("lspconfig").gopls.setup({
	capabilities = require("user.lsp").make_client_capabilities(),
})

require("lspconfig").lua_ls.setup({
	capabilities = require("user.lsp").make_client_capabilities(),
})

require("lspconfig").nil_ls.setup({
	capabilities = require("user.lsp").make_client_capabilities(),
})
