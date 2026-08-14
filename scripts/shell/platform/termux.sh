[[ -n "${PREFIX:-}" ]] && dotfiles_prepend_path "$PREFIX/bin"
[[ -r "${PREFIX:-}/etc/profile.d/autojump.sh" ]] && source "$PREFIX/etc/profile.d/autojump.sh"
DOTFILES_LOAD_TRACE="${DOTFILES_LOAD_TRACE}:termux"
