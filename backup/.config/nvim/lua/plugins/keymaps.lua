-- telescope

vim.keymap.set("n", "<leader>fs", ":Telescope find_files<cr>")
vim.keymap.set("n", "<leader>fp", ":Telescope git_files<cr>")
vim.keymap.set("n", "<leader>fz", ":Telescope live_grep<cr>")
vim.keymap.set("n", "<leader>fo", ":Telescope oldfiles<cr>")

-- tree
vim.keymap.set("n", "<leader>e", ":NvimTreeFindFileToggle<cr>")

-- markdown preview
vim.keymap.set("n", "<leader>mp", ":MarkdownPreviewToggle<cr>")

-- markdown preview
vim.keymap.set({"n", "v"}, "<leader>c", ":CommentToggle<cr>")

-- hop easymotion
vim.keymap.set("n", "<leader>s", ":HopChar1<cr>")

-- 在 obsidian.nvim 的 setup 或 keymaps 部分添加
local function toggle_conceal()
  if vim.o.conceallevel == 0 then
    vim.o.conceallevel = 2
  else
    vim.o.conceallevel = 0
  end
end

-- 绑定键映射（替换原来的两个）
vim.keymap.set("n", "<leader>tl", toggle_conceal, { desc = "Toggle conceal level (0<->2)" })

