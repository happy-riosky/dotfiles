#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TINTY="$ROOT/home/.vim/autoload/lightline/colorscheme/tinty.vim"
LIGHTLINE="$HOME/.vim/pack/vendor/start/lightline.vim"

[[ -f "$TINTY" ]] || {
  printf 'FAIL: missing tinty Lightline colorscheme: %s\n' "$TINTY" >&2
  exit 1
}
[[ -d "$LIGHTLINE" ]] || {
  printf 'FAIL: missing Lightline plugin: %s\n' "$LIGHTLINE" >&2
  exit 1
}

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# 态 1：伪造 tinty 调色板（tinted-vim 生成文件暴露的 g:tinted_gui*/cterm*）
# → palette 动态构建，accent 必须取黄槽 gui0A（用不常见 hex 防兜底值撞色）
cat > "$TMP/dynamic.vim" <<'SCRIPT'
let g:tinted_gui00 = '#303446'
let g:tinted_gui02 = '#414559'
let g:tinted_gui03 = '#51576d'
let g:tinted_gui05 = '#c6d0f5'
let g:tinted_gui08 = '#e78284'
let g:tinted_gui0A = '#acacac'
let g:tinted_gui0C = '#81c8be'
let g:tinted_cterm00 = 236
let g:tinted_cterm02 = 238
let g:tinted_cterm03 = 61
let g:tinted_cterm05 = 189
let g:tinted_cterm08 = 210
let g:tinted_cterm0A = 222
let g:tinted_cterm0C = 152
runtime autoload/lightline/colorscheme/tinty.vim
if !exists('g:lightline#colorscheme#tinty#palette') | cquit | endif
if match(string(g:lightline#colorscheme#tinty#palette), '#acacac') < 0 | cquit | endif
qa!
SCRIPT

vim -Nu NONE -i NONE -n -es \
  "+set runtimepath^=$ROOT/home/.vim" \
  "+set runtimepath^=$LIGHTLINE" \
  -S "$TMP/dynamic.vim"

# 态 2：无 g:tinted_gui* → 内置 catppuccin-frappe 兜底 palette（黄 #e5c890）
cat > "$TMP/fallback.vim" <<'SCRIPT'
runtime autoload/lightline/colorscheme/tinty.vim
if !exists('g:lightline#colorscheme#tinty#palette') | cquit | endif
if match(string(g:lightline#colorscheme#tinty#palette), '#e5c890') < 0 | cquit | endif
qa!
SCRIPT

vim -Nu NONE -i NONE -n -es \
  "+set runtimepath^=$ROOT/home/.vim" \
  "+set runtimepath^=$LIGHTLINE" \
  -S "$TMP/fallback.vim"

printf 'vim integration tests passed\n'
