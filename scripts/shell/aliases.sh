# yazi：启动前按当前 tinty scheme 生成/刷新 flavor 与 glow 样式（yazi 无
# theme 热重载，见 docs/theming.md）；theme.toml 的 [flavor] dark/light 同指
# tinty，明暗探测失效化。刷新失败仅告警，裸启动（沿用上次生成或内建主题）
command -v yazi >/dev/null 2>&1 && y() {
	if [ -n "${DOTFILES_ROOT:-}" ] && [ -f "$DOTFILES_ROOT/scripts/tinty/generate" ]; then
		bash "$DOTFILES_ROOT/scripts/tinty/generate" >/dev/null 2>&1 || \
			printf 'y: tinty/generate 刷新失败，沿用上次生成的主题\n' >&2
	fi
	command yazi "$@"
}
command -v nvim >/dev/null 2>&1 && alias v='nvim'
command -v fd >/dev/null 2>&1 && command -v fzf >/dev/null 2>&1 && command -v pbcopy >/dev/null 2>&1 && \
  alias fp='fd --type f | fzf | pbcopy'
# fr：fd + fzf 预览；tmux 内 OSC 11 背景探测不可靠，darwin 下 bat 主题
# 随 macOS 外观切换（浅 OneHalfLight / 深 OneHalfDark）；显式导出
# BAT_THEME 时不覆盖；非 darwin 原样透传
command -v fd >/dev/null 2>&1 && command -v fzf >/dev/null 2>&1 && command -v bat >/dev/null 2>&1 && fr() {
	if [ "$DOTFILES_PLATFORM" = darwin ] && [ -z "${BAT_THEME:-}" ]; then
		local theme=OneHalfLight
		if [ "$(defaults read -g AppleInterfaceStyle 2>/dev/null)" = "Dark" ]; then
			theme=OneHalfDark
		fi
		fd --type f | fzf --preview "bat --color=always --style=numbers --theme=$theme {}"
	else
		fd --type f | fzf --preview 'bat --color=always --style=numbers {}'
	fi
}
# glow markdown 阅读器：样式跟随 tinty——启动前刷新生成器产物
# ~/.config/tinted-theming/tinty-glow.json，且仅当其 _tinty_scheme 标记与
# tinty current_scheme 一致时使用（-s 显式传绝对路径——glow 的 -s 只认内建
# 样式名或 JSON 文件绝对路径，不支持 ~ 展开与命名样式查找；GLAMOUR_STYLE
# 同时覆盖 TUI 模式）；标记不匹配（切换 scheme 后生成失败/残留过期文件）则
# 回退内建样式，绝不渲染过期深浅。显式传 -s/--style 时不覆盖；无 tinty
# 生成物时 darwin 改读 macOS 外观设置选内建 dark/light，其余平台原样透传。
# gl 为短别名
command -v glow >/dev/null 2>&1 && glow() {
	local style_file="${XDG_CONFIG_HOME:-$HOME/.config}/tinted-theming/tinty-glow.json"
	local scheme_file="${XDG_DATA_HOME:-$HOME/.local/share}/tinted-theming/tinty/current_scheme"
	if [ -n "${DOTFILES_ROOT:-}" ] && [ -f "$DOTFILES_ROOT/scripts/tinty/generate" ]; then
		bash "$DOTFILES_ROOT/scripts/tinty/generate" >/dev/null 2>&1 || true
	fi
	local arg explicit=
	for arg in "$@"; do
		case "$arg" in
			-s*|--style*) explicit=1 ;;
		esac
	done
	if [ -n "$explicit" ]; then
		command glow "$@"
	elif [ -r "$style_file" ] && [ -r "$scheme_file" ] && \
		grep -q "\"_tinty_scheme\": \"$(tr -d '[:space:]' < "$scheme_file")\"" "$style_file"; then
		GLAMOUR_STYLE="$style_file" command glow -s "$style_file" "$@"
	elif [ "$DOTFILES_PLATFORM" = darwin ]; then
		local style=light
		if [ "$(defaults read -g AppleInterfaceStyle 2>/dev/null)" = "Dark" ]; then
			style=dark
		fi
		command glow -s "$style" "$@"
	else
		command glow "$@"
	fi
}
command -v glow >/dev/null 2>&1 && alias gl='glow'
# gd：由受管脚本 ~/.local/bin/gd 提供（repo 上下文感知的 gh dash 启动器）
# eza 系列：zsh 侧此处定义会被 oh-my-zsh 覆盖，由 .zshrc 内联块在
# oh-my-zsh 之后重定义回 eza；此处主要供 bash 生效
command -v eza >/dev/null 2>&1 && alias ls='eza'
command -v eza >/dev/null 2>&1 && alias ll='eza -l'
command -v eza >/dev/null 2>&1 && alias la='eza -la'
command -v eza >/dev/null 2>&1 && alias lt='eza -la --tree --level=4'
# lazygit：UI 主题跟随 tinty——启动前刷新运行时产物，优先叠加生成的
# ~/.config/lazygit/tinty.yml（当前 scheme 渲染，_tinty_scheme 标记须与
# current_scheme 一致，防切换后陈旧深浅错配）；标记不符/生成失败时按
# tinty variant 回退 frappe.yml(dark)/latte-theme.yml(light) overlay；无
# tinty 时统一叠 frappe.yml（对齐 nvim :LazyGit 的 frappe 兜底）；overlay
# 或 base 不可读时才裸启动（内建主题）。delta 明暗由 tinty 的 git config 决定。
command -v lazygit >/dev/null 2>&1 && lg() {
	local dir="${XDG_CONFIG_HOME:-$HOME/.config}/lazygit"
	local base="$dir/config.yml" overlay=""
	if [ -n "${DOTFILES_ROOT:-}" ] && [ -f "$DOTFILES_ROOT/scripts/tinty/generate" ]; then
		bash "$DOTFILES_ROOT/scripts/tinty/generate" >/dev/null 2>&1 || true
	fi
	local scheme_file="${XDG_DATA_HOME:-$HOME/.local/share}/tinted-theming/tinty/current_scheme"
	if [ -r "$dir/tinty.yml" ] && [ -r "$scheme_file" ] && \
		grep -q "# _tinty_scheme: $(tr -d '[:space:]' < "$scheme_file")" "$dir/tinty.yml"; then
		overlay="$dir/tinty.yml"
	elif command -v tinty >/dev/null 2>&1; then
		case "$(command tinty current variant 2>/dev/null)" in
			dark) overlay="$dir/frappe.yml" ;;
			light) overlay="$dir/latte-theme.yml" ;;
		esac
	else
		overlay="$dir/frappe.yml"
	fi
	if [ -n "$overlay" ] && [ -r "$base" ] && [ -r "$overlay" ]; then
		LG_CONFIG_FILE="$base,$overlay" command lazygit "$@"
	else
		command lazygit "$@"
	fi
}
# tinty (tinted-theming)：bat 跟随终端 16 色调色板（tinted-shell 已重定义，
# base16-256 为 bat 内置主题）；fr 预览里显式 --theme 仍优先生效。
# theme 用 fzf 挑选 scheme 并应用（zsh 侧 tinty 为包装函数，apply 后调色板即时生效）
command -v bat >/dev/null 2>&1 && command -v tinty >/dev/null 2>&1 && \
	alias bat='bat --theme=base16-256'
command -v tinty >/dev/null 2>&1 && command -v fzf >/dev/null 2>&1 && \
	alias theme='tinty apply "$(tinty list | fzf)"'
DOTFILES_LOAD_TRACE="${DOTFILES_LOAD_TRACE}:aliases"
