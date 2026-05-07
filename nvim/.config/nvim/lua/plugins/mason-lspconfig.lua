return {
	"mason-org/mason-lspconfig.nvim",
	dependencies = {
		{ "mason-org/mason.nvim", opts = {} },
		"neovim/nvim-lspconfig",
	},
	opts = {
		automatic_enable = true,
		ensure_installed = {},
	},
	config = function(_, opts)
		require("mason-lspconfig").setup(opts)

		local map = function(keys, func, desc)
			vim.keymap.set("n", keys, func, { buffer = 0, desc = "LSP: " .. desc })
		end

		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup("lsp-keymaps", { clear = true }),
			callback = function(event)
				map("ga", function()
					require("telescope.builtin").diagnostics({ severity = 1, root_dir = true })
				end, "Goto lsp error+warn list")

				map("gq", function()
					require("telescope.builtin").diagnostics({ severity = 2, root_dir = true })
				end, "Goto lsp warning list")

				map("gd", vim.lsp.buf.definition, "[G]oto [D]efinition")
				map("gr", vim.lsp.buf.references, "[G]oto [R]eferences")
				map("gI", vim.lsp.buf.implementation, "[G]oto [I]mplementation")
				map("gt", vim.lsp.buf.type_definition, "[G]oto [T]ype Definition")

				map("g0", require("telescope.builtin").lsp_document_symbols, "Document Symbols")
				map("gw", require("telescope.builtin").lsp_dynamic_workspace_symbols, "Workspace [S]ymbols")

				map("<leader>r", vim.lsp.buf.rename, "[Re]name")
				map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")
				map("K", vim.lsp.buf.hover, "Hover Documentation")
				map("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
			end,
		})

		-- Helper: prefer project-local uv-managed binaries
		local function get_ruff_cmd()
			local project_venv = vim.fn.getcwd() .. "/.venv/bin/ruff"
			if vim.fn.executable(project_venv) == 1 then
				return { project_venv, "server" }
			end
			return { "ruff", "server" } -- fallback to mason/global
		end

		local function get_basedpyright_cmd()
			local project_venv = vim.fn.getcwd() .. "/.venv/bin/basedpyright-langserver"
			if vim.fn.executable(project_venv) == 1 then
				return { project_venv, "--stdio" }
			end
			return { "basedpyright-langserver", "--stdio" }
		end

		-- Define configs (this replaces the old .setup() calls)
		vim.lsp.config("ruff", {
			cmd = get_ruff_cmd(),
			offset_encoding = "utf-8",
			on_attach = function(client, bufnr)
				-- Optional: let basedpyright handle hover if you prefer
				-- client.server_capabilities.hoverProvider = false
			end,
		})

		vim.lsp.config("basedpyright", {
			cmd = get_basedpyright_cmd(),
			offset_encoding = "utf-8",
			settings = {
				basedpyright = {
					analysis = {
						autoSearchPaths = true,
						diagnosticMode = "workspace",
						useLibraryCodeForTypes = true,
						typeCheckingMode = "standard", -- "strict" / "basic" / "off"
						-- Use venv from nvim's cwd if it exists
						venvPath = ".",
						venv = ".venv",
					},
				},
			},
		})

		vim.lsp.enable({ "ruff", "basedpyright" })

		vim.g.copilot_nes_debounce = 500
	end,
}
