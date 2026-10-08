#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

assert_silent() {
  local name="$1"
  shift
  local stdout="$TMP_ROOT/$name.stdout" stderr="$TMP_ROOT/$name.stderr"
  "$@" >"$stdout" 2>"$stderr" || fail "$name failed"
  [[ ! -s "$stdout" ]] || fail "$name wrote stdout"
  [[ ! -s "$stderr" ]] || fail "$name wrote stderr"
}

test_public_paths() {
  if grep -REn '/Users/riosky|/home/riosky|/mnt/c|127\.0\.0\.1:7897|/Library/PostgreSQL' \
    "$ROOT/home/.zshenv" "$ROOT/home/.zprofile" "$ROOT/home/.zshrc" \
    "$ROOT/home/.bash_profile" "$ROOT/home/.bashrc" \
    "$ROOT/home/.config/lazygit" "$ROOT/home/.config/nvim" \
    "$ROOT/scripts/shell"; then
    fail 'public shell files contain host-specific paths'
  fi
  if grep -REn 'tmux (attach|new-session)|exec tmux' \
    "$ROOT/home/.zshrc" "$ROOT/home/.bashrc" "$ROOT/scripts/shell"; then
    fail 'shell startup invokes tmux'
  fi
}

test_load_order() {
  local home="$TMP_ROOT/order-home"
  mkdir -p "$home"
  printf 'DOTFILES_LOAD_TRACE="${DOTFILES_LOAD_TRACE}:host"\n' > "$home/.zshenv.host"
  printf 'DOTFILES_LOAD_TRACE="${DOTFILES_LOAD_TRACE}:local"\n' > "$home/.zshenv.local"
  HOME="$home" DOTFILES_ROOT="$ROOT" DOTFILES_PLATFORM=darwin DOTFILES_PROFILE=full \
    /bin/zsh -c 'source "$DOTFILES_ROOT/scripts/shell/load.zsh"; [[ "$DOTFILES_LOAD_TRACE" == core:darwin:full:aliases:host:local ]]' || \
    fail 'zsh load order is wrong'
  printf 'DOTFILES_LOAD_TRACE="${DOTFILES_LOAD_TRACE}:host"\n' > "$home/.bashrc.host"
  printf 'DOTFILES_LOAD_TRACE="${DOTFILES_LOAD_TRACE}:local"\n' > "$home/.bashrc.local"
  HOME="$home" DOTFILES_ROOT="$ROOT" DOTFILES_PLATFORM=linux DOTFILES_PROFILE=server \
    /bin/bash -c 'source "$DOTFILES_ROOT/scripts/shell/load.bash"; [[ "$DOTFILES_LOAD_TRACE" == core:linux:server:aliases:host:local ]]' || \
    fail 'bash load order is wrong'
  HOME="$home" DOTFILES_ROOT="$ROOT" DOTFILES_PLATFORM=wsl DOTFILES_PROFILE=server \
    /bin/zsh -c 'source "$DOTFILES_ROOT/scripts/shell/load.zsh"; [[ "$DOTFILES_LOAD_TRACE" == core:wsl:server:aliases:host:local ]]' || \
    fail 'zsh wsl load order is wrong'
  HOME="$home" DOTFILES_ROOT="$ROOT" DOTFILES_PLATFORM=wsl DOTFILES_PROFILE=server \
    /bin/bash -c 'source "$DOTFILES_ROOT/scripts/shell/load.bash"; [[ "$DOTFILES_LOAD_TRACE" == core:wsl:server:aliases:host:local ]]' || \
    fail 'bash wsl load order is wrong'
}

test_noninteractive_silence() {
  local home="$TMP_ROOT/silent-home"
  mkdir -p "$home"
  cp -R "$ROOT/home/." "$home/"
  assert_silent zsh env HOME="$home" DOTFILES_ROOT="$ROOT" DOTFILES_PLATFORM=darwin DOTFILES_PROFILE=full \
    ZDOTDIR="$home" /bin/zsh -c ':'
  assert_silent bash env HOME="$home" DOTFILES_ROOT="$ROOT" DOTFILES_PLATFORM=linux DOTFILES_PROFILE=server \
    BASH_ENV="$home/.bashrc" /bin/bash -c ':'
}

test_bash_platform_detection() {
  [[ "$(uname -s)" == Darwin ]] || return 0
  local home="$TMP_ROOT/bash-platform-home"
  HOME="$home" DOTFILES_ROOT="$ROOT" /bin/bash -c 'source "$DOTFILES_ROOT/scripts/shell/load.bash"; [[ "$DOTFILES_PLATFORM:$DOTFILES_PROFILE" == darwin:full ]]' || \
    fail 'bash did not detect Darwin/full'
}

test_darwin_homebrew_and_oc() {
  [[ "$(uname -s)" == Darwin ]] || return 0
  local home="$TMP_ROOT/darwin-home" fake_brew="$TMP_ROOT/fake-homebrew"
  mkdir -p "$home" "$fake_brew/bin"
  cp -R "$ROOT/home/." "$home/"
  printf '#!/usr/bin/env sh\n' > "$fake_brew/bin/tmux"
  printf '#!/usr/bin/env sh\n' > "$fake_brew/bin/opencode"
  chmod +x "$fake_brew/bin/tmux" "$fake_brew/bin/opencode"
  HOME="$home" PATH=/usr/bin:/bin DOTFILES_HOMEBREW_PREFIX="$fake_brew" \
    DOTFILES_PLATFORM=darwin DOTFILES_PROFILE=full ZDOTDIR="$home" \
    /bin/zsh -dfi -c 'unsetopt monitor; source "$HOME/.zshenv"; source "$HOME/.zshrc"; command -v tmux >/dev/null || exit 1; alias oc | grep -q opencode || exit 1' || \
    fail 'Darwin shell did not expose Homebrew tmux and oc alias'
}

test_missing_optional_tools() {
  local home="$TMP_ROOT/minimal-home" path="$TMP_ROOT/minimal-bin"
  mkdir -p "$home" "$path"
  cp -R "$ROOT/home/." "$home/"
  ln -s /bin/zsh "$path/zsh"
  ln -s /bin/bash "$path/bash"
  assert_silent minimal-zsh env HOME="$home" DOTFILES_ROOT="$ROOT" PATH="$path:/usr/bin:/bin" \
    DOTFILES_PLATFORM=darwin DOTFILES_PROFILE=full ZDOTDIR="$home" /bin/zsh -df -c 'source "$HOME/.zshrc"'
  assert_silent minimal-bash env HOME="$home" DOTFILES_ROOT="$ROOT" PATH="$path:/usr/bin:/bin" \
    DOTFILES_PLATFORM=linux DOTFILES_PROFILE=server /bin/bash --noprofile --norc -c 'source "$HOME/.bashrc"'
}

test_zoxide_init() {
  local home="$TMP_ROOT/zoxide-home" bin="$TMP_ROOT/zoxide-bin"
  mkdir -p "$home" "$bin"
  printf '#!/usr/bin/env sh\nprintf "export DOTFILES_TEST_ZOXIDE_LOADED=1\\n"\n' > "$bin/zoxide"
  chmod +x "$bin/zoxide"
  HOME="$home" PATH="$bin:/usr/bin:/bin" DOTFILES_ROOT="$ROOT" DOTFILES_PLATFORM=linux DOTFILES_PROFILE=server \
    /bin/zsh -df -c 'source "$DOTFILES_ROOT/scripts/shell/load.zsh"; [[ "${DOTFILES_TEST_ZOXIDE_LOADED:-}" == 1 ]]' || \
    fail 'zsh loader did not initialize zoxide'
  HOME="$home" PATH="$bin:/usr/bin:/bin" DOTFILES_ROOT="$ROOT" DOTFILES_PLATFORM=linux DOTFILES_PROFILE=server \
    /bin/bash --noprofile --norc -c 'source "$DOTFILES_ROOT/scripts/shell/load.bash"; [[ "${DOTFILES_TEST_ZOXIDE_LOADED:-}" == 1 ]]' || \
    fail 'bash loader did not initialize zoxide'
}

test_conda_darwin_zsh_only() {
  local home="$TMP_ROOT/conda-home" zdotdir="$TMP_ROOT/conda-zdotdir"
  local calls="$TMP_ROOT/conda-calls"
  mkdir -p "$home/miniconda3/bin" "$zdotdir"
  cp -R "$ROOT/home/." "$home/"
  printf '%s\n' \
    '#!/usr/bin/env sh' \
    'printf "called\n" >> "$DOTFILES_TEST_CONDA_CALLS"' \
    '[ "${CONDA_AUTO_ACTIVATE_BASE:-}" = false ] || exit 1' \
    'if [ "${DOTFILES_TEST_CONDA_FAIL:-}" = 1 ]; then printf "export DOTFILES_TEST_CONDA_PARTIAL=1\n"; exit 1; fi' \
    'printf "export DOTFILES_TEST_CONDA_LOADED=1\n"' \
    > "$home/miniconda3/bin/conda"
  chmod +x "$home/miniconda3/bin/conda"

  HOME="$home" DOTFILES_ROOT="$ROOT" DOTFILES_PLATFORM=darwin DOTFILES_PROFILE=full \
    DOTFILES_TEST_CONDA_CALLS="$calls" ZDOTDIR="$zdotdir" \
    /bin/zsh -dfi -c 'unsetopt monitor; source "$HOME/.zshenv"; source "$HOME/.zshrc"; [[ "$DOTFILES_TEST_CONDA_LOADED" == 1 ]]' || \
    fail 'Darwin zsh did not initialize Conda with base auto-activation disabled'

  : > "$calls"
  HOME="$home" DOTFILES_ROOT="$ROOT" DOTFILES_PLATFORM=darwin DOTFILES_PROFILE=full \
    DOTFILES_TEST_CONDA_CALLS="$calls" DOTFILES_TEST_CONDA_FAIL=1 ZDOTDIR="$zdotdir" \
    /bin/zsh -dfi -c 'unsetopt monitor; source "$HOME/.zshenv"; source "$HOME/.zshrc"; [[ -z "${DOTFILES_TEST_CONDA_PARTIAL:-}" ]]' || \
    fail 'Darwin zsh evaluated output from a failed Conda hook'

  : > "$calls"
  HOME="$home" DOTFILES_ROOT="$ROOT" DOTFILES_PLATFORM=darwin DOTFILES_PROFILE=full \
    DOTFILES_TEST_CONDA_CALLS="$calls" ZDOTDIR="$zdotdir" \
    /bin/zsh -df -c 'source "$HOME/.zshenv"; source "$HOME/.zshrc"' || \
    fail 'non-interactive Darwin zsh startup failed'
  [[ ! -s "$calls" ]] || fail 'non-interactive Darwin zsh invoked Conda'

  HOME="$home" DOTFILES_ROOT="$ROOT" DOTFILES_PLATFORM=linux DOTFILES_PROFILE=server \
    DOTFILES_TEST_CONDA_CALLS="$calls" ZDOTDIR="$zdotdir" \
    /bin/zsh -dfi -c 'unsetopt monitor; source "$HOME/.zshenv"; source "$HOME/.zshrc"; [[ -z "${DOTFILES_TEST_CONDA_LOADED:-}" ]]' || \
    fail 'Linux zsh initialized Conda'
  [[ ! -s "$calls" ]] || fail 'Linux zsh invoked Conda'

  HOME="$home" DOTFILES_ROOT="$ROOT" DOTFILES_PLATFORM=termux DOTFILES_PROFILE=termux \
    DOTFILES_TEST_CONDA_CALLS="$calls" ZDOTDIR="$zdotdir" \
    /bin/zsh -dfi -c 'unsetopt monitor; source "$HOME/.zshenv"; source "$HOME/.zshrc"; [[ -z "${DOTFILES_TEST_CONDA_LOADED:-}" ]]' || \
    fail 'Termux zsh initialized Conda'
  [[ ! -s "$calls" ]] || fail 'Termux zsh invoked Conda'

  HOME="$home" DOTFILES_ROOT="$ROOT" DOTFILES_PLATFORM=darwin DOTFILES_PROFILE=full \
    DOTFILES_TEST_CONDA_CALLS="$calls" \
    /bin/bash --noprofile --norc -c 'source "$HOME/.bash_profile"; [[ -z "${DOTFILES_TEST_CONDA_LOADED:-}" ]]' || \
    fail 'Darwin bash initialized Conda'
  [[ ! -s "$calls" ]] || fail 'Darwin bash invoked Conda'
}

test_tinty_nvim_guard() {
  local home="$TMP_ROOT/tinty-home" zdotdir="$TMP_ROOT/tinty-zdotdir"
  local bin="$TMP_ROOT/tinty-bin" data="$home/.local/share/tinted-theming/tinty"
  local probe="$TMP_ROOT/tinty-probe" tinty_out="$TMP_ROOT/tinty-fake-out"
  mkdir -p "$home" "$zdotdir" "$bin" "$data"
  cp -R "$ROOT/home/." "$home/"
  printf '%s\n' \
    '#!/usr/bin/env sh' \
    'printf "%s\n" "argv=$*" >> "$DOTFILES_TEST_TINTY_OUT"' \
    'if [ -t 0 ]; then echo stdin_tty=1 >> "$DOTFILES_TEST_TINTY_OUT"; else echo stdin_tty=0 >> "$DOTFILES_TEST_TINTY_OUT"; fi' \
    'cp "$DOTFILES_TEST_TINTY_DATA/probe2.template" "$DOTFILES_TEST_TINTY_DATA/probe2.sh"' \
    > "$bin/tinty"
  chmod +x "$bin/tinty"
  printf '%s\n' \
    'printf "%s\n" "probe1:${TTY:-empty}" >> "$DOTFILES_TEST_TINTY_PROBE"' \
    > "$data/probe.sh"
  printf '%s\n' \
    'printf "%s\n" "probe2:${TTY:-empty}" >> "$DOTFILES_TEST_TINTY_PROBE"' \
    > "$data/probe2.template"

  # nvim :terminal 子进程（NVIM 已设、TMUX 泄漏）：source 守卫生效
  HOME="$home" PATH="$bin:/usr/bin:/bin" DOTFILES_ROOT="$ROOT" \
    DOTFILES_PLATFORM=darwin DOTFILES_PROFILE=full ZDOTDIR="$zdotdir" \
    DOTFILES_TEST_TINTY_PROBE="$probe" DOTFILES_TEST_TINTY_OUT="$tinty_out" \
    DOTFILES_TEST_TINTY_DATA="$data" \
    NVIM=/tmp/fake-nvim TMUX=/tmp/fake,123,0 \
    /bin/zsh -dfi -c 'unsetopt monitor; source "$HOME/.zshrc"' || \
    fail 'zsh startup failed with tinty nvim guard'
  grep -q '^probe1:/nonexistent-tty-nvim-guard$' "$probe" || fail 'tinty source guard inactive inside nvim terminal'

  # 普通 shell（无 NVIM）：守卫不得激活（真 tmux pane 行为不变）
  : > "$probe"
  HOME="$home" PATH="$bin:/usr/bin:/bin" DOTFILES_ROOT="$ROOT" \
    DOTFILES_PLATFORM=darwin DOTFILES_PROFILE=full ZDOTDIR="$zdotdir" \
    DOTFILES_TEST_TINTY_PROBE="$probe" DOTFILES_TEST_TINTY_OUT="$tinty_out" \
    DOTFILES_TEST_TINTY_DATA="$data" \
    TMUX=/tmp/fake,123,0 \
    /bin/zsh -dfi -c 'unsetopt monitor; source "$HOME/.zshrc"' || \
    fail 'zsh startup failed without nvim'
  grep -q '^probe1:/nonexistent-tty-nvim-guard$' "$probe" && fail 'tinty source guard activated outside nvim terminal'

  # dotfiles_tinty：NVIM 下非交互子命令 stdin 屏蔽；apply 后新 *.sh 走守卫 source
  : > "$probe"
  : > "$tinty_out"
  HOME="$home" PATH="$bin:/usr/bin:/bin" DOTFILES_ROOT="$ROOT" \
    DOTFILES_PLATFORM=darwin DOTFILES_PROFILE=full ZDOTDIR="$zdotdir" \
    DOTFILES_TEST_TINTY_PROBE="$probe" DOTFILES_TEST_TINTY_OUT="$tinty_out" \
    DOTFILES_TEST_TINTY_DATA="$data" \
    NVIM=/tmp/fake-nvim TMUX=/tmp/fake,123,0 \
    /bin/zsh -dfi -c 'unsetopt monitor; source "$HOME/.zshrc"; dotfiles_tinty apply; alias tinty | grep -q dotfiles_tinty' || \
    fail 'dotfiles_tinty apply failed inside nvim terminal'
  grep -q '^argv=apply$' "$tinty_out" || fail 'dotfiles_tinty did not invoke tinty apply'
  grep -q '^stdin_tty=0$' "$tinty_out" || fail 'dotfiles_tinty did not shield stdin inside nvim terminal'
  grep -q '^probe2:/nonexistent-tty-nvim-guard$' "$probe" || fail 'post-apply re-source bypassed tinty nvim guard'
}

test_yazi_restart_wrapper() {
  # y() 哨兵循环：R 绑 quit --code=99 后由包装函数重新拉起——重启前重跑
  # tinty/generate、经 --cwd-file 回到最后浏览目录、其余退出码透传且不重启
  local bin="$TMP_ROOT/yazi-bin" fake_root="$TMP_ROOT/yazi-fake-root"
  local browsed="$TMP_ROOT/yazi-browsed"
  mkdir -p "$bin" "$fake_root/scripts/tinty" "$browsed"
  printf '#!/usr/bin/env sh\nprintf "generate\\n" >> "${DOTFILES_TEST_YAZI_GEN:-/dev/null}"\n' \
    > "$fake_root/scripts/tinty/generate"
  chmod +x "$fake_root/scripts/tinty/generate"
  printf '%s\n' \
    '#!/usr/bin/env sh' \
    'printf "run:%s\n" "$*" >> "$DOTFILES_TEST_YAZI_OUT"' \
    'n=0' \
    '[ -f "$DOTFILES_TEST_YAZI_COUNT" ] && n=$(cat "$DOTFILES_TEST_YAZI_COUNT")' \
    'n=$((n + 1)); printf "%s\n" "$n" > "$DOTFILES_TEST_YAZI_COUNT"' \
    'if [ "$n" -le "${DOTFILES_TEST_YAZI_RESTARTS:-0}" ]; then' \
    '  for a in "$@"; do' \
    '    case "$a" in' \
    '      --cwd-file=*) [ -n "${DOTFILES_TEST_YAZI_CWD:-}" ] && printf "%s\n" "$DOTFILES_TEST_YAZI_CWD" > "${a#--cwd-file=}" ;;' \
    '    esac' \
    '  done' \
    '  exit 99' \
    'fi' \
    'exit "${DOTFILES_TEST_YAZI_FINAL_RC:-0}"' \
    > "$bin/yazi"
  chmod +x "$bin/yazi"

  local shell out gen count rc_out
  local -a flags
  for shell in zsh bash; do
    if [ "$shell" = zsh ]; then flags=(-df); else flags=(--noprofile --norc); fi
    out="$TMP_ROOT/yazi-$shell.out"
    gen="$TMP_ROOT/yazi-$shell.gen"
    count="$TMP_ROOT/yazi-$shell.count"
    rc_out="$(HOME="$TMP_ROOT/yazi-$shell-home" PATH="$bin:/usr/bin:/bin" \
      DOTFILES_ROOT="$fake_root" DOTFILES_TEST_ALIASES="$ROOT/scripts/shell/aliases.sh" \
      DOTFILES_TEST_YAZI_OUT="$out" DOTFILES_TEST_YAZI_GEN="$gen" DOTFILES_TEST_YAZI_COUNT="$count" \
      DOTFILES_TEST_YAZI_RESTARTS=1 DOTFILES_TEST_YAZI_CWD="$browsed" \
      /bin/$shell "${flags[@]}" -c 'source "$DOTFILES_TEST_ALIASES"; y; printf "RC:%s\n" "$?"')" || \
      fail "y() restart loop failed to run in $shell"
    [[ "$rc_out" == 'RC:0' ]] || fail "y() did not absorb restart exit code ($shell): $rc_out"
    [[ "$(command cat -- "$count")" == 2 ]] || fail "y() did not relaunch yazi after code 99 ($shell)"
    sed -n '1p' "$out" | grep -q '^run:--cwd-file=' || fail "y() first launch lacks --cwd-file ($shell)"
    sed -n '2p' "$out" | grep -q "^run:$browsed --cwd-file=" || \
      fail "y() relaunch did not restore browsed cwd ($shell)"
    [ "$(grep -c '^generate$' "$gen")" = 2 ] || \
      fail "y() did not re-run tinty/generate before relaunch ($shell)"

    out="$TMP_ROOT/yazi-$shell-rc.out"
    count="$TMP_ROOT/yazi-$shell-rc.count"
    rc_out="$(HOME="$TMP_ROOT/yazi-$shell-home" PATH="$bin:/usr/bin:/bin" \
      DOTFILES_ROOT="$fake_root" DOTFILES_TEST_ALIASES="$ROOT/scripts/shell/aliases.sh" \
      DOTFILES_TEST_YAZI_OUT="$out" DOTFILES_TEST_YAZI_COUNT="$count" \
      DOTFILES_TEST_YAZI_RESTARTS=0 DOTFILES_TEST_YAZI_FINAL_RC=42 \
      /bin/$shell "${flags[@]}" -c 'source "$DOTFILES_TEST_ALIASES"; y; printf "RC:%s\n" "$?"')" || \
      fail "y() plain-run failed in $shell"
    [[ "$rc_out" == 'RC:42' ]] || fail "y() did not propagate yazi exit code ($shell): $rc_out"
    [[ "$(command cat -- "$count")" == 1 ]] || fail "y() restarted without code 99 ($shell)"
  done

  # 重启但 cwd 文件未写入：保留原参数重启，不误入无限循环以外的路径
  out="$TMP_ROOT/yazi-nocwd.out"
  count="$TMP_ROOT/yazi-nocwd.count"
  HOME="$TMP_ROOT/yazi-nocwd-home" PATH="$bin:/usr/bin:/bin" \
    DOTFILES_ROOT="$fake_root" DOTFILES_TEST_ALIASES="$ROOT/scripts/shell/aliases.sh" \
    DOTFILES_TEST_YAZI_OUT="$out" DOTFILES_TEST_YAZI_COUNT="$count" \
    DOTFILES_TEST_YAZI_RESTARTS=1 \
    /bin/zsh -df -c 'source "$DOTFILES_TEST_ALIASES"; y' || \
    fail "y() restart without cwd file failed in zsh"
  [[ "$(command cat -- "$count")" == 2 ]] || fail "y() did not relaunch without cwd file (zsh)"
  sed -n '2p' "$out" | grep -q '^run:--cwd-file=' || \
    fail "y() relaunch without cwd file changed args (zsh)"
}

test_public_paths
test_load_order
test_noninteractive_silence
test_bash_platform_detection
test_darwin_homebrew_and_oc
test_missing_optional_tools
test_zoxide_init
test_conda_darwin_zsh_only
test_tinty_nvim_guard
test_yazi_restart_wrapper
printf 'shell integration tests passed\n'
