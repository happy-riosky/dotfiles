-- vim-tmux-navigator: C-h/j/k/l 无缝导航 nvim 窗口与 tmux pane
-- https://github.com/christoomey/vim-tmux-navigator
-- nvim 侧到窗口边缘自动回退 `tmux select-pane`（tmux 侧 is_vim 守卫在
-- .tmux.conf）；接管 kickstart 的 C-hjkl 窗口键（init.lua 原映射已删，
-- aerial 的 C-j/k 置空也让位）。zoomed pane（prefix+z）内不跳出。
-- no_mappings=1（对齐 .vimrc）：$TMUX 下插件自带的 t 模式 expr 映射
-- `IsFZF() ? "<C-j>" : "<C-w>:…TmuxNavigate*"` 是 Vim 术语（terminal
-- window 前缀），且在 init 之后加载会覆盖自定义 t 映射；nvim 终端模式
-- 只有 <C-\> 特殊，`<C-w>:…` 整串字节会被打进终端程序（lazygit 里触发
-- 非预期行为）。故 normal/t 模式映射全部自管。
-- 浮窗感知一步导航：浮窗（lazygit/toggleterm float）盖住下方 split，
-- TmuxNavigate* 的 wincmd 只会钻到浮窗背后（“第一次 C-l 离开弹窗、
-- 第二次才到 tmux”）；故浮窗内跳过 wincmd 直接 `tmux select-pane` 一步
-- 到位（绕过 zoom 守卫：从弹窗显式跳出永远应生效），弹窗保持打开。
-- t 模式经函数 rhs 直接派发，无需 <C-\><C-n>——不切模式，返回弹窗仍在
-- 终端模式。代价：终端缓冲区内 shell 失去原生 C-h(backspace)/
-- C-j(enter)/C-k(kill-line)/C-l(clear)。

vim.g.tmux_navigator_no_mappings = 1

vim.pack.add { 'https://github.com/christoomey/vim-tmux-navigator' }

vim.g.tmux_navigator_disable_when_zoomed = 1

local nav_name = { h = 'Left', j = 'Down', k = 'Up', l = 'Right', p = 'Previous' }
local nav_flag = { h = 'L', j = 'D', k = 'U', l = 'R', p = 'l' }

local function navigate(dir)
  if vim.env.TMUX and vim.api.nvim_win_get_config(0).relative ~= '' then
    vim.fn.system { 'tmux', 'select-pane', '-t', vim.env.TMUX_PANE, '-' .. nav_flag[dir] }
    return
  end
  vim.cmd('TmuxNavigate' .. nav_name[dir])
end

for _, dir in ipairs { 'h', 'j', 'k', 'l' } do
  vim.keymap.set('n', '<C-' .. dir .. '>', function() navigate(dir) end, { silent = true, desc = 'Navigate ' .. nav_name[dir]:lower() })
  vim.keymap.set('t', '<C-' .. dir .. '>', function() navigate(dir) end, { silent = true, desc = 'Navigate ' .. nav_name[dir]:lower() .. ' (from terminal mode)' })
end
vim.keymap.set('n', '<C-\\>', function() navigate('p') end, { silent = true, desc = 'Navigate previous (tmux last pane)' })
