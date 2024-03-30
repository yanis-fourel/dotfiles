local lspconfig = require('lspconfig')
local M = {}

M.setup = function(capabilities)
	capabilities['offsetEncoding'] = 'utf-8'
	lspconfig.clangd.setup { capabilities = capabilities }
end

return M

