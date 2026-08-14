#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

make_fixture() {
  local fixture="$1"
  mkdir -p "$fixture/package-lists"
  printf '# formulae\nalpha\ncustom/tap/tool\n' > "$fixture/package-lists/brew-formulae.txt"
  printf '# casks\nalpha-app\n' > "$fixture/package-lists/brew-casks.txt"
  printf '# apt\nalpha\nbeta\n' > "$fixture/package-lists/apt.txt"
  printf '# termux\ngamma\n' > "$fixture/package-lists/termux.txt"
}

make_fake_managers() {
  local bin="$1"
  mkdir -p "$bin"
  for command in brew apt-get pkg; do
    printf '#!/usr/bin/env bash\nprintf "%%s:%%s\\n" "%s" "$*" >> "$PACKAGE_LOG"\n' \
      "$command" > "$bin/$command"
    chmod +x "$bin/$command"
  done
  printf '#!/usr/bin/env bash\nprintf "sudo:%%s\\n" "$*" >> "$PACKAGE_LOG"\n"$@"\n' > "$bin/sudo"
  chmod +x "$bin/sudo"
}

test_dry_run_is_side_effect_free() {
  local fixture="$TMP_ROOT/dry-repo" home="$TMP_ROOT/dry-home"
  local bin="$TMP_ROOT/dry-bin" log="$TMP_ROOT/dry.log" output="$TMP_ROOT/dry.out"
  make_fixture "$fixture"
  make_fake_managers "$bin"
  mkdir -p "$home"

  HOME="$home" PATH="$bin:/usr/bin:/bin" PACKAGE_LOG="$log" \
    DOTFILES_ROOT="$fixture" DOTFILES_PLATFORM=linux DOTFILES_OS_ID=debian \
    "$ROOT/scripts/packages" server --dry-run > "$output"

  [[ ! -e "$log" ]] || fail 'packages dry-run invoked a package manager'
  grep -Fq 'apt-get install -y alpha beta' "$output" || fail 'packages dry-run omitted apt plan'
}

test_profile_validation() {
  local fixture="$TMP_ROOT/validation-repo" home="$TMP_ROOT/validation-home"
  make_fixture "$fixture"
  mkdir -p "$home"

  HOME="$home" DOTFILES_ROOT="$fixture" DOTFILES_PLATFORM=darwin \
    "$ROOT/scripts/packages" full --dry-run >/dev/null
  HOME="$home" DOTFILES_ROOT="$fixture" DOTFILES_PLATFORM=termux \
    "$ROOT/scripts/packages" termux --dry-run >/dev/null
  if HOME="$home" DOTFILES_ROOT="$fixture" DOTFILES_PLATFORM=darwin \
    "$ROOT/scripts/packages" server --dry-run >/dev/null 2>&1; then
    fail 'packages accepted server profile on Darwin'
  fi
  if HOME="$home" DOTFILES_ROOT="$fixture" DOTFILES_PLATFORM=linux DOTFILES_OS_ID=arch \
    "$ROOT/scripts/packages" server --dry-run >/dev/null 2>&1; then
    fail 'packages accepted an unsupported Linux distribution'
  fi
  if HOME="$home" DOTFILES_ROOT="$fixture" DOTFILES_PLATFORM=wsl \
    "$ROOT/scripts/packages" server --dry-run >/dev/null 2>&1; then
    fail 'packages accepted WSL'
  fi
}

test_package_manager_commands() {
  local fixture="$TMP_ROOT/commands-repo" home="$TMP_ROOT/commands-home"
  local bin="$TMP_ROOT/commands-bin" log="$TMP_ROOT/commands.log"
  make_fixture "$fixture"
  make_fake_managers "$bin"
  mkdir -p "$home"

  HOME="$home" PATH="$bin:/usr/bin:/bin" PACKAGE_LOG="$log" \
    DOTFILES_ROOT="$fixture" DOTFILES_PLATFORM=darwin \
    "$ROOT/scripts/packages" full >/dev/null
  grep -Fxq 'brew:install alpha custom/tap/tool' "$log" || fail 'brew formulae command is wrong'
  grep -Fxq 'brew:install --cask alpha-app' "$log" || fail 'brew cask command is wrong'

  : > "$log"
  HOME="$home" PATH="$bin:/usr/bin:/bin" PACKAGE_LOG="$log" \
    DOTFILES_APT_GET="$bin/apt-get" DOTFILES_SUDO="$bin/sudo" \
    DOTFILES_ROOT="$fixture" DOTFILES_PLATFORM=linux DOTFILES_OS_ID=ubuntu \
    "$ROOT/scripts/packages" server >/dev/null
  grep -Fxq 'apt-get:update' "$log" || fail 'apt update command is missing'
  grep -Fxq 'apt-get:install -y alpha beta' "$log" || fail 'apt install command is wrong'

  : > "$log"
  HOME="$home" PATH="$bin:/usr/bin:/bin" PACKAGE_LOG="$log" \
    DOTFILES_ROOT="$fixture" DOTFILES_PLATFORM=termux \
    "$ROOT/scripts/packages" termux >/dev/null
  grep -Fxq 'pkg:install -y gamma' "$log" || fail 'Termux install command is wrong'
}

test_manifest_validation_precedes_execution() {
  local fixture="$TMP_ROOT/invalid-repo" home="$TMP_ROOT/invalid-home"
  local bin="$TMP_ROOT/invalid-bin" log="$TMP_ROOT/invalid.log"
  make_fixture "$fixture"
  make_fake_managers "$bin"
  mkdir -p "$home"
  printf 'alpha\n--dangerous-option\n' > "$fixture/package-lists/apt.txt"

  if HOME="$home" PATH="$bin:/usr/bin:/bin" PACKAGE_LOG="$log" \
    DOTFILES_ROOT="$fixture" DOTFILES_PLATFORM=linux DOTFILES_OS_ID=debian \
    "$ROOT/scripts/packages" server >/dev/null 2>&1; then
    fail 'packages accepted an unsafe manifest entry'
  fi
  [[ ! -e "$log" ]] || fail 'packages executed before validating the manifest'

  printf '%s\n' '--dangerous-cask-option' > "$fixture/package-lists/brew-casks.txt"
  if HOME="$home" PATH="$bin:/usr/bin:/bin" PACKAGE_LOG="$log" \
    DOTFILES_ROOT="$fixture" DOTFILES_PLATFORM=darwin \
    "$ROOT/scripts/packages" full >/dev/null 2>&1; then
    fail 'packages accepted an unsafe cask entry'
  fi
  [[ ! -e "$log" ]] || fail 'packages installed formulae before validating casks'
}

test_dry_run_is_side_effect_free
test_profile_validation
test_package_manager_commands
test_manifest_validation_precedes_execution
printf 'package integration tests passed\n'
