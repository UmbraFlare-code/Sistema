" ~/.config/nvim/init.vim - Configuración de Neovim para desarrollo
" Optimizada para programación en C, C++, Python y más

" =============================================================================
" CONFIGURACIÓN BÁSICA
" =============================================================================

" Configuración de archivos
set nocompatible                " No compatible con vi
set encoding=utf-8              " Codificación UTF-8
set fileencoding=utf-8          " Codificación de archivos
set fileencodings=utf-8         " Lista de codificaciones

" Numeración y visualización
set number                      " Numeración de líneas
set relativenumber             " Números relativos
set cursorline                 " Resaltar línea actual
set cursorcolumn               " Resaltar columna actual
set colorcolumn=80,120         " Guías de columnas
set signcolumn=yes             " Columna de signos siempre visible
set scrolloff=8                " Líneas de contexto al hacer scroll
set sidescrolloff=8            " Columnas de contexto al hacer scroll horizontal

" Indentación y espaciado
set tabstop=4                  " Ancho de tab
set shiftwidth=4               " Espacios para autoindent
set softtabstop=4              " Espacios al presionar tab
set expandtab                  " Usar espacios en lugar de tabs
set autoindent                 " Mantener indentación
set smartindent                " Indentación inteligente
set cindent                    " Indentación estilo C

" Comportamiento general
set nowrap                     " No cortar líneas largas
set linebreak                  " Romper líneas en palabras completas
set mouse=a                    " Soporte completo para mouse
set clipboard=unnamed,unnamedplus " Usar clipboard del sistema
set backspace=indent,eol,start " Backspace mejorado
set whichwrap+=<,>,h,l        " Navegación entre líneas

" Búsqueda mejorada
set ignorecase                 " Búsqueda insensible a mayúsculas
set smartcase                  " Sensible si hay mayúsculas
set incsearch                  " Búsqueda incremental
set hlsearch                   " Resaltar búsquedas
set gdefault                   " Global por defecto en sustituciones

" Interfaz
set termguicolors              " Colores true color
set showmatch                  " Mostrar paréntesis coincidentes
set matchtime=2                " Tiempo de resaltado de coincidencias
set wildmenu                   " Menú de autocompletado mejorado
set wildmode=longest:full,full " Modo de autocompletado
set laststatus=2               " Siempre mostrar barra de estado
set showcmd                    " Mostrar comandos parciales
set showmode                   " Mostrar modo actual
set ruler                      " Mostrar posición del cursor

" Archivos y respaldo
set noswapfile                 " No crear archivos swap
set nobackup                   " No crear respaldos
set nowritebackup             " No escribir respaldos
set undofile                   " Archivo de deshacer persistente
set undodir=~/.config/nvim/undo " Directorio de deshacer
set history=1000               " Historia de comandos

" Crear directorio de deshacer si no existe
if !isdirectory(expand('~/.config/nvim/undo'))
    call mkdir(expand('~/.config/nvim/undo'), 'p')
endif

" =============================================================================
" MAPEOS DE TECLAS Y ATAJOS
" =============================================================================

" Líder más cómodo
let mapleader = " "
let maplocalleader = "\\"

" Guardar y salir rápido
nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>
nnoremap <leader>x :wq<CR>
nnoremap <leader>Q :q!<CR>

" Navegación mejorada
nnoremap j gj
nnoremap k gk
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" Redimensionar ventanas
nnoremap <silent> <C-Up> :resize +2<CR>
nnoremap <silent> <C-Down> :resize -2<CR>
nnoremap <silent> <C-Left> :vertical resize -2<CR>
nnoremap <silent> <C-Right> :vertical resize +2<CR>

" Navegación de buffers
nnoremap <silent> <S-h> :bprevious<CR>
nnoremap <silent> <S-l> :bnext<CR>
nnoremap <leader>bd :bdelete<CR>

" Búsqueda y reemplazo
nnoremap <leader><space> :nohlsearch<CR>
nnoremap <leader>s :%s/\<<C-r><C-w>\>//g<Left><Left>
vnoremap <leader>s :s/\%V

" Compilación y ejecución (teclas de función)
nnoremap <F5> :w<CR>:!clear && gcc -Wall -Wextra -g -std=c99 % -o %:r && ./%:r<CR>
nnoremap <F6> :w<CR>:!clear && g++ -Wall -Wextra -std=c++17 -g % -o %:r && ./%:r<CR>
nnoremap <F7> :w<CR>:!clear && python3 %<CR>
nnoremap <F8> :w<CR>:!clear && make && ./%:r<CR>
nnoremap <F9> :w<CR>:!clear && make clean && make<CR>

" Compilación con flags específicos
nnoremap <leader>cc :w<CR>:!gcc -Wall -Wextra -g -std=c99 % -o %:r<CR>
nnoremap <leader>cpp :w<CR>:!g++ -Wall -Wextra -g -std=c++17 % -o %:r<CR>
nnoremap <leader>run :!./%:r<CR>
nnoremap <leader>py :w<CR>:!python3 %<CR>

" Debug con GDB
nnoremap <leader>gdb :w<CR>:!gcc -Wall -Wextra -g % -o %:r && gdb ./%:r<CR>

" =============================================================================
" AUTOCOMPLETADO Y SNIPPETS
" =============================================================================

" Autocompletado mejorado
set completeopt=menuone,noselect,noinsert
set shortmess+=c

" Navegación en menú de autocompletado
inoremap <expr> <Tab> pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
inoremap <expr> <CR> pumvisible() ? "\<C-y>" : "\<CR>"

" Insertar llaves automáticamente
inoremap {<CR> {<CR>}<C-o>O
inoremap {{ {
inoremap {} {}
inoremap () ()
inoremap [] []
inoremap "" ""
inoremap '' ''

" Completar estructuras de control en C
inoremap <leader>if if ()<Left>
inoremap <leader>for for (int i = 0; i < ; i++)<Left><Left><Left><Left><Left><Left><Left>
inoremap <leader>while while ()<Left>

" =============================================================================
" CONFIGURACIÓN POR TIPO DE ARCHIVO
" =============================================================================

" Archivos C
autocmd FileType c setlocal cindent
autocmd FileType c setlocal commentstring=/*\ %s\ */
autocmd FileType c nnoremap <buffer> <F10> :w<CR>:!gcc -Wall -Wextra -g -std=c99 % -o %:r -lm<CR>

" Archivos C++
autocmd FileType cpp setlocal cindent
autocmd FileType cpp setlocal commentstring=//\ %s
autocmd FileType cpp nnoremap <buffer> <F10> :w<CR>:!g++ -Wall -Wextra -g -std=c++17 % -o %:r<CR>

" Archivos Python
autocmd FileType python setlocal tabstop=4 shiftwidth=4 softtabstop=4
autocmd FileType python setlocal commentstring=#\ %s
autocmd FileType python nnoremap <buffer> <F10> :w<CR>:!python3 %<CR>
autocmd FileType python nnoremap <buffer> <F11> :w<CR>:!python3 -m py_compile %<CR>

" Archivos JavaScript
autocmd FileType javascript setlocal tabstop=2 shiftwidth=2 softtabstop=2
autocmd FileType javascript setlocal commentstring=//\ %s

" Archivos HTML
autocmd FileType html setlocal tabstop=2 shiftwidth=2 softtabstop=2
autocmd FileType html setlocal commentstring=<!--\ %s\ -->

" Makefile (no expandir tabs)
autocmd FileType make setlocal noexpandtab tabstop=8 shiftwidth=8

" Archivos de configuración
autocmd FileType conf,config setlocal commentstring=#\ %s

" =============================================================================
" PLANTILLAS PARA ARCHIVOS NUEVOS
" =============================================================================

" Plantillas automáticas
autocmd BufNewFile *.c 0r ~/.config/nvim/templates/template.c
autocmd BufNewFile *.cpp 0r ~/.config/nvim/templates/template.cpp
autocmd BufNewFile *.py 0r ~/.config/nvim/templates/template.py
autocmd BufNewFile Makefile 0r ~/.config/nvim/templates/template.mk
autocmd BufNewFile *.h call InsertHeaderGuard()

" Función para crear header guards en archivos .h
function! InsertHeaderGuard()
    let guard = toupper(substitute(expand('%:t'), '\.', '_', 'g'))
    call append(0, ['#ifndef ' . guard, '#define ' . guard, '', '', '#endif // ' . guard])
    normal! 3G
endfunction

" Plantilla para archivos .h
autocmd BufNewFile *.h call InsertCHeader()

function! InsertCHeader()
    let filename = expand('%:t:r')
    call append(0, ['#ifndef ' . toupper(filename) . '_H'])
    call append(1, ['#define ' . toupper(filename) . '_H'])
    call append(2, [''])
    call append(3, ['#ifdef __cplusplus'])
    call append(4, ['extern "C" {'])
    call append(5, ['#endif'])
    call append(6, [''])
    call append(7, ['/* Declaraciones de funciones */'])
    call append(8, [''])
    call append(9, ['#ifdef __cplusplus'])
    call append(10, ['}'])
    call append(11, ['#endif'])
    call append(12, [''])
    call append(13, ['#endif // ' . toupper(filename) . '_H'])
    normal! 8G
endfunction

" =============================================================================
" FUNCIONES PERSONALIZADAS
" =============================================================================

" Función para compilar y ejecutar según el tipo de archivo
function! CompileAndRun()
    write
    let l:ext = expand('%:e')
    let l:file = expand('%')
    let l:name = expand('%:r')
    
    if l:ext == 'c'
        execute '!clear && gcc -Wall -Wextra -g -std=c99 ' . l:file . ' -o ' . l:name . ' && ./' . l:name
    elseif l:ext == 'cpp'
        execute '!clear && g++ -Wall -Wextra -g -std=c++17 ' . l:file . ' -o ' . l:name . ' && ./' . l:name
    elseif l:ext == 'py'
        execute '!clear && python3 ' . l:file
    elseif l:ext == 'java'
        execute '!clear && javac ' . l:file . ' && java ' . l:name
    elseif l:ext == 'go'
        execute '!clear && go run ' . l:file
    elseif l:ext == 'rs'
        execute '!clear && rustc ' . l:file . ' && ./' . l:name
    else
        echo 'Tipo de archivo no soportado para compilación automática'
    endif
endfunction

" Función para crear un nuevo proyecto
function! NewProject(name, type)
    let l:project_dir = expand('~/Proyectos/' . a:type . '/' . a:name)
    call mkdir(l:project_dir, 'p')
    
    if a:type == 'C'
        call writefile(['#include <stdio.h>', '', 'int main() {', '    printf("Hello, World!\n");', '    return 0;', '}'], l:project_dir . '/main.c')
        call writefile(['CC = gcc', 'CFLAGS = -Wall -Wextra -std=c99 -g', 'TARGET = main', 'SOURCES = main.c', '', 'all: $(TARGET)', '', '$(TARGET): $(SOURCES)', '	$(CC) $(CFLAGS) $(SOURCES) -o $(TARGET)', '', 'clean:', '	rm -f $(TARGET)', '', '.PHONY: all clean'], l:project_dir . '/Makefile')
    elseif a:type == 'CPP'
        call writefile(['#include <iostream>', '', 'int main() {', '    std::cout << "Hello, World!" << std::endl;', '    return 0;', '}'], l:project_dir . '/main.cpp')
        call writefile(['CXX = g++', 'CXXFLAGS = -Wall -Wextra -std=c++17 -g', 'TARGET = main', 'SOURCES = main.cpp', '', 'all: $(TARGET)', '', '$(TARGET): $(SOURCES)', '	$(CXX) $(CXXFLAGS) $(SOURCES) -o $(TARGET)', '', 'clean:', '	rm -f $(TARGET)', '', '.PHONY: all clean'], l:project_dir . '/Makefile')
    elseif a:type == 'Python'
        call writefile(['#!/usr/bin/env python3', '', 'def main():', '    print("Hello, World!")', '', 'if __name__ == "__main__":', '    main()'], l:project_dir . '/main.py')
        execute 'silent !chmod +x ' . l:project_dir . '/main.py'
    endif
    
    execute 'cd ' . l:project_dir
    echo 'Proyecto creado en: ' . l:project_dir
endfunction

" Comando para crear proyectos
command! -nargs=* NewProject call NewProject(<f-args>)

" =============================================================================
" CONFIGURACIÓN VISUAL Y COLORES
" =============================================================================

" Activar sintaxis
syntax on
filetype plugin indent on

" Esquema de colores mejorado
if has('termguicolors')
    set termguicolors
endif

" Colores personalizados
highlight CursorLine cterm=NONE ctermbg=235 ctermfg=NONE guibg=#2C2C2C
highlight CursorColumn cterm=NONE ctermbg=235 ctermfg=NONE guibg=#2C2C2C
highlight LineNr ctermfg=gray guifg=#666666
highlight CursorLineNr ctermfg=yellow guifg=#FFD700 cterm=bold gui=bold
highlight ColorColumn ctermbg=236 guibg=#303030
highlight MatchParen ctermbg=4 ctermfg=15 guibg=#005F87 guifg=#FFFFFF
highlight Search ctermbg=11 ctermfg=0 guibg=#FFFF00 guifg=#000000
highlight IncSearch ctermbg=9 ctermfg=15 guibg=#FF0000 guifg=#FFFFFF

" Colores para diferentes tipos de archivos
autocmd FileType c,cpp highlight cppSTLfunction ctermfg=cyan guifg=#00FFFF
autocmd FileType python highlight pythonFunction ctermfg=cyan guifg=#00FFFF

" =============================================================================
" CONFIGURACIONES ADICIONALES
" =============================================================================

" Mostrar espacios en blanco al final
highlight ExtraWhitespace ctermbg=red guibg=#FF0000
match ExtraWhitespace /\s\+$/
autocmd BufWinEnter * match ExtraWhitespace /\s\+$/
autocmd InsertEnter * match ExtraWhitespace /\s\+\%#\@<!$/
autocmd InsertLeave * match ExtraWhitespace /\s\+$/

" Eliminar espacios en blanco al guardar
autocmd BufWritePre * :%s/\s\+$//e

" Restaurar posición del cursor
autocmd BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif

" Guardar automáticamente al salir de insert mode
autocmd InsertLeave * if &modified && expand('%') != '' | silent write | endif

" Configuración de plegado (folding)
set foldenable
set foldlevelstart=10
set foldnestmax=10
set foldmethod=indent
nnoremap <space> za

" =============================================================================
" BARRA DE ESTADO PERSONALIZADA
" =============================================================================

" Configurar barra de estado
set laststatus=2
set noshowmode

function! GitBranch()
    return system("git rev-parse --abbrev-ref HEAD 2>/dev/null | tr -d '\n'")
endfunction

function! StatuslineGit()
    let l:branchname = GitBranch()
    return strlen(l:branchname) > 0 ? '  '.l:branchname.' ' : ''
endfunction

" Barra de estado personalizada
set statusline=
set statusline+=%#PmenuSel#
set statusline+=%{StatuslineGit()}
set statusline+=%#LineNr#
set statusline+=\ %f
set statusline+=%m
set statusline+=%=
set statusline+=%#CursorColumn#
set statusline+=\ %y
set statusline+=\ %{&fileencoding?&fileencoding:&encoding}
set statusline+=\[%{&fileformat}\]
set statusline+=\ %p%%
set statusline+=\ %l:%c
set statusline+=\ 

" =============================================================================
" COMANDOS PERSONALIZADOS
" =============================================================================

" Comando para formatear código
command! Format normal! gg=G

" Comando para ejecutar el archivo actual
command! Run call CompileAndRun()

" Comando para abrir terminal en split horizontal
command! Terminal split | terminal

" Comando para compilar con diferentes flags
command! -nargs=* Compile execute '!gcc -Wall -Wextra -g' <q-args> expand('%') '-o' expand('%:r')

" Comando para ver información del archivo
command! Info echo 'Archivo:' expand('%:p') '| Líneas:' line(') '| Tipo:' &filetype

" =============================================================================
" CONFIGURACIÓN DE DESARROLLO ESPECÍFICA
" =============================================================================

" Para archivos de configuración
autocmd FileType vim setlocal foldmethod=marker

" Resaltar todos los identificadores iguales al que está bajo el cursor
autocmd CursorHold * silent call matchadd('Search', '\<'.expand('<cword>').'\>', -1)
autocmd CursorMoved * call clearmatches()

" =============================================================================
" MAPEOS ADICIONALES PARA DESARROLLO
" =============================================================================

" Comentar/descomentar líneas
nnoremap <leader>/ :call ToggleComment()<CR>
vnoremap <leader>/ :call ToggleComment()<CR>

function! ToggleComment()
    let l:comment_char = GetCommentChar()
    if l:comment_char != ''
        if getline('.') =~ '^\s*' . l:comment_char
            execute 's/^\s*' . l:comment_char . '\s*//'
        else
            execute 's/^/' . l:comment_char . ' /'
        endif
    endif
endfunction

function! GetCommentChar()
    let l:ft = &filetype
    if l:ft == 'c' || l:ft == 'cpp' || l:ft == 'java' || l:ft == 'javascript'
        return '//'
    elseif l:ft == 'python' || l:ft == 'sh' || l:ft == 'bash'
        return '#'
    elseif l:ft == 'vim'
        return '"'
    else
        return '#'
    endif
endfunction

" Mapeos para tabs (no recomendado pero útil a veces)
nnoremap <leader>tn :tabnew<CR>
nnoremap <leader>tc :tabclose<CR>
nnoremap <leader>tm :tabmove<Space>

" =============================================================================
" CONFIGURACIÓN FINAL
" =============================================================================

" Configurar comportamiento del terminal
if has('nvim')
    tnoremap <Esc> <C-\><C-n>
    autocmd TermOpen * startinsert
endif

" Mensaje de bienvenida (comentado por defecto)
" autocmd VimEnter * echo "Neovim configurado para desarrollo - Presiona <leader>? para ayuda"

" Crear comando de ayuda personalizado
command! Help echo "Atajos principales:\n<F5> Compilar/ejecutar C\n<F6> Compilar/ejecutar C++\n<F7> Ejecutar Python\n<leader>w Guardar\n<leader>q Salir\n<leader>/ Comentar\n<leader>s Buscar/reemplazar"

nnoremap <leader>? :Help<CR>