alias bat="batcat"
alias m="man"
alias \?="echo $?"
alias v="vim"
alias vi="vim -u NONE -C"
alias x="xclip"

# use the explorer.exe to open current folder in win11
alias exp="explorer.exe ."

# for make
alias mk="make"
alias mka="make all"
alias mkc="make clean"

# for gcc
alias gE="gcc -E"

alias sai="sudo apt install" 
alias sp="sudo poweroff" 

alias ls="ls --color=auto"
alias ca="conda activate"

# remove all branches except current one
alias gdo="git branch | grep -v "\*" | xargs git branch -D"

# for neovim
alias v="nvim"

alias lta4="lsd -la --tree --depth=4"
