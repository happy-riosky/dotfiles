#!/usr/bin/env bash
# chat-popup.sh - prefix+C-g 极简 CLI 聊天：read → aichat → 打印，死循环。
# aichat 无 --session 完全无状态，对话不落任何本地库（opencode run 每轮写
# session 库，故弃用）。convo=Human:/AI: 转写完整重放（整段重放）；resp=最后
# 一条回复。协议指令 sysprompt 内嵌于本脚本（自包含，不依赖机器本地 role
# 文件，换机即可用）。命令：/y 复制回复、/yq 复制并退、/l less 看转写、
# /q 或 Ctrl-D 退出；/q 后按 y 复制（pbcopy/less 缺失均静默降级）。
# 模型显示自 aichat --info（macOS/Linux 配置路径不同，不直接读文件）；
# CHAT_MODEL 可覆盖显示与 -m。
set -euo pipefail

if ! command -v aichat >/dev/null 2>&1; then
  printf 'aichat not found — brew install aichat\n'
  IFS= read -r -t 2 _ 2>/dev/null </dev/tty || true
  exit 127
fi

# 注意：aichat 会对非 tty 的 stdin 自动读取（当作管道输入），命令替换里
# 不加 </dev/null 会把本脚本的输入流喝掉——所有 aichat 调用一律钉死 stdin。
# aichat 加 -S（关流式）：流式重组在长回复下曾出现丢字/乱码（"canД"），
# 关流式让回复一次性写出；NO_COLOR 兜底去 ANSI。
model=$(NO_COLOR=1 aichat --info </dev/null 2>/dev/null | awk '$1=="model"{print $2; exit}')
printf '\nchat-popup  model: %s  (/q quit, /y copy, /yq copy+quit, /l transcript)\n\n' "${CHAT_MODEL:-${model:-aichat default}}"

# 协议前缀：只随请求发送，不累积进 convo；结尾空行分隔指令与转写。
sysprompt='You are the assistant in an ongoing chat. The text below is a raw
transcript of the conversation so far, with lines labeled "Human:" (user)
and "AI:" (assistant). Reply with ONLY your next assistant message: plain
text, no labels, no simulated future turns. Answer directly with the content
itself - no preamble ("Here is...", "Sure!"), no meta-explanations of what
you are about to say, no closing offers to help further.


'

convo=''   # full chat history (Human:/AI: transcript)
resp=''    # last assistant reply

# 复制最后一条回复；pbcopy 失败/缺回复都不得杀脚本（set -e 下裸管道会闪退）。
copy_last() {
  if [[ -n "$resp" ]] && command -v pbcopy >/dev/null 2>&1; then
    if printf '%s' "$resp" | pbcopy; then printf '\n(copied)\n\n'; fi
  else
    printf '\n(no reply to copy)\n\n'
  fi
}

while true; do
  if ! IFS= read -r -p 'Human: ' line; then break; fi   # Ctrl-D
  if [[ "$line" = /q || "$line" = /exit ]]; then break; fi
  if [[ "$line" = /yq ]]; then copy_last; exit 0; fi
  if [[ "$line" = /y ]]; then copy_last; continue; fi
  if [[ "$line" = /l ]]; then
    if command -v less >/dev/null 2>&1; then
      printf '%s\n' "${convo#$'\n'}" | less
    else
      printf '\n[less not found]\n\n'
    fi
    continue
  fi
  if [[ -z "$line" ]]; then continue; fi
  convo+=$'\n'"Human: $line"
  if resp=$(NO_COLOR=1 aichat -S ${CHAT_MODEL:+-m "$CHAT_MODEL"} "$sysprompt$convo" </dev/null 2>&1); then
    printf '\nAI: %s\n\n' "$resp"
    convo+=$'\n'"AI: $resp"
  else
    printf '\n[error] %s\n\n' "$resp"
  fi
done

# 提示用 printf 打到 stdout（read -p 的 prompt 走 stderr，会被下面的
# 2>/dev/null 连带吞掉）。
printf '\n'
printf "Press 'y' to copy last reply, any other key to close..."
IFS= read -n1 -s -r key 2>/dev/null </dev/tty || true
if [[ "${key:-}" == y || "${key:-}" == Y ]] && command -v pbcopy >/dev/null 2>&1 && [[ -n "$resp" ]]; then
  printf '%s' "$resp" | pbcopy && printf ' (copied)\n'
fi
