" Map Colemak-dh movements keys
"noremap m h
"noremap n j
"noremap e k
"noremap i l
"
"noremap h m
"noremap j n
"noremap k e
"noremap l i
"
"noremap M H
"noremap N J
"noremap E K
"noremap I L
"
"noremap H M
"noremap J N
"noremap K E
"noremap L I
"

noremap <Left> h
noremap <Up> k
noremap <Down> j
noremap <Right> l

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


nnoremap <M-H> 5j
nnoremap <M-j> 5j
nnoremap <M-k> 5k
nnoremap <M-l> 5l


" Git remaps
nnoremap <leader>gs :G<CR>
nnoremap <leader>gg :diffger //3<CR>
nnoremap <leader>gm :diffger //2<CR>
