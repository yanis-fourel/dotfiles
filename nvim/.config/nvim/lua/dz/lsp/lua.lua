local lspconfig = require('lspconfig')

local M = {}

M.setup = function(capabilities)
	lspconfig.lua_ls.setup({
		capabilities = capabilities,
		settings = {
			Lua = {
				{
					callSnippet = 'Replace',
					showWord = 'Disable'
				},
				-- try without for now
				-- diagnostics = {
				-- 	globals = { 'vim' }
				-- },
				workspace = {
					-- Make the server aware of Neovim runtime files
					library = vim.api.nvim_get_runtime_file("", true),
				},
			}
		}
	})
end

return M
