#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

assert_link() {
  local path="$1" expected="$2"
  [[ -L "$path" ]] || fail "$path is not a symlink"
  [[ "$(readlink "$path")" == "$expected" ]] || fail "$path points to $(readlink "$path")"
}

make_fixture() {
  local fixture="$1"
  mkdir -p "$fixture/home/.ssh" "$fixture/home/.tmux/colors" \
    "$fixture/platforms/darwin/home" "$fixture/platforms/linux/home" \
    "$fixture/platforms/termux/home"
  printf '[core]\n\teditor = vim\n' > "$fixture/home/.gitconfig"
  printf 'Include ~/.ssh/config.d/*.conf\n' > "$fixture/home/.ssh/config"
  printf 'set -g mouse on\n' > "$fixture/home/.tmux.conf"
  printf 'set -g status on\n' > "$fixture/home/.tmux/colors/test.conf"
}

test_link_lifecycle() {
  local fixture="$TMP_ROOT/lifecycle-repo" home="$TMP_ROOT/lifecycle-home"
  make_fixture "$fixture"
  mkdir -p "$home"

  HOME="$home" DOTFILES_ROOT="$fixture" DOTFILES_PLATFORM=darwin \
    "$ROOT/scripts/link" --dry-run
  [[ ! -e "$home/.gitconfig" ]] || fail 'dry-run created .gitconfig'

  HOME="$home" DOTFILES_ROOT="$fixture" DOTFILES_PLATFORM=darwin \
    "$ROOT/scripts/link"
  assert_link "$home/.gitconfig" "$fixture/home/.gitconfig"
  assert_link "$home/.ssh/config" "$fixture/home/.ssh/config"
  assert_link "$home/.tmux/colors/test.conf" "$fixture/home/.tmux/colors/test.conf"

  HOME="$home" DOTFILES_ROOT="$fixture" DOTFILES_PLATFORM=darwin \
    "$ROOT/scripts/link"
  printf 'keep\n' > "$home/.tmux/local.conf"
  HOME="$home" DOTFILES_ROOT="$fixture" DOTFILES_PLATFORM=darwin \
    "$ROOT/scripts/unlink"
  [[ ! -e "$home/.gitconfig" ]] || fail 'unlink kept .gitconfig'
  [[ -f "$home/.tmux/local.conf" ]] || fail 'unlink removed unknown file'
}

test_existing_target_conflict() {
  local fixture="$TMP_ROOT/target-repo" home="$TMP_ROOT/target-home"
  make_fixture "$fixture"
  mkdir -p "$home"
  printf 'local\n' > "$home/.gitconfig"

  if HOME="$home" DOTFILES_ROOT="$fixture" DOTFILES_PLATFORM=darwin \
    "$ROOT/scripts/link" >/dev/null 2>&1; then
    fail 'link accepted an existing target'
  fi
  [[ "$(< "$home/.gitconfig")" == local ]] || fail 'link changed existing target'
}

test_legacy_shell_links_are_removed() {
  local fixture="$TMP_ROOT/legacy-repo" home="$TMP_ROOT/legacy-home"
  make_fixture "$fixture"
  mkdir -p "$fixture/home/.config/dotfiles/shell" "$home/.config/dotfiles/shell"
  ln -s "$fixture/home/.config/dotfiles/shell/load.zsh" \
    "$home/.config/dotfiles/shell/load.zsh"

  HOME="$home" DOTFILES_ROOT="$fixture" DOTFILES_PLATFORM=darwin \
    "$ROOT/scripts/link"
  [[ ! -e "$home/.config/dotfiles/shell/load.zsh" ]] || \
    fail 'link kept a legacy shell link'
  [[ ! -d "$home/.config/dotfiles" ]] || fail 'link kept an empty legacy directory'
}

test_unmanaged_legacy_link_is_preserved() {
  local fixture="$TMP_ROOT/unmanaged-legacy-repo" home="$TMP_ROOT/unmanaged-legacy-home"
  make_fixture "$fixture"
  mkdir -p "$fixture/home/.config/dotfiles/shell"
  mkdir -p "$home/.config/dotfiles/shell"
  ln -s "$fixture/other-load.zsh" "$home/.config/dotfiles/shell/load.zsh"

  HOME="$home" DOTFILES_ROOT="$fixture" DOTFILES_PLATFORM=darwin \
    "$ROOT/scripts/link"
  [[ "$(readlink "$home/.config/dotfiles/shell/load.zsh")" == "$fixture/other-load.zsh" ]] || \
    fail 'link changed an unmanaged legacy symlink'
}

test_wrong_symlink_conflict() {
  local fixture="$TMP_ROOT/symlink-repo" home="$TMP_ROOT/symlink-home"
  make_fixture "$fixture"
  mkdir -p "$home"
  ln -s "$fixture/old.gitconfig" "$home/.gitconfig"

  if HOME="$home" DOTFILES_ROOT="$fixture" DOTFILES_PLATFORM=darwin \
    "$ROOT/scripts/link" >/dev/null 2>&1; then
    fail 'link replaced an unmanaged symlink'
  fi
  [[ "$(readlink "$home/.gitconfig")" == "$fixture/old.gitconfig" ]] || \
    fail 'link changed an unmanaged symlink'
}

test_package_collision() {
  local fixture="$TMP_ROOT/collision-repo" home="$TMP_ROOT/collision-home"
  make_fixture "$fixture"
  mkdir -p "$fixture/platforms/darwin/home/.ssh" "$home"
  printf 'collision\n' > "$fixture/platforms/darwin/home/.ssh/config"

  if HOME="$home" DOTFILES_ROOT="$fixture" DOTFILES_PLATFORM=darwin \
    "$ROOT/scripts/link" --dry-run >/dev/null 2>&1; then
    fail 'link accepted shared/platform collision'
  fi
}

test_install_profile_validation() {
  local fixture="$TMP_ROOT/install-repo" home="$TMP_ROOT/install-home"
  make_fixture "$fixture"
  mkdir -p "$home"

  HOME="$home" DOTFILES_ROOT="$fixture" DOTFILES_PLATFORM=darwin \
    "$ROOT/install" full --dry-run
  if HOME="$home" DOTFILES_ROOT="$fixture" DOTFILES_PLATFORM=darwin \
    "$ROOT/install" server --dry-run >/dev/null 2>&1; then
    fail 'install accepted server profile on Darwin'
  fi
  if HOME="$home" DOTFILES_ROOT="$fixture" DOTFILES_PLATFORM=linux \
    "$ROOT/install" full --dry-run >/dev/null 2>&1; then
    fail 'install accepted full profile on Linux'
  fi
  HOME="$home" DOTFILES_ROOT="$fixture" DOTFILES_PLATFORM=linux DOTFILES_OS_ID=debian \
    "$ROOT/install" server --dry-run
  if HOME="$home" DOTFILES_ROOT="$fixture" DOTFILES_PLATFORM=linux DOTFILES_OS_ID=arch \
    "$ROOT/install" server --dry-run >/dev/null 2>&1; then
    fail 'install accepted unsupported Linux distribution'
  fi
}

test_karabiner_directory_link() {
  local fixture="$TMP_ROOT/karabiner-repo" home="$TMP_ROOT/karabiner-home"
  make_fixture "$fixture"
  mkdir -p "$fixture/platforms/darwin/home/.config/karabiner" "$home"
  printf '{}\n' > "$fixture/platforms/darwin/home/.config/karabiner/karabiner.json"

  HOME="$home" DOTFILES_ROOT="$fixture" DOTFILES_PLATFORM=darwin "$ROOT/scripts/link"
  assert_link "$home/.config/karabiner" "$fixture/platforms/darwin/home/.config/karabiner"
  HOME="$home" DOTFILES_ROOT="$fixture" DOTFILES_PLATFORM=darwin "$ROOT/scripts/unlink"
  [[ ! -e "$home/.config/karabiner" ]] || fail 'unlink kept Karabiner directory link'

  if HOME="$home" DOTFILES_ROOT="$fixture" DOTFILES_PLATFORM=darwin \
    DOTFILES_LINK_BACKEND=stow "$ROOT/scripts/link" --dry-run >/dev/null 2>&1; then
    fail 'link accepted Stow with the Karabiner directory package'
  fi
}

test_link_lifecycle
test_existing_target_conflict
test_legacy_shell_links_are_removed
test_unmanaged_legacy_link_is_preserved
test_wrong_symlink_conflict
test_package_collision
test_install_profile_validation
test_karabiner_directory_link
printf 'phase1 integration tests passed\n'
