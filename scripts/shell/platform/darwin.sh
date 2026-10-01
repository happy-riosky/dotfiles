brew_prefix="${DOTFILES_HOMEBREW_PREFIX:-}"
if [[ -z "$brew_prefix" ]]; then
  for candidate in /opt/homebrew /usr/local; do
    if [[ -x "$candidate/bin/brew" ]]; then
      brew_prefix="$candidate"
      break
    fi
  done
fi
if [[ -n "$brew_prefix" ]]; then
  dotfiles_prepend_path "$brew_prefix/bin"
fi
unset brew_prefix candidate
# lazygit：CONFIG_DIR 固定到 ~/.config/lazygit，与 Linux/Termux 共用同一份
# 受管配置，避免 macOS App Support 下出现重复副本（见 docs/theming.md）。
# 注意 state.yml 等运行时状态随之落到 ~/.config/lazygit/（不受管）。
export CONFIG_DIR="$HOME/.config/lazygit"
DOTFILES_LOAD_TRACE="${DOTFILES_LOAD_TRACE}:darwin"
