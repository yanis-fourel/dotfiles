-- Autoformat
return {
	"stevearc/conform.nvim",
	lazy = false,
	keys = {
		{
			"<leader>w",
			function()
				require("conform").format({ async = true, lsp_fallback = true })
			end,
			mode = "",
			desc = "Format buffer",
		},
	},
	opts = {
		notify_on_error = true,
		format_on_save = function(bufnr)
			local disable_filetypes = { c = true, cpp = true }
			return {
				timeout_ms = 500,
				lsp_fallback = not disable_filetypes[vim.bo[bufnr].filetype],
			}
		end,
		formatters_by_ft = {
			lua = { "stylua" },
			c = { "clang-format" },
			cpp = { "clang-format" },

			-- TODO: ? python = { "isort", "black" },
			python = { "black" },

			javascript = { "eslint_d" },
			typescript = { "eslint_d" },
		},
		log_level = vim.log.levels.DEBUG,
	},
}
