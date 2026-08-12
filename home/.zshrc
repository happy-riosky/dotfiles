[[ -o interactive ]] || return 0

if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

setopt CHASE_LINKS
export ZSH="$HOME/.oh-my-zsh"
if [[ -r "$ZSH/oh-my-zsh.sh" ]]; then
  if [[ -d "$ZSH/custom/themes/powerlevel10k" ]]; then
    ZSH_THEME="powerlevel10k/powerlevel10k"
  else
    ZSH_THEME="robbyrussell"
  fi
  plugins=(git)
  for plugin in zsh-vi-mode zsh-autosuggestions zsh-history-substring-search zsh-syntax-highlighting; do
    [[ -d "$ZSH/custom/plugins/$plugin" ]] && plugins+=("$plugin")
  done
  source "$ZSH/oh-my-zsh.sh"
fi

[[ -r "$HOME/.p10k.zsh" ]] && source "$HOME/.p10k.zsh"

export NVM_DIR="$HOME/.nvm"
[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
command -v nvm >/dev/null 2>&1 && nvm use default --silent >/dev/null 2>&1 || true
if command -v go >/dev/null 2>&1; then
  go_path="$(go env GOPATH 2>/dev/null || true)"
  [[ -n "$go_path" ]] && dotfiles_append_path "$go_path/bin"
  unset go_path
fi

alias m='man'
alias mk='make'
alias mka='make all'
alias mkc='make clean'
command -v lazygit >/dev/null 2>&1 && alias lg='lazygit'
command -v lsd >/dev/null 2>&1 && alias lt='lsd -la --tree --depth=4'
command -v pbcopy >/dev/null 2>&1 && alias pwp='pwd | pbcopy'
command -v opencode >/dev/null 2>&1 && alias oc='opencode'

if (( $+functions[history-substring-search-up] )); then
  bindkey -M vicmd 'k' history-substring-search-up
  bindkey -M vicmd 'j' history-substring-search-down
fi
bindkey -M emacs '^O' clear-screen
bindkey -M viins '^O' clear-screen
bindkey -M vicmd '^O' clear-screen
