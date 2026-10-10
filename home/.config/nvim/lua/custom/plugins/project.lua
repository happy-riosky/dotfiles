-- Project.nvim: 项目历史 + :Telescope projects 切换（DrKJeff16 维护 fork）
-- https://github.com/DrKJeff16/project.nvim
-- <leader>sp 打开项目选择器；picker 内 f=找文件 s=live grep w=改 cwd d=删除
--       n=重命名 r=最近文件 b=浏览；无 session 集成（fd 不装也能用）。
-- 打开 git root 内的文件即自动记录该项目，历史存于 stdpath('data')。

vim.pack.add { 'https://github.com/DrKJeff16/project.nvim' }

require('project').setup {
  telescope = {
    sort = 'newest', -- 最近使用的项目排前
    tilde = true, -- 路径显示为 ~/...
  },
}

require('telescope').load_extension 'projects'

vim.keymap.set('n', '<leader>sp', '<Cmd>Telescope projects<CR>', { desc = '[S]earch [P]rojects' })
