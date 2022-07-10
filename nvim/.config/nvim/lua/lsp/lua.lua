local lspconfig = require('lspconfig')

local M = {}

M.setup = function(capabilities)
	lspconfig.sumneko_lua.setup({
		capabilities = capabilities,
		settings = {
			Lua = {
				completion = {
					showWord = 'Disable'
				},
				diagnostics = {
					globals = { 'vim' }
				},
				workspace = {
					-- Make the server aware of Neovim runtime files
					library = vim.api.nvim_get_runtime_file("", true),
				},
			}
		}
	})
end

return M
