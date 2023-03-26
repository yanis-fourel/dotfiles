local lspconfig = require('lspconfig')

local M = {}

M.setup = function(capabilities)
	lspconfig.pyright.setup({
		capabilities = capabilities,
		settings = {
			python = {
				pythonPath = 'python3.10'
			}
		}
	})
end

return M
