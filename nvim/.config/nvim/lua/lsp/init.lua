local lspconfig = require('lspconfig')
local tele_builtin = require('telescope.builtin')

require('nvim-lsp-installer').setup({})


vim.keymap.set('n', 'K',  vim.lsp.buf.hover)
vim.keymap.set('n', 'gd', tele_builtin.lsp_definitions)
vim.keymap.set('n', 'gi', tele_builtin.lsp_implementations)
vim.keymap.set('n', 'gI', tele_builtin.lsp_incoming_calls)
vim.keymap.set('n', 'gt', tele_builtin.lsp_type_definitions)
vim.keymap.set('n', 'gr', tele_builtin.lsp_references)
vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action)
vim.keymap.set('n', '<leader>l', vim.lsp.buf.document_highlight)
vim.keymap.set('n', '<C-l>', function () vim.lsp.buf.clear_references(); vim.cmd("mod"); end)
vim.keymap.set('n', 'g0', tele_builtin.lsp_document_symbols)
vim.keymap.set('n', 'gw', tele_builtin.lsp_workspace_symbols)
vim.keymap.set('n', ']d', vim.lsp.diagnostic.goto_next)
vim.keymap.set('n', '[d', vim.lsp.diagnostic.goto_prev)
vim.keymap.set('n', '<leader>r', vim.lsp.buf.rename)
vim.keymap.set('n', '<leader>gi', 'gi') -- overwritten 'go into insert mode at position one last left insert mode'



-- local capabilities = require('cmp_nvim_lsp').update_capabilities(vim.lsp.protocol.make_client_capabilities())
local capabilities = vim.lsp.protocol.make_client_capabilities()

-- vim.pretty_print(capabilities)


-- Language-specific config
lspconfig.clangd.setup { capabilities = capabilities }
lspconfig.tsserver.setup { capabilities = capabilities }
lspconfig.pyright.setup { capabilities = capabilities }
require('lsp/lua').setup(capabilities)
require('lsp/rust').setup(capabilities)

