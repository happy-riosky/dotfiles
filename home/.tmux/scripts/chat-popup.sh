#!/usr/bin/env bash
# chat-popup.sh - prefix+C-g 极简 CLI 聊天：read → aichat → 打印，死循环。
# aichat 无 --session 完全无状态，对话不落任何本地库（opencode run 每轮写
# session 库，故弃用）。convo=Human:/AI: 转写完整重放（整段重放）；resp=最后
# 一条回复（/tr、/po 的结果同样更新 resp，供 /y 复制，但不进 convo 转写）。
# 协议指令 sysprompt 内嵌于本脚本（自包含，不依赖机器本地 role 文件，换机
# 即可用）。
#
# 命令与按键（banner 只指路 /h，全量帮助由 /h 打印）：
#   /h          帮助（命令与按键全量清单）
#   /tr <text>  一次性翻译：主要中文→地道英文，否则→地道中文；按普通回复
#               格式打印
#   /po <text>  一次性润色：同语言修正语法/错字/流畅度，保意保语气，同上
#   /y 复制回复、/yq 复制并退、/l less 看转写（pbcopy/less 缺失均静默降级）
#   /q          退出（尾部可按 y 复制最后回复）
#   Ctrl-D      空行直接退出，无尾部复制提示
#   Up/Down/C-r 输入历史（read -e + history -s，见下方隐私处理）
#
# prompt 着色：Human 前缀 ANSI 34 = 终端 color4 = tinty 当前 scheme base0D
# 蓝；AI 前缀 ANSI 33 = color3 = base0A 黄（仓库 accent 锚点）。二者随 tinty
# apply 自动跟随，无 tinty（server/termux）静默降级为终端默认蓝/黄；ps_human
# 的 \001/\002 包裹防 readline 折行宽度错乱（ps_ai 是普通 printf，无需）。
# headless（stdin 非 tty）时 -e 自动失效、prompt 不打印，测试链路可直跑。
#
# 历史隐私：交互态启动即 history -c（清 bash -i 载入的 shell 历史，防 ↑
# 翻出命令行）+ unset HISTFILE（防退出时聊天行经 histappend 写回
# ~/.bash_history）——聊天记录不留任何本地痕迹，与 aichat 无状态设计一致。
# 直跑（非 bash -i）且 stdin 是 tty 时自动 re-exec bash -i，readline/历史
# 才可用；headless 不 re-exec。
#
# 模型显示自 aichat --info（macOS/Linux 配置路径不同，不直接读文件）；
# CHAT_MODEL 可覆盖显示与 -m。bash 3.2 可移植（无 read -i）。
set -euo pipefail

if [[ $- != *i* && -t 0 ]]; then
  exec bash -i "$0" "$@"
fi

if ! command -v aichat >/dev/null 2>&1; then
  printf 'aichat not found — brew install aichat\n'
  IFS= read -r -t 2 _ 2>/dev/null </dev/tty || true
  exit 127
fi

# 输入历史只在交互态有 readline；headless 静默跳过。
hist_last=''
case $- in
  *i*)
    history -c
    unset HISTFILE
    ;;
esac

# 注意：aichat 会对非 tty 的 stdin 自动读取（当作管道输入），命令替换里
# 不加 </dev/null 会把本脚本的输入流喝掉——所有 aichat 调用一律钉死 stdin。
# aichat 加 -S（关流式）：流式重组在长回复下曾出现丢字/乱码（"canД"），
# 关流式让回复一次性写出；NO_COLOR 兜底去 ANSI。
model=$(NO_COLOR=1 aichat --info </dev/null 2>/dev/null | awk '$1=="model"{print $2; exit}')
printf '\nchat-popup  model: %s  (/h for help)\n\n' "${CHAT_MODEL:-${model:-aichat default}}"

help_text='commands:
  /h            this help
  /l            transcript in less
  /tr <text>    translate (zh<->en)
  /po <text>    polish (same language)
  /y /yq        copy last reply / copy and quit
  /q            quit (y copies last reply on close)
  Ctrl-D        quit directly
keys:
  Up/Down/C-r   input history / search'

# 协议前缀：只随请求发送，不累积进 convo；结尾空行分隔指令与转写。
sysprompt='You are the assistant in an ongoing chat. The text below is a raw
transcript of the conversation so far, with lines labeled "Human:" (user)
and "AI:" (assistant). Reply with ONLY your next assistant message: plain
text, no labels, no simulated future turns. Answer directly with the content
itself - no preamble ("Here is...", "Sure!"), no meta-explanations of what you
are about to say, no closing offers to help further.


'

tr_prompt='Translate the text after "Text:" below. If it is mainly Chinese,
translate it into natural, idiomatic English; otherwise translate it into
natural, idiomatic Chinese. Output ONLY the translation itself - no notes, no
alternatives, no explanations.

Text:
'

po_prompt='Polish the text after "Text:" below: fix grammar, typos, punctuation
and awkward phrasing, keeping the same language, meaning and tone. Output ONLY
the corrected text - no notes, no explanations.

Text:
'

convo=''   # full chat history (Human:/AI: transcript)
resp=''    # last assistant reply

# 着色 prompt：色码用 \001/\002 包裹（readline 非打印字符标记）。
ps_human=$'\001\033[34m\002Human: \001\033[0m\002'
ps_ai=$'\033[33mAI: \033[0m'

# 复制最后一条回复；pbcopy 失败/缺回复都不得杀脚本（set -e 下裸管道会闪退）。
copy_last() {
  if [[ -n "$resp" ]] && command -v pbcopy >/dev/null 2>&1; then
    if printf '%s' "$resp" | pbcopy; then printf '\n(copied)\n\n'; fi
  else
    printf '\n(no reply to copy)\n\n'
  fi
}

ask() { # $1=完整 prompt；stdout=回复（错误信息也走 stdout），rc 透传
  NO_COLOR=1 aichat -S ${CHAT_MODEL:+-m "$CHAT_MODEL"} "$1" </dev/null 2>&1
}

oneshot() { # $1=prompt 前缀 $2=text：按普通回复格式打印、更新 resp、不进 convo
  local out
  if out=$(ask "$1$2"); then
    printf '\n%s%s\n\n' "$ps_ai" "$out"
    resp=$out
  else
    printf '\n[error] %s\n\n' "$out"
  fi
}

while true; do
  if ! IFS= read -e -r -p "$ps_human" line; then exit 0; fi   # Ctrl-D：直接退
  if [[ -z "$line" ]]; then continue; fi
  # 记录输入历史（连续重复去重；slash 命令同样入史，↑ 可改写重发）。
  case $- in
    *i*)
      if [[ "$line" != "$hist_last" ]]; then
        history -s -- "$line"
        hist_last=$line
      fi
      ;;
  esac
  if [[ "$line" = /h ]]; then
    printf '\n%s\n\n' "$help_text"
    continue
  fi
  if [[ "$line" = /q ]]; then break; fi
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
  if [[ "$line" = /tr || "$line" = /tr\ * ]]; then
    text="${line#/tr}"
    text="${text#"${text%%[! ]*}"}"
    if [[ -z "$text" ]]; then
      printf '\nusage: /tr <text>\n\n'
    else
      oneshot "$tr_prompt" "$text"
    fi
    continue
  fi
  if [[ "$line" = /po || "$line" = /po\ * ]]; then
    text="${line#/po}"
    text="${text#"${text%%[! ]*}"}"
    if [[ -z "$text" ]]; then
      printf '\nusage: /po <text>\n\n'
    else
      oneshot "$po_prompt" "$text"
    fi
    continue
  fi
  convo+=$'\n'"Human: $line"
  if resp=$(ask "$sysprompt$convo"); then
    printf '\n%s%s\n\n' "$ps_ai" "$resp"
    convo+=$'\n'"AI: $resp"
  else
    printf '\n[error] %s\n\n' "$resp"
  fi
done

# 提示用 printf 打到 stdout（read -p 的 prompt 走 stderr，非 tty 时不显示）。
# 尾部键读 stdin：弹窗内即终端，行为不变；headless 从管道取下一字节，可测。
printf '\n'
printf "Press 'y' to copy last reply, any other key to close..."
IFS= read -n1 -s -r key || true
if [[ "${key:-}" == y || "${key:-}" == Y ]] && command -v pbcopy >/dev/null 2>&1 && [[ -n "$resp" ]]; then
  printf '%s' "$resp" | pbcopy && printf ' (copied)\n'
fi
