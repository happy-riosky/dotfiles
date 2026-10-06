#!/bin/sh
# status-line.sh - tmux 状态栏动态段（左/右两种发射模式）
# 用法: status-line.sh left  <client_width> <pane_command>   左组：cmd 块
#       status-line.sh right <client_width>                  右组：电池/uptime/日期/时刻
#       （无 mode 旧调用兼容：按 right + width=<arg1> 处理，live server
#        reload 前不断流）
# 布局（斜切平行四边形，外亮内浅镜像，槽位语义见 hooks/tmux.sh）：
#   左（"\" 斜）: 会话段=seg1(黄锚点,conf 静态) + cmd=seg2(与日期同色,
#                 常驻)——合并为一块，段间 ◥ 过渡边由 conf 内联(prefix 同拍)
#   右（"/" 斜，块块贴合）:     电池=seg4 → uptime=seg3 → 日期=seg2 → 时刻=seg1(黄锚点)
# 宽度门控（width 缺失/非数字按全显，不惩罚异常上下文）：
#   cmd 常驻（左侧）；时刻 常驻（右端锚点）；电池 >=60；uptime、日期 >=100
# 电池直调 tmux-battery 插件脚本（[ -x ] 守卫，缺插件/无电池静默省段），
# 图标读 conf 里的 @batt_icon_status_* 选项，与原 #{battery_icon_status} 同源。
# uptime: Linux/Termux/WSL 读 /proc/uptime；macOS 用 date+%s 减 sysctl -n
#   kern.boottime 的 sec 字段；都失败输出 "?"。
# 格式降级链: "5d 3h"（>=1d，分钟丢弃）-> "23h 15m"（>=1h）-> "42m"。
# 测试钩子: TMUX_UPTIME_PROC / TMUX_UPTIME_BOOTTIME / TMUX_BATT_DIR / TMUX_TP_FILE。
# 宽度比较必须在 shell 里做数值判断：tmux 格式层 #{>=:} 是字典序、
# #{?#{e|...}} 恒真（未求值字面串非空即真），均不可用于宽度门控。
set -eu

BATT_MIN=60    # 低于此宽度隐藏电池（右组）
RICH_MIN=100   # 低于此宽度隐藏 uptime 与日期（右组，两者同进退）

case ${1:-} in
left)  mode=left;  width=${2:-}; cmd=${3:-} ;;
right) mode=right; width=${2:-}; cmd='' ;;
*)     mode=right; width=${1:-}; cmd='' ;;   # 旧调用兼容
esac

# ---- 调色板 -------------------------------------------------------------
# tinty hook 产物（tinty apply/init 重写）；缺失时用 frappe 常量兜底
# ——注意：兜底值仍是旧黄混设计（与 simple_batt_fallback.tmux.conf 同值，
# 同步缓议，见 docs/theming.md）。
# 测试钩子: TMUX_TP_FILE 指向替代配色文件。
tp_file=${TMUX_TP_FILE:-${XDG_DATA_HOME:-$HOME/.local/share}/tinted-theming/tinty/tmux-status-colors.conf}

tp() { # tp <option> <fallback_hex>
	v=$(sed -n "s/^set -g $1 \"\\([^\"]*\\)\"$/\\1/p" "$tp_file" 2>/dev/null | head -n 1)
	if [ -n "$v" ]; then printf '%s' "$v"; else printf '%s' "$2"; fi
}

TP_BG=$(tp @tp_bg '#303446')
TP_FG=$(tp @tp_fg '#a5adcb')
TP_S1_BG=$(tp @tp_seg1_bg '#b57224'); TP_S1_FG=$(tp @tp_seg1_fg '#303446')
TP_S2_BG=$(tp @tp_seg2_bg '#93622d'); TP_S2_FG=$(tp @tp_seg2_fg '#303446')
TP_S3_BG=$(tp @tp_seg3_bg '#715236'); TP_S3_FG=$(tp @tp_seg3_fg '#a5adcb')
TP_S4_BG=$(tp @tp_seg4_bg '#52443d'); TP_S4_FG=$(tp @tp_seg4_fg '#a5adcb')

is_num() {
	case $1 in ''|*[!0-9]*) return 1 ;; esac
	return 0
}

# width 缺失/非数字时视为全显
wide_enough() {
	if is_num "$width"; then
		[ "$width" -ge "$1" ]
	else
		return 0
	fi
}

# ---- 段内容 -------------------------------------------------------------

batt_part() {
	dir=${TMUX_BATT_DIR:-$HOME/.tmux/plugins/tmux-battery}
	pct_script="$dir/scripts/battery_percentage.sh"
	icon_script="$dir/scripts/battery_icon_status.sh"
	[ -x "$pct_script" ] || return 1
	pct=$( "$pct_script" 2>/dev/null | tr -d '%' ) || pct=''
	[ -n "$pct" ] || return 1
	icon=''
	if [ -x "$icon_script" ]; then
		icon=$( "$icon_script" 2>/dev/null ) || icon=''
	fi
	printf '%s%%%s' "$pct" "$icon"
}

uptime_secs() {
	proc=${TMUX_UPTIME_PROC:-/proc/uptime}
	if [ -r "$proc" ]; then
		up=''
		read -r up _ <"$proc" || up=''
		up=${up%%.*}
		if is_num "$up"; then
			printf '%s' "$up"
			return 0
		fi
	fi

	boot=''
	# 注意锚定 '^{':贪婪 '.*sec = ' 会误吞 'usec = 0'(boottime 只有单行)
	if [ -n "${TMUX_UPTIME_BOOTTIME:-}" ] && [ -r "$TMUX_UPTIME_BOOTTIME" ]; then
		boot=$(sed -n 's/^[[:space:]]*{ sec = \([0-9][0-9]*\),.*/\1/p' \
			"$TMUX_UPTIME_BOOTTIME" | head -n 1)
	elif command -v sysctl >/dev/null 2>&1; then
		boot=$(sysctl -n kern.boottime 2>/dev/null \
			| sed -n 's/^[[:space:]]*{ sec = \([0-9][0-9]*\),.*/\1/p' | head -n 1) || boot=''
	fi

	now=$(date +%s) || now=''
	if is_num "$boot" && is_num "$now" && [ "$now" -gt "$boot" ]; then
		printf '%s' "$((now - boot))"
		return 0
	fi
	return 1
}

fmt_uptime() {
	secs=$1
	if [ "$secs" -ge 86400 ]; then
		printf '%dd %dh' $((secs / 86400)) $((secs % 86400 / 3600))
	elif [ "$secs" -ge 3600 ]; then
		printf '%dh %dm' $((secs / 3600)) $((secs % 3600 / 60))
	else
		printf '%dm' $((secs / 60))
	fi
}

# ---- 发射 ---------------------------------------------------------------

# 左组（合并进会话块）：会话段 + ◥ 过渡边由 conf 内联（prefix
# 两分支同拍即时翻转——#() 任务输出有滞后，若过渡边出自脚本会与文本块
# 变色不同步）；本脚本只补 cmd 段内容（seg2，与日期同色）+ ◣ 尾边；
# cmd 为空时仅输出会话段的闭合尾边（颜色按 prefix 参数，此场景无同拍
# 对比，滞后不可见）。
if [ "$mode" = left ]; then
	if [ -n "$cmd" ]; then
		out="#[fg=$TP_S2_FG]#[bg=$TP_S2_BG] $cmd "
		out="$out#[fg=$TP_S2_BG]#[bg=$TP_BG]◣"
	else
		prev_bg="$TP_S1_BG"
		if [ "${4:-0}" = "1" ]; then
			prev_bg="$TP_FG"
		fi
		out="#[fg=$prev_bg]#[bg=$TP_BG]◣"
	fi
	printf '%s' "$out"
	exit 0
fi

# 右组："/" 斜块块贴合：每块 ◢ 入首（fg=块色 bg=前块色，无底色
# 斜缝），首块自底色升、末块平边收（tmux-power build_right_status 同款）。
# 填充区必须含完整右边缘（◢）才能与色块连通，装反会断裂成楔子。
# 块内样式码随 #() 输出渲染（tmux 3.5a 实测，见 docs/theming.md）。
segs=''

add_seg() { # add_seg <bg> <fg> <text>
	segs="$segs$1|$2|$3
"
}

if wide_enough "$BATT_MIN" && batt=$(batt_part); then
	add_seg "$TP_S4_BG" "$TP_S4_FG" "$batt"
fi

if wide_enough "$RICH_MIN"; then
	if up=$(uptime_secs); then
		add_seg "$TP_S3_BG" "$TP_S3_FG" "$(fmt_uptime "$up")"
	else
		add_seg "$TP_S3_BG" "$TP_S3_FG" '?'
	fi
	add_seg "$TP_S2_BG" "$TP_S2_FG" "$(date '+%Y-%m-%d')"
fi

# 时刻常驻 = 右端黄锚点
add_seg "$TP_S1_BG" "$TP_S1_FG" "$(date '+%H:%M')"

out=''
prev_bg="$TP_BG"
while IFS='|' read -r bg fg text; do
	[ -n "$text" ] || continue
	out="$out#[fg=$bg]#[bg=$prev_bg]◢"
	out="$out#[fg=$fg]#[bg=$bg] $text "
	prev_bg="$bg"
done <<EOF
$segs
EOF

if [ "$prev_bg" != "$TP_BG" ]; then
	out="$out#[default]"
fi

printf '%s' "$out"
