#!/usr/bin/env bash
# Export currently-effective macOS preference domains into
# platforms/darwin/managed/preferences/ as real plists (git golden copies).
# Preference domains must NOT be mackup symlinks on modern macOS.
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/dotfiles}"
MANUAL="$DOTFILES/platforms/darwin/managed/preferences"

# Domains previously managed as mackup Preference plists (plus hotkeys/rectangle handled separately).
DOMAINS=(
  com.adobe.Photoshop
  com.apple.dt.Xcode
  com.apple.Music
  com.apple.Music.eq
  com.apple.Terminal
  com.bahoom.HyperSwitch
  com.googlecode.iterm2
  com.hegenberg.BetterTouchTool
  com.manytricks.Keymo
  edu.ucsd.cs.mmccrack.bibdesk
  fr.chachatelier.pierre.LaTeXiT
  net.matthewpalmer.Rocket
  org.vim.MacVim
)

mkdir -p "$MANUAL"

log() { printf '[prefs-export] %s\n' "$*"; }
warn() { printf '[prefs-export] WARN: %s\n' "$*" >&2; }

export_domain() {
  local domain="$1"
  local live="$HOME/Library/Preferences/${domain}.plist"
  local golden="$MANUAL/${domain}.plist"
  local tmp
  tmp="$(mktemp)"

  if defaults export "$domain" "$tmp" 2>/dev/null; then
    plutil -convert binary1 "$tmp" 2>/dev/null || true
    cp "$tmp" "$golden"
    rm -f "$tmp"
    log "exported $domain (defaults)"
    return 0
  fi

  if [[ -f "$live" && ! -L "$live" ]]; then
    cp "$live" "$tmp"
    plutil -convert binary1 "$tmp" 2>/dev/null || true
    cp "$tmp" "$golden"
    rm -f "$tmp"
    log "exported $domain (file copy)"
    return 0
  fi

  if [[ -L "$live" ]]; then
    local target
    target="$(readlink "$live")"
    if [[ -f "$target" ]]; then
      cp "$target" "$golden"
      warn "$domain is still a symlink — copied target; demote with prefs-restore.sh"
      rm -f "$tmp"
      return 0
    fi
  fi

  rm -f "$tmp"
  warn "skip $domain (domain unreadable and no live file)"
}

for d in "${DOMAINS[@]}"; do
  export_domain "$d"
done

# Global preference keys that live in .GlobalPreferences (no per-domain plist).
scroll_direction="$(defaults read -g com.apple.swipescrolldirection 2>/dev/null || true)"
case "$scroll_direction" in
  1|YES|yes|true)
    printf 'YES\n' > "$MANUAL/global-swipescrolldirection"
    log "exported global com.apple.swipescrolldirection"
    ;;
  0|NO|no|false)
    printf 'NO\n' > "$MANUAL/global-swipescrolldirection"
    log "exported global com.apple.swipescrolldirection"
    ;;
  *) warn "skip global com.apple.swipescrolldirection (unreadable)" ;;
esac

log "done → $MANUAL"
