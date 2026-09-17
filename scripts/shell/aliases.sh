command -v yazi >/dev/null 2>&1 && alias y='yazi'
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
command -v gh >/dev/null 2>&1 && alias gd='gh dash'
# eza 系列：zsh 侧此处定义会被 oh-my-zsh 覆盖，由 .zshrc 内联块在
# oh-my-zsh 之后重定义回 eza；此处主要供 bash 生效
command -v eza >/dev/null 2>&1 && alias ls='eza'
command -v eza >/dev/null 2>&1 && alias ll='eza -l'
command -v eza >/dev/null 2>&1 && alias la='eza -la'
command -v eza >/dev/null 2>&1 && alias lt='eza -la --tree --level=4'
DOTFILES_LOAD_TRACE="${DOTFILES_LOAD_TRACE}:aliases"
