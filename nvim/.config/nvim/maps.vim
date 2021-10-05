let mapleader = " "


" Don't jump to next match on * press
nnoremap * *``

" Quick vimrc edit
nnoremap <leader>v :e $MYVIMRC<CR>
nnoremap <leader>c :w<CR><C-^>:source $MYVIMRC<CR>

" Go to tab by number
noremap <leader>1 1gt
noremap <leader>2 2gt
noremap <leader>3 3gt
noremap <leader>4 4gt
noremap <leader>5 5gt
noremap <leader>6 6gt
noremap <leader>7 7gt
noremap <leader>8 8gt
noremap <leader>9 9gt

" Disables command line I always get stuck on
nnoremap q: <Nop>
