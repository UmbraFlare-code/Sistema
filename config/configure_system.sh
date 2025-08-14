#!/bin/bash
set -e

NEW_USER="$1"

# -------------------------------
# Instalar dependencias
# -------------------------------
sudo pacman -Sy --noconfirm \
    neovim \
    git \
    clang \
    fbterm \
    unzip \
    wget \
    fontconfig \
    freetype2 \
    ly

# -------------------------------
# Instalar Nerd Font Monofur
# -------------------------------
FONT_DIR="/home/$NEW_USER/.local/share/fonts"
mkdir -p "$FONT_DIR"
wget -O "$FONT_DIR/MonofurNerdFontMono-Regular.ttf" \
  "https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/Monofur/Regular/complete/Monofur%20Nerd%20Font%20Mono%20Regular.ttf"
fc-cache -fv

# -------------------------------
# Configuración de fbterm
# -------------------------------
sudo tee /etc/fbtermrc >/dev/null <<EOF
font-names=Monofur Nerd Font Mono
font-size=16
font-width=1
font-height=2
term=fbterm
cursor-shape=1
cursor-underline=0
EOF

# Permitir que el usuario use fbterm sin sudo
sudo gpasswd -a "$NEW_USER" video
sudo chmod u+s /usr/bin/fbterm

# -------------------------------
# Configuración de ly
# -------------------------------
sudo tee /etc/ly/config.ini >/dev/null <<EOF
[general]
lang = es_ES.UTF-8
tty = 1
save_user = true
save_session = true

[appearance]
font = Monofur Nerd Font:size=14
hide_cursor = false

[behavior]
login_delay = 0
timeout = 0
EOF

# Forzar que ly se ejecute dentro de fbterm
sudo mkdir -p /etc/systemd/system/ly.service.d
sudo tee /etc/systemd/system/ly.service.d/override.conf >/dev/null <<EOF
[Service]
ExecStart=
ExecStart=/usr/bin/fbterm -s 14 -- /usr/bin/ly
EOF

sudo systemctl disable getty@tty1
sudo systemctl enable ly.service

# -------------------------------
# Instalar vim-plug
# -------------------------------
sudo -u "$NEW_USER" sh -c 'curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
     https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'

# -------------------------------
# Configuración de Neovim
# -------------------------------
sudo -u "$NEW_USER" tee /home/$NEW_USER/.config/nvim/init.vim >/dev/null <<'EOF'
" ================================
" Configuración Neovim para C++
" ================================
set nocompatible
set encoding=utf-8
set number
set relativenumber
set tabstop=4
set shiftwidth=4
set expandtab
set cursorline
set mouse=a
syntax on
filetype plugin indent on

" ------------------------
" Plugins con vim-plug
" ------------------------
call plug#begin('~/.vim/plugged')

" Explorador de archivos
Plug 'preservim/nerdtree'
Plug 'ryanoasis/vim-devicons'

" Barra de estado
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

" Autocompletado inteligente
Plug 'neoclide/coc.nvim', {'branch': 'release'}

call plug#end()

" ------------------------
" Configuración NERDTree
" ------------------------
nnoremap <leader>e :NERDTreeToggle<CR>
autocmd VimEnter * NERDTree | wincmd p

" ------------------------
" Configuración de ventanas
" ------------------------
nnoremap <leader>v :vsplit<CR>
nnoremap <leader>s :split<CR>
nnoremap <C-h> <C-w>h
nnoremap <C-l> <C-w>l
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <A-=> :vertical resize +5<CR>
nnoremap <A--> :vertical resize -5<CR>

" ------------------------
" COC solo para C++
" ------------------------
autocmd FileType cpp,hpp,h,cxx,hxx :CocInstall -sync coc-clangd | q
autocmd BufReadPost *.cpp,*.hpp,*.h,*.c,*.cxx,*.hxx :silent! CocEnable

" Atajos C++
nmap <leader>d <Plug>(coc-definition)
nmap <leader>r <Plug>(coc-references)
nmap <leader>rn <Plug>(coc-rename)
nmap <leader>f <Plug>(coc-format)

" Mejoras visuales para Airline
let g:airline_powerline_fonts = 1
EOF

# -------------------------------
# Mensaje final
# -------------------------------
echo "✅ Configuración completada."
echo "El sistema iniciará con 'ly' en fbterm y recordará el último usuario."
echo "Entra a Neovim y ejecuta :PlugInstall para instalar los plugins."
