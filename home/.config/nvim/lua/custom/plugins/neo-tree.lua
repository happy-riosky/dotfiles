-- Neo-tree file explorer with in-tree fuzzy filtering
-- https://github.com/nvim-neo-tree/neo-tree.nvim
-- <leader>e reveals the current file; inside it, / filters the tree as you type.

vim.pack.add {
  { src = 'https://github.com/nvim-neo-tree/neo-tree.nvim', version = vim.version.range '*' },
  'https://github.com/nvim-lua/plenary.nvim',
  'https://github.com/MunifTanjim/nui.nvim',
}

vim.keymap.set('n', '<leader>e', '<Cmd>Neotree reveal<CR>', { desc = 'Toggle [E]xplorer', silent = true })

-- nvim >= 0.12 的 :restart 会保存并恢复 session；恢复时 buffer 名被展开成
-- <cwd>/neo-tree filesystem [1]，neo-tree 无法复用，重建时撞名报 E95。
-- 在 SessionLoadPost 清掉这些残留窗口与 buffer（含 neo-tree popup）。
local clean_restored_tree_buffers = function()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_get_name(buf):match 'neo%-tree [%w_]+ %[%d+%]$' then
      for _, win in ipairs(vim.fn.win_findbuf(buf)) do
        local tabpage = vim.api.nvim_win_get_tabpage(win)
        if #vim.api.nvim_tabpage_list_wins(tabpage) > 1 then
          pcall(vim.api.nvim_win_close, win, true)
        else
          pcall(vim.api.nvim_win_set_buf, win, vim.api.nvim_create_buf(true, false))
        end
      end
      pcall(vim.api.nvim_buf_delete, buf, { force = true })
    end
  end
end

vim.api.nvim_create_autocmd('SessionLoadPost', {
  group = vim.api.nvim_create_augroup('neotree-session-clean', { clear = true }),
  callback = clean_restored_tree_buffers,
})

require('neo-tree').setup {
  filesystem = {
    filtered_items = {
      hide_dotfiles = false,
      hide_gitignored = false,
    },
    window = {
      mappings = {
        ['<leader>e'] = 'close_window',
        -- 释放 <space>，让全局 <leader> 快捷键在树内可用
        ['<space>'] = 'none',
      },
    },
  },
}
