brew_prefix="${DOTFILES_HOMEBREW_PREFIX:-}"
if [[ -z "$brew_prefix" ]]; then
  for candidate in /opt/homebrew /usr/local; do
    if [[ -x "$candidate/bin/brew" ]]; then
      brew_prefix="$candidate"
      break
    fi
  done
fi
if [[ -n "$brew_prefix" ]]; then
  dotfiles_prepend_path "$brew_prefix/bin"
  [[ -r "$brew_prefix/etc/profile.d/autojump.sh" ]] && source "$brew_prefix/etc/profile.d/autojump.sh"
fi
unset brew_prefix candidate
DOTFILES_LOAD_TRACE="${DOTFILES_LOAD_TRACE}:darwin"
