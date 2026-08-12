[[ -n "${PREFIX:-}" ]] && dotfiles_prepend_path "$PREFIX/bin"
DOTFILES_LOAD_TRACE="${DOTFILES_LOAD_TRACE}:termux"
