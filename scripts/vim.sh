sudo apt remove vim
sudo apt install vim-gtk3
git clone https://github.com/mileszs/ack.vim.git ~/.vim/pack/vendor/start/ack.vim
git clone --depth=1 https://github.com/ctrlpvim/ctrlp.vim.git ~/.vim/pack/vendor/start/ctrlp
git clone https://github.com/preservim/nerdtree.git ~/.vim/pack/vendor/start/nerdtree
vim -u NONE -c "helptags ~/.vim/pack/vendor/start/nerdtree/doc" -c q
git clone https://github.com/christoomey/vim-tmux-navigator.git ~/.vim/pack/vendor/start/vim-tmux-navigator
git clone https://github.com/easymotion/vim-easymotion ~/.vim/pack/vendor/start/vim-easymotion
git clone https://github.com/justmao945/vim-clang.git ~/.vim/pack/completion/start/vim-clang
git clone https://github.com/itchyny/lightline.vim.git ~/.vim/pack/vendor/start/lightline.vim
git clone https://github.com/tpope/vim-commentary.git ~/.vim/pack/vendor/start/vim-commentary.git
vim -u NONE -c "helptags commentary/doc" -c q
cp ~/dotfiles/backup/icebergDark.vim ~/.vim/pack/vendor/start/lightline.vim/autoload/lightline/colorscheme/icebergDark.vim ;
