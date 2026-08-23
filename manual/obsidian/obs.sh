#!/usr/bin/env bash
set -euo pipefail

SCRIPT_ENTRY="${BASH_SOURCE[0]}"
LINK_PATH="$HOME/bin/obs"

usage() {
  cat <<'USAGE'
usage: obs.sh <command> [args]

commands:
  vaults                         list registered Obsidian vaults and paths
  status [vault]                 show Git and window status for all or one vault
  files <vault> [folder]         list files in a vault or folder
  folders <vault>                list folders in a vault
  launch                         launch Obsidian without bringing it to the foreground
  open <vault>                   open or focus a vault in Obsidian
  open-file <vault> <file>       open a vault-relative file in Obsidian
  vim <vault> [path]             open a vault or vault-relative path in Vim
  path <vault> [directory]       print a vault or directory's absolute path
  choose                         open the Obsidian Vault Manager
  version                        print the Obsidian CLI version
  link [--dry-run]               create ~/bin/obs -> this script
  help                           print this help

examples:
  obs vaults
  obs status
  obs files "Work" "Projects/2026"
  obs launch
  obs open "Work"
  obs open-file "Work" "Projects/2026/Plan.md"
  obs vim "Work" "Projects/2026"
  cd "$(obs path "Work" "Projects/2026")"
USAGE
}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

usage_error() {
  printf 'error: %s\n\n' "$*" >&2
  usage >&2
  exit 2
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "$1 is required but not found in PATH"
}

require_macos() {
  [[ "$(uname -s)" == Darwin ]] || die 'this command is supported on macOS only'
}

require_obsidian() {
  require_macos
  require_command obsidian
}

resolve_script_path() {
  local source_path="$1" link_target source_dir

  case "$source_path" in
    /*) ;;
    *) source_path="$PWD/$source_path" ;;
  esac

  # The checked-in entry point is a real file. The one-hop resolution lets the
  # command work when invoked through the managed ~/bin/obs link without
  # recursively following unrelated links.
  if [[ -L "$source_path" ]]; then
    link_target="$(readlink "$source_path")" || die "cannot read script link: $source_path"
    case "$link_target" in
      /*) source_path="$link_target" ;;
      *) source_path="$(dirname "$source_path")/$link_target" ;;
    esac
  fi

  [[ -f "$source_path" && ! -L "$source_path" ]] || \
    die "obs.sh must resolve to a real file: $source_path"

  source_dir="$(cd -P "$(dirname "$source_path")" && pwd)" || \
    die "cannot resolve script directory: $source_path"
  printf '%s/%s\n' "$source_dir" "$(basename "$source_path")"
}

SCRIPT_PATH="$(resolve_script_path "$SCRIPT_ENTRY")"

registered_vault_entries() {
  local output

  output="$(obsidian vaults verbose </dev/null)" || return 1
  if [[ -n "$output" ]]; then
    printf '%s\n' "$output"
  fi
}

find_vault_path() {
  local vault="$1" entries="$2" entry_vault entry_path

  while IFS=$'\t' read -r entry_vault entry_path; do
    if [[ "$entry_vault" == "$vault" ]]; then
      printf '%s\n' "$entry_path"
      return 0
    fi
  done <<< "$entries"
  return 1
}

vault_path() {
  local vault="$1" path entries="${2:-}"

  # Resolve from the registry. Targeting a closed vault through the CLI can
  # open a window as a side effect.
  if [[ -z "$entries" ]]; then
    entries="$(registered_vault_entries)" || \
      die "could not list registered vaults"
  fi
  path="$(find_vault_path "$vault" "$entries")" || \
    die "vault not found or unavailable: $vault"
  canonical_vault_path "$path"
}

canonical_vault_path() {
  local path="$1"

  [[ -d "$path" ]] || die "vault path does not exist: $path"
  (cd -P "$path" && pwd) || die "cannot access vault path: $path"
}

relative_path() {
  local root="$1" relative="$2" root_real parent target component
  local -a components
  local IFS='/'

  case "$relative" in
    '') die 'vault-relative path must not be empty' ;;
    /*) die "path must be relative to the vault: $relative" ;;
  esac

  # Do not traverse symlinked components. This keeps files, directories, Vim,
  # and Obsidian operations under the registered vault's real directory.
  read -r -a components <<< "$relative"
  target="$root"
  for component in "${components[@]}"; do
    case "$component" in
      ''|.) ;;
      ..) target="$target/.." ;;
      *)
        target="$target/$component"
        [[ ! -L "$target" ]] || die "path contains a symlink: $relative"
        ;;
    esac
  done

  root_real="$(cd -P "$root" && pwd)" || die "cannot access vault: $root"
  if [[ -d "$root/$relative" ]]; then
    target="$(cd -P "$root/$relative" && pwd)" || \
      die "cannot access vault path: $relative"
  else
    parent="$(cd -P "$root/$(dirname "$relative")" 2>/dev/null && pwd)" || \
      die "parent directory does not exist: $relative"
    target="$parent/$(basename "$relative")"
  fi

  case "$target" in
    "$root_real"|"$root_real"/*) printf '%s\n' "$target" ;;
    *) die "path escapes the vault: $relative" ;;
  esac
}

obsidian_window_titles() {
  require_command osascript
  osascript <<'APPLESCRIPT'
tell application "System Events"
    if not (exists process "Obsidian") then
        return ""
    end if

    tell process "Obsidian"
        set window_titles to title of every window
    end tell

    set AppleScript's text item delimiters to linefeed
    return window_titles as text
end tell
APPLESCRIPT
}

vault_window_status() {
  local vault="$1" window_titles="$2" windows_known="$3"

  if [[ "$windows_known" != 1 ]]; then
    printf 'unknown\n'
    return 0
  fi

  case "$window_titles" in
    *" - $vault - Obsidian"*|"$vault - Obsidian"*) printf 'open\n' ;;
    *) printf 'closed\n' ;;
  esac
}

show_status() {
  local vault="$1" path="$2" window_titles="${3:-}" windows_known="${4:-0}"
  local git_root git_status first_line changes branch

  printf '== %s ==\n' "$vault"
  printf 'path: %s\n' "$path"
  printf 'window: %s\n' "$(vault_window_status "$vault" "$window_titles" "$windows_known")"

  if ! git_root="$(git -C "$path" rev-parse --show-toplevel 2>/dev/null)"; then
    printf 'git: not a git repository\n\n'
    return 0
  fi

  if ! git_status="$(git -C "$path" status --short --branch 2>&1)"; then
    printf 'git: unavailable\n%s\n\n' "$git_status"
    return 1
  fi

  [[ -n "$git_root" ]] || {
    printf 'git: unavailable\n\n'
    return 1
  }

  first_line="${git_status%%$'\n'*}"
  branch="${first_line#\#\# }"
  case "$git_status" in
    *$'\n'*) changes="${git_status#*$'\n'}" ;;
    *) changes='' ;;
  esac

  if [[ -n "$changes" ]]; then
    printf 'git: dirty\n'
    printf 'branch: %s\n' "$branch"
    printf 'changes:\n%s\n\n' "$changes"
  else
    printf 'git: clean\n'
    printf 'branch: %s\n\n' "$branch"
  fi
}

uri_encode() {
  local value="$1" char byte
  local LC_ALL=C

  # Iterate over bytes so this remains compatible with the Bash shipped by
  # macOS. RFC 3986 unreserved bytes can stay literal; all others are encoded.
  while [[ -n "$value" ]]; do
    char="${value%"${value#?}"}"
    value="${value#?}"
    case "$char" in
      [-A-Za-z0-9._~]) printf '%s' "$char" ;;
      *)
        printf -v byte '%d' "'$char"
        printf '%%%02X' "$byte"
        ;;
    esac
  done
  printf '\n'
}

cmd_vaults() {
  require_obsidian
  obsidian vaults verbose </dev/null
}

cmd_status() {
  local entries vault path failed=0 window_titles windows_known=1

  require_obsidian
  require_command git
  if ! window_titles="$(obsidian_window_titles 2>/dev/null)"; then
    window_titles=''
    windows_known=0
    printf 'warning: window status unavailable; grant the terminal Accessibility access\n' >&2
  fi
  entries="$(registered_vault_entries)" || die 'could not list registered vaults'

  case "$#" in
    0)
      if [[ -z "$entries" ]]; then
        printf 'no registered vaults\n'
        return 0
      fi
      while IFS=$'\t' read -r vault path; do
        [[ -n "$vault" ]] || continue
        [[ -n "$path" ]] || die "could not parse vault registry entry: $vault"
        path="$(canonical_vault_path "$path")"
        if ! show_status "$vault" "$path" "$window_titles" "$windows_known" </dev/null; then
          failed=1
        fi
      done <<< "$entries"
      return "$failed"
      ;;
    1)
      path="$(vault_path "$1" "$entries")"
      show_status "$1" "$path" "$window_titles" "$windows_known"
      ;;
    *) usage_error 'status accepts zero or one vault argument' ;;
  esac
}

cmd_files() {
  local vault="$1" root folder

  require_obsidian
  root="$(vault_path "$vault")"
  if [[ "$#" == 2 ]]; then
    folder="$2"
    relative_path "$root" "$folder" >/dev/null
    [[ -d "$root/$folder" ]] || die "folder not found: $folder"
    obsidian vault="$vault" files folder="$folder" </dev/null
  else
    obsidian vault="$vault" files </dev/null
  fi
}

cmd_folders() {
  local vault="$1"

  require_obsidian
  vault_path "$vault" >/dev/null
  obsidian vault="$vault" folders </dev/null
}

cmd_launch() {
  require_macos
  require_command open
  open -g -a Obsidian
}

cmd_open() {
  local vault="$1" encoded_vault

  require_obsidian
  require_command open
  vault_path "$vault" >/dev/null
  encoded_vault="$(uri_encode "$vault")"
  open "obsidian://open?vault=$encoded_vault"
}

cmd_open_file() {
  local vault="$1" file="$2" root encoded_vault encoded_file target

  require_obsidian
  require_command open
  root="$(vault_path "$vault")"
  target="$(relative_path "$root" "$file")"
  [[ -f "$target" && ! -L "$target" ]] || die "file not found or is a symlink: $file"
  encoded_vault="$(uri_encode "$vault")"
  encoded_file="$(uri_encode "$file")"
  open "obsidian://open?vault=$encoded_vault&file=$encoded_file"
}

cmd_vim() {
  local vault="$1" root target relative

  require_obsidian
  require_command vim
  root="$(vault_path "$vault")"

  if [[ "$#" == 1 ]]; then
    (cd "$root" && exec vim .)
    return
  fi

  relative="$2"
  target="$(relative_path "$root" "$relative")"
  if [[ -d "$target" ]]; then
    (cd "$target" && exec vim .)
  else
    (cd "$root" && exec vim -- "$relative")
  fi
}

cmd_path() {
  local vault="$1" root target

  require_obsidian
  root="$(vault_path "$vault")"
  if [[ "$#" == 1 ]]; then
    printf '%s\n' "$root"
    return
  fi

  target="$(relative_path "$root" "$2")"
  [[ -d "$target" ]] || die "directory not found: $2"
  printf '%s\n' "$target"
}

cmd_choose() {
  require_macos
  require_command open
  open 'obsidian://choose-vault'
}

cmd_version() {
  require_obsidian
  obsidian version </dev/null
}

cmd_link() {
  local dry_run=0 existing

  case "$#" in
    0) ;;
    1)
      [[ "$1" == --dry-run ]] || usage_error 'link accepts only --dry-run'
      dry_run=1
      ;;
    *) usage_error 'link accepts zero or one argument' ;;
  esac

  if [[ -L "$LINK_PATH" ]]; then
    existing="$(readlink "$LINK_PATH")" || die "cannot read existing link: $LINK_PATH"
    if [[ "$existing" == "$SCRIPT_PATH" ]]; then
      printf 'already linked: %s -> %s\n' "$LINK_PATH" "$existing"
      return 0
    fi
    die "refusing to overwrite $LINK_PATH (points to $existing)"
  fi
  [[ ! -e "$LINK_PATH" ]] || die "refusing to overwrite $LINK_PATH (not a symlink)"
  [[ (! -e "$HOME/bin" && ! -L "$HOME/bin") || -d "$HOME/bin" ]] || \
    die "bin path exists and is not a directory: $HOME/bin"

  if (( dry_run == 1 )); then
    [[ -d "$HOME/bin" ]] || printf 'would create directory %s\n' "$HOME/bin"
    printf 'would link %s -> %s\n' "$LINK_PATH" "$SCRIPT_PATH"
    return 0
  fi

  mkdir -p "$HOME/bin"
  ln -s "$SCRIPT_PATH" "$LINK_PATH"
  printf 'linked: %s -> %s\n' "$LINK_PATH" "$SCRIPT_PATH"
}

main() {
  local command="${1:-help}"
  if [[ $# -gt 0 ]]; then
    shift
  fi

  case "$command" in
    help|-h|--help)
      [[ $# -eq 0 ]] || usage_error 'help accepts no arguments'
      usage
      ;;
    vaults)
      [[ $# -eq 0 ]] || usage_error 'vaults accepts no arguments'
      cmd_vaults
      ;;
    status) cmd_status "$@" ;;
    files)
      [[ $# -ge 1 && $# -le 2 ]] || usage_error 'files requires a vault and optional folder'
      cmd_files "$@"
      ;;
    folders)
      [[ $# -eq 1 ]] || usage_error 'folders requires one vault'
      cmd_folders "$@"
      ;;
    launch)
      [[ $# -eq 0 ]] || usage_error 'launch accepts no arguments'
      cmd_launch
      ;;
    open)
      [[ $# -eq 1 ]] || usage_error 'open requires one vault'
      cmd_open "$@"
      ;;
    open-file)
      [[ $# -eq 2 ]] || usage_error 'open-file requires a vault and file'
      cmd_open_file "$@"
      ;;
    vim)
      [[ $# -ge 1 && $# -le 2 ]] || usage_error 'vim requires a vault and optional path'
      cmd_vim "$@"
      ;;
    path)
      [[ $# -ge 1 && $# -le 2 ]] || usage_error 'path requires a vault and optional directory'
      cmd_path "$@"
      ;;
    choose)
      [[ $# -eq 0 ]] || usage_error 'choose accepts no arguments'
      cmd_choose
      ;;
    version)
      [[ $# -eq 0 ]] || usage_error 'version accepts no arguments'
      cmd_version
      ;;
    link) cmd_link "$@" ;;
    *) usage_error "unknown command: $command" ;;
  esac
}

main "$@"
