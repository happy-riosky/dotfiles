-- Oil: 像编辑文件一样编辑目录（重命名/移动/新建，:w 一次性应用）
-- https://github.com/stevearc/oil.nvim
-- -: 打开当前文件所在目录；树状浏览仍走 neo-tree（<leader>e），职责互补。

vim.pack.add { 'https://github.com/stevearc/oil.nvim' }

require('oil').setup {
  view_options = {
    show_hidden = true,
  },
}

vim.keymap.set('n', '-', '<Cmd>Oil<CR>', { desc = 'Open parent [D]irectory' })
