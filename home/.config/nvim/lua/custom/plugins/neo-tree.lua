-- Neo-tree file explorer with in-tree fuzzy filtering
-- https://github.com/nvim-neo-tree/neo-tree.nvim
-- <leader>e reveals the current file; inside it, / filters the tree as you type.

vim.pack.add {
  { src = 'https://github.com/nvim-neo-tree/neo-tree.nvim', version = vim.version.range '*' },
  'https://github.com/nvim-lua/plenary.nvim',
  'https://github.com/MunifTanjim/nui.nvim',
}

vim.keymap.set('n', '<leader>e', '<Cmd>Neotree reveal<CR>', { desc = 'Toggle [E]xplorer', silent = true })

require('neo-tree').setup {
  filesystem = {
    filtered_items = {
      hide_dotfiles = false,
      hide_gitignored = false,
    },
    window = {
      mappings = {
        ['<leader>e'] = 'close_window',
      },
    },
  },
}
