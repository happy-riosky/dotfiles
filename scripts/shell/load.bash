[[ -n "${DOTFILES_BASH_LOADED:-}" ]] && return 0
DOTFILES_BASH_LOADED=1

DOTFILES_ROOT="${DOTFILES_ROOT:-$HOME/dotfiles}"
DOTFILES_SHELL_HOME="$DOTFILES_ROOT/scripts/shell"
DOTFILES_LOCAL_HOME="${DOTFILES_LOCAL_HOME:-$HOME}"
DOTFILES_PLATFORM="${DOTFILES_PLATFORM:-}"
if [[ -z "$DOTFILES_PLATFORM" ]]; then
  if [[ -n "${TERMUX_VERSION:-}" || "${PREFIX:-}" == */com.termux/* ]]; then
    DOTFILES_PLATFORM=termux
  elif [[ "$(uname -s)" == Darwin ]]; then
    DOTFILES_PLATFORM=darwin
  else
    DOTFILES_PLATFORM=linux
  fi
fi
DOTFILES_PROFILE="${DOTFILES_PROFILE:-}"
if [[ -z "$DOTFILES_PROFILE" ]]; then
  case "$DOTFILES_PLATFORM" in
    darwin) DOTFILES_PROFILE=full ;;
    linux) DOTFILES_PROFILE=server ;;
    termux) DOTFILES_PROFILE=termux ;;
    *) return 1 ;;
  esac
fi

source "$DOTFILES_SHELL_HOME/core.sh"
source "$DOTFILES_SHELL_HOME/platform/$DOTFILES_PLATFORM.sh"
source "$DOTFILES_SHELL_HOME/profiles/$DOTFILES_PROFILE.sh"
[[ -r "$DOTFILES_LOCAL_HOME/.bashrc.host" ]] && source "$DOTFILES_LOCAL_HOME/.bashrc.host"
[[ -r "$DOTFILES_LOCAL_HOME/.bashrc.local" ]] && source "$DOTFILES_LOCAL_HOME/.bashrc.local"
export DOTFILES_ROOT DOTFILES_PLATFORM DOTFILES_PROFILE
