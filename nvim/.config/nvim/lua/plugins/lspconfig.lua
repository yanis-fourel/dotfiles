return {
	"neovim/nvim-lspconfig",
	dependencies = {
		{ "j-hui/fidget.nvim", opts = {} },
	},
	config = function()
		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
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

		-- LSP servers and clients are able to communicate to each other what features they support.
		--  By default, Neovim doesn't support everything that is in the LSP specification.
		--  When you add nvim-cmp, luasnip, etc. Neovim now has *more* capabilities.
		--  So, we create new capabilities with nvim cmp, and then broadcast that to the servers.
		local capabilities = vim.lsp.protocol.make_client_capabilities()
		capabilities = vim.tbl_deep_extend("force", capabilities, require("cmp_nvim_lsp").default_capabilities())

		--  Add any additional override configuration in the following tables. Available keys are:
		--  - cmd (table): Override the default command used to start the server
		--  - filetypes (table): Override the default list of associated filetypes for the server
		--  - capabilities (table): Override fields in capabilities. Can be used to disable certain LSP features.
		--  - settings (table): Override the default settings passed when initializing the server.
		--        For example, to see the options for `lua_ls`, you could go to: https://luals.github.io/wiki/settings/
		local servers = {
			-- Typescript has an entire language plugins that can be useful:
			--    https://github.com/pmizio/typescript-tools.nvim
			-- but for me, tsserver is enough
			ts_ls = {},
			svelte = {},
			eslint = {},
			bashls = {},

			lua_ls = {
				settings = {
					Lua = {
						completion = {
							callSnippet = "Replace",
						},
						runtime = {
							version = "LuaJIT",
						},
						workspace = {
							checkThirdParty = false,
							library = {
								vim.env.VIMRUNTIME,
								-- Depending on the usage, you might want to add additional paths here.
								-- "${3rd}/luv/library"
								-- "${3rd}/busted/library",
							},
						},
						diagnostics = { disable = { "missing-fields" } },
					},
				},
			},
			gopls = {
				filetype = { "go", "gomod", "gowork" },
			},
			zls = {},
			rust_analyzer = {},
			rnix = {},
		}

		servers = vim.tbl_extend(
			"error",
			servers,
			require("lspconf.python")(capabilities),
			require("lspconf.clangd")(capabilities)
		)

		-- -- You can add other tools here that you want Mason to install
		-- -- for you, so that they are available from within Neovim.
		-- local ensure_installed = vim.tbl_keys(servers or {})
		-- vim.list_extend(ensure_installed, {
		-- 	"stylua", -- Used to format Lua code
		-- 	"clang-format",
		-- 	"black",
		-- })

		for name, config in pairs(servers) do
			if config == nil then
				return
			end

			if config.capabilities == nil then
				config.capabilities = capabilities
			end

			require("lspconfig")[name].setup(config)
		end
	end,
}
