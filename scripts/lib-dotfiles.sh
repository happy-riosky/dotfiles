#!/usr/bin/env bash

dotfiles_root() {
  if [[ -n "${DOTFILES_ROOT:-}" ]]; then
    printf '%s\n' "$DOTFILES_ROOT"
  else
    cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd
  fi
}

dotfiles_platform() {
  if [[ -n "${DOTFILES_PLATFORM:-}" ]]; then
    printf '%s\n' "$DOTFILES_PLATFORM"
    return
  fi

  if [[ -n "${TERMUX_VERSION:-}" || "${PREFIX:-}" == */com.termux/* ]]; then
    printf 'termux\n'
    return
  fi

  case "$(uname -s)" in
    Darwin) printf 'darwin\n' ;;
    Linux)
      if [[ -r /proc/version ]] && grep -qi microsoft /proc/version; then
        printf 'wsl\n'
      else
        printf 'linux\n'
      fi
      ;;
    *) printf 'unsupported\n' ;;
  esac
}

source_roots() {
  local root="$1" platform="$2"
  [[ -d "$root/home" ]] && printf '%s\n' "$root/home"
  [[ -d "$root/platforms/$platform/home" ]] && printf '%s\n' "$root/platforms/$platform/home"
}

source_entries() {
  local source_root="$1" source_path relative
  while IFS= read -r source_path; do
    relative="${source_path#"$source_root"/}"
    [[ "$relative" == .gitkeep ]] && continue
    printf '%s\t%s\n' "$relative" "$source_path"
  done < <(find "$source_root" \( -type f -o -type l \) -print | LC_ALL=C sort)
}

canonical_existing_path() {
  local path="$1" parent base
  parent="$(dirname "$path")"
  base="$(basename "$path")"
  (cd -P "$parent" && printf '%s/%s\n' "$PWD" "$base")
}

link_matches_source() {
  local target="$1" source="$2" raw resolved
  [[ -L "$target" ]] || return 1
  raw="$(readlink "$target")"
  if [[ "$raw" == /* ]]; then
    resolved="$(canonical_existing_path "$raw")"
  else
    resolved="$(canonical_existing_path "$(dirname "$target")/$raw")"
  fi
  [[ "$resolved" == "$(canonical_existing_path "$source")" ]]
}

check_source_collisions() {
  local root="$1" platform="$2" shared platform_home
  local shared_list platform_list collision
  shared="$root/home"
  platform_home="$root/platforms/$platform/home"
  [[ -d "$shared" && -d "$platform_home" ]] || return 0
  shared_list="$(mktemp)"
  platform_list="$(mktemp)"
  source_entries "$shared" | cut -f1 > "$shared_list"
  source_entries "$platform_home" | cut -f1 > "$platform_list"
  collision="$(comm -12 "$shared_list" "$platform_list" || true)"
  rm -f "$shared_list" "$platform_list"
  if [[ -n "$collision" ]]; then
    printf 'link: shared and %s packages both provide:\n%s\n' "$platform" "$collision" >&2
    return 1
  fi
}

check_target_conflicts() {
  local root="$1" platform="$2" source_root relative source target failed=0
  while IFS= read -r source_root; do
    while IFS=$'\t' read -r relative source; do
      target="$HOME/$relative"
      if [[ -e "$target" || -L "$target" ]]; then
        if ! link_matches_source "$target" "$source"; then
          printf 'link: target exists and is not managed: %s\n' "$target" >&2
          failed=1
        fi
      fi
    done < <(source_entries "$source_root")
  done < <(source_roots "$root" "$platform")
  (( failed == 0 ))
}
