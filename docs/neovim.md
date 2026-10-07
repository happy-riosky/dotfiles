# Neovim

## 受管文件

`home/.config/nvim/` 镜像 `~/.config/nvim/`。安装器创建逐文件软链接；配置目录
及其子目录保持为真实目录。

- `init.lua`：当前基于 Kickstart 的配置，含 Diffview 设置与映射。
- `lua/`：Kickstart 健康检查、可选插件示例与自定义插件加载器。
- `nvim-pack-lock.json`：插件来源与固定 revision，纳入版本控制。
- `.stylua.toml`：Lua 格式化设置。
- `doc/kickstart.txt`：上游帮助；用 `:helptags ~/.config/nvim/doc` 生成本地
  索引。

可选插件示例保持禁用；自定义加载器（`init.lua` 中的
`require 'custom.plugins'`）已启用，加载每个 `lua/custom/plugins/*.lua`
（aerial、flash、lazygit、neo-tree、oil、render-markdown、toggleterm；
`<leader>tt` 经 toggleterm.nvim 开关浮动终端，与 `<leader>gg` 的 lazygit 浮窗
相互独立）。上游 Git 检出、GitHub templates/workflows、生成的 `doc/tags` 与
上游 `.gitignore` 不受管。后者忽略 lockfile，而个人配置中保留它是有用的。

基于 [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim)；原 MIT 声明
保留在 [third-party/kickstart-MIT.md](third-party/kickstart-MIT.md)。

## 安装

本配置需要 Neovim 0.12 或更新版本（内建 `vim.pack` 插件管理器）。Neovim 需另行
安装；现有包清单不安装它。插件/工具安装还会用到 Git、make、C 编译器、unzip、
curl、ripgrep、fd 与 tree-sitter CLI。剪贴板集成需要合适的平台剪贴板 provider。
已启用 Nerd Font（`vim.g.have_nerd_font = true`）；kitty 配置使用
`FiraCode Nerd Font Mono`，请在每台机器安装该字体（或两处一起改）。

在已有配置的机器上链接前，先退出 Neovim，并把旧配置移到受管源树之外的备份
位置。安装器刻意拒绝替换已存在的未受管文件。

在 macOS 上从 dotfiles 仓库执行：

```sh
./install full --dry-run
./install full
./scripts/doctor
nvim
```

Debian/Ubuntu 用 `server`、Termux 用 `termux` 代替 `full`，并确认每台机器上的
Neovim 满足版本要求。标准配置路径假定 `XDG_CONFIG_HOME` 与 `NVIM_APPNAME` 均
未设置。

## 主题

colorscheme 是官方 `catppuccin/nvim` 插件，`frappe`（深色）flavour，无自定义
highlight。语法、诊断、UI 与 Git diff 颜色全部使用 Catppuccin 官方调色板，
注释为斜体（官方默认）。Vim 配置刻意保留自定义的 Latte Yellow 方案；两个
编辑器不再视觉对齐。

Telescope、Blink 补全、Diffview、mini.statusline、Gitsigns、Mason、Fidget、
which-key 与 neo-tree 集成均已显式启用（注意：catppuccin 的集成键名是
`neotree`，不是 `neo_tree`）。修改 setup 后重启 Neovim。加载后执行
`:colorscheme catppuccin-frappe` 也会重新应用配置。

## 文件树

neo-tree 是文件浏览器，配置在 `lua/custom/plugins/neo-tree.lua`。`<leader>e`
在树中定位当前文件，在树内再按一次则关闭树。在树内：

- `/` 边输入边模糊过滤树，同时保留匹配项的目录结构；`<C-n>`/`<C-p>` 在结果间
  移动，`<CR>` 打开，`<C-x>` 清除过滤，`H` 切换隐藏/被过滤项。
- `f` 提交时过滤并保持树的过滤状态；`D` 仅模糊查找目录。

点文件与 gitignore 的文件默认显示（`filtered_items`）。目录、文件与 Git 图标
来自 Nerd Font：mini.icons（由 `vim.g.have_nerd_font` 启用）为 neo-tree 与
Telescope mock 了 `nvim-web-devicons`。

## 目录编辑（oil.nvim）

[oil.nvim](https://github.com/stevearc/oil.nvim) 把目录当作 buffer 来编辑，
配置在 `lua/custom/plugins/oil.lua`。它与 neo-tree 互补：树导航用 neo-tree
（`<leader>e`），批量文件操作用 oil。

- `-` 打开当前文件所在目录（`:Oil`）。
- 通过编辑行来重命名/移动/创建/删除条目（含跨目录的路径），再 `:w` 一次性应用
  全部修改。
- 显示隐藏文件（`view_options.show_hidden`）；`g.` 切换显示，`<C-p>` 预览光标
  下文件（oil 默认）。完整键位见 `:h oil` 与 oil buffer 内的 `g?`。

## LazyGit 集成

`lua/custom/plugins/lazygit.lua` 在 PATH 上有二进制时于浮窗中运行
[lazygit](https://github.com/jesseduffield/lazygit)；没有它的机器（例如
`server` profile）只会收到警告。

- `<leader>gg` 或 `:LazyGit [args]` 开关浮窗，以当前文件所在仓库根为工作
  目录；在 lazygit 内或 normal 模式下按 `q` 关闭。
- `:LazyGitConfig` 编辑受管的 lazygit 配置。
- 共享 lazygit 配置设置了 `os.editPreset: nvim-remote`，在 lazygit 中对文件按
  `e` 会在本 Neovim 实例的新 tab 中打开——包括从 staging 面板的行跳转——并
  关闭浮窗。lazygit 运行在 Neovim 之外时，`e` 回退为新的 `nvim` 进程；`o`
  仍用系统默认应用打开文件。
- 浮窗运行 lazygit 时 `LG_CONFIG_FILE` 指向基础配置加 `frappe.yml` 片段，
  TUI 从终端的 Latte 主题切换到与 Neovim 匹配的 catppuccin frappe（黄色
  accent），delta 渲染无需 `--light`。独立运行的 lazygit 保持 Latte 基础
  配置。
- lazygit 配置是单一受管文件：macOS 以其原生路径
  `~/Library/Application Support/lazygit/config.yml` 读取，该路径链接到其他
  平台使用的同一个 `home/.config/lazygit/config.yml`。

已知限制：lazygit 相对仓库根解析被编辑的路径，跨仓库工作时保持 Neovim 工作
目录在仓库根；该 preset 的"编辑并等待"路径上游不支持 remote，阻塞等待编辑器的
工具（如经 `core.editor` 编辑提交信息）会另起进程。

## 光标跳转（flash.nvim）

[flash.nvim](https://github.com/folke/flash.nvim) 提供带标签的跳转 motion，
配置在 `lua/custom/plugins/flash.lua`。它是 Vim 配置中 vim-easymotion 的
Neovim 对应物。

- `s`：输入任意字符，再按标签字符跳到匹配处。
- `<leader>f`：Treesitter 节点选择——为光标周围的语法节点打标签；选一个即
  选中其范围（可与 `d`/`y` 等 operator 配合）。
- `<leader>h` / `<leader>l`：跳到光标上方 / 下方的词首（easymotion 的 `b` /
  `w`）。
- `<leader>j` / `<leader>k`：跳到光标下方 / 上方的行首（easymotion 的 `j` /
  `k`）；标签放在第零列。
- `f`、`t`、`F`、`T` 走 flash 的 char 模式：用同一个键重复 motion，或用 `;` /
  `,` 跳下一个 / 上一个匹配。

裸键 `s` 与 `<leader>h` 和既有前缀共存：mini.surround 序列（`sa`、`sd`、
`sr` …）与 gitsigns 的 `<leader>h*` hunk 映射先解析，裸键在 `timeoutlen` 之后
才打开 flash。标签只有小写：`<leader>h/j/k/l` 目标是两字母标签（第一个字母选
组，第二个跳转），`s` 通过继续输入 pattern 字符收窄范围。buffer 格式化从
`<leader>f` 移到了 `<leader>cf`（which-key 的 `[C]ode` 组），把 `<leader>f`
让给 Treesitter 选择。

## 维护

编辑 `~/dotfiles/home/.config/nvim/init.lua`（或其链接的 HOME 路径）。Neovim
插件由 `vim.pack` 管理，不走 `scripts/plugins`。

- 不拉取查看插件状态：`:lua vim.pack.update(nil, { offline = true })`。
- 拉取插件更新：`:lua vim.pack.update()`；`:write` 应用更新，`:quit` 取消。
- 与配置改动一起复查 `nvim-pack-lock.json` 的变化。
- 检查前置条件：`:checkhealth kickstart`。
- 移除插件：删除其 `vim.pack.add` 行（只停止加载）**并且**执行
  `:lua vim.pack.del({ 'name' })`——它同时删除
  `~/.local/share/nvim/site/pack/core/opt/` 下的磁盘克隆与 lockfile 条目。
  仅用 git 回退 `nvim-pack-lock.json` 不够：只要克隆还在磁盘上，启动时的
  lock-repair 会自动补回条目（陈旧的 `minuet-ai.nvim`，2026-09-30）。安装状态
  按机器隔离；每台机器都要执行 `vim.pack.del`。

全新安装时，启动可能下载插件、Mason 工具与 Treesitter parser。既有的插件
检出、Mason 安装、parser、state 与 cache 都留在 dotfiles 之外的 Neovim
data/state/cache 目录。迁移不会删除或重装它们。备份目录请放在 `home/` 与
`platforms/*/home/` 之外，因为那里即使被 Git 忽略的文件也会参与链接。
