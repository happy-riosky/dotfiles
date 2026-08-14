#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

# A literal '%' directly before a '#{}' or '#(...)' expansion is consumed by
# strftime on Linux/Termux before tmux can expand the command. The unexpanded
# plugin path then leaks into the status bar as plain text (seen on Termux:
# "16%(/data/data/com.termux/files/home/.tmux/plugin...").
test_no_percent_before_hash_expansion() {
  local conf
  while IFS= read -r conf; do
    if grep -nE '%#\{|%#\(' "$conf"; then
      fail "literal '%' before a '#' expansion in $conf (strftime hazard)"
    fi
  done < <(find "$ROOT/home/.tmux.conf" "$ROOT/home/.tmux" \
    -name '*.tmux.conf' -type f 2>/dev/null)
}

test_no_percent_before_hash_expansion
printf 'tmux integration tests passed\n'
