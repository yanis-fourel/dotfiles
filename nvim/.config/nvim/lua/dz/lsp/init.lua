local lspconfig = require('lspconfig')
local tele_builtin = require('telescope.builtin')

require('mason').setup({})



vim.keymap.set('n', 'gd', tele_builtin.lsp_definitions)
vim.keymap.set('n', 'ga', function() tele_builtin.diagnostics({severity = 1, root_dir = true}) end)
vim.keymap.set('n', 'gq', function() tele_builtin.diagnostics({severity_limit = 2, root_dir = true}) end)
vim.keymap.set('n', 'gi', tele_builtin.lsp_implementations)
vim.keymap.set('n', 'gI', tele_builtin.lsp_incoming_calls)
vim.keymap.set('n', 'gt', tele_builtin.lsp_type_definitions)
vim.keymap.set('n', 'gr', tele_builtin.lsp_references)
vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action)
vim.keymap.set('n', '<leader>l', vim.lsp.buf.document_highlight)
-- vim.keymap.set('n', '<C-l>', function () vim.lsp.buf.clear_references(); vim.cmd("mod"); end )
vim.keymap.set('n', 'g0', tele_builtin.lsp_document_symbols)
vim.keymap.set('n', 'gw', tele_builtin.lsp_workspace_symbols)
vim.keymap.set('n', ']d', vim.diagnostic.goto_next)
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev)
vim.keymap.set('n', '<leader>r', vim.lsp.buf.rename)
vim.keymap.set('n', '<leader>gi', 'gi') -- overwritten 'go into insert mode at position one last left insert mode'



-- local capabilities = require('cmp_nvim_lsp').update_capabilities(vim.lsp.protocol.make_client_capabilities())
local capabilities = vim.lsp.protocol.make_client_capabilities()

-- vim.pretty_print(lspconfig)

require('neodev').setup({
	library = { plugins = { "nvim-dap-ui" }, types = true },
}) -- IMPORTANT: setup BEFORE lua lsp


-- see https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md
-- for the name of the properties

-- Language-specific config
lspconfig.tsserver.setup { capabilities = capabilities }
-- lspconfig.jdtls.setup { capabilities = capabilities }
lspconfig.bashls.setup { capabilities = capabilities }
lspconfig.als.setup { capabilities = capabilities }
-- lspconfig.docker_compose_language_service.setup { capabilities = capabilities }
-- lspconfig.dockerls.setup { capabilities = capabilities }

require('dz.lsp.clangd').setup(capabilities)
require('dz.lsp.lua').setup(capabilities)
require('dz.lsp.rust').setup(capabilities)
require('dz.lsp.python').setup(capabilities)
require('dz.lsp.go').setup(capabilities)
-- require('dz.lsp.sonarlint').setup()

-- autocmd BufRead,BufNewFile .env lua vim.diagnostic.disable(<abuf>) 

vim.api.nvim_create_autocmd({'BufEnter', 'BufNewFile'}, {
	pattern = '.env',
	callback = function(ev)
		vim.diagnostic.disable(ev.buf)
	end
})

