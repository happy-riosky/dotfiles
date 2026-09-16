command -v yazi >/dev/null 2>&1 && alias y='yazi'
command -v fd >/dev/null 2>&1 && command -v fzf >/dev/null 2>&1 && command -v pbcopy >/dev/null 2>&1 && \
  alias fp='fd --type f | fzf | pbcopy'
command -v fd >/dev/null 2>&1 && command -v fzf >/dev/null 2>&1 && command -v bat >/dev/null 2>&1 && \
  alias fr="fd --type f | fzf --preview 'bat --color=always --style=numbers {}'"
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
DOTFILES_LOAD_TRACE="${DOTFILES_LOAD_TRACE}:aliases"
