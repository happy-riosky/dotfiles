#!/usr/bin/env bash
# chat-popup.sh 契约测试：headless（stdin 管道，read -e 自动降级为普通 read、
# prompt 不打印）覆盖命令流——对话往返、/y /yq 复制（stub pbcopy）、/l 转写、
# Ctrl-D EOF 直退（无尾部提示）、/q 尾部复制提示与尾部 y/Y 复制（空回复静默，
# 不复用 copy_last）、/tr /po 的 prompt 注入
# 及 convo 纯净、空参 usage 不调 aichat、/h 帮助与 banner 热键外移；aichat
# 失败（stub 遇 prompt 含 boom 即 exit 1）走 [error] 且 set -e 下循环存活。
# AI 前缀
# 着色（ESC[33m）经原始字节断言；Human prompt 着色与 ↑/C-r 历史需真 tty，
# 手动烟测覆盖（见 docs/progress.md 操作记录）。
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

SCRIPT="$ROOT/home/.tmux/scripts/chat-popup.sh"
[ -r "$SCRIPT" ] || fail "script missing: $SCRIPT"

tmp="$(mktemp -d)"
cleanup() {
  rm -rf "$tmp"
}
trap cleanup EXIT

stub="$tmp/bin"
mkdir -p "$stub"
AI_LOG="$tmp/ai.log"
PB_LOG="$tmp/pb.log"
: >"$AI_LOG"
: >"$PB_LOG"
export AI_LOG PB_LOG

# aichat stub：--info 出 model；对话调用把完整 prompt 追加进 $AI_LOG，按
# 内容特征回固定文本。最后一个参数才是 prompt（-S [-m model] prompt）。
# prompt 含 boom 时 exit 1，模拟 aichat 失败以覆盖脚本 [error] 路径。
cat >"$stub/aichat" <<'EOF'
#!/usr/bin/env bash
if [ "${1:-}" = --info ]; then
  printf 'model stub-model\n'
  exit 0
fi
for prompt; do :; done
printf '%s\n' "$prompt" >>"$AI_LOG"
case "$prompt" in
  *boom*) printf 'stub-ai-error'; exit 1 ;;
  *Translate*) printf 'translated-stub' ;;
  *Polish*) printf 'polished-stub' ;;
  *) printf 'stub-reply' ;;
esac
EOF
cat >"$stub/pbcopy" <<'EOF'
#!/usr/bin/env bash
cat >"$PB_LOG"
EOF
chmod +x "$stub/aichat" "$stub/pbcopy"

run() {
  printf '%b' "$1" | env -u TMUX -u CHAT_MODEL HOME="$tmp" PATH="$stub:$PATH" bash "$SCRIPT"
}

test_roundtrip_copy_transcript() {
  local out
  out="$(run 'hello\n/y\n/l\n/q\nn\n')" || fail 'roundtrip: rc'
  case "$out" in *'chat-popup  model: stub-model'*) ;; *) fail 'roundtrip: banner model' ;; esac
  case "$out" in *$'\033[33mAI: \033[0mstub-reply'*) ;; *) fail 'roundtrip: colored AI reply' ;; esac
  case "$out" in *'(copied)'*) ;; *) fail 'roundtrip: /y copy' ;; esac
  [ "$(cat "$PB_LOG")" = 'stub-reply' ] || fail 'roundtrip: pbcopy content'
  case "$out" in *"Press 'y' to copy"*) ;; *) fail 'roundtrip: /q tail prompt' ;; esac
  if command -v less >/dev/null 2>&1; then
    case "$out" in *'Human: hello'*) ;; *) fail 'roundtrip: transcript input' ;; esac
  fi
}

test_eof_direct_quit() {
  local out
  out="$(run 'hello\n')" || fail 'eof: rc'
  case "$out" in *$'\033[33mAI: \033[0mstub-reply'*) ;; *) fail 'eof: colored reply' ;; esac
  case "$out" in *"Press 'y'"*) fail 'eof: tail prompt must not show' ;; esac
  out="$(run '')" || fail 'eof-empty: rc'
  case "$out" in *"Press 'y'"*) fail 'eof-empty: tail prompt must not show' ;; esac
}

test_yq() {
  local out
  out="$(run 'hi\n/yq\n')" || fail 'yq: rc'
  case "$out" in *'(copied)'*) ;; *) fail 'yq: copy' ;; esac
  case "$out" in *"Press 'y'"*) fail 'yq: must exit without tail prompt' ;; esac
  out="$(run '/yq\n')" || fail 'yq-empty: rc'
  case "$out" in *'(no reply to copy)'*) ;; *) fail 'yq-empty: hint' ;; esac
}

test_tail_copy_on_quit() {
  local out
  : >"$PB_LOG"
  out="$(run 'hi\n/q\ny\n')" || fail 'tail-copy: rc'
  case "$out" in *"Press 'y' to copy"*) ;; *) fail 'tail-copy: tail prompt' ;; esac
  case "$out" in *'close... (copied)'*) ;; *) fail 'tail-copy: copied marker' ;; esac
  [ "$(cat "$PB_LOG")" = 'stub-reply' ] || fail 'tail-copy: pbcopy content'
  out="$(run 'hi\n/q\nY\n')" || fail 'tail-copy-upper: rc'
  case "$out" in *'close... (copied)'*) ;; *) fail 'tail-copy-upper: copied marker' ;; esac
  [ "$(cat "$PB_LOG")" = 'stub-reply' ] || fail 'tail-copy-upper: pbcopy content'
  out="$(run '/q\ny\n')" || fail 'tail-copy-empty: rc'
  case "$out" in *'(copied)'*) fail 'tail-copy-empty: no reply must stay silent' ;; esac
}

test_help() {
  local out
  : >"$AI_LOG"
  out="$(run '/h\n/q\nn\n')" || fail 'help: rc'
  case "$out" in *'(/h for help)'*) ;; *) fail 'help: banner pointer' ;; esac
  case "$out" in *'/tr <text>'*) ;; *) fail 'help: /tr line' ;; esac
  case "$out" in *'Up/Down/C-r'*) ;; *) fail 'help: keys section' ;; esac
  # banner 只指路 /h，不再枚举热键
  if head -n 4 <<<"$out" | grep -q '/tr translate'; then
    fail 'help: banner must not enumerate hotkeys'
  fi
  [ ! -s "$AI_LOG" ] || fail 'help: aichat must not be called'
}

test_tr_po() {
  local out
  : >"$AI_LOG"
  out="$(run '/tr hello world\n/l\n/q\nn\n')" || fail 'tr: rc'
  case "$out" in *$'\033[33mAI: \033[0mtranslated-stub'*) ;; *) fail 'tr: colored output format' ;; esac
  case "$out" in *'Human:'*) fail 'tr: convo polluted' ;; esac
  grep -q 'Translate' "$AI_LOG" || fail 'tr: prompt'
  [ "$(tail -n 1 "$AI_LOG")" = 'hello world' ] || fail 'tr: text is prompt tail'

  : >"$AI_LOG"
  out="$(run '/po i has a apple\n/q\nn\n')" || fail 'po: rc'
  case "$out" in *$'\033[33mAI: \033[0mpolished-stub'*) ;; *) fail 'po: colored output format' ;; esac
  grep -q 'Polish' "$AI_LOG" || fail 'po: prompt'
  grep -q 'i has a apple' "$AI_LOG" || fail 'po: text'

  : >"$AI_LOG"
  out="$(run '/tr\n/po\n/q\nn\n')" || fail 'usage: rc'
  case "$out" in *'usage: /tr <text>'*) ;; *) fail 'usage: /tr hint' ;; esac
  case "$out" in *'usage: /po <text>'*) ;; *) fail 'usage: /po hint' ;; esac
  [ ! -s "$AI_LOG" ] || fail 'usage: aichat must not be called'
}

# 失败先成功后 boom：失败轮的 Human: boom 已进 convo，之后的 ask 都含 boom
# 也会失败，故成功轮必须在前；存活证据 = 走到 /q 尾部提示。
test_ai_error_survives() {
  local out
  : >"$AI_LOG"
  out="$(run 'hello\nboom\n/q\nn\n')" || fail 'error: rc'
  case "$out" in *'[error] stub-ai-error'*) ;; *) fail 'error: [error] output' ;; esac
  case "$out" in *"Press 'y'"*) ;; *) fail 'error: loop must survive to /q' ;; esac
  out="$(run '/tr boom\n/q\nn\n')" || fail 'error-oneshot: rc'
  case "$out" in *'[error] stub-ai-error'*) ;; *) fail 'error-oneshot: [error] output' ;; esac
  case "$out" in *'translated-stub'*) fail 'error-oneshot: no success output' ;; esac
}

test_roundtrip_copy_transcript
test_eof_direct_quit
test_yq
test_tail_copy_on_quit
test_help
test_tr_po
test_ai_error_survives
printf 'chat-popup: all tests passed\n'
