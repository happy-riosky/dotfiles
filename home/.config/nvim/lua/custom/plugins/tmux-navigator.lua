-- vim-tmux-navigator: C-h/j/k/l 无缝导航 nvim 窗口与 tmux pane
-- https://github.com/christoomey/vim-tmux-navigator
-- nvim 侧到窗口边缘自动回退 `tmux select-pane`（tmux 侧 is_vim 守卫在
-- .tmux.conf）；接管 kickstart 的 C-hjkl 窗口键（init.lua 原映射已删，
-- aerial 的 C-j/k 置空也让位）。zoomed pane（prefix+z）内不跳出。

vim.pack.add { 'https://github.com/christoomey/vim-tmux-navigator' }

vim.g.tmux_navigator_disable_when_zoomed = 1
