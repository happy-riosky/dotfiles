-- Markdown 阅读模式渲染（terminal 里 frogmouth 的 nvim 等价物）
-- https://github.com/MeanderingProgrammer/render-markdown.nvim
-- <leader>tm: 切换渲染；normal 模式看渲染视图，insert 模式自动显示原文

vim.pack.add { 'https://github.com/MeanderingProgrammer/render-markdown.nvim' }

require('render-markdown').setup {}

vim.keymap.set('n', '<leader>tm', '<cmd>RenderMarkdown toggle<CR>', { desc = '[T]oggle [M]arkdown render' })
