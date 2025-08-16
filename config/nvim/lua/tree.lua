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
