# faster source
alias s='source'
alias sb='source ~/.bashrc'

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# some more ls aliases
alias ll='ls -alhF'
alias la='ls -A'
alias l='ls -CF'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# a quick way to get out of current directory
alias ..='cd ..'
alias ...='cd ../../../'
alias ....='cd ../../../../'
alias .....='cd ../../../../'
alias .4='cd ../../../../'
alias .5='cd ../../../../..'

# define my own alias
# copy the output of the shell into the clipboard
alias x="xclip -selection c"

# use the explorer.exe to open current folder in win11
alias exp="explorer.exe ."

# for development
alias eca="cd /mnt/c/Learn/csdiy/UCB_EECS16A_Su20 && jupyter notebook"
alias odd="cd /home/riosky/src/odoo && code . && cd -"

# git relate
alias ga="git add"
alias g.="git add ."
alias gb="git branch"
alias gs="git status"
alias gl="git log"
alias gc="git commit"
alias gm="git commit -m"
alias gp="git push"
alias gpo="git push origin"
alias gr="git remote"
alias gv="git remote -v"

# test gitlet
alias tgl="export PROJ2PATH='/mnt/c/Learn/csdiy/UCB_CS61B_Sp21/cs61b/sp21-s42/proj2' &&
    export TESTGITLETPATH='/mnt/c/Learn/csdiy/UCB_CS61B_Sp21/test-gitlet' &&
    cd $PROJ2PATH &&
    make &&
    cp ./gitlet/*.class $TESTGITLETPATH/gitlet &&
    make clean &&
    cd $TESTGITLETPATH ||
    rm ./.gitlet &&
    la"

# anaconda
alias ca="conda activate"

# a more beautiful cat
alias bat="batcat"
