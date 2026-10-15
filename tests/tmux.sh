#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

# A literal '%' directly before a '#{}' or '#(...)' expansion is consumed by
# strftime on Linux/Termux before tmux can expand the command. The unexpanded
# plugin path then leaks into the status bar as plain text (seen on Termux:
# "16%(/data/data/com.termux/files/home/.tmux/plugin...").
# Escape a literal '%' as '%%' instead; strip escaped pairs before matching.
test_no_percent_before_hash_expansion() {
  local conf
  while IFS= read -r conf; do
    if sed 's/%%/@@/g' "$conf" | grep -nE '%#\{|%#\('; then
      fail "literal '%' before a '#' expansion in $conf (strftime hazard)"
    fi
  done < <(find "$ROOT/home/.tmux.conf" "$ROOT/home/.tmux" \
    -name '*.tmux.conf' -type f 2>/dev/null)
}

# Plugins executed by TPM run via run-shell with the tmux SERVER's PATH,
# captured at server start -- it may lack ~/.local/bin.
# .tmux.conf must prepend user-local bins to the global environment BEFORE
# TPM is initialized, so plugin detection and source-file reloads both work.
test_server_path_fix_precedes_tpm() {
  local conf="$ROOT/home/.tmux.conf"
  grep -q "tmux set-environment -g PATH" "$conf" || \
    fail '.tmux.conf does not fix the server PATH for plugins'
  [[ "$(grep -n "run '~/.tmux/plugins/tpm/tpm'" "$conf" | cut -d: -f1)" -gt \
     "$(grep -n 'tmux set-environment -g PATH' "$conf" | cut -d: -f1)" ]] || \
    fail '.tmux.conf initializes TPM before fixing the server PATH'
}

# yazi requires TERM and TERM_PROGRAM to be refreshed from the attaching
# client (https://yazi-rs.github.io/docs/image-preview). The update-environment
# override replaces tmux's default wholesale, so it must carry them explicitly.
test_update_environment_keeps_term_vars() {
  local conf="$ROOT/home/.tmux.conf"
  local vars v has_term=0 has_tp=0
  vars=$(sed -n 's/^set -g update-environment "\(.*\)"$/\1/p' "$conf")
  [ -n "$vars" ] || fail 'update-environment override not found in .tmux.conf'
  for v in $vars; do
    [ "$v" = "TERM" ] && has_term=1
    [ "$v" = "TERM_PROGRAM" ] && has_tp=1
  done
  [ "$has_term" = 1 ] || fail 'update-environment is missing TERM (yazi requirement)'
  [ "$has_tp" = 1 ] || fail 'update-environment is missing TERM_PROGRAM (yazi requirement)'
}

# prefix+O 契约：ocv 优先、opencode 兜底；都缺则绝不 new-window。
test_prefix_o_fallback_chain() {
  local conf="$ROOT/home/.tmux.conf"
  grep -q '^bind O run ' "$conf" || \
    fail 'prefix+O must be a guarded run-shell binding'
  grep -q 'command -v ocv || command -v opencode' "$conf" || \
    fail 'prefix+O does not resolve ocv-then-opencode fallback'
  grep -qF '[ -n "$app" ] && tmux new-window' "$conf" || \
    fail 'prefix+O missing empty-guard: neither binary must open a window'
}

# prefix+. 换号契约：dense 编号下 stock 裸 move-window 必报 index in use，
# 被占号必须 park 到 :999 再 -b 插入落位；空缺号才直接 move。占位符必须
# %1——command-prompt 只替换首个 %%（man 语义），%1 才全替换；模板多处
# %% 会让后续 move-window 收到字面 %%（实测翻车），故禁用 %%。
test_prefix_dot_renumber_binding() {
  local conf="$ROOT/home/.tmux.conf" line
  grep -q '^bind \. command-prompt' "$conf" || \
    fail 'prefix+. must stay a command-prompt binding'
  line="$(grep '^bind \. ' "$conf")"
  case "$line" in *%%*) \
    fail 'prefix+. template must not use %% (only first occurrence is substituted)' ;; \
  esac
  case "$line" in *%1*%1*) ;; *) \
    fail 'prefix+. template needs %1 (all-occurrence substitution) at least twice' ;; \
  esac
  grep -qF 'grep -q ^%1:' "$conf" || \
    fail 'prefix+. must probe target-index occupancy before choosing branch'
  grep -qF 'move-window -t :999; move-window -b -t :%1' "$conf" || \
    fail 'prefix+. occupied branch must park at :999 then insert with -b'
}

# prefix+S-Left/S-Right 契约：swap 必须 -d（焦点随窗口走，否则留在原槽
# 位）；首/末窗口守卫防 swap -1/+1 环绕；#{window_index} 必须 ## 双写——
# run 绑定参数触发时做格式展开，单写会被外层吞成当前窗口常量。
test_relative_shift_bindings() {
  local conf="$ROOT/home/.tmux.conf"
  grep -q '^bind S-Left run ' "$conf" || fail 'prefix+S-Left shift binding missing'
  grep -q '^bind S-Right run ' "$conf" || fail 'prefix+S-Right shift binding missing'
  grep -qF 'tmux swap-window -d -t -1' "$conf" || \
    fail 'S-Left must swap with -d (focus follows the window)'
  grep -qF 'tmux swap-window -d -t +1' "$conf" || \
    fail 'S-Right must swap with -d (focus follows the window)'
  grep -qF '"##{window_index}"' "$conf" || \
    fail 'shift bindings must double-escape #{window_index} (##) for inner tmux'
}

# zen 生命周期契约测试已拆至 tests/tmux-zen.sh（需 tmux 运行时，缺失时跳过）。

test_no_percent_before_hash_expansion
test_server_path_fix_precedes_tpm
test_update_environment_keeps_term_vars
test_prefix_o_fallback_chain
test_prefix_dot_renumber_binding
test_relative_shift_bindings
printf 'tmux integration tests passed\n'
