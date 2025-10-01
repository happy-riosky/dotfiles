bindkey -M vicmd 'k' history-substring-search-up
bindkey -M vicmd 'j' history-substring-search-down

# Enable ^O to clear the screen as ^L is for moving
bindkey -M emacs "^O" clear-screen
bindkey -M viins "^O" clear-screen
bindkey -M vicmd "^O" clear-screen
