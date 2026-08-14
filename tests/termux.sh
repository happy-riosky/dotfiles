#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

test_loader_does_not_source_system_profile() {
  local home="$TMP_ROOT/termux-profile-home" prefix="$TMP_ROOT/termux-profile-prefix"
  mkdir -p "$home" "$prefix/etc/profile.d"
  printf 'DOTFILES_AUTOJUMP_LOADED=1\n' > "$prefix/etc/profile.d/autojump.sh"

  HOME="$home" PREFIX="$prefix" DOTFILES_ROOT="$ROOT" \
    DOTFILES_PLATFORM=termux DOTFILES_PROFILE=termux /bin/zsh -df -c \
    'source "$DOTFILES_ROOT/scripts/shell/load.zsh"; [[ -z "${DOTFILES_AUTOJUMP_LOADED:-}" ]]' || \
    fail 'Termux loader sourced a system-owned profile script'
}

test_zvm_fix() {
  local home="$TMP_ROOT/zvm-fix-home" custom out
  mkdir -p "$home/.oh-my-zsh/custom"

  # unsupported platform is rejected
  if HOME="$home" DOTFILES_ROOT="$ROOT" DOTFILES_PLATFORM=darwin \
    "$ROOT/scripts/termux-zvm-fix" >/dev/null 2>&1; then
    fail 'termux-zvm-fix ran on a non-Termux platform'
  fi

  # dry-run has no side effects
  HOME="$home" DOTFILES_ROOT="$ROOT" DOTFILES_PLATFORM=termux \
    "$ROOT/scripts/termux-zvm-fix" --dry-run >/dev/null
  [[ ! -e "$home/.oh-my-zsh/custom/zz-zvm-termux.zsh" ]] || \
    fail 'termux-zvm-fix dry-run wrote the patch file'

  # apply creates the patch and reports idempotency
  HOME="$home" DOTFILES_ROOT="$ROOT" DOTFILES_PLATFORM=termux \
    "$ROOT/scripts/termux-zvm-fix" >/dev/null
  out="$(HOME="$home" DOTFILES_ROOT="$ROOT" DOTFILES_PLATFORM=termux \
    "$ROOT/scripts/termux-zvm-fix")"
  [[ -f "$home/.oh-my-zsh/custom/zz-zvm-termux.zsh" ]] || \
    fail 'termux-zvm-fix did not create the patch file'
  grep -q 'zvm_zle-line-finish' "$home/.oh-my-zsh/custom/zz-zvm-termux.zsh" || \
    fail 'termux-zvm-fix patch does not override line-finish'
  grep -q 'ZVM_CURSOR_STYLE_ENABLED=false' "$home/.oh-my-zsh/custom/zz-zvm-termux.zsh" || \
    fail 'termux-zvm-fix patch does not disable cursor styling'
  [[ "$out" == *"already patched"* ]] || fail 'termux-zvm-fix is not idempotent'

  # unmanaged content is never overwritten
  printf 'custom local tweak\n' > "$home/.oh-my-zsh/custom/zz-zvm-termux.zsh"
  if HOME="$home" DOTFILES_ROOT="$ROOT" DOTFILES_PLATFORM=termux \
    "$ROOT/scripts/termux-zvm-fix" >/dev/null 2>&1; then
    fail 'termux-zvm-fix overwrote an unmanaged patch file'
  fi
  [[ "$(< "$home/.oh-my-zsh/custom/zz-zvm-termux.zsh")" == "custom local tweak" ]] || \
    fail 'termux-zvm-fix changed an unmanaged patch file'
}

test_loader_does_not_source_system_profile
test_zvm_fix
printf 'termux integration tests passed\n'
