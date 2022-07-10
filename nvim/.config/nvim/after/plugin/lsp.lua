local lsp_installer = require('nvim-lsp-installer')
local lspconfig = require('lspconfig')

local capabilities = require('cmp_nvim_lsp').update_capabilities(vim.lsp.protocol.make_client_capabilities())
local default_capabilities = vim.lsp.protocol.make_client_capabilities()


capabilities.textDocument.completion.completionItem.snippetSupport = false

lspconfig.clangd.setup { capabilities = capabilities }
lspconfig.rust_analyzer.setup { capabilities = capabilities }
lspconfig.tsserver.setup { capabilities = capabilities }


vim.keymap.set('n', 'K',  vim.lsp.buf.hover)
vim.keymap.set('n', 'gd', vim.lsp.buf.definition)
vim.keymap.set('n', 'gi', vim.lsp.buf.implementation)
vim.keymap.set('n', ']d', vim.lsp.diagnostic.goto_next)
vim.keymap.set('n', '[d', vim.lsp.diagnostic.goto_prev)

-- overwritten 'go into insert mode at position one last left insert mode'
vim.keymap.set('n', '<leader>gi', 'gi')


