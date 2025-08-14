" ~/.config/nvim/init.vim - Configuración mínima para C/C++

set number            " Numeración de líneas
set relativenumber    " Números relativos
set tabstop=4         " Tabs de 4 espacios
set shiftwidth=4      " Autoindent de 4 espacios
set expandtab         " Usa espacios en lugar de tabs
set autoindent        " Indentación automática
set smartindent       " Mejor indentación
set nowrap            " No cortar líneas largas
set cursorline        " Resaltar línea actual
set termguicolors     " Colores en terminal

syntax on             " Resaltado de sintaxis
filetype plugin indent on

" Compilación rápida
nnoremap <F5> :w<CR>:!gcc % -o %:r && ./%:r<CR>
nnoremap <F6> :w<CR>:!g++ % -o %:r && ./%:r<CR>

" Búsqueda
set hlsearch
set incsearch
