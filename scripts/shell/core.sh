dotfiles_default_editor() {
  if [[ -n "${EDITOR:-}" ]]; then
    export VISUAL="${VISUAL:-$EDITOR}"
  elif command -v nvim >/dev/null 2>&1; then
    export EDITOR=nvim
    export VISUAL="${VISUAL:-nvim}"
  else
    export EDITOR=vim
    export VISUAL="${VISUAL:-vim}"
  fi
}

dotfiles_prepend_path() {
  [[ -d "$1" ]] || return 0
  case ":$PATH:" in
    *":$1:"*) ;;
    *) PATH="$1${PATH:+:$PATH}" ;;
  esac
}

dotfiles_append_path() {
  [[ -d "$1" ]] || return 0
  case ":$PATH:" in
    *":$1:"*) ;;
    *) PATH="${PATH:+$PATH:}$1" ;;
  esac
}

dotfiles_prepend_path "$HOME/.local/bin"
dotfiles_prepend_path "$HOME/bin"
nvm_default_file="$HOME/.nvm/alias/default"
if [[ -r "$nvm_default_file" ]]; then
  IFS= read -r nvm_default_version < "$nvm_default_file"
  dotfiles_prepend_path "$HOME/.nvm/versions/node/v${nvm_default_version#v}/bin"
  unset nvm_default_version
fi
unset nvm_default_file
export PATH
DOTFILES_LOAD_TRACE="${DOTFILES_LOAD_TRACE:+$DOTFILES_LOAD_TRACE:}core"
