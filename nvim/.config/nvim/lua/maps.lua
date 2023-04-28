vim.keymap.set('n', '<leader><leader>cs', 'aDZ_COMMIT_STOP<ESC>')
vim.keymap.set('i', '<C-c><C-s>', 'DZ_COMMIT_STOP')

vim.keymap.set('n','<leader>>>', '>i{')
vim.keymap.set('n','<leader><<', '<i{')

vim.keymap.set('n','<leader><leader>s', '<cmd>silent! source %<CR>')

vim.keymap.set('n','/', '/\\v')

vim.keymap.set('n','^', '0^', { noremap = true })


vim.keymap.set('t','<Esc>', '<C-\\><C-n>')

vim.keymap.set('x','<leader>p', '"_dP')

vim.keymap.set('n','<leader>yq', '<cmd>%!yq<CR>')
vim.keymap.set('n','<leader>jq', '<cmd>%!jq --tab<CR>')
vim.keymap.set('v','<leader>jq', "<cmd>'<,'>!jq --tab<CR>")
vim.keymap.set('n','<leader><leader>jq', '<cmd>%!jq --tab -c<CR>')
vim.keymap.set('v','<leader><leader>jq', "<cmd>'<,'>!jq --tab -c<CR>")

-- {{{ hjkl

-- Map j and k to gj/gk, but only when no count is given
-- However, for larger jumps like 6j add the current position to the jump list
-- so that you can use <c-o>/<c-i> to jump to the previous position
-- TODO vim.keymap.set('n','<expr>', '<Down> v:count ? (v:count > 5 ? "m'" . v:count : '') . 'j' : 'gj'')
-- TODO vim.keymap.set('n','<expr>', '<Up>   v:count ? (v:count > 5 ? "m'" . v:count : '') . 'k' : 'gk'')

vim.keymap.set('n','<Left>', 'h', { remap = true })
vim.keymap.set('n','<Right>', 'l', { remap = true})

-- }}}

-- Don't jump to next match on * press
vim.keymap.set('n','*', '*``')


-- {{{ Go to tab by number 

vim.keymap.set('n','<leader>1', '1gt')
vim.keymap.set('n','<leader>2', '2gt')
vim.keymap.set('n','<leader>3', '3gt')
vim.keymap.set('n','<leader>4', '4gt')
vim.keymap.set('n','<leader>5', '5gt')
vim.keymap.set('n','<leader>6', '6gt')
vim.keymap.set('n','<leader>7', '7gt')
vim.keymap.set('n','<leader>8', '8gt')
vim.keymap.set('n','<leader>9', '9gt')

-- }}}

-- rename with substitute cmd
vim.keymap.set('n','<leader><leader>re', 'yiw:%s///g<c-F>hhhhpla')

vim.keymap.set('n','<leader><leader>x', '<cmd>source %<CR>')
-- }}}


--
-- TODO luafy: vim.keymap.set('c','<expr>', '%% getcmdtype() == ':' ? expand('%:h').'/' : '%%'')
vim.cmd([[ cnoremap <expr> %% getcmdtype() == ':' ? expand('%:h').'/' : '%%' ]])
