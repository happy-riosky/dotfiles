#!/usr/bin/env bash
# sisyphus.sh - prefix+C-s 弹窗入口：nvim 打开 Obsidian vault 根部的
# sisyphus.md，经嵌套会话启动（弹窗总注释见 .tmux.conf）。
# vault 不存在时静默退出（exit 0，弹窗一闪而过）。
# q/C-d 快退：实例级全局映射 :wqa（自动保存+退出→嵌套会话消亡→弹窗
# 关闭）；-c 逐次注入故仅此 nvim 实例生效——切 buffer 仍有效，其他 nvim
# 与共享配置零影响；仅 normal mode，insert 打字不受影响；代价是整个弹窗
# 实例内 q 不再录宏。
set -euo pipefail

vault="$HOME/Documents/Obsidian/sisyphus"
note="$vault/sisyphus.md"
[ -f "$note" ] || exit 0

exec tmux new-session -c "$vault" \
  nvim -c 'nnoremap q :wqa<CR>' -c 'nnoremap <C-d> :wqa<CR>' "$note" \
  \; set status off \; set destroy-unattached on
