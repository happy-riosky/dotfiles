scriptencoding utf-8
set encoding=utf-8

set nocompatible
set runtimepath^=~/.vim
syntax on

" Disable the default Vim startup message.
set shortmess+=I

" The backspace key has slightly unintuitive behavior by default. For example,
" by default, you can't backspace before the insertion point set with 'i'.
" This configuration makes backspace behave more reasonably, in that you can
" backspace over anything.
set backspace=indent,eol,start

" By default, Vim doesn't let you hide a buffer (i.e. have a buffer that isn't
" shown in any window) that has unsaved changes. This is to prevent you from "
" forgetting about unsaved changes and then quitting e.g. via `:qa!`. We find
" hidden buffers helpful enough to disable this protection. See `:help hidden`
" for more information on this.
set hidden

" This setting makes search case-insensitive when all characters in the string
" being searched are lowercase. However, the search becomes case-sensitive if
" it contains any capital letters. This makes searching more convenient.
set ignorecase
set smartcase

" Enable searching as you type, rather than waiting till you press enter.
set incsearch

" Unbind some useless/annoying default key bindings.
nmap Q <Nop> " 'Q' in normal mode enters Ex mode. You almost never want this.

" Disable audible bell because it's annoying.
set noerrorbells visualbell t_vb=

" Enable mouse support. You should avoid relying on this too much, but it can
" sometimes be convenient.
set mouse+=a

" ------------------------------------------------------------------------------
" Backup, undo an files
" ------------------------------------------------------------------------------

" Turn backup off, since most stuff is in SVN, git etc. anyway...
set nobackup
set nowb
set noswapfile

" ------------------------------------------------------------------------------
" UI config
" ------------------------------------------------------------------------------

set number              " show line numbers
set relativenumber      " show relative numbering
set showcmd             " show command in bottom bar
set cursorline          " highlight current line
filetype indent on      " load filetype-specific indent files
filetype plugin on      " load filetype specific plugin files
set wildmenu            " visual autocomplete for command menu
set wildmode=longest,list,full
set showmatch           " highlight matching [{()}]
set shortmess-=S        " show count of matches
set laststatus=2        " Show the status line at the bottom
set showtabline=2       " Keep the editor frame visible with a single tab
set noshowmode          " Lightline already shows the current mode
set signcolumn=yes      " Keep text aligned when signs appear
set fillchars=eob:\     " Hide Vim's end-of-buffer tildes
set mouse+=a            " A necessary evil, mouse support
set noerrorbells visualbell t_vb=    "Disable annoying error noises
set splitbelow          " Open new vertical split bottom
set splitright          " Open new horizontal splits right
set linebreak           " Have lines wrap instead of continue off-screen
set scrolloff=12        " Keep cursor in approximately the middle of the screen
set updatetime=100      " Some plugins require fast updatetime
set ttyfast             " Improve redrawing
set hlsearch            " Highlight searches

" Clear highlights on hitting the ESC key
nnoremap <silent> <ESC> :nohlsearch<return><esc>

" use real color
set termguicolors
if exists('&t_SI')
  let &t_SI = "\<Esc>[6 q"  " Steady beam in Insert mode
  let &t_EI = "\<Esc>[2 q"  " Steady block outside Insert mode
endif

let g:lightline = {
  \ 'colorscheme': 'tinty',
  \ 'active': {
  \   'left': [ [ 'mode', 'paste' ], [ 'readonly', 'filename', 'modified' ] ],
  \   'right': [ [ 'lineinfo' ], [ 'percent' ], [ 'filetype', 'fileencoding', 'fileformat' ] ]
  \ },
  \ 'inactive': {
  \   'left': [ [ 'filename' ] ],
  \   'right': [ [ 'lineinfo' ] ]
  \ },
  \ 'component': {
  \   'filename': '%f',
  \   'lineinfo': '%3l:%-2v'
  \ }
  \ }

" ------------------------------------------------------------------------------
" configure editor with tabs and nice stuff...
" ------------------------------------------------------------------------------

set expandtab           " enter spaces when tab is pressed
set textwidth=120       " break lines when line length increases
set tabstop=2           " use 2 spaces to represent tab
set softtabstop=2
set shiftwidth=2        " number of spaces to use for auto indent
set autoindent          " copy indent from current line when starting a new line

" make backspaces more powerfull
set backspace=indent,eol,start
set ruler               " show line and column number
set showcmd             " show (partial) command in status line

" ------------------------------------------------------------------------------
" Movement
" ------------------------------------------------------------------------------

" Use ctrl-[hjkl] to select the active split!
nmap <silent> <c-k> :wincmd k<CR>
nmap <silent> <c-j> :wincmd j<CR>
nmap <silent> <c-h> :wincmd h<CR>
nmap <silent> <c-l> :wincmd l<CR>

" Have j and k navigate visual lines rather than logical ones
nmap j gj
nmap k gk

noremap J 10j
noremap K 10k

" Center the cursor line after half-page jumps
nnoremap <C-d> <C-d>zz
nnoremap <C-u> <C-u>zz

" Jump to start and end of line using the home row keys
map H ^
map L $

" (Shift)Tab (de)indents code (!!!useless!!!)
vnoremap <Tab> >>
vnoremap <S-Tab> <<

" ------------------------------------------------------------------------------
" Undo
" ------------------------------------------------------------------------------
set undofile " Maintain undo history between sessions
set undodir=~/.vim/undodir

" ------------------------------------------------------------------------------
" Use Leader
" ------------------------------------------------------------------------------

" Leader is space
let mapleader = " "

" use macros faster
nnoremap <Leader>a :normal @
"  - |     --  Split with leader
nnoremap <Leader>- :sp<CR>
nnoremap <Leader>" :sp<CR>
nnoremap <Leader>\| :vsp<CR>
nnoremap <Leader>% :vsp<CR>

" fly between files
nnoremap <Leader>b :ls<CR>:b<space>
nnoremap <Leader>m :marks<CR>:'

"  w wq q   --  Quick Save
nmap <Leader>w :w<CR>
nmap <Leader>q :q<CR>
nmap <Leader>wq :wq<CR>
nmap <Leader>qa :qa<CR>
nmap <Leader>Q :q!<CR>

"  y d p P   --  Quick copy paste into system clipboard
nmap <Leader>y "+y
nmap <Leader>d "+d
vmap <Leader>y "+y
vmap <Leader>d "+d
nmap <Leader>p "+p
nmap <Leader>P "+P
vmap <Leader>p "+p
vmap <Leader>P "+P

" numbers / tabs
nnoremap <Leader>1 1gt<CR>
nnoremap <Leader>2 2gt<CR>
nnoremap <Leader>3 3gt<CR>
nnoremap <Leader>4 4gt<CR>
nnoremap <Leader>5 5gt<CR>
nnoremap <Leader>6 6gt<CR>
nnoremap <Leader>7 7gt<CR>
nnoremap <Leader>8 8gt<CR>
nnoremap <Leader>9 9gt<CR>
nnoremap <Leader>n :tabnew<CR>
nnoremap <Leader>x :tabclose<CR>
nnoremap <Leader>, :tabprevious<CR>
nnoremap <Leader>. :tabnext<CR>
nnoremap <Leader>< :tabm -1<CR>
nnoremap <Leader>> :tabm +1<CR>

" enter the visual block mode
nnoremap <Leader>v <C-v>
" work with https://github.com/tpope/vim-commentary
map <Leader>c gcc<CR>

" ------------------------------------------------------------------------------
" Custom commands
" ------------------------------------------------------------------------------
"  Use Hc to enable and disanle the appearance of the 80th column
command Hc call ToggleColorColumn()
function ToggleColorColumn()
    if &colorcolumn != ""
        set cc=
        highlight clear ColorColumn
    else
        set cc=80
        " highlight ColorColumn ctermbg=darkgrey guibg=darkgrey
    endif
endfunction
"  Map Hc to <space>c
" map <Leader>c :Hc<CR>

" ------------------------------------------------------------------------------
" Snippets / Abbrev
" ------------------------------------------------------------------------------
iabbrev ,c int main() {<CR><tab><CR>}
" from: https://www.reddit.com/r/neovim/comments/16mijcz/anyone_here_use_iabbrev/
iabbrev <expr> ,d strftime('%Y-%m-%d')
iabbrev <expr> ,t strftime('%Y-%m-%d %T ')
inoreabbrev <expr> ,u system('uuidgen')->trim()->tolower()

" ------------------------------------------------------------------------------
" Plugins
" ------------------------------------------------------------------------------
packloadall

" 配色跟随 tinty：source tinted-vim 生成的调色板文件（暴露 g:tinted_gui*，
" 供高亮组与 lightline tinty colorscheme 使用），FocusGained 时重新 source
" 并重建 lightline palette（tmux 内焦点事件由 tmux-sensible 的
" focus-events on 传递；SSH 裸用无焦点事件，下次打开刷新——与 nvim 同款
" 限制）。无 tinty 的机器回退 catppuccin_frappe（catppuccin/vim 插件自带，
" 须在 packloadall 之后才可 colorscheme）。
let s:tinty_colors = expand('~/.local/share/tinted-theming/tinty/base16-vim-colors-file.vim')
if filereadable(s:tinty_colors)
  let g:tinted_colorspace = 256
  execute 'source' fnameescape(s:tinty_colors)
  augroup dotfiles_tinty
    autocmd!
    autocmd FocusGained * call s:TintyRefresh()
  augroup END
else
  colorscheme catppuccin_frappe
endif

function! s:TintyRefresh() abort
  if !filereadable(s:tinty_colors)
    return
  endif
  execute 'source' fnameescape(s:tinty_colors)
  " 重建 lightline palette：unlet 缓存 → 重载 colorscheme → 重新应用
  unlet! g:lightline#colorscheme#tinty#palette
  runtime autoload/lightline/colorscheme/tinty.vim
  call lightline#colorscheme()
endfunction

" Change the default mapping and the default command to invoke CtrlP
let g:ctrlp_map = '<c-p>'
let g:ctrlp_cmd = 'CtrlP'

" provide path directly to the library file
let g:clang_library_path = '/usr/lib/llvm-10/lib/libclang-10.so.1'

" Easymotion
" ------------------------------------------------------------------------------
let g:EasyMotion_smartcase = 1
map <Leader> <Plug>(easymotion-prefix)

" hjkl  s j k t / ? g/   -- EasyMotion
map <Leader>h <Plug>(easymotion-b)
map <Leader>j <Plug>(easymotion-j)
map <Leader>k <Plug>(easymotion-k)
map <Leader>l <Plug>(easymotion-w)

" NERDTree
" ------------------------------------------------------------------------------
map <C-n> :NERDTreeToggle<CR>
map <Leader>e :NERDTreeToggle<CR>
" show the hidden files
let NERDTreeShowHidden=1
augroup nerdtree_panel
  autocmd!
  autocmd FileType nerdtree setlocal wincolor=NerdTreePanel
augroup END
" Close vim if only window left is NERDTree
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif

" vim-tmux-navigator
" ------------------------------------------------------------------------------
let g:tmux_navigator_no_mappings = 1

nnoremap <silent> {Left-Mapping} :<C-U>TmuxNavigateLeft<cr>
nnoremap <silent> {Down-Mapping} :<C-U>TmuxNavigateDown<cr>
nnoremap <silent> {Up-Mapping} :<C-U>TmuxNavigateUp<cr>
nnoremap <silent> {Right-Mapping} :<C-U>TmuxNavigateRight<cr>
nnoremap <silent> {Previous-Mapping} :<C-U>TmuxNavigatePrevious<cr>
