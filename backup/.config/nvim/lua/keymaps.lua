-- space bar leader key
vim.g.mapleader = " "

-- movement
vim.keymap.set("n", "j", "gj")
vim.keymap.set("n", "k", "gk")
vim.keymap.set("n", "H", "^")
vim.keymap.set("n", "J", "10j")
vim.keymap.set("n", "K", "10k")
vim.keymap.set("n", "L", "$")

-- save and quit
vim.keymap.set("n", "<leader>w", ":w<cr>")
vim.keymap.set("n", "<leader>q", ":q<cr>")
vim.keymap.set("n", "<leader>wq", ":wq<cr>")
vim.keymap.set("n", "<leader>Q", ":wqa<cr>")

-- buffers
vim.keymap.set("n", "<leader>]", ":bn<cr>")
vim.keymap.set("n", "<leader>[", ":bp<cr>")
vim.keymap.set("n", "<leader>x", ":bd<cr>")

-- yank to clipboard
vim.keymap.set({"n", "v"}, "<leader>y", [["+y]])
vim.keymap.set({"n", "v"}, "<leader>p", [["+p]])

-- black python formatting
vim.keymap.set("n", "<leader>fmp", ":silent !black %<cr>")

