## Intro

Cross-platform dotfiles managed with explicit HOME links. Supports macOS (full),
Debian/Ubuntu (server), and Termux.

## Layout

```text
home/                          # cross-platform, linked into $HOME
platforms/darwin/home/         # macOS-only linked configs (Karabiner, Hammerspoon, etc.)
platforms/darwin/managed/      # macOS Preferences goldens (real files, not linked)
package-lists/                 # brew, apt, termux package lists
plugin-lists/                  # tmux/vim/zsh plugin sources
manual/                        # manually-applied overrides, kept out of the managed link domain
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

Docker Desktop's `$HOME/.docker/daemon.json` is intentionally not managed by
this repository. [Docker documents it](https://docs.docker.com/desktop/settings-and-maintenance/settings/#docker-engine)
as the Docker Engine configuration file and directs users to edit it in Docker
Desktop or a text editor. It remains a real local file because Docker Desktop
can reject a symlink during startup.

### Install packages

Package installation is explicit so linking configs never unexpectedly uses the
network or privilege escalation. The same platform/profile restrictions as
`install` apply.

```bash
./scripts/packages full --dry-run       # macOS: Homebrew formulae and casks
./scripts/packages server --dry-run     # Debian/Ubuntu: apt
./scripts/packages termux --dry-run     # Termux: pkg
./scripts/packages full
```

Every selected manifest is validated before the package manager runs. Dry-run
only prints `RUN ...` commands.

### Install plugins

Plugin repositories are grouped by host application and listed without commit
pins, so new installs use each repository's default branch. Existing targets
must be real checkouts with the expected origin; every checkout is verified with
`git fsck`.

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
| AeroSpace | leaf link | `platforms/darwin/home/.config/aerospace/` | `install` |
| Hammerspoon | leaf link | `platforms/darwin/home/.hammerspoon/init.lua` | `install` |
| lazygit (macOS path) | leaf link | `platforms/darwin/home/Library/Application Support/lazygit/config.yml` | `install` |
| System hotkeys | real plist | `platforms/darwin/managed/hotkeys/` | `scripts/hotkeys-*.sh` |
| Rectangle | real plist | `platforms/darwin/managed/hotkeys/` | `scripts/hotkeys-*.sh` |
| App Preferences | real plists | `platforms/darwin/managed/preferences/` | `scripts/prefs-*.sh` |

### Configure Amethyst (macOS only)

The Amethyst YAML configuration is maintained at
`platforms/darwin/home/.config/amethyst/amethyst.yml` and linked to
`~/.config/amethyst/amethyst.yml` by `./install full`. See Amethyst's [official
Configuration Files documentation](https://github.com/ianyh/Amethyst/blob/development/docs/configuration-files.md)
for supported locations, settings, and command syntax; the [official sample
configuration](https://github.com/ianyh/Amethyst/blob/development/.amethyst.sample.yml)
is a useful reference.

Amethyst stores GUI preferences separately, and a custom YAML configuration takes
precedence over GUI settings. Manage each setting from one source to avoid
confusing behavior, restart Amethyst after editing the YAML file, and run
`./scripts/doctor` to verify the managed link. The app's configuration-file
warning is expected whenever a custom configuration is present.

### Configure AeroSpace (macOS only)

The AeroSpace TOML configuration is maintained at
`platforms/darwin/home/.config/aerospace/aerospace.toml` and linked to
`~/.config/aerospace/aerospace.toml` by `./install full`. Changes made through the
linked file are therefore visible in Git immediately.

### Configure Hammerspoon Space controls (macOS only)

The Hammerspoon configuration is maintained at
`platforms/darwin/home/.hammerspoon/init.lua` and linked to
`~/.hammerspoon/init.lua` by `./install full`. Install Hammerspoon explicitly with
`./scripts/packages full` or `brew install --cask hammerspoon`. Launch the app,
grant it Accessibility access in System Settings, and choose `Reload Config` from
its menu bar menu after changing the configuration. See Hammerspoon's [Getting
Started guide](https://www.hammerspoon.org/go/) and [`hs.spaces` API
documentation](https://www.hammerspoon.org/docs/hs.spaces.html) for the underlying
runtime and Space operations.

The current shortcuts use **Left Command+Control+Shift** to avoid the Amethyst
bindings and the existing Karabiner Right Command layer:

| Shortcut | Action |
|----------|--------|
| `Left Command+Control+Shift+N` | Create and switch to a native Space |
| `Left Command+Control+Shift+E` | Move ordinary windows from the current Space to an adjacent Space |
| `Left Command+Control+Shift+D` twice | Switch away and delete the current native Space |
| `Left Command+Control+Shift+F` | Exit the focused application's native full-screen mode |

Hammerspoon receives Command as an aggregate modifier and cannot distinguish the
left and right Command keys itself. Use the Left Command key for these bindings;
the Right Command key remains reserved for the existing Karabiner layer.

Space operations use Hammerspoon's `hs.spaces` module and may briefly show Mission
Control. The module depends on macOS Accessibility behavior and private APIs; if
deleting a Space fails after a macOS update, use Mission Control manually rather
than closing windows blindly. Do not bind the clear action to a close-all-windows
workflow unless unsaved documents have been accounted for. `N` also works while the
focused Space is full-screen or Split View; `E` and `D` deliberately refuse those
Spaces until you press `F` or the native `Control+Command+F` shortcut first.

The clear action moves only ordinary windows that belong exclusively to the current
Space. Windows assigned to All Desktops, full-screen applications, Split View, or
other special Spaces are skipped. Deleting a Space moves its remaining windows to
another Space; it does not close those applications. The delete shortcut requires
two presses within two seconds and never removes the last regular Desktop Space.

### TCC-protected domains

`com.apple.Music.plist` may refuse `cp` (`Operation not permitted`). Grant Full
Disk Access to Terminal, or copy manually from the golden.
