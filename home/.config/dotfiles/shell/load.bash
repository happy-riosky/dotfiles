[[ -n "${DOTFILES_BASH_LOADED:-}" ]] && return 0
DOTFILES_BASH_LOADED=1

DOTFILES_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles"
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

source "$DOTFILES_CONFIG_HOME/shell/core.sh"
source "$DOTFILES_CONFIG_HOME/platform/$DOTFILES_PLATFORM.sh"
source "$DOTFILES_CONFIG_HOME/profiles/$DOTFILES_PROFILE.sh"
[[ -r "$DOTFILES_CONFIG_HOME/host.bash" ]] && source "$DOTFILES_CONFIG_HOME/host.bash"
[[ -r "$DOTFILES_CONFIG_HOME/local.bash" ]] && source "$DOTFILES_CONFIG_HOME/local.bash"
export DOTFILES_PLATFORM DOTFILES_PROFILE
