local lspconfig = require('lspconfig')

local M = {}

M.setup = function(capabilities)
	lspconfig.pyright.setup({
		capabilities = capabilities,
		settings = {
			python = {

			}
		}
	})
end

return M
