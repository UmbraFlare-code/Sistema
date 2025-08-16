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
