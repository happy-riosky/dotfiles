## Intro

Cross-platform dotfiles managed with explicit HOME links. Supports macOS (full),
Debian/Ubuntu (server), and Termux.

## Layout

```text
home/                          # cross-platform, linked into $HOME
platforms/darwin/home/         # macOS-only linked configs (Karabiner, lazygit macOS path, etc.)
platforms/darwin/managed/      # macOS Preferences goldens (real files, not linked)
package-lists/                 # brew, apt, termux package lists
plugin-lists/                  # tmux/vim/zsh plugin sources
scripts/                       # link, unlink, doctor, plugins, prefs/hotkeys
scripts/shell/                 # shared shell loader and platform/profile fragments
install                        # entry point: ./install {full|server|termux}
```

## Usage

### Link configs

```bash
./install full --dry-run       # macOS
./install full
./scripts/doctor
```

Other profiles: `./install server` (Debian/Ubuntu), `./install termux` (Termux).
Unsupported platform/profile combinations fail explicitly.

### Install plugins

Plugin repositories are grouped by host application and listed without commit
pins, so new installs use each repository's default branch.

```bash
./scripts/plugins --dry-run --app tmux
./scripts/plugins --app tmux
```

### Restore macOS Preferences (macOS only)

```bash
bash scripts/hotkeys-restore.sh --yes
bash scripts/prefs-restore.sh --yes
```

Backups are saved to `~/.local/state/dotfiles/`. Omit `--yes` for a confirmation
prompt.

### Export current Preferences after changes

```bash
bash scripts/hotkeys-export.sh
bash scripts/prefs-export.sh
git add platforms/darwin/managed
git commit -m "Update macOS preference golden configs"
```

## macOS Preferences

Preferences are **real files**, never symlinks. Goldens live under
`platforms/darwin/managed/`.

| Config | Runtime | Golden | Tool |
|--------|---------|--------|------|
| Core (Git, SSH, tmux, Vim, shell) | leaf links | `home/` | `install` |
| Karabiner | directory link | `platforms/darwin/home/.config/karabiner/` | `install` |
| lazygit (macOS path) | leaf link | `platforms/darwin/home/Library/Application Support/lazygit/config.yml` | `install` |
| System hotkeys | real plist | `platforms/darwin/managed/hotkeys/` | `scripts/hotkeys-*.sh` |
| Rectangle | real plist | `platforms/darwin/managed/hotkeys/` | `scripts/hotkeys-*.sh` |
| App Preferences | real plists | `platforms/darwin/managed/preferences/` | `scripts/prefs-*.sh` |

### TCC-protected domains

`com.apple.Music.plist` may refuse `cp` (`Operation not permitted`). Grant Full
Disk Access to Terminal, or copy manually from the golden.
