source "${DOTFILES_ROOT:-$HOME/dotfiles}/scripts/shell/load.bash"
case $- in *i*) ;; *) return 0 ;; esac

HISTCONTROL=ignoreboth
HISTSIZE=1000
HISTFILESIZE=2000
shopt -s histappend checkwinsize
PROMPT_COMMAND="history -a; history -n"
PS1='\u@\h:\W\$ '

[[ -r /usr/share/bash-completion/bash_completion ]] && source /usr/share/bash-completion/bash_completion
[[ -r /etc/bash_completion ]] && source /etc/bash_completion
[[ -r /usr/share/bash-completion/completions/fzf ]] && source /usr/share/bash-completion/completions/fzf
[[ -r /usr/share/doc/fzf/examples/key-bindings.bash ]] && source /usr/share/doc/fzf/examples/key-bindings.bash
[[ -r "$HOME/.fzf.bash" ]] && source "$HOME/.fzf.bash"

alias m='man'
alias mk='make'
alias mka='make all'
alias mkc='make clean'
command -v lazygit >/dev/null 2>&1 && alias lg='lazygit'
