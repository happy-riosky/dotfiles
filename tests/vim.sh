#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
THEME="$ROOT/home/.vim/autoload/lightline/colorscheme/catppuccin_latte_yellow.vim"
LIGHTLINE="$HOME/.vim/pack/vendor/start/lightline.vim"

[[ -f "$THEME" ]] || {
  printf 'FAIL: missing custom Lightline theme: %s\n' "$THEME" >&2
  exit 1
}
[[ -d "$LIGHTLINE" ]] || {
  printf 'FAIL: missing Lightline plugin: %s\n' "$LIGHTLINE" >&2
  exit 1
}

vim -Nu NONE -i NONE -n -es \
  "+set runtimepath^=$ROOT/home/.vim" \
  "+set runtimepath^=$LIGHTLINE" \
  '+runtime autoload/lightline/colorscheme/catppuccin_latte_yellow.vim' \
  '+if !exists("g:lightline#colorscheme#catppuccin_latte_yellow#palette") | cquit | endif' \
  '+qa!'

printf 'vim integration tests passed\n'
