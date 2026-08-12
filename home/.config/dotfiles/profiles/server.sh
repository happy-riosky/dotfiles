export GEM_HOME="${GEM_HOME:-$HOME/gems}"
dotfiles_prepend_path "$GEM_HOME/bin"
DOTFILES_LOAD_TRACE="${DOTFILES_LOAD_TRACE}:server"
