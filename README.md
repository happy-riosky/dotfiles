## Intro

This repository is migrating from Mackup to explicit, cross-platform HOME links.

> Migration in progress: follow [`MIGRATION_PLAN.md`](MIGRATION_PLAN.md). The old
> `setup` and plugin installer scripts are disabled until the new `./install`
> migration is complete.

## Usage

### Set up the environment

- Preview or link the supported macOS core profile:

```bash
./install full --dry-run
./install full
./scripts/doctor
```

- Other first-release profiles are `./install server` on Debian/Ubuntu and
  `./install termux` in Termux. Unsupported platform/profile combinations fail.

- Install fixed-commit tmux and Vim plugins when a checkout is missing:

```bash
./scripts/plugins --dry-run --group core
./scripts/plugins --group core
```

- Restore macOS preference domains (macOS only; after apps are installed)

```
bash ~/dotfiles/scripts/hotkeys-restore.sh
bash ~/dotfiles/scripts/prefs-restore.sh
```

## Legacy Preference Notes

The section below describes the previous Mackup behavior. Current golden files
live under `platforms/darwin/managed/`; the export and restore scripts use that
directory directly.

### Preference domains (macOS): not managed via mackup symlinks

On modern macOS, `cfprefsd` often fails to load preference **domains** when the
plist under `~/Library/Preferences/` is a **symlink** (mackup’s default model).
The file can exist, but the domain does not load after reboot.

### What is managed how

| Config | Runtime (effective) | Golden copy in git | Tool |
|--------|---------------------|--------------------|------|
| Core Git, SSH, tmux and Vim files | leaf links into `home/` | `home/` | `install` / `scripts/link` |
| Shell and Karabiner (transitional) | links into `backup/` | `backup/` | Phase 2/3 migration |
| System keyboard shortcuts | **real** `com.apple.symbolichotkeys` | `platforms/darwin/managed/hotkeys/symbolichotkeys.plist` | `scripts/hotkeys-*.sh` |
| Rectangle | **real** `com.knollsoft.Rectangle` | `platforms/darwin/managed/hotkeys/RectangleConfig.json` | `scripts/hotkeys-*.sh` |
| Other app Preferences plists | **real** files under `~/Library/Preferences/` | `platforms/darwin/managed/preferences/*.plist` | `scripts/prefs-*.sh` |

Custom mackup app definitions live in `dotfiles/.mackup/` (linked to `~/.mackup`).
Pure Preference-only apps are listed under `applications_to_ignore` in `.mackup.cfg`.

### After you change shortcuts or app prefs

```
bash ~/dotfiles/scripts/hotkeys-export.sh
bash ~/dotfiles/scripts/prefs-export.sh
git -C ~/dotfiles add platforms/darwin/managed
git -C ~/dotfiles commit -m "Update macOS preference golden configs"
```

### After a reboot looks wrong, or on a new machine

```
bash ~/dotfiles/scripts/hotkeys-restore.sh
bash ~/dotfiles/scripts/prefs-restore.sh
```

Verify domains are real files and readable:

```
ls -l ~/Library/Preferences/com.apple.symbolichotkeys.plist
ls -l ~/Library/Preferences/com.knollsoft.Rectangle.plist
# should be regular files, not "-> ..."

defaults read com.knollsoft.Rectangle leftHalf
defaults read com.googlecode.iterm2 | head
```

### Apple Music note

`com.apple.Music.plist` is TCC-protected on some systems (`Operation not permitted`
when replacing an old Mackup symlink). Golden copy is in
`platforms/darwin/managed/preferences/com.apple.Music.plist`. To demote it:

1. Grant **Full Disk Access** to Terminal (or iTerm), then re-run `prefs-restore.sh`, or
2. Manually remove the symlink in Finder and copy the golden file.

### Do not

- Let `mackup restore` re-create Preference symlinks for ignored / overridden apps.
- Replace Preference plists with symlinks into `dotfiles/backup/` again.
