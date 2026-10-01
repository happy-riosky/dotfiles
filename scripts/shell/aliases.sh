# yazi：启动前按当前 tinty scheme 生成/刷新 flavor（yazi 无 theme 热重载，
# 见 docs/theming.md）；theme.toml 的 [flavor] dark/light 同指 tinty，
# 明暗探测失效化。无 DOTFILES_ROOT/脚本缺失时裸启动（沿用上次生成或内建主题）
command -v yazi >/dev/null 2>&1 && y() {
	if [ -n "${DOTFILES_ROOT:-}" ] && [ -f "$DOTFILES_ROOT/scripts/tinty-yazi-flavor" ]; then
		bash "$DOTFILES_ROOT/scripts/tinty-yazi-flavor" >/dev/null 2>&1 || true
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
# glow markdown 阅读器：tmux 内 OSC 11 背景探测不可靠，darwin 下改读 macOS 外观设置；
# 显式传 -s/--style 时不覆盖；gl 为短别名；非 darwin 原样透传
command -v glow >/dev/null 2>&1 && glow() {
	if [ "$DOTFILES_PLATFORM" != darwin ]; then
		command glow "$@"
		return
	fi
	local style=light explicit=
	if [ "$(defaults read -g AppleInterfaceStyle 2>/dev/null)" = "Dark" ]; then
		style=dark
	fi
	local arg
	for arg in "$@"; do
		case "$arg" in
			-s*|--style*) explicit=1 ;;
		esac
	done
	if [ -n "$explicit" ]; then
		command glow "$@"
	else
		command glow -s "$style" "$@"
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
# lazygit：UI 主题跟随 tinty——按当前 scheme variant 选 overlay
# （dark→frappe.yml / light→latte-theme.yml）经 LG_CONFIG_FILE 叠加到
# config.yml；无 tinty 或缺 overlay 文件时裸启动（lazygit 内建主题）。
# delta 的明暗由 tinty 的 git config 决定，无需在此传 --dark/--light。
command -v lazygit >/dev/null 2>&1 && lg() {
	local dir="${XDG_CONFIG_HOME:-$HOME/.config}/lazygit"
	local base="$dir/config.yml" overlay=""
	if command -v tinty >/dev/null 2>&1; then
		case "$(command tinty current variant 2>/dev/null)" in
			dark) overlay="$dir/frappe.yml" ;;
			light) overlay="$dir/latte-theme.yml" ;;
		esac
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
