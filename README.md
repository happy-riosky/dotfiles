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
docs/                          # platform guides and application configuration notes
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

## macOS Application Configuration

See [the macOS guide](docs/macos.md) for application configuration paths,
Preferences restore/export, Amethyst, AeroSpace, Hammerspoon, Mouseless (including
restarting after configuration edits), Docker Desktop, and TCC permissions.
