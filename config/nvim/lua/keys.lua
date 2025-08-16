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
