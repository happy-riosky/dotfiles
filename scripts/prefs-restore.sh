#!/usr/bin/env bash
# Restore preference domains from platforms/darwin/managed/preferences/ into REAL
# ~/Library/Preferences/*.plist files (never mackup symlinks).
#
# Usage: scripts/prefs-restore.sh [--yes] [--backup-dir DIR]
#   --yes          Skip confirmation prompt
#   --backup-dir   Override default backup location
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/dotfiles}"
MANUAL="$DOTFILES/platforms/darwin/managed/preferences"

YES=0
BACKUP_DIR=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --yes) YES=1; shift ;;
    --backup-dir) BACKUP_DIR="$2"; shift 2 ;;
    *) printf 'usage: scripts/prefs-restore.sh [--yes] [--backup-dir DIR]\n' >&2; exit 2 ;;
  esac
done

log() { printf '[prefs-restore] %s\n' "$*"; }
warn() { printf '[prefs-restore] WARN: %s\n' "$*" >&2; }

[[ -d "$MANUAL" ]] || { warn "missing $MANUAL — run prefs-export.sh first"; exit 1; }

if [[ "$YES" -eq 0 ]]; then
  printf '[prefs-restore] This will overwrite %d preference domains.\n' \
    "$(find "$MANUAL" -name '*.plist' | wc -l | tr -d ' ')"
  printf '[prefs-restore] Continue? [y/N] '
  read -r response
  [[ "$response" =~ ^[Yy]$ ]] || { log 'aborted'; exit 0; }
fi

BACKUP_DIR="${BACKUP_DIR:-$HOME/.local/state/dotfiles/prefs-backup-$(date +%Y%m%d-%H%M%S)}"
mkdir -p "$BACKUP_DIR"
log "backup dir: $BACKUP_DIR"

backup_file() {
  local path="$1" rel
  if [[ -f "$path" && ! -L "$path" ]]; then
    rel="${path#"$HOME/Library/Preferences/"}"
    mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
    cp -p "$path" "$BACKUP_DIR/$rel"
  fi
}

restore_backup() {
  local path="$1" rel
  rel="${path#"$HOME/Library/Preferences/"}"
  if [[ -f "$BACKUP_DIR/$rel" ]]; then
    cp -p "$BACKUP_DIR/$rel" "$path"
    return 0
  fi
  return 1
}

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
  backup_file "$path"
  cp "$src" "$path"
  chmod 600 "$path" 2>/dev/null || true
}

refresh_prefs() {
  killall -u "$USER" cfprefsd 2>/dev/null || true
  sleep 0.3
}

shopt -s nullglob
FAILED=0
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
        if restore_backup "$live"; then
          log "reverted $domain from backup"
        fi
        FAILED=$((FAILED + 1))
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

if [[ "$FAILED" -gt 0 ]]; then
  warn "$FAILED domain(s) failed — backups in $BACKUP_DIR"
  exit 1
fi

log "done — backups in $BACKUP_DIR"
