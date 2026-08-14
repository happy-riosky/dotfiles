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
    /bin/zsh -c 'source "$DOTFILES_ROOT/scripts/shell/load.zsh"; [[ "$DOTFILES_LOAD_TRACE" == core:darwin:full:host:local ]]' || \
    fail 'zsh load order is wrong'
  printf 'DOTFILES_LOAD_TRACE="${DOTFILES_LOAD_TRACE}:host"\n' > "$home/.bashrc.host"
  printf 'DOTFILES_LOAD_TRACE="${DOTFILES_LOAD_TRACE}:local"\n' > "$home/.bashrc.local"
  HOME="$home" DOTFILES_ROOT="$ROOT" DOTFILES_PLATFORM=linux DOTFILES_PROFILE=server \
    /bin/bash -c 'source "$DOTFILES_ROOT/scripts/shell/load.bash"; [[ "$DOTFILES_LOAD_TRACE" == core:linux:server:host:local ]]' || \
    fail 'bash load order is wrong'
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

test_public_paths
test_load_order
test_noninteractive_silence
test_bash_platform_detection
test_darwin_homebrew_and_oc
test_missing_optional_tools
printf 'shell integration tests passed\n'
