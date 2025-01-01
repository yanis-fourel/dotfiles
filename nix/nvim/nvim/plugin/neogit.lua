local neogit = require("neogit")
neogit.setup {}

vim.keymap.set("n", "<leader>gs", neogit.open, { desc = "[G]it [S]tatus (and more)" })
