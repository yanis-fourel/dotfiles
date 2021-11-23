vim.api.nvim_set_keymap("n", "<leader>=", "<cmd>Tabularize /=<CR>", { noremap = true});
vim.api.nvim_set_keymap("n", "<leader>/", "<cmd>Tabularize /\\/\\/<CR>", { noremap = true});
vim.api.nvim_set_keymap("n", "<leader>\\", "<cmd>Tabularize /\\\\$<CR>", { noremap = true});
vim.api.nvim_set_keymap("n", "<leader>.", "<cmd>Tabularize /\\W\\zs\\.\\w/l1l0<CR>", { noremap = true});
vim.api.nvim_set_keymap("n", "<leader>:", "<cmd>Tabularize /\\:\\zs\\w*[^\\s]/<CR>", { noremap = true});
vim.api.nvim_set_keymap("n", "<leader>,", "<cmd>Tabularize /\\,/l0l1<CR>", { noremap = true});
