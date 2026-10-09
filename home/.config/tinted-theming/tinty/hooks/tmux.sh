#!/usr/bin/env bash
# tinty hook：按 apply/init 的 scheme 渲染 tmux 状态栏色槽到 <data>/
# tmux-status-colors.conf（运行时产物，@tp_* 用户选项），.tmux.conf 启动时
# source（-q 容忍缺失），本 hook 对运行中 server 热加载；status-line.sh
# 直接读该文件取色，simple_batt 布局的窗口/会话块经 #{@tp_*} 引用。
# 设计：中性海拔 + 黄锚点（与 vim lightline tinty 配色同构）——
#   seg1 = 纯 base0A 黄（左=会话块 / 右=日期块，镜像锚点），字色按明暗
#          （深色 scheme→base00，浅色→base05，防浅底低对比）
#   seg2 = base03（活动窗口 / uptime）   字色 base05
#   seg3 = base02（电池）                字色 base05
#   seg4 = base01（其他窗口 / cmd）      字色 base05
# 海拔槽由 scheme 设计师调好，深浅 scheme 天然和谐；不做黄色混色。
# prefix 按下 = 反色指示：黄字 + 底色 + 加粗（见 simple_batt.tmux.conf）。
# 注意：simple_batt_fallback 与 status-line.sh 内置的 frappe 常量仍是旧
# 黄混设计（同步缓议，见 docs/theming.md）。
# 缺 env 即静默退出保留旧产物（首行 _tinty_scheme 标记陈旧）。成功零输出；
# 槽位语义见 docs/theming.md。
set -euo pipefail

data_dir="${XDG_DATA_HOME:-$HOME/.local/share}/tinted-theming/tinty"
out="$data_dir/tmux-status-colors.conf"

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

[ -n "${TINTY_SCHEME_ID:-}" ] || exit 0
p00="$(rgb 00)" || exit 0
p01="$(rgb 01)" || exit 0
p02="$(rgb 02)" || exit 0
p03="$(rgb 03)" || exit 0
p05="$(rgb 05)" || exit 0
p0a="$(rgb 0A)" || exit 0

read -r bg_r bg_g bg_b <<<"$p00"
read -r e1_r e1_g e1_b <<<"$p01"
read -r e2_r e2_g e2_b <<<"$p02"
read -r e3_r e3_g e3_b <<<"$p03"
read -r fg_r fg_g fg_b <<<"$p05"
read -r ac_r ac_g ac_b <<<"$p0a"

# 黄锚点块字色按 scheme 明暗（同 delta.sh 的 luma 规则）
lum=$(( (2126 * bg_r + 7152 * bg_g + 722 * bg_b) / 10000 ))
if [ "$lum" -ge 128 ]; then
	accent_fg="$(hex "$fg_r" "$fg_g" "$fg_b")"
else
	accent_fg="$(hex "$bg_r" "$bg_g" "$bg_b")"
fi

mkdir -p "$data_dir"
{
	printf '%s\n' "# _tinty_scheme: $TINTY_SCHEME_ID"
	printf '%s\n' '# 由 ~/.config/tinted-theming/tinty/hooks/tmux.sh 渲染（tinty'
	printf '%s\n' '# apply/init 自动重写）；@tp_* 供 simple_batt 布局与'
	printf '%s\n' '# status-line.sh 引用；槽位语义见 docs/theming.md。'
	printf 'set -g @tp_bg "%s"\n' "$(hex "$bg_r" "$bg_g" "$bg_b")"
	printf 'set -g @tp_fg "%s"\n' "$(hex "$fg_r" "$fg_g" "$fg_b")"
	printf 'set -g @tp_accent "%s"\n' "$(hex "$ac_r" "$ac_g" "$ac_b")"
	printf 'set -g @tp_seg1_bg "%s"\n' "$(hex "$ac_r" "$ac_g" "$ac_b")"
	printf 'set -g @tp_seg1_fg "%s"\n' "$accent_fg"
	printf 'set -g @tp_seg2_bg "%s"\n' "$(hex "$e3_r" "$e3_g" "$e3_b")"
	printf 'set -g @tp_seg2_fg "%s"\n' "$(hex "$fg_r" "$fg_g" "$fg_b")"
	printf 'set -g @tp_seg3_bg "%s"\n' "$(hex "$e2_r" "$e2_g" "$e2_b")"
	printf 'set -g @tp_seg3_fg "%s"\n' "$(hex "$fg_r" "$fg_g" "$fg_b")"
	printf 'set -g @tp_seg4_bg "%s"\n' "$(hex "$e1_r" "$e1_g" "$e1_b")"
	printf 'set -g @tp_seg4_fg "%s"\n' "$(hex "$fg_r" "$fg_g" "$fg_b")"
} >"$out"

# 无运行中 server 时静默跳过；启动路径由 .tmux.conf source 兜底
tmux source-file "$out" 2>/dev/null || true

# 刷新 server 全局调色板环境（BASE16_THEME / FZF_DEFAULT_OPTS）：popup/
# run-shell 等非交互派生进程不加载 .zshrc，只能继承 server env，陈旧值会
# 让其内 fzf/base16 消费方停在旧 scheme（实测两者均冻结在 server 启动值）。
# 必须在干净子 bash 里 source：本脚本的 set -u 会被 tinted-shell 脚本里
# 未守卫的 $ITERM_SESSION_ID 等展开触发 unbound variable 致命错误（|| true
# 接不住，交互 shell 无 set -u 故无恙）；子进程内 TTY 指向不可写路径屏蔽
# OSC 输出，只取 env 副作用后回传。tmux CLI 同上面 source-file 裸调（默认
# socket，命中即刷新）。缺产物/子进程失败静默跳过（保留旧 env）。
if command -v tmux >/dev/null 2>&1 && \
   [ -r "$data_dir/tinted-shell-scripts-file.sh" ] && \
   [ -r "$data_dir/tinted-fzf-sh-file.sh" ]; then
	fresh="$(bash -c '
		unset FZF_DEFAULT_OPTS BASE16_THEME
		TTY=/nonexistent-tty-env-only
		. "$1"
		. "$2"
		printf "%s\n%s" "${BASE16_THEME:-}" "${FZF_DEFAULT_OPTS# }"
	' hook-palette-env "$data_dir/tinted-shell-scripts-file.sh" \
		"$data_dir/tinted-fzf-sh-file.sh" 2>/dev/null)" || fresh=
	if [ -n "$fresh" ]; then
		tmux set-environment -g BASE16_THEME "${fresh%%$'\n'*}" || true
		tmux set-environment -g FZF_DEFAULT_OPTS "${fresh#*$'\n'}" || true
	fi
fi
