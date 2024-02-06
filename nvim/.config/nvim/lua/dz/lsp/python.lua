local lspconfig = require('lspconfig')

local M = {}

local augroup = vim.api.nvim_create_augroup("BlackAutoFmt", {})

M.setup = function(capabilities)
	lspconfig.pyright.setup({
		capabilities = capabilities,
		settings = {
			python = {
				analysis = {
					diagnosticSeverityOverrides = {
						reportInvalidTypeForm = 'none', -- causes problem with avial types
					}
				},
			}
		},
		on_attach = function (_, bufnr)
			vim.api.nvim_create_autocmd("BufWritePre", {
				group = augroup,
				buffer = bufnr,
				callback = function()
					vim.lsp.buf.format({ bufnr = bufnr })
				end
			})
		end
	})
end

return M
