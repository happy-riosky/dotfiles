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

test_no_percent_before_hash_expansion
test_server_path_fix_precedes_tpm
test_update_environment_keeps_term_vars
printf 'tmux integration tests passed\n'
