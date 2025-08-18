#!/bin/bash
# Herramientas esenciales y Neovim con nvim-tree
# Uso: ./03-essential-tools.sh

set -e

echo "🛠️ Instalando herramientas esenciales..."

# Herramientas de desarrollo
DEV_PACKAGES=(
    gdb
    wget
    curl
    unzip
    tree
    htop
    ncdu
    ripgrep
    fd
)

echo "📦 Instalando herramientas de desarrollo..."
pacman -S --noconfirm "${DEV_PACKAGES[@]}"

# Configurar Neovim con nvim-tree
echo "📝 Configurando Neovim ultra-optimizado..."

# Copiar configuración de Neovim si existe
if [ -d "/home/$USER/sistema-install/config/nvim" ]; then
    echo "📁 Copiando configuración de Neovim..."
    cp -r /home/$USER/sistema-install/config/nvim /home/$USER/.config/
    echo "✅ Configuración de Neovim copiada"
else
    echo "📝 Creando configuración de Neovim desde cero..."
    # Crear directorios de configuración
    mkdir -p /home/$USER/.config/nvim/lua
    mkdir -p /home/$USER/.config/nvim/templates

# Configuración principal de Neovim
cat > /home/$USER/.config/nvim/init.lua << 'EOF'
-- ~/.config/nvim/init.lua
-- Configuración Neovim ultra-optimizada con Tree

-- Configuraciones básicas
require('options')
require('keys')
require('plugins')
require('tree')

-- Autocomandos para plantillas
vim.api.nvim_create_autocmd("BufNewFile", {
    pattern = "*.c",
    command = "0r ~/.config/nvim/templates/template.c"
})

vim.api.nvim_create_autocmd("BufNewFile", {
    pattern = "*.cpp", 
    command = "0r ~/.config/nvim/templates/template.cpp"
})

vim.api.nvim_create_autocmd("BufNewFile", {
    pattern = "*.py",
    command = "0r ~/.config/nvim/templates/template.py"
})

-- Compilación rápida
vim.keymap.set('n', '<F5>', ':w<CR>:!clear && gcc -O2 -march=native % -o %:r && ./%:r<CR>')
vim.keymap.set('n', '<F6>', ':w<CR>:!clear && g++ -O2 -march=native -std=c++17 % -o %:r && ./%:r<CR>')
vim.keymap.set('n', '<F7>', ':w<CR>:!clear && python3 %<CR>')
EOF

# Opciones de Neovim
cat > /home/$USER/.config/nvim/lua/options.lua << 'EOF'
-- ~/.config/nvim/lua/options.lua
-- Opciones básicas optimizadas para rendimiento

local opt = vim.opt

-- Rendimiento
opt.updatetime = 300
opt.timeoutlen = 500
opt.lazyredraw = false  -- Mejor en hardware modesto
opt.ttyfast = true

-- Interfaz mínima
opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.signcolumn = "yes"
opt.colorcolumn = "80"

-- Edición
opt.expandtab = true
opt.shiftwidth = 4
opt.tabstop = 4
opt.autoindent = true
opt.smartindent = true

-- Búsqueda
opt.ignorecase = true
opt.smartcase = true
opt.incsearch = true
opt.hlsearch = true

-- Archivos
opt.backup = false
opt.writebackup = false
opt.swapfile = false
opt.undofile = true
opt.undodir = vim.fn.expand("~/.config/nvim/undo")

-- Crear directorio undo si no existe
vim.fn.system("mkdir -p " .. vim.fn.expand("~/.config/nvim/undo"))

-- Clipboard
opt.clipboard = "unnamedplus"
EOF

# Atajos de teclado
cat > /home/$USER/.config/nvim/lua/keys.lua << 'EOF'
-- ~/.config/nvim/lua/keys.lua
-- Atajos de teclado optimizados

local keymap = vim.keymap

-- Leader key
vim.g.mapleader = " "

-- nvim-tree toggle (como VSCode Ctrl+Shift+E)
keymap.set('n', '<C-n>', ':NvimTreeToggle<CR>', { silent = true })
keymap.set('n', '<leader>e', ':NvimTreeFocus<CR>', { silent = true })

-- Navegación básica mejorada
keymap.set('n', '<C-h>', '<C-w>h')
keymap.set('n', '<C-j>', '<C-w>j')
keymap.set('n', '<C-k>', '<C-w>k')
keymap.set('n', '<C-l>', '<C-w>l')

-- Guardar y salir rápido
keymap.set('n', '<leader>w', ':w<CR>')
keymap.set('n', '<leader>q', ':q<CR>')
keymap.set('n', '<leader>x', ':wq<CR>')

-- Limpiar búsqueda
keymap.set('n', '<leader><space>', ':nohlsearch<CR>')

-- Navegación buffers
keymap.set('n', '<S-h>', ':bprevious<CR>')
keymap.set('n', '<S-l>', ':bnext<CR>')

-- Redimensionar ventanas
keymap.set('n', '<C-Up>', ':resize +2<CR>')
keymap.set('n', '<C-Down>', ':resize -2<CR>')
keymap.set('n', '<C-Left>', ':vertical resize -2<CR>')
keymap.set('n', '<C-Right>', ':vertical resize +2<CR>')
EOF

# Gestión de plugins
cat > /home/$USER/.config/nvim/lua/plugins.lua << 'EOF'
-- ~/.config/nvim/lua/plugins.lua
-- Plugin manager ultra-minimalista

-- Instalar packer si no existe
local fn = vim.fn
local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
if fn.empty(fn.glob(install_path)) > 0 then
  packer_bootstrap = fn.system({
    'git', 'clone', '--depth', '1', 
    'https://github.com/wbthomason/packer.nvim',
    install_path
  })
end

return require('packer').startup(function(use)
  -- Packer se gestiona a sí mismo
  use 'wbthomason/packer.nvim'

  -- File tree como VSCode (PLUGIN PRINCIPAL)
  use {
    'nvim-tree/nvim-tree.lua',
    requires = {
      'nvim-tree/nvim-web-devicons', -- Iconos opcionales
    }
  }

  -- Esquema de colores básico
  use 'navarasu/onedark.nvim'

  -- Autocompletado básico (opcional, consume ~10MB)
  use {
    'hrsh7th/nvim-cmp',
    requires = {
      'hrsh7th/cmp-buffer',
      'hrsh7th/cmp-path',
      'hrsh7th/cmp-cmdline',
      'L3MON4D3/LuaSnip',
      'saadparwaiz1/cmp_luasnip',
    },
    config = function()
      local cmp = require('cmp')
      cmp.setup({
        snippet = {
          expand = function(args)
            require('luasnip').lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ['<C-d>'] = cmp.mapping.scroll_docs(-4),
          ['<C-f>'] = cmp.mapping.scroll_docs(4),
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<C-e>'] = cmp.mapping.abort(),
          ['<CR>'] = cmp.mapping.confirm({ select = true }),
          ['<Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            else
              fallback()
            end
          end, { 'i', 's' }),
        }),
        sources = cmp.config.sources({
          { name = 'buffer' },
          { name = 'path' },
        })
      })
    end
  }

  -- Sincronizar plugins en primera instalación
  if packer_bootstrap then
    require('packer').sync()
  end
end)
EOF

# Configuración nvim-tree
cat > /home/$USER/.config/nvim/lua/tree.lua << 'EOF'
-- ~/.config/nvim/lua/tree.lua
-- nvim-tree configuración estilo VSCode

-- Configuración completa nvim-tree
require("nvim-tree").setup({
  -- Desactivar netrw (file explorer por defecto)
  disable_netrw = true,
  hijack_netrw = true,
  
  -- Comportamiento como VSCode
  view = {
    width = 30,
    side = "left",
    number = false,
    relativenumber = false,
  },
  
  -- Renderizado eficiente
  renderer = {
    add_trailing = false,
    group_empty = false,
    highlight_git = false,  -- Desactivar para ahorrar CPU
    highlight_opened_files = "none",
    root_folder_modifier = ":~",
    indent_markers = {
      enable = true,
      inline_arrows = true,
      icons = {
        corner = "└",
        edge = "│",
        item = "│",
        none = " ",
      },
    },
    icons = {
      webdev_colors = false,  -- Menos memoria
      git_placement = "before",
      padding = " ",
      symlink_arrow = " ➛ ",
      show = {
        file = true,
        folder = true,
        folder_arrow = true,
        git = false,  -- Desactivar para ahorrar CPU
      },
      glyphs = {
        default = "",
        symlink = "",
        bookmark = "",
        folder = {
          arrow_closed = "",
          arrow_open = "",
          default = "",
          open = "",
          empty = "",
          empty_open = "",
          symlink = "",
          symlink_open = "",
        },
        git = {
          unstaged = "✗",
          staged = "✓",
          unmerged = "",
          renamed = "➜",
          untracked = "★",
          deleted = "",
          ignored = "◌",
        },
      },
    },
  },
  
  -- Filtros para ocultar archivos
  filters = {
    dotfiles = false,
    custom = { "^.git$", "node_modules", ".cache" },
  },
  
  -- Acciones de archivo
  actions = {
    open_file = {
      quit_on_open = false,
      resize_window = false,
    },
    change_dir = {
      enable = true,
      global = false,
    },
  },
  
  -- Git integración ligera
  git = {
    enable = false,  -- Desactivar para mejor rendimiento
    ignore = true,
  },
  
  -- System open
  system_open = {
    cmd = "xdg-open",
    args = {},
  },
  
  -- Diagnósticos
  diagnostics = {
    enable = false,  -- Sin LSP para ahorrar recursos
  },
  
  -- Update focus
  update_focused_file = {
    enable = true,
    update_cwd = true,
  },
  
  -- Tab behavior
  tab = {
    sync = {
      open = false,
      close = false,
      ignore = {},
    },
  },
})

-- Auto-abrir nvim-tree si nvim se abre sin archivo
local function open_nvim_tree()
  if vim.fn.argc() == 0 then
    require("nvim-tree.api").tree.open()
  end
end

vim.api.nvim_create_autocmd("VimEnter", {
  callback = open_nvim_tree
})

-- Aplicar esquema de colores
vim.cmd.colorscheme('onedark')
EOF

# Plantillas de código
echo "📄 Creando plantillas de código..."

cat > /home/$USER/.config/nvim/templates/template.c << 'EOF'
#include <stdio.h>
#include <stdlib.h>

int main(int argc, char *argv[]) {
    printf("Hello, World!\n");
    return 0;
}
EOF

cat > /home/$USER/.config/nvim/templates/template.cpp << 'EOF'
#include <iostream>

int main() {
    std::cout << "Hello, World!" << std::endl;
    return 0;
}
EOF

cat > /home/$USER/.config/nvim/templates/template.py << 'EOF'
#!/usr/bin/env python3

def main():
    print("Hello, World!")

if __name__ == "__main__":
    main()
EOF

# Configurar permisos
chown -R $USER:$USER /home/$USER/.config/nvim

# Script de rendimiento
echo "⚡ Creando script de rendimiento..."
cat > /usr/local/bin/performance-mode.sh << 'EOF'
#!/bin/bash
# Activar modo rendimiento máximo

echo "🚀 Activando modo rendimiento máximo..."

# CPU governor performance
echo performance > /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# Limpiar caché
echo 3 > /proc/sys/vm/drop_caches

# Optimizar I/O
echo 0 > /proc/sys/vm/laptop_mode
echo 1 > /proc/sys/vm/drop_caches

echo "✅ Modo rendimiento activado!"
EOF

chmod +x /usr/local/bin/performance-mode.sh

# Script de limpieza de memoria
cat > /usr/local/bin/memory-cleanup.sh << 'EOF'
#!/bin/bash
# Limpieza de memoria

echo "🧹 Limpiando memoria..."

# Limpiar caché
echo 1 > /proc/sys/vm/drop_caches
echo 2 > /proc/sys/vm/drop_caches
echo 3 > /proc/sys/vm/drop_caches

# Limpiar buffers
sync

echo "✅ Memoria limpiada!"
EOF

chmod +x /usr/local/bin/memory-cleanup.sh

# Configuración final
echo "🎯 Configuración final..."

# Crear alias para modo rendimiento
echo 'alias perf="sudo performance-mode.sh"' >> /home/$USER/.bashrc
echo 'alias clean="sudo memory-cleanup.sh"' >> /home/$USER/.bashrc

# Configurar tmux
cat > /home/$USER/.tmux.conf << 'EOF'
# Configuración tmux minimalista
set -g default-terminal "screen-256color"
set -g status off
set -g mouse on
set -g base-index 1
setw -g pane-base-index 1

# Atajos rápidos
bind-key v split-window -h
bind-key s split-window -v
bind-key h select-pane -L
bind-key j select-pane -D
bind-key k select-pane -U
bind-key l select-pane -R
EOF

chown $USER:$USER /home/$USER/.tmux.conf

echo "✅ Herramientas esenciales instaladas!"
echo "🎉 ¡Sistema ultra-minimalista completado!"
echo ""
echo "📊 Consumo estimado:"
echo "   Sistema Base: ~290MB"
echo "   X11 + dwm: ~66MB"
echo "   Neovim + nvim-tree: ~60MB"
echo "   Total: ~416MB"
echo "   RAM libre: ~3.5GB"
echo ""
echo "🚀 Comandos útiles:"
echo "   perf - Activar modo rendimiento"
echo "   clean - Limpiar memoria"
echo "   v - Abrir Neovim"
echo "   tmux - Iniciar sesión tmux"
echo ""
echo "🎯 ¡Disfruta del máximo rendimiento en tu Celeron 4GB!"
