-- Aerial: 代码/文档大纲侧栏（markdown 场景即 frogmouth 的 Contents 面板）
-- https://github.com/stevearc/aerial.nvim
-- <leader>a: 开关侧栏并聚焦（同 <leader>e）；注意新版语义 focus = not bang。
-- 侧栏内：j/k 移动；J/K 移动+文档跟滚；PageUp/PageDown 滚文档不抢焦点；
-- p 对位不聚焦；Enter 跳转；C-j/k 置空以保留全局窗口导航。

vim.pack.add { 'https://github.com/stevearc/aerial.nvim' }

local scroll_doc = function(key)
  local source_win = require('aerial.util').get_winids(0)
  if source_win then vim.api.nvim_win_call(source_win, function() vim.cmd.normal { vim.api.nvim_replace_termcodes(key, true, true, true), bang = true } end) end
end

require('aerial').setup {
  keymaps = {
    ['<C-j>'] = false,
    ['<C-k>'] = false,
    ['J'] = 'actions.down_and_scroll',
    ['K'] = 'actions.up_and_scroll',
    ['<PageDown>'] = { callback = function() scroll_doc '<PageDown>' end, desc = 'Scroll doc down' },
    ['<PageUp>'] = { callback = function() scroll_doc '<PageUp>' end, desc = 'Scroll doc up' },
  },
}

vim.keymap.set('n', '<leader>a', '<cmd>AerialToggle<CR>', { desc = 'Toggle [A]erial outline' })
