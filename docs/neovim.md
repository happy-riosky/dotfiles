# Neovim

## Managed Files

`home/.config/nvim/` mirrors `~/.config/nvim/`. The installer creates individual
file symlinks; the configuration directory and its subdirectories remain real
directories.

- `init.lua`: current Kickstart-based configuration, including Diffview setup and mappings.
- `lua/`: Kickstart health check, optional plugin examples, and the custom plugin loader.
- `nvim-pack-lock.json`: plugin sources and pinned revisions, kept in version control.
- `.stylua.toml`: Lua formatting settings.
- `doc/kickstart.txt`: upstream help; generate the local index with `:helptags ~/.config/nvim/doc`.

Optional plugin examples remain disabled; the custom loader
(`require 'custom.plugins'` in `init.lua`) is enabled and loads every
`lua/custom/plugins/*.lua` (currently neo-tree). The upstream Git checkout,
GitHub templates/workflows, generated `doc/tags`, and upstream `.gitignore`
are not managed. The latter ignores the lockfile, which is useful to retain
in a personal configuration.

Based on [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim); the original
MIT notice is preserved in [third-party/kickstart-MIT.md](third-party/kickstart-MIT.md).

## Setup

This configuration requires Neovim 0.12 or newer for the built-in `vim.pack`
plugin manager. Install Neovim separately; the existing package manifests do not
install it. Plugin/tool installation also uses Git, make, a C compiler, unzip,
curl, ripgrep, fd, and the tree-sitter CLI. Clipboard integration needs a suitable
platform clipboard provider. A Nerd Font is enabled
(`vim.g.have_nerd_font = true`); kitty is configured to use
`FiraCode Nerd Font Mono`, so install that font (or change both) on each machine.

Before linking on a machine with an existing configuration, quit Neovim and move
that configuration to a backup outside the managed source tree. The installer
deliberately refuses to replace existing unmanaged files.

Run these commands from the dotfiles repository on macOS:

```sh
./install full --dry-run
./install full
./scripts/doctor
nvim
```

Use `server` on Debian/Ubuntu or `termux` on Termux instead of `full`, and ensure
Neovim meets the version requirement on each machine. The standard config path
assumes `XDG_CONFIG_HOME` and `NVIM_APPNAME` are unset.

## Theme

The colorscheme is the official `catppuccin/nvim` plugin with the `frappe`
(dark) flavour and no custom highlights. Syntax, diagnostics, UI, and Git
diff colors all use Catppuccin's official palette, and comments are italic
(official default). The Vim configuration keeps its custom Latte Yellow scheme
on purpose; the two editors are no longer visually matched.

Telescope, Blink completion, Diffview, mini.statusline, Gitsigns, Mason,
Fidget, which-key, and neo-tree integrations are enabled explicitly (note:
catppuccin's integration key is `neotree`, not `neo_tree`). Restart Neovim
after changing the setup. Once loaded, `:colorscheme catppuccin-frappe`
reapplies the configuration as well.

## File Tree

neo-tree is the file explorer, configured in
`lua/custom/plugins/neo-tree.lua`. `<leader>e` reveals the current file in it and
also closes it from inside the tree. In the tree:

- `/` fuzzy-filters the tree as you type while keeping the directory structure
  of the matches; `<C-n>`/`<C-p>` move through results, `<CR>` opens,
  `<C-x>` clears the filter, and `H` toggles hidden/filtered items.
- `f` filters on submit and keeps the tree filtered; `D` fuzzy-finds
  directories only.

Dotfiles and gitignored files are shown (`filtered_items`). Folder, file, and
Git icons come from the Nerd Font: mini.icons (enabled by
`vim.g.have_nerd_font`) mocks `nvim-web-devicons` for neo-tree and Telescope.

## Maintenance

Edit `~/dotfiles/home/.config/nvim/init.lua` (or its linked HOME path).
Neovim plugins are managed by `vim.pack`, not `scripts/plugins`.

- Inspect plugin state without fetching: `:lua vim.pack.update(nil, { offline = true })`.
- Fetch plugin updates: `:lua vim.pack.update()`; `:write` applies updates and `:quit` cancels.
- Review changes to `nvim-pack-lock.json` alongside configuration changes.
- Check prerequisites: `:checkhealth kickstart`.

On a fresh setup, startup can download plugins, Mason tools, and Treesitter
parsers. Existing plugin checkouts, Mason installations, parsers, state, and
caches stay in Neovim's data/state/cache directories outside dotfiles. Migration
does not delete or reinstall them. Keep backup directories outside `home/` and
`platforms/*/home/`, since even Git-ignored files there are considered for linking.
