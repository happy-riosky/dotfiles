#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

make_fixture() {
  local fixture="$1"
  mkdir -p "$fixture/plugin-lists"
  printf '# target repository\n~/.tmux/plugins/one https://github.com/example/one.git\n' \
    > "$fixture/plugin-lists/tmux.txt"
  printf '# target repository\n~/.vim/pack/vendor/start/two https://github.com/example/two.git\n' \
    > "$fixture/plugin-lists/vim.txt"
  printf '# target repository\n~/.oh-my-zsh https://github.com/example/three.git\n' \
    > "$fixture/plugin-lists/zsh.txt"
}

make_fake_git() {
  local bin="$1"
  mkdir -p "$bin"
  cat > "$bin/git" <<'EOF'
#!/bin/bash
printf 'git:%s\n' "$*" >> "$PLUGIN_LOG"
if [[ "$1" == clone ]]; then
  shift
  [[ "${1:-}" == -- ]] && shift
  repository="$1"
  target="$2"
  mkdir -p "$target/.git"
  printf '%s\n' "$repository" > "$target/.git/origin"
  exit 0
fi
if [[ "$1" == -C ]]; then
  target="$2"
  shift 2
  case "$1:${2:-}:${3:-}" in
    rev-parse:--is-inside-work-tree:) printf 'true\n' ;;
    rev-parse:--show-toplevel:) printf '%s\n' "$target" ;;
    remote:get-url:origin) cat "$target/.git/origin" ;;
    fsck:--no-dangling:) ;;
    *) exit 1 ;;
  esac
  exit 0
fi
exit 1
EOF
  chmod +x "$bin/git"
}

test_dry_run_has_no_side_effects() {
  local fixture="$TMP_ROOT/dry-repo" home="$TMP_ROOT/dry-home"
  local bin="$TMP_ROOT/dry-bin" log="$TMP_ROOT/dry.log" output="$TMP_ROOT/dry.out"
  make_fixture "$fixture"
  make_fake_git "$bin"
  mkdir -p "$home"

  HOME="$home" PATH="$bin:/usr/bin:/bin" PLUGIN_LOG="$log" DOTFILES_ROOT="$fixture" \
    "$ROOT/scripts/plugins" --dry-run --app tmux > "$output"

  [[ ! -e "$home/.tmux" ]] || fail 'plugins dry-run created a directory'
  [[ ! -e "$log" ]] || fail 'plugins dry-run invoked git for a missing target'
  grep -Fq 'install https://github.com/example/one.git' "$output" || \
    fail 'plugins dry-run omitted the clone plan'
}

test_clone_is_verified() {
  local fixture="$TMP_ROOT/clone-repo" home="$TMP_ROOT/clone-home"
  local bin="$TMP_ROOT/clone-bin" log="$TMP_ROOT/clone.log"
  make_fixture "$fixture"
  make_fake_git "$bin"
  mkdir -p "$home"

  HOME="$home" PATH="$bin:/usr/bin:/bin" PLUGIN_LOG="$log" DOTFILES_ROOT="$fixture" \
    "$ROOT/scripts/plugins" --app tmux >/dev/null

  [[ -d "$home/.tmux/plugins/one/.git" ]] || fail 'plugins did not clone the repository'
  grep -Fq 'remote get-url origin' "$log" || fail 'plugins did not verify the clone origin'
  grep -Fq 'fsck --no-dangling' "$log" || fail 'plugins did not verify cloned objects'
}

test_existing_checkout_origin_is_enforced() {
  local fixture="$TMP_ROOT/existing-repo" home="$TMP_ROOT/existing-home"
  local bin="$TMP_ROOT/existing-bin" log="$TMP_ROOT/existing.log"
  make_fixture "$fixture"
  make_fake_git "$bin"
  mkdir -p "$home/.tmux/plugins/one/.git"
  printf 'https://github.com/other/repository.git\n' > "$home/.tmux/plugins/one/.git/origin"

  if HOME="$home" PATH="$bin:/usr/bin:/bin" PLUGIN_LOG="$log" DOTFILES_ROOT="$fixture" \
    "$ROOT/scripts/plugins" --app tmux >/dev/null 2>&1; then
    fail 'plugins accepted a checkout from the wrong repository'
  fi
  [[ "$(< "$home/.tmux/plugins/one/.git/origin")" == \
    'https://github.com/other/repository.git' ]] || fail 'plugins changed an unmanaged checkout'
  if grep -Fq 'clone' "$log"; then
    fail 'plugins tried to replace an unmanaged checkout'
  fi
}

test_all_manifests_are_validated_before_clone() {
  local fixture="$TMP_ROOT/invalid-repo" home="$TMP_ROOT/invalid-home"
  local bin="$TMP_ROOT/invalid-bin" log="$TMP_ROOT/invalid.log"
  make_fixture "$fixture"
  make_fake_git "$bin"
  mkdir -p "$home"
  printf '~/.vim/pack/vendor/start/two --upload-pack=bad\n' > "$fixture/plugin-lists/vim.txt"

  if HOME="$home" PATH="$bin:/usr/bin:/bin" PLUGIN_LOG="$log" DOTFILES_ROOT="$fixture" \
    "$ROOT/scripts/plugins" >/dev/null 2>&1; then
    fail 'plugins accepted an unsafe repository URL'
  fi
  [[ ! -e "$home/.tmux/plugins/one" ]] || fail 'plugins cloned before validating every manifest'
  [[ ! -e "$log" ]] || fail 'plugins invoked git before validating every manifest'
}

test_unmanaged_target_is_preserved() {
  local fixture="$TMP_ROOT/conflict-repo" home="$TMP_ROOT/conflict-home"
  make_fixture "$fixture"
  mkdir -p "$home/.tmux/plugins"
  printf 'keep\n' > "$home/.tmux/plugins/one"

  if HOME="$home" DOTFILES_ROOT="$fixture" "$ROOT/scripts/plugins" --app tmux \
    >/dev/null 2>&1; then
    fail 'plugins accepted an unmanaged target'
  fi
  [[ "$(< "$home/.tmux/plugins/one")" == keep ]] || fail 'plugins changed an unmanaged target'
}

test_symlinked_parent_is_rejected() {
  local fixture="$TMP_ROOT/symlink-parent-repo" home="$TMP_ROOT/symlink-parent-home"
  local outside="$TMP_ROOT/symlink-parent-outside" bin="$TMP_ROOT/symlink-parent-bin"
  local log="$TMP_ROOT/symlink-parent.log"
  make_fixture "$fixture"
  make_fake_git "$bin"
  mkdir -p "$home" "$outside"
  ln -s "$outside" "$home/.tmux"

  if HOME="$home" PATH="$bin:/usr/bin:/bin" PLUGIN_LOG="$log" DOTFILES_ROOT="$fixture" \
    "$ROOT/scripts/plugins" --app tmux >/dev/null 2>&1; then
    fail 'plugins followed a symlinked parent directory'
  fi
  [[ ! -e "$outside/plugins/one" ]] || fail 'plugins wrote outside HOME through a symlink'
}

test_nested_target_in_unmanaged_checkout_is_rejected() {
  local fixture="$TMP_ROOT/nested-repo" home="$TMP_ROOT/nested-home"
  local bin="$TMP_ROOT/nested-bin" log="$TMP_ROOT/nested.log"
  make_fixture "$fixture"
  make_fake_git "$bin"
  mkdir -p "$home/.tmux/.git"

  if HOME="$home" PATH="$bin:/usr/bin:/bin" PLUGIN_LOG="$log" DOTFILES_ROOT="$fixture" \
    "$ROOT/scripts/plugins" --app tmux >/dev/null 2>&1; then
    fail 'plugins wrote inside an unmanaged checkout'
  fi
  [[ ! -e "$home/.tmux/plugins/one" ]] || fail 'plugins created a nested target'
  [[ ! -e "$log" ]] || fail 'plugins invoked git before rejecting nested target'
}

test_dry_run_has_no_side_effects
test_clone_is_verified
test_existing_checkout_origin_is_enforced
test_all_manifests_are_validated_before_clone
test_unmanaged_target_is_preserved
test_symlinked_parent_is_rejected
test_nested_target_in_unmanaged_checkout_is_rejected
printf 'plugin integration tests passed\n'
