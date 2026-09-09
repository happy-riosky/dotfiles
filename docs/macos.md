# macOS Application Configuration

This guide covers macOS-only application configuration for the `full` profile.
Run repository commands from the repository root. See the [README](../README.md)
for installing packages, linking configs, and installing plugins.

## Configuration Management

macOS Preferences plists are **real files**, never symlinks. Goldens live under
`platforms/darwin/managed/`. Ordinary application config files use managed links.

| Config | Runtime | Repository source | Tool |
|--------|---------|-------------------|------|
| Core (Git, SSH, tmux, Vim, shell) | leaf links | `home/` | `install` |
| Karabiner | directory link | `platforms/darwin/home/.config/karabiner/` | `install` |
| Amethyst | leaf link | `platforms/darwin/home/.config/amethyst/amethyst.yml` | `install` |
| AeroSpace | leaf link | `platforms/darwin/home/.config/aerospace/` | `install` |
| Hammerspoon | leaf link | `platforms/darwin/home/.hammerspoon/init.lua` | `install` |
| Mouseless | leaf link | `platforms/darwin/home/Library/Application Support/Mouseless/configs/config.yaml` | `install` |
| lazygit (macOS path) | leaf link | `platforms/darwin/home/Library/Application Support/lazygit/config.yml` | `install` |
| System hotkeys | real plist | `platforms/darwin/managed/hotkeys/` | `scripts/hotkeys-*.sh` |
| Rectangle | real plist | `platforms/darwin/managed/hotkeys/` | `scripts/hotkeys-*.sh` |
| App Preferences | real plists | `platforms/darwin/managed/preferences/` | `scripts/prefs-*.sh` |

## Restore Preferences

```bash
bash scripts/hotkeys-restore.sh --yes
bash scripts/prefs-restore.sh --yes
```

Backups are saved to `~/.local/state/dotfiles/`. Omit `--yes` for a confirmation
prompt.

## Export Preferences After Changes

```bash
bash scripts/hotkeys-export.sh
bash scripts/prefs-export.sh
git add platforms/darwin/managed
git commit -m "chore(macos): update preference goldens"
```

## Configure Amethyst

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

## Configure AeroSpace

The AeroSpace TOML configuration is maintained at
`platforms/darwin/home/.config/aerospace/aerospace.toml` and linked to
`~/.config/aerospace/aerospace.toml` by `./install full`. Changes made through the
linked file are therefore visible in Git immediately.

## Configure Hammerspoon Space Controls

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

## Configure Homerow

Configure activation shortcuts in Homerow's Settings. The notes below describe
upstream reports checked on **2026-09-07**, not verified settings on this machine;
the example bindings have not been applied to Homerow or Karabiner.

### Space Shortcuts Requiring Two Presses

Requiring two presses to activate Homerow is not the normal workflow or evidence
that double-tap activation was configured. [Issue #212](https://github.com/nchudleigh/homerow/issues/212),
opened on 2026-03-31, reports a regression affecting `Command+Shift+Space` in
**1.5.0-1.5.3**, with **1.4.x** working correctly:

- The first press does nothing; the second activates Homerow.
- Pressing Space alone beforehand makes the next activation work on the first try.
- After dismissing Homerow, other Space shortcuts, such as Raycast's
  `Command+Space`, can also require two presses.
- The reporter reproduced it with Karabiner and BetterTouchTool disabled; other
  users confirmed the symptoms, including on macOS Tahoe.

As of the check date, the issue remains open. The [official changelog](https://www.homerow.app/changelog)
lists **1.5.3 (2026-03-19)** as its latest entry, with no explicit fix for this bug.
These reports do not establish the cause of every local activation failure.

Reported workarounds:

1. Use a shortcut without Space, such as `Command+Shift+F`, after checking for
   conflicts. The issue author reports that this works on the first press.
2. Alternatively, disable **Automatic click**. A [user reports this workaround](https://github.com/nchudleigh/homerow/issues/212#issuecomment-4641217347),
   but each target click then needs confirmation with Space or Return.

### Multiple Shortcuts for One Mode

Separate shortcuts for different modes are not the same as multiple shortcuts
activating one mode. Native support for the latter has not been confirmed:
[issue #181](https://github.com/nchudleigh/homerow/issues/181), requesting both
`Command+Shift+J` and `Command+Shift+K` to activate scroll mode, remains open as of
the check date. The discussion recommends Karabiner as a workaround; this is
community advice, not an official statement of a product limitation.

For example, bind the desired Homerow mode to `Command+Shift+F`, then use Karabiner
to map `Left Command+Shift+Space` to that same shortcut. Both physical shortcuts
can then reach the same mode, while Homerow receives a shortcut without Space.
Use Left Command to avoid this repository's Right Command layer, check both
shortcuts for conflicts, and test both entry points on the installed version.
This combined mapping is a proposed workaround, not a locally verified fix.

## Configure Mouseless

The Mouseless YAML configuration is maintained at
`platforms/darwin/home/Library/Application Support/Mouseless/configs/config.yaml`
and linked to `~/Library/Application Support/Mouseless/configs/config.yaml` by
`./install full`. Edits through the linked file are visible in Git.

The current `mac` keymap includes:

| Shortcut | Action |
|----------|--------|
| Meh+M (`Control+Option+Shift+M`) | Toggle the overlay (`toggle overlay`) |
| `Escape` | Hide the overlay |
| Meh+F (`Control+Option+Shift+F`) | Toggle free mode (`toggle free mode`) |
| `Escape` | Exit free mode |
| `Tab` while the overlay is visible | Open the config editor |

Meh means Control+Option+Shift, without Command. The YAML binding is
`toggle overlay: ctrl+alt+shift+M` and `toggle free mode: ctrl+alt+shift+F`.
Karabiner turns a tap of Left Command into Meh+M and a tap of Left Option into
Meh+F on keyboards that are not ignored by the active Karabiner profile. Holding
either modifier still passes through the original Left Command or Left Option,
so Mouseless `hold for drag` and `hold for move` remain available. The Meh+M and
Meh+F pass-through exceptions must stay ahead of the general Control mappings.
Other Control editing shortcuts are unchanged.

Settings are also available from the Mouseless menu. Changes made in the config
editor apply immediately; save them in the editor to persist them to disk.

**After editing the YAML file externally, restart Mouseless to load the changes.**
The file is read at startup; do not rely on hot reload. A running instance and its
settings UI may still show the previous bindings even when Git shows the desired
change. See the [official configuration documentation](https://mouseless.click/docs/customizing_mouseless.html).

For manual file edits, first quit Mouseless gracefully and check that it stopped:

```bash
osascript -e 'if application "Mouseless" is running then tell application "Mouseless" to quit'
osascript -e 'application "Mouseless" is running'
```

The second command must print `false` before you edit the file. If it prints
`true`, finish any save/confirmation dialog, wait for the app to exit, and check
again. Then edit the repository YAML file or its linked HOME path and start the
app:

```bash
open -a "Mouseless"
```

Opening an already running application does not restart it. After startup, confirm
that Settings shows Control+Option+Shift+M for `toggle overlay` and
Control+Option+Shift+F for `toggle free mode`. Tap Left Command to toggle the
overlay, tap Left Option to toggle free mode on or off, and press Escape to exit
either state.
Check the saved diff and managed link separately:

```bash
git diff -- "platforms/darwin/home/Library/Application Support/Mouseless/configs/config.yaml"
./scripts/doctor
```

These repository checks do not verify which configuration the running app has
loaded. Missing or invalid YAML can make Mouseless fall back to its defaults.

## Docker Desktop

Docker Desktop's `$HOME/.docker/daemon.json` is intentionally not managed by
this repository. [Docker documents it](https://docs.docker.com/desktop/settings-and-maintenance/settings/#docker-engine)
as the Docker Engine configuration file and directs users to edit it in Docker
Desktop or a text editor. It remains a real local file because Docker Desktop
can reject a symlink during startup.

## TCC-Protected Domains

`com.apple.Music.plist` may refuse `cp` (`Operation not permitted`). Grant Full
Disk Access to Terminal, or copy manually from the golden.
