local lspconfig = require('lspconfig')


require('nvim-lsp-installer').setup()


vim.keymap.set('n', 'K',  vim.lsp.buf.hover)
vim.keymap.set('n', 'gd', vim.lsp.buf.definition)
vim.keymap.set('n', 'gi', vim.lsp.buf.implementation)
vim.keymap.set('n', ']d', vim.lsp.diagnostic.goto_next)
vim.keymap.set('n', '[d', vim.lsp.diagnostic.goto_prev)
vim.keymap.set('n', '<leader>gi', 'gi') -- overwritten 'go into insert mode at position one last left insert mode'


-- local capabilities = require('cmp_nvim_lsp').update_capabilities(vim.lsp.protocol.make_client_capabilities())
local capabilities = vim.lsp.protocol.make_client_capabilities()

capabilities.textDocument.completion.completionItem.snippetSupport = false
table.remove(capabilities.textDocument.completion.completionItemKind.valueSet, 15) -- removing 'snippet'
-- vim.pretty_print(capabilities)


-- Language-specific config
lspconfig.clangd.setup { capabilities = capabilities }
lspconfig.tsserver.setup { capabilities = capabilities }
require('lsp/lua').setup(capabilities)
require('lsp/rust').setup(capabilities)

