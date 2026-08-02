## Intro

This repo contains the way that I manage my dotfiles with the help of [`mackup`](https://github.com/lra/mackup).

## Usage

### Set up the environment

- Set up the basics

```
cd ~ && git clone https://github.com/happy-riosky/dotfiles
bash ~/dotfiles/setup
```

- Set up `oh-my-zsh`, `tmux`, `vim`

```
bash scripts/oh-my-zsh.sh
bash scripts/tmux.sh
bash scripts/vim.sh
```

- Restore macOS preference domains (macOS only; after apps are installed)

```
bash ~/dotfiles/scripts/hotkeys-restore.sh
bash ~/dotfiles/scripts/prefs-restore.sh
```

## Preference domains (macOS): not managed via mackup symlinks

On modern macOS, `cfprefsd` often fails to load preference **domains** when the
plist under `~/Library/Preferences/` is a **symlink** (mackup’s default model).
The file can exist, but the domain does not load after reboot.

### What is managed how

| Config | Runtime (effective) | Golden copy in git | Tool |
|--------|---------------------|--------------------|------|
| Shell, editors, most app files | mackup symlink → `backup/` | mackup | `mackup backup` / `restore` |
| System keyboard shortcuts | **real** `com.apple.symbolichotkeys` | `backup/manual/symbolichotkeys.plist` | `scripts/hotkeys-*.sh` |
| Rectangle | **real** `com.knollsoft.Rectangle` | `backup/manual/RectangleConfig.json` | `scripts/hotkeys-*.sh` |
| Other app Preferences plists | **real** files under `~/Library/Preferences/` | `backup/manual/prefs/*.plist` | `scripts/prefs-*.sh` |
| Hybrid apps (iTerm2, BibDesk, Rocket, Xcode, BTT, Photoshop) | App Support / XDG still mackup; Preferences real | `~/.mackup/*.cfg` overrides drop Preference paths | mackup + prefs scripts |

Custom mackup app definitions live in `dotfiles/.mackup/` (linked to `~/.mackup`).
Pure Preference-only apps are listed under `applications_to_ignore` in `.mackup.cfg`.

### After you change shortcuts or app prefs

```
bash ~/dotfiles/scripts/hotkeys-export.sh
bash ~/dotfiles/scripts/prefs-export.sh
git -C ~/dotfiles add backup/manual
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
when unlinking the mackup symlink). Golden copy is still in
`backup/manual/prefs/com.apple.Music.plist`. To demote it:

1. Grant **Full Disk Access** to Terminal (or iTerm), then re-run `prefs-restore.sh`, or
2. Manually remove the symlink in Finder and copy the golden file.

### Do not

- Let `mackup restore` re-create Preference symlinks for ignored / overridden apps.
- Replace Preference plists with symlinks into `dotfiles/backup/` again.
