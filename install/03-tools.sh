#!/bin/bash
# Herramientas esenciales y Neovim con nvim-tree para sistema ultra-ligero
# Uso: ./03-tools.sh

set -e

echo "🛠️ Instalando herramientas esenciales ultra-ligeras..."

# Verificar que estamos ejecutando como root
if [ "$EUID" -ne 0 ]; then
    echo "❌ Error: Este script debe ejecutarse como root (sudo)"
    exit 1
fi

# Obtener el usuario actual (no root)
CURRENT_USER=$(logname 2>/dev/null || echo $SUDO_USER)
if [ -z "$CURRENT_USER" ]; then
    echo "❌ Error: No se pudo determinar el usuario actual"
    exit 1
fi

# Verificar espacio disponible
AVAILABLE_SPACE=$(df / | awk 'NR==2 {print $4}')
echo "💾 Espacio disponible: $((AVAILABLE_SPACE / 1024))MB"

if [ "$AVAILABLE_SPACE" -lt 200000 ]; then  # 200MB mínimo
    echo "⚠️ Advertencia: Espacio muy limitado"
    echo "   Se instalará solo lo esencial"
    MINIMAL_MODE=true
else
    MINIMAL_MODE=false
fi

# Función para instalar paquetes con verificación
install_package_safe() {
    local package=$1
    echo "📦 Instalando: $package"
    
    if pacman -S --noconfirm "$package"; then
        echo "   ✅ $package instalado exitosamente"
        return 0
    else
        echo "   ⚠️ Error al instalar $package, continuando..."
        return 1
    fi
}

# Herramientas de desarrollo esenciales (ultra-ligeras)
if [ "$MINIMAL_MODE" = false ]; then
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
    for package in "${DEV_PACKAGES[@]}"; do
        if ! pacman -Q "$package" >/dev/null 2>&1; then
            install_package_safe "$package"
        else
            echo "✅ $package ya está instalado"
        fi
    done
else
    # Modo ultra-minimal: solo lo básico
    ESSENTIAL_PACKAGES=(
        wget
        htop
        tree
    )
    
    echo "📦 Instalando solo herramientas esenciales (modo minimal)..."
    for package in "${ESSENTIAL_PACKAGES[@]}"; do
        if ! pacman -Q "$package" >/dev/null 2>&1; then
            install_package_safe "$package"
        else
            echo "✅ $package ya está instalado"
        fi
    done
fi

# Configurar Neovim con nvim-tree
echo "📝 Configurando Neovim ultra-optimizado..."

# Crear directorio de configuración del usuario
mkdir -p /home/$CURRENT_USER/.config

# Copiar configuración de Neovim si existe
if [ -d "/home/$CURRENT_USER/sistema-install/config/nvim" ]; then
    echo "📁 Copiando configuración de Neovim..."
    cp -r /home/$CURRENT_USER/sistema-install/config/nvim /home/$CURRENT_USER/.config/
    chown -R $CURRENT_USER:$CURRENT_USER /home/$CURRENT_USER/.config/nvim
    echo "✅ Configuración de Neovim copiada"
else
    echo "📝 Creando configuración de Neovim desde cero..."
    # Crear directorios de configuración
    mkdir -p /home/$CURRENT_USER/.config/nvim/lua
    mkdir -p /home/$CURRENT_USER/.config/nvim/templates

# Configuración principal de Neovim
cat > /home/$CURRENT_USER/.config/nvim/init.lua << 'EOF'
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

-- Compilación rápida optimizada para Celeron
vim.keymap.set('n', '<F5>', ':w<CR>:!clear && gcc -O2 -march=native % -o %:r && ./%:r<CR>')
vim.keymap.set('n', '<F6>', ':w<CR>:!clear && g++ -O2 -march=native -std=c++17 % -o %:r && ./%:r<CR>')
vim.keymap.set('n', '<F7>', ':w<CR>:!clear && python3 %<CR>')

-- Atajos adicionales para bspwm
vim.keymap.set('n', '<F8>', ':w<CR>:!clear && make<CR>')
vim.keymap.set('n', '<F9>', ':w<CR>:!clear && ./run.sh<CR>')
EOF

# Opciones de Neovim optimizadas
cat > /home/$CURRENT_USER/.config/nvim/lua/options.lua << 'EOF'
-- ~/.config/nvim/lua/options.lua
-- Opciones básicas optimizadas para rendimiento en Celeron 4GB

local opt = vim.opt

-- Rendimiento máximo
opt.updatetime = 300
opt.timeoutlen = 500
opt.lazyredraw = false  -- Mejor en hardware modesto
opt.ttyfast = true
opt.synmaxcol = 200     -- Limitar syntax highlighting en líneas largas

-- Interfaz ultra-mínima
opt.number = true
opt.relativenumber = false  -- Desactivado para mejor rendimiento
opt.cursorline = false      -- Desactivado para ahorrar CPU
opt.signcolumn = "no"       -- Sin columna de signos
opt.colorcolumn = ""        -- Sin columna de color

-- Edición básica
opt.expandtab = true
opt.shiftwidth = 4
opt.tabstop = 4
opt.autoindent = true
opt.smartindent = false     -- Menos procesamiento

-- Búsqueda
opt.ignorecase = true
opt.smartcase = true
opt.incsearch = true
opt.hlsearch = false        -- Sin highlight para mejor rendimiento

-- Archivos - sin backups para ahorrar I/O
opt.backup = false
opt.writebackup = false
opt.swapfile = false
opt.undofile = false        -- Sin undo persistente para ahorrar espacio

-- Clipboard (si está disponible)
if vim.fn.has('clipboard') == 1 then
    opt.clipboard = "unnamedplus"
end

-- Desactivar plugins innecesarios
vim.g.loaded_gzip = 1
vim.g.loaded_tar = 1
vim.g.loaded_tarPlugin = 1
vim.g.loaded_zip = 1
vim.g.loaded_zipPlugin = 1
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
EOF

# Atajos de teclado optimizados para bspwm
cat > /home/$CURRENT_USER/.config/nvim/lua/keys.lua << 'EOF'
-- ~/.config/nvim/lua/keys.lua
-- Atajos de teclado optimizados para bspwm

local keymap = vim.keymap

-- Leader key
vim.g.mapleader = " "

-- nvim-tree toggle (integración con bspwm)
keymap.set('n', '<C-n>', ':NvimTreeToggle<CR>', { silent = true })
keymap.set('n', '<leader>e', ':NvimTreeFocus<CR>', { silent = true })

-- Navegación básica (compatible con bspwm)
keymap.set('n', '<C-h>', '<C-w>h')
keymap.set('n', '<C-j>', '<C-w>j')
keymap.set('n', '<C-k>', '<C-w>k')
keymap.set('n', '<C-l>', '<C-w>l')

-- Guardar y salir rápido
keymap.set('n', '<leader>w', ':w<CR>')
keymap.set('n', '<leader>q', ':q<CR>')
keymap.set('n', '<leader>x', ':wq<CR>')

-- Navegación de buffers (optimizado)
keymap.set('n', '<S-h>', ':bprevious<CR>')
keymap.set('n', '<S-l>', ':bnext<CR>')

-- Redimensionar ventanas (compatible con bspwm)
keymap.set('n', '<C-Up>', ':resize +2<CR>')
keymap.set('n', '<C-Down>', ':resize -2<CR>')
keymap.set('n', '<C-Left>', ':vertical resize -2<CR>')
keymap.set('n', '<C-Right>', ':vertical resize +2<CR>')

-- Atajos específicos para desarrollo ligero
keymap.set('n', '<leader>c', ':!clear<CR>')
keymap.set('n', '<leader>r', ':!./run.sh<CR>')
keymap.set('n', '<leader>m', ':!make<CR>')
EOF

# Plugin manager ultra-minimalista
cat > /home/$CURRENT_USER/.config/nvim/lua/plugins.lua << 'EOF'
-- ~/.config/nvim/lua/plugins.lua
-- Plugin manager ultra-minimalista para Celeron 4GB

-- Solo instalar plugins si hay espacio suficiente
local fn = vim.fn
local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'

-- Verificar espacio disponible
local space_check = io.popen("df / | awk 'NR==2 {print $4}'")
local available_space = tonumber(space_check:read("*a"))
space_check:close()

local minimal_mode = available_space < 500000  -- Menos de 500MB

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

  if not minimal_mode then
    -- File tree como VSCode (PLUGIN PRINCIPAL)
    use {
      'nvim-tree/nvim-tree.lua',
      requires = {
        'nvim-tree/nvim-web-devicons', -- Iconos opcionales
      }
    }

    -- Esquema de colores básico
    use 'navarasu/onedark.nvim'

    -- Autocompletado básico solo si hay espacio
    use {
      'hrsh7th/nvim-cmp',
      requires = {
        'hrsh7th/cmp-buffer',
        'hrsh7th/cmp-path',
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
            ['<C-Space>'] = cmp.mapping.complete(),
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
  else
    -- Modo ultra-minimal: solo colores básicos
    use 'default'
  end

  -- Sincronizar plugins en primera instalación
  if packer_bootstrap then
    require('packer').sync()
  end
end)
EOF

# Configuración nvim-tree optimizada
cat > /home/$CURRENT_USER/.config/nvim/lua/tree.lua << 'EOF'
-- ~/.config/nvim/lua/tree.lua
-- nvim-tree configuración ultra-optimizada para Celeron 4GB

-- Solo cargar si nvim-tree está disponible
local status_ok, nvim_tree = pcall(require, "nvim-tree")
if not status_ok then
  -- Fallback: usar netrw básico
  vim.g.netrw_banner = 0
  vim.g.netrw_liststyle = 3
  return
end

-- Configuración ultra-eficiente
nvim_tree.setup({
  -- Desactivar netrw
  disable_netrw = true,
  hijack_netrw = true,
  
  -- Vista minimalista
  view = {
    width = 25,  -- Más estrecho para ahorrar espacio
    side = "left",
    number = false,
    relativenumber = false,
  },
  
  -- Renderizado ultra-eficiente
  renderer = {
    add_trailing = false,
    group_empty = true,        -- Agrupar directorios vacíos
    highlight_git = false,
    highlight_opened_files = "none",
    root_folder_modifier = ":~",
    indent_markers = {
      enable = false,          -- Desactivar para mejor rendimiento
    },
    icons = {
      webdev_colors = false,
      git_placement = "before",
      show = {
        file = false,          -- Sin iconos de archivo
        folder = true,
        folder_arrow = true,
        git = false,
      },
      glyphs = {
        default = "",
        symlink = "",
        folder = {
          arrow_closed = ">",
          arrow_open = "v",
          default = "[D]",
          open = "[D]",
          empty = "[D]",
          empty_open = "[D]",
          symlink = "[L]",
          symlink_open = "[L]",
        },
      },
    },
  },
  
  -- Filtros optimizados
  filters = {
    dotfiles = false,
    custom = { "^.git$", "node_modules", ".cache", "__pycache__", "*.o", "*.so" },
  },
  
  -- Desactivar características pesadas
  git = {
    enable = false,
    ignore = true,
  },
  
  diagnostics = {
    enable = false,
  },
  
  -- Acciones básicas
  actions = {
    open_file = {
      quit_on_open = true,     -- Cerrar árbol al abrir archivo
      resize_window = false,
    },
  },
  
  -- Update focus básico
  update_focused_file = {
    enable = false,            -- Desactivar para mejor rendimiento
  },
})

-- Solo auto-abrir si hay pocos argumentos
local function open_nvim_tree()
  if vim.fn.argc() == 0 and vim.fn.line2byte('$') == -1 then
    nvim_tree.api.tree.open()
  end
end

vim.api.nvim_create_autocmd("VimEnter", {
  callback = open_nvim_tree
})

-- Aplicar esquema de colores solo si está disponible
pcall(function()
  vim.cmd.colorscheme('onedark')
end)
EOF

# Plantillas de código optimizadas
echo "📄 Creando plantillas de código..."

cat > /home/$CURRENT_USER/.config/nvim/templates/template.c << 'EOF'
#include <stdio.h>
#include <stdlib.h>

int main(int argc, char *argv[]) {
    printf("Hello, World!\n");
    return 0;
}
EOF

cat > /home/$CURRENT_USER/.config/nvim/templates/template.cpp << 'EOF'
#include <iostream>

int main() {
    std::cout << "Hello, World!" << std::endl;
    return 0;
}
EOF

cat > /home/$CURRENT_USER/.config/nvim/templates/template.py << 'EOF'
#!/usr/bin/env python3

def main():
    print("Hello, World!")

if __name__ == "__main__":
    main()
EOF

    # Configurar permisos
    chown -R $CURRENT_USER:$CURRENT_USER /home/$CURRENT_USER/.config/nvim
fi

# Scripts de rendimiento
echo "⚡ Creando scripts de rendimiento..."

# Script de rendimiento
cat > /usr/local/bin/perf << 'EOF'
#!/bin/bash
# Activar modo rendimiento máximo para Celeron

echo "🚀 Activando modo rendimiento máximo..."

# CPU governor performance (si está disponible)
if [ -d "/sys/devices/system/cpu/cpu0/cpufreq" ]; then
    echo performance | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor > /dev/null
    echo "✅ CPU governor: performance"
fi

# Limpiar caché
echo 3 > /proc/sys/vm/drop_caches
echo "✅ Caché limpiado"

# Optimizar I/O scheduler
for disk in /sys/block/sd*; do
    if [ -d "$disk" ]; then
        echo noop > $disk/queue/scheduler 2>/dev/null || echo "⚠️ No se pudo cambiar scheduler"
    fi
done

echo "✅ Modo rendimiento activado!"
echo "📊 Memoria libre: $(free -h | awk 'NR==2{print $7}')"
EOF

chmod +x /usr/local/bin/perf

# Script de limpieza de memoria
cat > /usr/local/bin/clean << 'EOF'
#!/bin/bash
# Limpieza de memoria para Celeron 4GB

echo "🧹 Limpiando memoria..."

# Limpiar diferentes tipos de caché
echo 1 > /proc/sys/vm/drop_caches  # Page cache
sleep 1
echo 2 > /proc/sys/vm/drop_caches  # Dentries e inodes
sleep 1
echo 3 > /proc/sys/vm/drop_caches  # Todo
sync

# Compactar memoria
echo 1 > /proc/sys/vm/compact_memory 2>/dev/null || true

echo "📊 Estado de memoria:"
free -h

echo "✅ Memoria limpiada!"
EOF

chmod +x /usr/local/bin/clean

# Configuración final
echo "🎯 Configuración final..."

# Crear aliases útiles
cat >> /home/$CURRENT_USER/.bashrc << 'EOF'

# Aliases para sistema ultra-ligero
alias ll='ls -la'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias v='nvim'
alias c='gcc -O2 -march=native'
alias cpp='g++ -O2 -march=native -std=c++17'
alias py='python3'

# Funciones útiles
cr() { gcc -O2 -march=native "$1" -o "${1%.*}" && ./"${1%.*}"; }
cpprun() { g++ -O2 -march=native -std=c++17 "$1" -o "${1%.*}" && ./"${1%.*}"; }

# Prompt minimalista
PS1='[\u@\h \W]\$ '
EOF

# Configurar tmux ultra-ligero
cat > /home/$CURRENT_USER/.tmux.conf << 'EOF'
# Configuración tmux ultra-minimalista para Celeron 4GB
set -g default-terminal "screen-256color"
set -g status off                    # Sin barra de estado para ahorrar memoria
set -g mouse on
set -g base-index 1
setw -g pane-base-index 1

# Sin historial extenso
set -g history-limit 1000

# Atajos básicos
bind-key v split-window -h
bind-key s split-window -v
bind-key h select-pane -L
bind-key j select-pane -D
bind-key k select-pane -U
bind-key l select-pane -R

# Redimensionar rápido
bind-key -r H resize-pane -L 5
bind-key -r J resize-pane -D 5
bind-key -r K resize-pane -U 5
bind-key -r L resize-pane -R 5

# Copiar modo vim
setw -g mode-keys vi
bind Enter copy-mode
EOF

# Configurar permisos finales
chown $CURRENT_USER:$CURRENT_USER /home/$CURRENT_USER/.bashrc
chown $CURRENT_USER:$CURRENT_USER /home/$CURRENT_USER/.tmux.conf

# Limpiar cache de pacman
echo "🧹 Limpiando cache de instalación..."
pacman -Sc --noconfirm || true

echo "✅ Herramientas esenciales instaladas!"
echo "🎉 ¡Sistema ultra-minimalista completado!"
echo ""
echo "📊 Consumo estimado:"
echo "   Sistema Base: ~290MB"
echo "   X11 + bspwm: ~66MB"
echo "   Neovim + nvim-tree: ~60MB"
echo "   Total: ~416MB"
echo "   RAM libre: ~3.5GB"
echo ""
echo "🚀 Comandos útiles:"
echo "   perf - Activar modo rendimiento"
echo "   clean - Limpiar memoria"
echo "   v - Abrir Neovim"
echo "   tmux - Iniciar sesión tmux"
echo "   cr file.c - Compilar y ejecutar C"
echo "   cpprun file.cpp - Compilar y ejecutar C++"
echo ""
echo "🎯 ¡Disfruta del máximo rendimiento en tu Celeron 4GB con bspwm!"