local lspconfig = require('lspconfig')
local M = {}

local augroup = vim.api.nvim_create_augroup("GoAutoFmt", {})

M.setup = function(capabilities)
	lspconfig.gopls.setup {
		capabilities = capabilities,
		filetypes = { "go", "gomod", "gowork"},
		on_attach = function (_, bufnr)
			vim.api.nvim_create_autocmd("BufWritePre", {
				group = augroup,
				buffer = bufnr,
				callback = function()
					vim.lsp.buf.format({ bufnr = bufnr })
				end
			})
		end
	}

end

return M
