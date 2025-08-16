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
