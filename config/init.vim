" =============================
"      Vim IDE minimal
" =============================
set nocompatible
set encoding=utf-8
syntax on
set termguicolors
set number
set relativenumber
set cursorline
set hidden        " Permite cambiar de buffer sin guardar
set splitbelow    " Splits horizontales abajo
set splitright    " Splits verticales a la derecha
set scrolloff=3   " Mantener margen vertical
set showmatch
set hlsearch
set incsearch

" Indentación
set tabstop=4
set shiftwidth=4
set expandtab
set autoindent
set smartindent

" Plugins
call plug#begin('~/.vim/plugged')
Plug 'preservim/nerdtree'           " Explorador de archivos
Plug 'ryanoasis/vim-devicons'       " Iconos Nerd Font
Plug 'vim-airline/vim-airline'      " Barra de estado
Plug 'vim-airline/vim-airline-themes'
Plug 'neoclide/coc.nvim', {'branch': 'release'} " Autocompletado
call plug#end()

" =============================
"    NERDTree
" =============================
let g:NERDTreeShowHidden=1
let g:NERDTreeMinimalUI=1
let g:NERDTreeIgnore=['\.git$', '\.cache']
nnoremap <leader>e :NERDTreeToggle<CR>
autocmd VimEnter * if argc() == 0 | NERDTree | endif

" =============================
"    Ventanas y redimensionado
" =============================
" Navegación entre splits
nnoremap <C-h> <C-w>h
nnoremap <C-l> <C-w>l
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k

" Redimensionar ventanas
nnoremap <C-Up>    :resize +2<CR>
nnoremap <C-Down>  :resize -2<CR>
nnoremap <C-Left>  :vertical resize -2<CR>
nnoremap <C-Right> :vertical resize +2<CR>

" =============================
"    Airline
" =============================
let g:airline_powerline_fonts = 1
let g:airline_theme = 'gruvbox'

" =============================
"    COC (Autocompletado)
" =============================
" Muestra sugerencias con <Tab>
inoremap <silent><expr> <TAB>
      \ pumvisible() ? "\<C-n>" :
      \ CheckBackspace() ? "\<Tab>" :
      \ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

function! CheckBackspace() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1] =~ '\s'
endfunction

" =============================
"    Misceláneos
" =============================
filetype plugin indent on
set background=dark
colorscheme desert
