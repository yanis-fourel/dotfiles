local treeclimber = require('tree-climber')

local keyopts = {}

-- vim.keymap.set({'n', 'v', 'o'}, 'h', treeclimber.goto_parent, keyopts)
-- vim.keymap.set({'n', 'v', 'o'}, 'l'    , treeclimber.goto_child , keyopts)
vim.keymap.set({'n', 'v', 'o'}, '<S-down>'    , treeclimber.goto_next  , keyopts)
vim.keymap.set({'n', 'v', 'o'}, '<S-up>'    , treeclimber.goto_prev  , keyopts)
vim.keymap.set({'v', 'o'}     , 'in'   , treeclimber.select_node, keyopts)
vim.keymap.set('n'            , '<S-left>', treeclimber.swap_prev  , keyopts)
vim.keymap.set('n'            , '<S-right>', treeclimber.swap_next  , keyopts)
