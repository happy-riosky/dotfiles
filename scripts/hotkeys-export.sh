#!/usr/bin/env bash
# Export currently-effective macOS symbolic hotkeys + Rectangle config into
# dotfiles/backup/manual/ (git-friendly golden copies).
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/dotfiles}"
MANUAL="$DOTFILES/backup/manual"
RECTANGLE_DOMAIN="com.knollsoft.Rectangle"
SYMBOLIC_SRC="$HOME/Library/Preferences/com.apple.symbolichotkeys.plist"
SYMBOLIC_GOLDEN="$MANUAL/symbolichotkeys.plist"
RECTANGLE_GOLDEN="$MANUAL/RectangleConfig.json"

mkdir -p "$MANUAL"

log() { printf '[hotkeys-export] %s\n' "$*"; }
die() { printf '[hotkeys-export] ERROR: %s\n' "$*" >&2; exit 1; }

export_symbolichotkeys() {
  if [[ ! -e "$SYMBOLIC_SRC" && ! -L "$SYMBOLIC_SRC" ]]; then
    die "missing $SYMBOLIC_SRC — set shortcuts in System Settings first"
  fi

  local tmp
  tmp="$(mktemp)"
  # Resolve symlink if present so we never write a link into manual/
  if [[ -L "$SYMBOLIC_SRC" ]]; then
    cp "$(readlink "$SYMBOLIC_SRC")" "$tmp"
  else
    cp "$SYMBOLIC_SRC" "$tmp"
  fi
  # Prefer defaults export once the domain is healthy
  if defaults export com.apple.symbolichotkeys "$tmp.export" 2>/dev/null; then
    mv "$tmp.export" "$tmp"
  fi
  plutil -convert binary1 "$tmp" 2>/dev/null || true
  cp "$tmp" "$SYMBOLIC_GOLDEN"
  rm -f "$tmp"
  log "wrote $SYMBOLIC_GOLDEN"
}

# Build RectangleConfig.json from live defaults (same shape as app Export).
export_rectangle() {
  if ! defaults read "$RECTANGLE_DOMAIN" >/dev/null 2>&1; then
    if [[ -f "$RECTANGLE_GOLDEN" ]]; then
      log "Rectangle domain not loaded; keeping existing $RECTANGLE_GOLDEN"
      return 0
    fi
    die "Rectangle domain missing and no golden JSON present"
  fi

  python3 - "$RECTANGLE_DOMAIN" "$RECTANGLE_GOLDEN" <<'PY'
import json, plistlib, subprocess, sys

domain, out_path = sys.argv[1], sys.argv[2]
raw = subprocess.check_output(["defaults", "export", domain, "-"], stderr=subprocess.DEVNULL)
prefs = plistlib.loads(raw)

# Keys that are window actions (dict with keyCode / empty dict)
KNOWN_ACTIONS = {
    "bottomHalf", "bottomLeft", "bottomRight", "center", "centerHalf",
    "larger", "leftHalf", "maximize", "maximizeHeight", "nextDisplay",
    "previousDisplay", "reflowTodo", "restore", "rightHalf", "smaller",
    "toggleTodo", "topHalf", "topLeft", "topRight", "firstThird", "firstTwoThirds",
    "centerThird", "lastTwoThirds", "lastThird", "firstFourth", "secondFourth",
    "thirdFourth", "lastFourth", "firstThreeFourths", "lastThreeFourths",
    "topLeftSixth", "topCenterSixth", "topRightSixth", "bottomLeftSixth",
    "bottomCenterSixth", "bottomRightSixth", "specified", "specifiedWidth",
    "specifiedHeight",
}

# Skip noisy runtime-only keys
SKIP = {
    "NSStatusItem Preferred Position Item-0",
    "SULastCheckTime",
    "SUHasLaunchedBefore",
    "lastVersion",
    "internalTilingNotified",
}

def wrap(value):
    if value is None:
        return {}
    if isinstance(value, bool):
        return {"bool": value}
    if isinstance(value, int) and not isinstance(value, bool):
        return {"int": int(value)}
    if isinstance(value, float):
        return {"float": float(value)}
    if isinstance(value, str):
        return {"string": value}
    if isinstance(value, dict):
        # shortcut dict or empty
        if not value:
            return {}
        if "keyCode" in value or "modifierFlags" in value:
            return {
                k: int(v) for k, v in value.items()
                if k in ("keyCode", "modifierFlags")
            }
        return {"dict": value}
    if isinstance(value, (list, tuple)):
        return {"array": list(value)}
    return {}

defaults_out = {}
shortcuts_out = {}

for key, value in sorted(prefs.items()):
    if key in SKIP or key.startswith("NS"):
        continue
    if key in KNOWN_ACTIONS or (
        isinstance(value, dict) and ("keyCode" in value or value == {})
        and key[0].islower()
    ):
        if isinstance(value, dict) and "keyCode" in value:
            shortcuts_out[key] = {
                "keyCode": int(value["keyCode"]),
                "modifierFlags": int(value.get("modifierFlags", 0)),
            }
        # empty shortcut dicts omitted from shortcuts section
        continue
    wrapped = wrap(value)
    if wrapped == {} and value not in (None, {}, False, 0, 0.0, ""):
        continue
    defaults_out[key] = wrapped

# Also include empty disabled-action placeholders only if present as empty dicts
doc = {
    "bundleId": domain,
    "defaults": defaults_out,
    "shortcuts": shortcuts_out,
    "version": str(prefs.get("lastVersion", "")),
}

with open(out_path, "w", encoding="utf-8") as f:
    json.dump(doc, f, indent=2, ensure_ascii=False)
    f.write("\n")
print(out_path)
PY
  log "wrote $RECTANGLE_GOLDEN"
}

main() {
  export_symbolichotkeys
  export_rectangle
  log "done. commit manual/ when ready:"
  log "  git -C \"$DOTFILES\" add backup/manual && git -C \"$DOTFILES\" status"
}

main "$@"
