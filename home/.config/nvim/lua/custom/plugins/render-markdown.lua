-- Markdown 阅读模式渲染（terminal 里 frogmouth 的 nvim 等价物）
-- https://github.com/MeanderingProgrammer/render-markdown.nvim
-- <leader>tm: 切换渲染；normal 模式看渲染视图，insert 模式自动显示原文
-- Checkbox 自定义状态（raw 匹配方括号内原文）：obsidian.nvim 的 <cr>/<leader>ch
-- 默认循环 ' ' → '~' → '!' → '>' → 'x'，这里以 ASCII 字符渲染（两列宽对齐默认
-- 图标 󰄱/󰱒）；语义组着色（Diagnostic*/@markup.raw）随 tinty 主题切换。
-- '- [-]'（cancelled）不在默认循环里，手输渲染为暗色。

vim.pack.add { 'https://github.com/MeanderingProgrammer/render-markdown.nvim' }

require('render-markdown').setup {
  checkbox = {
    custom = {
      todo = { raw = '[-]', rendered = '- ', highlight = 'RenderMarkdownTodo' },
      tilde = { raw = '[~]', rendered = '~ ', highlight = 'DiagnosticInfo' },
      important = { raw = '[!]', rendered = '! ', highlight = 'DiagnosticError' },
      deferred = { raw = '[>]', rendered = '> ', highlight = 'DiagnosticWarn' },
    },
  },
}

vim.keymap.set('n', '<leader>tm', '<cmd>RenderMarkdown toggle<CR>', { desc = '[T]oggle [M]arkdown render' })
