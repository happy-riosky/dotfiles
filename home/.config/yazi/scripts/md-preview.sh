#!/usr/bin/env bash
# yazi markdown previewer: YAML frontmatter via bat, body via glow.
# Invoked from yazi.toml as: md-preview.sh <width> <dark|light> <file>
# glow 样式：tinty 生成物 ~/.config/tinted-theming/tinty-glow.json（y() 启动前
# 刷新）存在且其 _tinty_scheme 标记与 tinty current_scheme 一致时，-s 显式传
# 绝对路径（glow 的 -s 只认内建样式名或 JSON 文件绝对路径，不支持 ~ 展开
# 与命名样式查找）；否则回退内建 dark/light（$2）。标记校验确保切换 scheme
# 后绝不渲染过期深浅样式（陈旧样式比内建更糟）。
# bat 用内建 base16-256 主题：输出 ANSI 16 色索引，跟随 tinted-shell 重定义
# 的终端调色板，与 aliases.sh 的 bat 别名一致，不依赖 $2 明暗探测。
set -euo pipefail

w=$1
t=$2
f=$3

glow_style="${XDG_CONFIG_HOME:-$HOME/.config}/tinted-theming/tinty-glow.json"
scheme_file="${XDG_DATA_HOME:-$HOME/.local/share}/tinted-theming/tinty/current_scheme"
glow_args=(-w="$w")
if [ -r "$glow_style" ] && [ -r "$scheme_file" ] && \
  grep -q "\"_tinty_scheme\": \"$(tr -d '[:space:]' < "$scheme_file")\"" "$glow_style"; then
  glow_args+=(-s="$glow_style")
else
  glow_args+=(-s="$t")
fi

has_frontmatter() {
  [ "$(head -n1 "$f" | tr -d '\r')" = "---" ] &&
    awk '/^---[[:space:]]*$/ { c++ } END { exit !(c >= 2) }' "$f"
}

if has_frontmatter; then
  awk 'NR == 1 { next } /^---/ { exit } { print }' "$f" |
    bat --language yaml --style=plain --color=always --paging=never \
        --terminal-width="$w" --theme=base16-256
  awk 'NR == 1 { next } /^---/ { p = 1; next } p' "$f" |
    CLICOLOR_FORCE=1 glow "${glow_args[@]}" -
else
  CLICOLOR_FORCE=1 glow "${glow_args[@]}" "$f"
fi
