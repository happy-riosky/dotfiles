#!/usr/bin/env bash
# yazi markdown previewer: YAML frontmatter via bat, body via glow.
# Invoked from yazi.toml as: md-preview.sh <width> <dark|light> <file>
set -euo pipefail

w=$1
t=$2
f=$3

case $t in
  light) bat_theme="Monokai Extended Light" ;;
  dark)  bat_theme="Monokai Extended" ;;
  *)     bat_theme="" ;;
esac

has_frontmatter() {
  [ "$(head -n1 "$f" | tr -d '\r')" = "---" ] &&
    awk '/^---[[:space:]]*$/ { c++ } END { exit !(c >= 2) }' "$f"
}

if has_frontmatter; then
  fm_cmd=(bat --language yaml --style=plain --color=always --paging=never --terminal-width="$w")
  if [ -n "$bat_theme" ]; then
    fm_cmd+=(--theme="$bat_theme")
  fi
  awk 'NR == 1 { next } /^---/ { exit } { print }' "$f" | "${fm_cmd[@]}"
  awk 'NR == 1 { next } /^---/ { p = 1; next } p' "$f" |
    CLICOLOR_FORCE=1 glow -w="$w" -s="$t" -
else
  CLICOLOR_FORCE=1 glow -w="$w" -s="$t" "$f"
fi
