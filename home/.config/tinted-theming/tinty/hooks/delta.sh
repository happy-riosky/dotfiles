#!/usr/bin/env bash
# tinty hook：按 apply/init 的 scheme 渲染 delta 样式到 <data>/
# delta-scheme-colors.gitconfig（运行时产物），由受管 darwin git config
# 的 [include] 引用；经 config.toml 以 bash 显式调用（无 exec 位要求，
# bash 3.2）。输入为 tinty 的 TINTY_SCHEME_ID 与 PALETTE_BASE<XX>_RGB_*
# （0-255）；缺变量即静默退出保留旧产物（首行 _tinty_scheme 标记陈旧）。
# 成功零输出；槽位语义见 docs/theming.md。
set -euo pipefail

data_dir="${XDG_DATA_HOME:-$HOME/.local/share}/tinted-theming/tinty"
out="$data_dir/delta-scheme-colors.gitconfig"

comp() {
	local name="TINTY_SCHEME_PALETTE_BASE$1_RGB_$2"
	local v="${!name:-}"
	case "$v" in '' | *[!0-9]*) return 1 ;; esac
	[ "$v" -le 255 ] || return 1
	printf '%d' "$v"
}

rgb() {
	local r g b
	r="$(comp "$1" R)" || return 1
	g="$(comp "$1" G)" || return 1
	b="$(comp "$1" B)" || return 1
	printf '%d %d %d' "$r" "$g" "$b"
}

hex() {
	printf '#%02x%02x%02x' "$1" "$2" "$3"
}

blend() {
	local pct="$7"
	printf '#%02x%02x%02x' \
		$(( ($1 * (100 - pct) + $4 * pct + 50) / 100 )) \
		$(( ($2 * (100 - pct) + $5 * pct + 50) / 100 )) \
		$(( ($3 * (100 - pct) + $6 * pct + 50) / 100 ))
}

[ -n "${TINTY_SCHEME_ID:-}" ] || exit 0
p00="$(rgb 00)" || exit 0
p01="$(rgb 01)" || exit 0
p02="$(rgb 02)" || exit 0
p04="$(rgb 04)" || exit 0
p08="$(rgb 08)" || exit 0
p0b="$(rgb 0B)" || exit 0
p0d="$(rgb 0D)" || exit 0

read -r b_r b_g b_b <<<"$p00"
read -r b1_r b1_g b1_b <<<"$p01"
read -r b2_r b2_g b2_b <<<"$p02"
read -r z4_r z4_g z4_b <<<"$p04"
read -r m_r m_g m_b <<<"$p08"
read -r g_r g_g g_b <<<"$p0b"
read -r h_r h_g h_b <<<"$p0d"

# 浓度按 scheme 明暗自适应（与 tinty-theme.js 同规则）：base00 亮度 ≥128
# 判浅色——浅色 accent 偏深，浓混会吃掉深色正文对比度。
lum=$(( (2126 * b_r + 7152 * b_g + 722 * b_b) / 10000 ))
if [ "$lum" -ge 128 ]; then
	body_pct=15
	emph_pct=30
else
	body_pct=60
	emph_pct=75
fi

m_bg="$(blend "$b_r" "$b_g" "$b_b" "$m_r" "$m_g" "$m_b" "$body_pct")"
m_em="$(blend "$b_r" "$b_g" "$b_b" "$m_r" "$m_g" "$m_b" "$emph_pct")"
g_bg="$(blend "$b_r" "$b_g" "$b_b" "$g_r" "$g_g" "$g_b" "$body_pct")"
g_em="$(blend "$b_r" "$b_g" "$b_b" "$g_r" "$g_g" "$g_b" "$emph_pct")"
m_hex="$(hex "$m_r" "$m_g" "$m_b")"
g_hex="$(hex "$g_r" "$g_g" "$g_b")"
z4_hex="$(hex "$z4_r" "$z4_g" "$z4_b")"
h_hex="$(hex "$h_r" "$h_g" "$h_b")"
blame="$(hex "$b_r" "$b_g" "$b_b") $(hex "$b1_r" "$b1_g" "$b1_b") $(hex "$b2_r" "$b2_g" "$b2_b")"

mkdir -p "$data_dir"
{
	printf '%s\n' "# _tinty_scheme: $TINTY_SCHEME_ID"
	printf '%s\n' '# 由 ~/.config/tinted-theming/tinty/hooks/delta.sh 渲染（tinty'
	printf '%s\n' '# apply/init 自动重写）；槽位语义见 docs/theming.md。'
	printf '%s\n' '[delta]'
	printf '\t%s\n' "minus-style = syntax \"$m_bg\""
	printf '\t%s\n' "minus-emph-style = syntax \"$m_em\""
	printf '\t%s\n' "minus-empty-line-marker-style = normal \"$m_bg\""
	printf '\t%s\n' "plus-style = syntax \"$g_bg\""
	printf '\t%s\n' "plus-emph-style = syntax \"$g_em\""
	printf '\t%s\n' "plus-empty-line-marker-style = normal \"$g_bg\""
	printf '\t%s\n' "hunk-header-style = \"$h_hex\""
	printf '\t%s\n' "line-numbers-left-style = \"$m_hex\""
	printf '\t%s\n' "line-numbers-minus-style = \"$m_hex\""
	printf '\t%s\n' "line-numbers-zero-style = \"$z4_hex\""
	printf '\t%s\n' "line-numbers-right-style = \"$g_hex\""
	printf '\t%s\n' "line-numbers-plus-style = \"$g_hex\""
	printf '\t%s\n' "blame-palette = \"$blame\""
} >"$out"
