-- Obsidian vault 集成（https://github.com/epwalsh/obsidian.nvim）
-- 多 vault：进入 vault 内 markdown buffer 时自动按 .obsidian 根切换 workspace。
-- vault 列表按本机存在性过滤；无 vault 的机器（server/Termux）整模块跳过。
-- 渲染已由 render-markdown.nvim 承担（ui.enable = false 避免双重 extmark）。
-- 注意：wiki 链接/标签补全上游仅支持 nvim-cmp，本配置用 blink.cmp，补全不可用；
-- 其余功能（:Obsidian* 命令、gf 跟链、telescope 搜索）完整。
-- macOS 贴图命令 :ObsidianPasteImg 需 brew install pngpaste。

local vaults = {
  { name = 'agentic-wiki', path = '~/Documents/llm-wiki/agentic-wiki' },
  { name = 'Life', path = '~/Documents/Obsidian/Life/Life' },
  { name = 'Computer', path = '~/Documents/Obsidian/Computer' },
  { name = 'sisyphus', path = '~/Documents/Obsidian/sisyphus' },
}

local workspaces = {}
for _, vault in ipairs(vaults) do
  if vim.uv.fs_stat(vim.fn.expand(vault.path)) then table.insert(workspaces, { name = vault.name, path = vault.path }) end
end

if #workspaces == 0 then return end

vim.pack.add { 'https://github.com/epwalsh/obsidian.nvim' }

require('obsidian').setup {
  workspaces = workspaces,
  completion = { nvim_cmp = false },
  picker = { name = 'telescope.nvim' },
  ui = { enable = false },
}

-- vault buffer 内默认映射（上游，buffer-local）：gf 跟链、<cr> 智能动作、
-- <leader>ch 切换 checkbox；全局命令入口集中在前缀 <leader>o
vim.keymap.set('n', '<leader>oo', '<cmd>ObsidianQuickSwitch<CR>', { desc = '[O]bsidian quick switch note' })
vim.keymap.set('n', '<leader>os', '<cmd>ObsidianSearch<CR>', { desc = '[O]bsidian [s]earch notes' })
vim.keymap.set('n', '<leader>on', '<cmd>ObsidianNew<CR>', { desc = '[O]bsidian [n]ew note' })
vim.keymap.set('n', '<leader>od', '<cmd>ObsidianToday<CR>', { desc = '[O]bsidian [d]aily note (today)' })
vim.keymap.set('n', '<leader>ob', '<cmd>ObsidianBacklinks<CR>', { desc = '[O]bsidian [b]acklinks' })
vim.keymap.set('n', '<leader>ow', '<cmd>ObsidianWorkspace<CR>', { desc = '[O]bsidian switch [w]orkspace (vault)' })

if vim.fn.executable 'pngpaste' == 1 then
  vim.keymap.set('n', '<leader>oi', '<cmd>ObsidianPasteImg<CR>', { desc = '[O]bsidian paste [i]mage from clipboard' })
end
