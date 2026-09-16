#!/usr/bin/env bash
set -euo pipefail

REPO=$(cd "$(dirname "$0")/../.." && pwd)
ASSET="$REPO/platforms/darwin/home/.config/karabiner/assets/complex_modifications/miryoku.json"
KARABINER="$REPO/platforms/darwin/home/.config/karabiner/karabiner.json"

usage() { echo "usage: rules.sh {enable|disable|status}" >&2; exit 2; }
[[ $# -eq 1 ]] || usage

count_miryoku() {
  jq '[.profiles[] | select(.selected) | .complex_modifications.rules[]
       | select(.description | startswith("Miryoku"))] | length' "$KARABINER"
}

rewrite() {
  local filter=$1
  jq --indent 4 --slurpfile asset "$ASSET" "$filter" "$KARABINER" > "$KARABINER.tmp" \
    && mv "$KARABINER.tmp" "$KARABINER"
}

case $1 in
  status)
    total=$(jq '[.profiles[] | select(.selected) | .complex_modifications.rules[]] | length' "$KARABINER")
    echo "miryoku rules: $(count_miryoku)/6 (profile total: $total)"
    ;;
  enable)
    [[ $(count_miryoku) -gt 0 ]] && { echo "already enabled"; exit 0; }
    rewrite '.profiles |= map(if .selected then
        .complex_modifications.rules = ($asset[0].rules + .complex_modifications.rules)
      else . end)'
    echo "enabled: $(count_miryoku)/6 (Karabiner hot-reloads within ~1s)"
    ;;
  disable)
    rewrite '.profiles |= map(if .selected then
        .complex_modifications.rules |= map(select((.description // "") | startswith("Miryoku") | not))
      else . end)'
    echo "disabled: $(count_miryoku)/6 remain (Karabiner hot-reloads within ~1s)"
    ;;
  *) usage ;;
esac
