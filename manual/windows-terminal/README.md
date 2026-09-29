# windows-terminal

Machine-agnostic golden copy of the Windows Terminal user `settings.json`.
Explicit keybindings and clipboard preferences are tracked; `profiles.list`
holds only the hand-written `WSL ~` profile (machine-agnostic: default distro
via `wsl.exe ~`, no hardcoded distro name). `defaultProfile`, `newTabMenu`,
`schemes`, and `themes` are deliberately omitted. The live file's remaining
profile entries are a per-machine snapshot of dynamic profiles (WSL distros,
Azure Cloud Shell) plus built-ins, all of which Terminal re-merges on its
own — so dropping them keeps the copy portable while a full-file apply stays
lossless.

Windows Terminal rewrites this file wholesale when its Settings UI saves,
and it lives outside the WSL `$HOME` link domain, so it is tracked as a
manual golden (like `platforms/darwin/managed/`), never a symlink. Not
managed by `link`/`unlink`/`doctor`.

## Keybindings of note

| Keys | Action | Notes |
| --- | --- | --- |
| `alt+[` / `alt+]` | `MoveFocusPreviousInOrder` / `MoveFocusNextInOrder` | Cycle split panes in creation order, wrapping at both ends (verified in 1.24 source; requires the `id`-style binding format) |
| `alt+d` | `splitPane` right + `commandline: wsl.exe ~` | Inline and self-contained: always a WSL pane on the right, default distro, starting at `~` — independent of the `WSL ~` profile |
| `alt+shift+d` | `DuplicatePaneAuto` | Duplicate pane, auto split direction |

The `WSL ~` profile is the dropdown counterpart: opening it as a new tab
lands in Linux `~` (unlike dynamic WSL profiles, which default to
`%USERPROFILE%` / `/mnt/c/Users/...`).

Note: on save/hot-reload Terminal normalizes inline `command` bindings into
named `User.*` actions (defined in the `actions` array, keyed by id) and may
reorder `keybindings`. Both forms are semantically identical and valid input;
this golden copy keeps the inline form for readability. An export taken from
a live file will show the normalized form — expected drift, not an error.

## Apply / export

Resolve the Store-package `LocalState` directory from Windows itself (no
hardcoded username):

```bash
la="$(powershell.exe -NoProfile -Command '$env:LOCALAPPDATA' | tr -d '\r')"
wt_dir="/mnt/$(printf %s "${la:0:1}" | tr 'A-Z' 'a-z')$(printf %s "${la:2}" | tr '\\' '/')/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState"

cp settings.json "$wt_dir/settings.json"     # apply (Terminal hot-reloads on save)
cp "$wt_dir/settings.json" settings.json     # export after changing keys via the UI
```

On apply, back up the live file first (`cp "$wt_dir/settings.json"{,.bak}`).
Hand-written profiles, if a machine ever gains any, do not survive a full-file
apply — port them manually before overwriting.
