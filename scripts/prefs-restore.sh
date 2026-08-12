#!/usr/bin/env bash
# Restore preference domains from platforms/darwin/managed/preferences/ into REAL
# ~/Library/Preferences/*.plist files (never mackup symlinks).
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/dotfiles}"
MANUAL="$DOTFILES/platforms/darwin/managed/preferences"

log() { printf '[prefs-restore] %s\n' "$*"; }
warn() { printf '[prefs-restore] WARN: %s\n' "$*" >&2; }

ensure_real_file() {
  local path="$1" src="$2"
  mkdir -p "$(dirname "$path")"
  if [[ -L "$path" ]]; then
    log "removing symlink $path"
    if ! rm -f "$path" 2>/dev/null; then
      warn "cannot remove symlink (TCC?): $path — grant Full Disk Access to Terminal, or remove manually"
      return 1
    fi
  fi
  cp "$src" "$path"
  chmod 600 "$path" 2>/dev/null || true
}

refresh_prefs() {
  killall -u "$USER" cfprefsd 2>/dev/null || true
  sleep 0.3
}

[[ -d "$MANUAL" ]] || { warn "missing $MANUAL — run prefs-export.sh first"; exit 1; }

shopt -s nullglob
for golden in "$MANUAL"/*.plist; do
  domain="$(basename "$golden" .plist)"
  live="$HOME/Library/Preferences/${domain}.plist"
  if ensure_real_file "$live" "$golden"; then
    defaults import "$domain" "$live" 2>/dev/null || true
    if defaults read "$domain" >/dev/null 2>&1; then
      log "OK $domain"
    else
      refresh_prefs
      if defaults read "$domain" >/dev/null 2>&1; then
        log "OK $domain (after cfprefsd)"
      else
        warn "restored file but domain still unreadable: $domain"
      fi
    fi
  fi
done

# Restore global keys exported from .GlobalPreferences.
if [[ -f "$MANUAL/global-swipescrolldirection" ]]; then
  scroll_direction="$(< "$MANUAL/global-swipescrolldirection")"
  case "$scroll_direction" in
    YES|NO)
      if defaults write -g com.apple.swipescrolldirection -bool "$scroll_direction" 2>/dev/null; then
        log "OK global com.apple.swipescrolldirection"
      else
        warn "could not write global com.apple.swipescrolldirection"
      fi
      ;;
    *) warn "invalid global com.apple.swipescrolldirection: $scroll_direction" ;;
  esac
fi

log "done"
