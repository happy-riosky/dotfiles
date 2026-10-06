#!/usr/bin/env bash
# tinty hook：渲染 ~/.config/otty/themes/tinty-<scheme-slug>.ottytheme
# （运行时产物，16 色 base16 标准映射，与 kitty 同源）。Otty 保存配置为
# 原子写（temp+rename 不跟随软链），受管软链会被顶回（2026-09-16 退管，
# 见 docs/archive/process.md），故不经 link 管理。`config reload` 不重读
# 同名主题文件的内容、也不对已存在窗口重应用主题（实测）——故 theme/
# theme-dark 经 otty-cli config set 指到**当前 slug**（键值变化让 reload
# 后新建窗口/标签即时拿到新配色；旧窗口需重开，app 重启必然正确）。
# 无 CLI / 未运行时只写文件（持久层不依赖 IPC）。内联 palette-*/
# foreground/background 快照色优先于主题文件（Otty 颜色 UI 会写回，
# 需 config unset 重清）。~/.config/otty 缺失（server/termux）或缺 tinty
# env 即静默退出保留旧产物。成功零输出；槽位映射见 docs/theming.md。
set -euo pipefail

otty_dir="$HOME/.config/otty"
[ -d "$otty_dir" ] || exit 0

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

hx() {
	local r g b
	r="$(comp "$1" R)" || return 1
	g="$(comp "$1" G)" || return 1
	b="$(comp "$1" B)" || return 1
	printf '#%02x%02x%02x' "$r" "$g" "$b"
}

[ -n "${TINTY_SCHEME_ID:-}" ] || exit 0
slug="tinty-$(printf '%s' "$TINTY_SCHEME_ID" | tr -C 'a-z0-9-' '-')"
out="$otty_dir/themes/$slug.ottytheme"

p00="$(rgb 00)" || exit 0
c00="$(hx 00)" || exit 0
c03="$(hx 03)" || exit 0
c05="$(hx 05)" || exit 0
c07="$(hx 07)" || exit 0
c08="$(hx 08)" || exit 0
c0a="$(hx 0A)" || exit 0
c0b="$(hx 0B)" || exit 0
c0c="$(hx 0C)" || exit 0
c0d="$(hx 0D)" || exit 0
c0e="$(hx 0E)" || exit 0

read -r b_r b_g b_b <<<"$p00"
lum=$(( (2126 * b_r + 7152 * b_g + 722 * b_b) / 10000 ))
if [ "$lum" -ge 128 ]; then
	mode=light
else
	mode=dark
fi

mkdir -p "$otty_dir/themes"
{
	printf '%s\n' "# _tinty_scheme: $TINTY_SCHEME_ID"
	printf '%s\n' '[meta]'
	printf '\t%s\n' "name = \"tinty $TINTY_SCHEME_ID\""
	printf '\t%s\n' "mode = \"$mode\""
	printf '%s\n' '[terminal]'
	printf '\t%s\n' "foreground = \"$c05\""
	printf '\t%s\n' "background = \"$c00\""
	printf '\t%s\n' 'palette = ['
	printf '\t\t%s\n' "\"$c00\", \"$c08\", \"$c0b\", \"$c0a\","
	printf '\t\t%s\n' "\"$c0d\", \"$c0e\", \"$c0c\", \"$c05\","
	printf '\t\t%s\n' "\"$c03\", \"$c08\", \"$c0a\", \"$c0b\","
	printf '\t\t%s\n' "\"$c0c\", \"$c0d\", \"$c0e\", \"$c07\","
	printf '\t%s\n' ']'
} >"$out"

# theme/theme-dark 指到当前 slug；相同值幂等跳过（避免无谓改写 config）。
cli="$(command -v otty-cli || true)"
if [ -z "$cli" ]; then
	for c in "$HOME/.local/bin/otty-cli" \
		/Applications/Otty.app/Contents/MacOS/otty-cli; do
		[ -x "$c" ] && cli="$c" && break
	done
fi
if [ -n "$cli" ]; then
	cur="$("$cli" config get theme </dev/null 2>/dev/null || true)"
	if [ "$cur" != "$slug" ]; then
		"$cli" -q config set theme "$slug" </dev/null >/dev/null 2>&1 || true
		"$cli" -q config set theme-dark "$slug" </dev/null >/dev/null 2>&1 || true
	fi
	"$cli" -q config reload </dev/null >/dev/null 2>&1 || true
	# 清理旧 scheme 的受管主题（含无后缀旧版 tinty.ottytheme）
	for old in "$otty_dir"/themes/tinty*.ottytheme; do
		[ "$old" = "$out" ] || rm -f -- "$old"
	done
fi
