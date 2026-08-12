#!/usr/bin/env bash
# Restore macOS symbolic hotkeys + Rectangle from platforms/darwin/managed/hotkeys/
# into REAL preference files (never mackup symlinks). Run manually or from setup.
#
# Usage: scripts/hotkeys-restore.sh [--yes] [--backup-dir DIR]
#   --yes          Skip confirmation prompt
#   --backup-dir   Override default backup location
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/dotfiles}"
MANUAL="$DOTFILES/platforms/darwin/managed/hotkeys"
RECTANGLE_DOMAIN="com.knollsoft.Rectangle"
SYMBOLIC_DST="$HOME/Library/Preferences/com.apple.symbolichotkeys.plist"
RECTANGLE_DST="$HOME/Library/Preferences/com.knollsoft.Rectangle.plist"
SYMBOLIC_GOLDEN="$MANUAL/symbolichotkeys.plist"
RECTANGLE_GOLDEN="$MANUAL/RectangleConfig.json"

YES=0
BACKUP_DIR=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --yes) YES=1; shift ;;
    --backup-dir) BACKUP_DIR="$2"; shift 2 ;;
    *) printf 'usage: scripts/hotkeys-restore.sh [--yes] [--backup-dir DIR]\n' >&2; exit 2 ;;
  esac
done

log() { printf '[hotkeys-restore] %s\n' "$*"; }
die() { printf '[hotkeys-restore] ERROR: %s\n' "$*" >&2; exit 1; }

[[ -d "$MANUAL" ]] || die "missing $MANUAL"

if [[ "$YES" -eq 0 ]]; then
  printf '[hotkeys-restore] This will overwrite system hotkeys and Rectangle config.\n'
  printf '[hotkeys-restore] Quit Rectangle first for best results.\n'
  printf '[hotkeys-restore] Continue? [y/N] '
  read -r response
  [[ "$response" =~ ^[Yy]$ ]] || { log 'aborted'; exit 0; }
fi

BACKUP_DIR="${BACKUP_DIR:-$HOME/.local/state/dotfiles/hotkeys-backup-$(date +%Y%m%d-%H%M%S)}"
mkdir -p "$BACKUP_DIR"
log "backup dir: $BACKUP_DIR"

backup_file() {
  local path="$1" rel
  if [[ -f "$path" && ! -L "$path" ]]; then
    rel="$(basename "$path")"
    cp -p "$path" "$BACKUP_DIR/$rel"
  fi
}

restore_backup() {
  local path="$1" rel
  rel="$(basename "$path")"
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
    rm -f "$path"
  fi
  backup_file "$path"
  cp "$src" "$path"
  chmod 600 "$path" 2>/dev/null || true
}

refresh_prefs() {
  killall -u "$USER" cfprefsd 2>/dev/null || true
  sleep 0.3
}

activate_symbolichotkeys() {
  local activator="/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings"
  if [[ -x "$activator" ]]; then
    "$activator" -u 2>/dev/null || true
  fi
  killall Dock 2>/dev/null || true
}

restore_symbolichotkeys() {
  [[ -f "$SYMBOLIC_GOLDEN" ]] || die "missing golden $SYMBOLIC_GOLDEN — run hotkeys-export.sh first"
  ensure_real_file "$SYMBOLIC_DST" "$SYMBOLIC_GOLDEN"
  if ! defaults import com.apple.symbolichotkeys "$SYMBOLIC_DST" 2>/dev/null; then
    warn "symbolichotkeys import failed"
    if restore_backup "$SYMBOLIC_DST"; then
      log "reverted symbolichotkeys from backup"
    fi
    return 1
  fi
  log "restored system hotkeys"
}

restore_rectangle() {
  [[ -f "$RECTANGLE_GOLDEN" ]] || die "missing golden $RECTANGLE_GOLDEN"

  killall Rectangle 2>/dev/null || true
  sleep 0.2

  local tmp_plist
  tmp_plist="$(mktemp).plist"

  python3 - "$RECTANGLE_GOLDEN" "$tmp_plist" <<'PY'
import json, plistlib, sys

src, dst = sys.argv[1], sys.argv[2]
doc = json.load(open(src, encoding="utf-8"))
out = {}

for key, spec in (doc.get("defaults") or {}).items():
    if not isinstance(spec, dict) or not spec:
        continue
    if "bool" in spec:
        out[key] = bool(spec["bool"])
    elif "int" in spec:
        out[key] = int(spec["int"])
    elif "float" in spec:
        out[key] = float(spec["float"])
    elif "string" in spec:
        out[key] = str(spec["string"])
    elif "dict" in spec:
        out[key] = spec["dict"]
    elif "array" in spec:
        out[key] = spec["array"]

for action, sc in (doc.get("shortcuts") or {}).items():
    if not isinstance(sc, dict):
        continue
    if "keyCode" not in sc:
        continue
    out[action] = {
        "keyCode": int(sc["keyCode"]),
        "modifierFlags": int(sc.get("modifierFlags", 0)),
    }

if "version" in doc and doc["version"]:
    out.setdefault("lastVersion", str(doc["version"]))

with open(dst, "wb") as f:
    plistlib.dump(out, f, fmt=plistlib.FMT_BINARY)
PY

  if [[ -L "$RECTANGLE_DST" ]]; then
    log "removing symlink $RECTANGLE_DST"
    rm -f "$RECTANGLE_DST"
  fi
  backup_file "$RECTANGLE_DST"
  cp "$tmp_plist" "$RECTANGLE_DST"
  chmod 600 "$RECTANGLE_DST" 2>/dev/null || true

  if ! defaults import "$RECTANGLE_DOMAIN" "$tmp_plist" 2>/dev/null; then
    warn "Rectangle import failed"
    if restore_backup "$RECTANGLE_DST"; then
      log "reverted Rectangle from backup"
    fi
    rm -f "$tmp_plist"
    return 1
  fi
  rm -f "$tmp_plist"

  log "restored Rectangle"
  if [[ -d /Applications/Rectangle.app ]]; then
    open -a Rectangle
    log "launched Rectangle"
  fi
}

verify() {
  log "verification:"
  if [[ -L "$SYMBOLIC_DST" ]]; then
    log "  WARN: $SYMBOLIC_DST is still a symlink"
  else
    log "  OK: symbolichotkeys is a real file"
  fi
  if [[ -L "$RECTANGLE_DST" ]]; then
    log "  WARN: $RECTANGLE_DST is still a symlink"
  else
    log "  OK: Rectangle plist is a real file"
  fi
  if defaults read "$RECTANGLE_DOMAIN" >/dev/null 2>&1; then
    log "  OK: defaults domain $RECTANGLE_DOMAIN is readable"
  else
    log "  WARN: defaults cannot read $RECTANGLE_DOMAIN yet (try log out/in)"
  fi
}

main() {
  local failed=0
  restore_symbolichotkeys || failed=1
  restore_rectangle || failed=1
  refresh_prefs
  [[ "$failed" -eq 0 ]] && defaults import com.apple.symbolichotkeys "$SYMBOLIC_DST" 2>/dev/null || true
  [[ "$failed" -eq 0 ]] && defaults import "$RECTANGLE_DOMAIN" "$RECTANGLE_DST" 2>/dev/null || true
  activate_symbolichotkeys
  verify
  if [[ "$failed" -gt 0 ]]; then
    warn "some restores failed — backups in $BACKUP_DIR"
    exit 1
  fi
  log "done — backups in $BACKUP_DIR"
  log "Test: desktop switch, same-app windows, Rectangle halves."
  log "If system hotkeys still wrong, log out/in once."
}

main
