#!/usr/bin/env bash
# swatches.sh — 在 truecolor 终端预览 Catppuccin 调色盘（色块 + 名称 + hex）
# 用法: swatches.sh [--table|--col] [frappe|latte|macchiato|mocha]
#   --table  对比表格：每个 flavor 一列，颜色为行（默认）
#   --col    单列排版：flavor 依次整块输出，每行 1 色
# 缺省 flavor 时显示全部（官方顺序 Latte → Frappé → Macchiato → Mocha）。
# 颜色命名与排序参考 https://catppuccin.com/palette ：
#   强调色在前: Rosewater → Flamingo → Pink → Mauve → Red → Maroon → Peach →
#               Yellow → Green → Teal → Sky → Sapphire → Blue → Lavender
#   底色在后:   Text → Subtext 1 → Subtext 0 → Overlay 2 → Overlay 1 → Overlay 0 →
#               Surface 2 → Surface 1 → Surface 0 → Base → Mantle → Crust
set -euo pipefail

MODE=table
FLAVOR=all
SEP=--

NAMES=(Rosewater Flamingo Pink Mauve Red Maroon Peach Yellow Green Teal Sky Sapphire Blue Lavender $SEP \
       Text "Subtext 1" "Subtext 0" "Overlay 2" "Overlay 1" "Overlay 0" \
       "Surface 2" "Surface 1" "Surface 0" Base Mantle Crust)

FRAPPE=(f2d5cf eebebe f4b8e4 ca9ee6 e78284 ea999c ef9f76 e5c890 a6d189 81c8be 99d1db 85c1dc 8caaee babbf1 $SEP \
        c6d0f5 b5bfe2 a5adce 949cbb 838ba7 737994 626880 51576d 414559 303446 292c3c 232634)
LATTE=(dc8a78 dd7878 ea76cb 8839ef d20f39 e64553 fe640b df8e1d 40a02b 179299 04a5e5 209fb5 1e66f5 7287fd $SEP \
       4c4f69 5c5f77 6c6f85 7c7f93 8c8fa1 9ca0b0 acb0be bcc0cc ccd0da eff1f5 e6e9ef dce0e8)
MACCHIATO=(f4dbd6 f0c6c6 f5bde6 c6a0f6 ed8796 ee99a0 f5a97f eed49f a6da95 8bd5ca 91d7e3 7dc4e4 8aadf4 b7bdf8 $SEP \
           cad3f5 b8c0e0 a5adcb 939ab7 8087a2 6e738d 5b6078 494d64 363a4f 24273a 1e2030 181926)
MOCHA=(f5e0dc f2cdcd f5c2e7 cba6f7 f38ba8 eba0ac fab387 f9e2af a6e3a1 94e2d5 89dceb 74c7ec 89b4fa b4befe $SEP \
       cdd6f4 bac2de a6adc8 9399b2 7f849c 6c7086 585b70 45475a 313244 1e1e2e 181825 11111b)

ALL=(latte frappe macchiato mocha)

usage() { echo "usage: swatches.sh [--table|--col] [frappe|latte|macchiato|mocha]" >&2; }

title_of() {
  case "$1" in
    frappe)    echo 'Frappe (dark)' ;;
    latte)     echo 'Latte (light)' ;;
    macchiato) echo 'Macchiato (dark)' ;;
    mocha)     echo 'Mocha (dark)' ;;
  esac
}

hex_of() { # $1=flavor $2=索引
  case "$1" in
    frappe)    echo "${FRAPPE[$2]}" ;;
    latte)     echo "${LATTE[$2]}" ;;
    macchiato) echo "${MACCHIATO[$2]}" ;;
    mocha)     echo "${MOCHA[$2]}" ;;
  esac
}

rgb() { # $1=hex → "r g b"
  echo "$((16#${1:0:2})) $((16#${1:2:2})) $((16#${1:4:2}))"
}

tcell() { # 表格单元格：色块 + hex，固定 14 列宽
  local hex=$1; set -- $(rgb "$hex")
  printf '\033[48;2;%d;%d;%dm    \033[0m #%s  ' "$1" "$2" "$3" "$hex"
}

ccell() { # 单列单元格：色块内嵌名称（按亮度自适应黑/白字）+ hex
  local hex=$1 name=$2; set -- $(rgb "$hex")
  local fg='0;0;0'
  (( ($1*299 + $2*587 + $3*114) / 1000 < 140 )) && fg='255;255;255'
  printf '\033[48;2;%d;%d;%dm\033[38;2;%sm %-9s \033[0m #%s\n' "$1" "$2" "$3" "$fg" "$name" "$hex"
}

print_table() { # $@=flavors，每个 flavor 一列
  local f i name t
  printf '%-11s' ''
  for f in "$@"; do t=$(title_of "$f"); printf '%-14s' "${t%% *}"; done
  printf '\n'
  for i in "${!NAMES[@]}"; do
    name=${NAMES[$i]}
    if [ "$name" = "$SEP" ]; then printf '\n'; continue; fi
    printf '%-11s' "$name"
    for f in "$@"; do tcell "$(hex_of "$f" "$i")"; done
    printf '\n'
  done
}

print_col() { # $@=flavors，整块依次输出
  local f i name first=1
  for f in "$@"; do
    [ $first -eq 1 ] || printf '\n'
    first=0
    echo "== $(title_of "$f") =="
    for i in "${!NAMES[@]}"; do
      name=${NAMES[$i]}
      [ "$name" = "$SEP" ] && { printf '\n'; continue; }
      ccell "$(hex_of "$f" "$i")" "$name"
    done
  done
}

for arg in "$@"; do
  case "$arg" in
    --table) MODE=table ;;
    --col|--column) MODE=col ;;
    frappe|latte|macchiato|mocha) FLAVOR=$arg ;;
    *) usage; exit 2 ;;
  esac
done

if [ "$FLAVOR" = all ]; then
  selected=("${ALL[@]}")
else
  selected=("$FLAVOR")
fi

if [ "$MODE" = col ]; then
  print_col "${selected[@]}"
else
  print_table "${selected[@]}"
fi
