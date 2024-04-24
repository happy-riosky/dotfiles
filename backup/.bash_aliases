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
alias gs="git status"
alias gl="git log"
alias gm="git commit -m"
alias gp="git push"
alias gpo="git push origin"

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
