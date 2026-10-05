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

# >>> tinty (tinted-theming) theme manager >>>
# tinty 的 hook 在子进程执行，无法改动当前 shell 的环境变量；
# 用函数包装 apply/init，跑完真 tinty 后 source 数据目录里新生成的
# *.sh（tinted-shell 的 16 色 ANSI 调色板 + tinted-fzf 配色由此生效）。
# 副作用：alias 覆盖 tinty 后 zsh 补全不可用，需要时用 command tinty。
if command -v tinty >/dev/null 2>&1; then
  # nvim :terminal（toggleterm 等）里 $TMUX 是外层 tmux 泄漏的假阳性：
  # tinted-shell 会据此用 DCS Ptmux 包装 OSC 4/10/11/12，nvim 内置终端
  # 不识别该包装，载荷被当纯文本渲染成首个提示符前的乱码。nvim 子进程
  # 恒有 $NVIM（TERM_PROGRAM 此时仍是 tmux，不可作判据）；据此用不可写
  # TTY 让 put_template* 变 no-op——nvim 终端调色板本就只由
  # g:terminal_color_* 决定，BASE16_THEME 等导出不受影响。
  dotfiles_tinty_source() {
    if [[ -n "${NVIM:-}" ]]; then
      local TTY=/nonexistent-tty-nvim-guard
    fi
    [[ -r "$1" ]] && . "$1"
  }
  dotfiles_tinty() {
    local marker script tinty_data_dir
    marker="$(mktemp)"
    # nvim 终端里非交互子命令屏蔽 stdin：hook 子进程 tty 失败即不写
    # OSC，免得 tinted-shell 再打一行 Ptmux 乱码；TMUX 保留（tinted-tmux
    # hook 的 tmux CLI 依赖）。裸 tinty（TUI）不拦截。
    if [[ -n "${NVIM:-}" && -n "${1:-}" ]]; then
      command tinty "$@" </dev/null
    else
      command tinty "$@"
    fi
    if [[ "$1" == "apply" || "$1" == "init" ]]; then
      tinty_data_dir="${XDG_DATA_HOME:-$HOME/.local/share}/tinted-theming/tinty"
      while IFS= read -r script; do
        dotfiles_tinty_source "$script"
      done < <(find "$tinty_data_dir" -maxdepth 1 \( -type f -o -type l \) -name '*.sh' -newer "$marker" 2>/dev/null)
    fi
    command rm -f "$marker"
  }
  # 启动只 source 磁盘上已生成的 *.sh（磁盘即真相），不再 tinty init 全量
  # 重应用：每个交互 shell 各自 init 会与用户的 cycle/apply 竞态，迟到的
  # init 把它读到的旧 scheme 覆写回全局（实测造成 frappe↔latte 连环闪变）。
  # *.sh 全缺失（首次安装 / tinty sync 后）才 init 一次引导。
  tinty_data_dir="${XDG_DATA_HOME:-$HOME/.local/share}/tinted-theming/tinty"
  if ! command ls "$tinty_data_dir"/*.sh >/dev/null 2>&1; then
    dotfiles_tinty init >/dev/null 2>&1
  else
    for script in "$tinty_data_dir"/*.sh; do
      dotfiles_tinty_source "$script"
    done
  fi
  unset tinty_data_dir script
  alias tinty=dotfiles_tinty
fi
# <<< tinty (tinted-theming) theme manager <<<

export NVM_DIR="$HOME/.nvm"
[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
command -v nvm >/dev/null 2>&1 && nvm use default --silent >/dev/null 2>&1 || true

# Load Conda only for interactive macOS shells.
if [[ "${DOTFILES_PLATFORM:-}" == darwin ]]; then
  export CONDA_AUTO_ACTIVATE_BASE=false
  if [[ -x "$HOME/miniconda3/bin/conda" ]]; then
    __conda_setup="$("$HOME/miniconda3/bin/conda" shell.zsh hook 2>/dev/null)" || __conda_setup=
  elif command -v conda >/dev/null 2>&1; then
    __conda_setup="$(conda shell.zsh hook 2>/dev/null)" || __conda_setup=
  fi
  if [[ -n "${__conda_setup:-}" ]]; then
    eval "$__conda_setup"
  fi
  unset __conda_setup
fi

if command -v go >/dev/null 2>&1; then
  go_path="$(go env GOPATH 2>/dev/null || true)"
  [[ -n "$go_path" ]] && dotfiles_append_path "$go_path/bin"
  unset go_path
fi

alias m='man'
alias mk='make'
alias mka='make all'
alias mkc='make clean'
# lg 由 aliases.sh 的 lg() 函数提供（跟随 tinty 主题）；此处不设 alias，
# 否则 zsh alias 展开优先于函数，会绕过主题包装
# gd 被 oh-my-zsh git 插件覆盖为 git diff；改由 ~/.local/bin/gd 提供
# （repo 上下文感知的 gh dash 启动器），unalias 让 PATH 解析到脚本
command -v gh >/dev/null 2>&1 && unalias gd 2>/dev/null || true
command -v eza >/dev/null 2>&1 && alias ls='eza'
command -v eza >/dev/null 2>&1 && alias ll='eza -l'
command -v eza >/dev/null 2>&1 && alias la='eza -la'
command -v eza >/dev/null 2>&1 && alias lt='eza -la --tree --level=4'
# l/lsa 已退役；不 unalias 会被 oh-my-zsh 定义解析成 eza -lah（多表头行）
unalias l lsa 2>/dev/null || true
command -v pbcopy >/dev/null 2>&1 && alias pwp='pwd | pbcopy'
command -v opencode >/dev/null 2>&1 && alias oc='opencode'

if (( $+functions[history-substring-search-up] )); then
  bindkey -M vicmd 'k' history-substring-search-up
  bindkey -M vicmd 'j' history-substring-search-down
fi
bindkey -M emacs '^O' clear-screen
bindkey -M viins '^O' clear-screen
bindkey -M vicmd '^O' clear-screen

[ -r "$HOME/.config/broot/launcher/bash/br" ] && source "$HOME/.config/broot/launcher/bash/br"

# >>> otty shell integration >>>
# Added by Otty — toggle in Settings > Shell > Shell Integration.
# Inert unless launched by Otty (it sets $OTTY_SHELL_INTEGRATION).
if [ -n "$OTTY_SHELL_INTEGRATION" ] && [ -r "$OTTY_SHELL_INTEGRATION/otty-integration.zsh" ]; then
  . "$OTTY_SHELL_INTEGRATION/otty-integration.zsh"
fi
# <<< otty shell integration <<<
