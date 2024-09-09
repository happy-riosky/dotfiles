# Intro

This repo caontains the way that I manage my dotfiles with the help of `mackup`.

`mackup` repo is in [here](https://github.com/lra/mackup?tab=readme-ov-file).

# Usage

## set up env

```
# do this in your home directory
$ git clone https://github.com/Duodecimy/dotfiles

$ ./dotfiles/setup
```

for Vim:
```
sudo apt install vim-gtk3
git clone https://github.com/mileszs/ack.vim.git ~/.vim/pack/vendor/start/ack.vim
git clone --depth=1 https://github.com/ctrlpvim/ctrlp.vim.git ~/.vim/pack/vendor/start/ctrlp
git clone https://github.com/preservim/nerdtree.git ~/.vim/pack/vendor/start/nerdtree
vim -u NONE -c "helptags ~/.vim/pack/vendor/start/nerdtree/doc" -c q
git clone https://github.com/christoomey/vim-tmux-navigator.git ~/.vim/pack/vendor/start/vim-tmux-navigator
git clone https://github.com/easymotion/vim-easymotion ~/.vim/pack/vendor/start/vim-easymotion
git clone https://github.com/justmao945/vim-clang.git ~/.vim/pack/completion/start/vim-clang
git clone https://github.com/itchyny/lightline.vim.git ~/.vim/pack/vendor/start/lightline.vim
```

for tmux:
```
ln -s ~/dotfiles/backup/.tmux ~/.tmux;
git clone https://github.com/tmux-plugins/tpm.git ~/.tmux/plugins/tpm
git clone https://github.com/tmux-plugins/tmux-battery.git ~/.tmux/plugins/tmux-battery
git clone https://github.com/tmux-plugins/tmux-sensible.git ~/.tmux/plugins/tmux-sensible
```

for oh-my-zsh:
```
git clone https://github.com/jeffreytse/zsh-vi-mode $ZSH_CUSTOM/plugins/zsh-vi-mode
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-history-substring-search ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-history-substring-search
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
# beautification
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
# take changes into account
exec zsh
# Keep in mind that plugins need to be added before oh-my-zsh.sh is sourced.
# the content below shold be added in the ~/.zshrc manually
echo "plugins += (zsh-vi-mode zsh-autosuggestions zsh-history-substring-search zsh-syntax-highlighting)" >> ~/.zshrc
```

## manually copy and paste

The files in the folder dotfiles/backup/manual should be set up manually.

```
cp custom/ ~/.oh-my-zsh/custom -r ;
cp icebergDark.vim ~/.vim/pack/vendor/start/lightline.vim/autoload/lightline/colorscheme/icebergDark.vim ;
```

