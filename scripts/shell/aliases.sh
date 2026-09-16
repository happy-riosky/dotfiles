command -v yazi >/dev/null 2>&1 && alias y='yazi'
command -v fd >/dev/null 2>&1 && command -v fzf >/dev/null 2>&1 && command -v pbcopy >/dev/null 2>&1 && \
  alias fp='fd --type f | fzf | pbcopy'
command -v fd >/dev/null 2>&1 && command -v fzf >/dev/null 2>&1 && command -v bat >/dev/null 2>&1 && \
  alias fr="fd --type f | fzf --preview 'bat --color=always --style=numbers {}'"
DOTFILES_LOAD_TRACE="${DOTFILES_LOAD_TRACE}:aliases"
