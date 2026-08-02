#!/usr/bin/env bash
# Restore macOS symbolic hotkeys + Rectangle from dotfiles/backup/manual/
# into REAL preference files (never mackup symlinks). Run manually or from setup.
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/dotfiles}"
MANUAL="$DOTFILES/backup/manual"
RECTANGLE_DOMAIN="com.knollsoft.Rectangle"
SYMBOLIC_DST="$HOME/Library/Preferences/com.apple.symbolichotkeys.plist"
RECTANGLE_DST="$HOME/Library/Preferences/com.knollsoft.Rectangle.plist"
SYMBOLIC_GOLDEN="$MANUAL/symbolichotkeys.plist"
RECTANGLE_GOLDEN="$MANUAL/RectangleConfig.json"

log() { printf '[hotkeys-restore] %s\n' "$*"; }
die() { printf '[hotkeys-restore] ERROR: %s\n' "$*" >&2; exit 1; }

ensure_real_file() {
  # $1 = path that must become a real file; $2 = source content path
  local path="$1" src="$2"
  mkdir -p "$(dirname "$path")"
  if [[ -L "$path" ]]; then
    log "removing symlink $path"
    rm -f "$path"
  fi
  cp "$src" "$path"
  chmod 600 "$path" 2>/dev/null || true
}

refresh_prefs() {
  # Drop user cfprefsd cache so domains reload from disk
  killall -u "$USER" cfprefsd 2>/dev/null || true
  sleep 0.3
}

activate_symbolichotkeys() {
  local activator="/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings"
  if [[ -x "$activator" ]]; then
    "$activator" -u 2>/dev/null || true
  fi
  # Dock hosts many Mission Control / space shortcuts
  killall Dock 2>/dev/null || true
}

restore_symbolichotkeys() {
  [[ -f "$SYMBOLIC_GOLDEN" ]] || die "missing golden $SYMBOLIC_GOLDEN — run hotkeys-export.sh first"
  ensure_real_file "$SYMBOLIC_DST" "$SYMBOLIC_GOLDEN"
  # Also push via defaults when possible
  defaults import com.apple.symbolichotkeys "$SYMBOLIC_DST" 2>/dev/null || true
  log "restored system hotkeys → $SYMBOLIC_DST"
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

# Disabled / empty actions that exist only as empty dicts in older plists:
# leave unset so Rectangle uses its own empty binding.

if "version" in doc and doc["version"]:
    out.setdefault("lastVersion", str(doc["version"]))

with open(dst, "wb") as f:
    plistlib.dump(out, f, fmt=plistlib.FMT_BINARY)
PY

  # Install as real file, then import into domain
  if [[ -L "$RECTANGLE_DST" ]]; then
    log "removing symlink $RECTANGLE_DST"
    rm -f "$RECTANGLE_DST"
  fi
  cp "$tmp_plist" "$RECTANGLE_DST"
  chmod 600 "$RECTANGLE_DST" 2>/dev/null || true
  defaults import "$RECTANGLE_DOMAIN" "$tmp_plist"
  rm -f "$tmp_plist"

  log "restored Rectangle → domain $RECTANGLE_DOMAIN"
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
  [[ -d "$MANUAL" ]] || die "missing $MANUAL"
  restore_symbolichotkeys
  restore_rectangle
  refresh_prefs
  # Re-import after cfprefsd restart for reliability
  defaults import com.apple.symbolichotkeys "$SYMBOLIC_DST" 2>/dev/null || true
  defaults import "$RECTANGLE_DOMAIN" "$RECTANGLE_DST" 2>/dev/null || true
  activate_symbolichotkeys
  verify
  log "done. Test: desktop switch, same-app windows, Rectangle halves."
  log "If system hotkeys still wrong, log out/in once."
}

main "$@"
