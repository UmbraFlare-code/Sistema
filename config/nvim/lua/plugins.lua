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
