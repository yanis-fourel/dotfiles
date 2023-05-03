local mark = require('harpoon.mark')
local ui   = require('harpoon.ui')

require('telescope').load_extension('harpoon')

vim.keymap.set("n", "<leader>a", mark.add_file)
-- vim.keymap.set("n", "<C-m>", ":Telescope harpoon marks<CR>")
vim.keymap.set("n", "<C-m>", ui.toggle_quick_menu) -- easier to close

vim.keymap.set("n", "<C-j>", function() ui.nav_file(1) end)
vim.keymap.set("n", "<C-l>", function() ui.nav_file(2) end)
vim.keymap.set("n", "<C-k>", function() ui.nav_file(3) end)
vim.keymap.set("n", "<C-h>", function() ui.nav_file(4) end)
