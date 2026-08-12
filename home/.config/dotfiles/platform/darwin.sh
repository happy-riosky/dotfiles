if command -v brew >/dev/null 2>&1; then
  brew_prefix="$(brew --prefix 2>/dev/null || true)"
  [[ -n "$brew_prefix" ]] && dotfiles_prepend_path "$brew_prefix/bin"
  [[ -r "$brew_prefix/etc/profile.d/autojump.sh" ]] && source "$brew_prefix/etc/profile.d/autojump.sh"
  unset brew_prefix
fi
DOTFILES_LOAD_TRACE="${DOTFILES_LOAD_TRACE}:darwin"
