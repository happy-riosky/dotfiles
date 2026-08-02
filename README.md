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

- Restore macOS system hotkeys + Rectangle (macOS only; after apps are installed)

```
bash ~/dotfiles/scripts/hotkeys-restore.sh
```

## Preference domains (macOS): not managed via mackup symlinks

On modern macOS, `cfprefsd` often fails to load preference **domains** when the
plist under `~/Library/Preferences/` is a **symlink** (mackup’s default model).
That is why system keyboard shortcuts and Rectangle settings looked fine in a
session and reset after reboot: the file existed, but the domain did not.

### What is managed how

| Config | Runtime (effective) | Golden copy in git | Tool |
|--------|---------------------|--------------------|------|
| Shell, editors, most app files | mackup symlink → `backup/` | mackup | `mackup backup` / `restore` |
| System keyboard shortcuts | **real** `~/Library/Preferences/com.apple.symbolichotkeys.plist` | `backup/manual/symbolichotkeys.plist` | `scripts/hotkeys-*.sh` |
| Rectangle | **real** `com.knollsoft.Rectangle` domain | `backup/manual/RectangleConfig.json` | `scripts/hotkeys-*.sh` |

`rectangle` and `macosx` are listed under `applications_to_ignore` in
`.mackup.cfg` so mackup will not re-symlink these plists.

Other MacOSX paths mackup used to link (e.g. `Library/Scripts`, `PDF Services`)
are also covered by ignoring `macosx`. Re-link them manually only if you need
them; do **not** re-link `com.apple.symbolichotkeys.plist`.

### After you change shortcuts

1. Set keys in **System Settings → Keyboard → Keyboard Shortcuts** and/or **Rectangle**.
2. Export golden copies into the repo:

```
bash ~/dotfiles/scripts/hotkeys-export.sh
git -C ~/dotfiles add backup/manual
git -C ~/dotfiles commit -m "Update hotkey golden configs"
```

### After a reboot still looks wrong, or on a new machine

```
bash ~/dotfiles/scripts/hotkeys-restore.sh
```

Then verify:

```
ls -l ~/Library/Preferences/com.apple.symbolichotkeys.plist
ls -l ~/Library/Preferences/com.knollsoft.Rectangle.plist
# both should be regular files, not "-> ..."

defaults read com.knollsoft.Rectangle leftHalf
```

No login LaunchAgent is required once preferences are real files.

### Do not

- Run `mackup restore` in a way that re-creates symlinks for Rectangle / symbolichotkeys
  (keep them in `applications_to_ignore`).
- Replace the Preferences plists with symlinks into `dotfiles/backup/` again.
