# Tinty 主题管理（tinted-theming）

[tinty](https://github.com/tinted-theming/tinty) 统一管理 base16/base24 配色，
一条命令同时切换 kitty、zsh（含 fzf）、tmux、nvim、git-delta 的主题。

## 布局：受管 vs 运行时

| 路径 | 性质 |
|---|---|
| `home/.config/tinted-theming/tinty/config.toml` | 受管 leaf link（本仓库） |
| `home/.config/lazygit/{config,frappe,latte-theme}.yml`、`home/.tmux/colors/simple_batt*.tmux.conf` | 受管（lazygit 基础+overlay / tmux 布局与回退配色） |
| `home/.config/opencode/tui-plugins/tinty-theme.js`、`home/.config/opencode/themes/catppuccin-yellow.json` | 受管（实时跟随插件 / 无 tinty 回退主题） |
| `~/.config/opencode/themes/tinty-*.json` | tinty-theme 插件生成（每 scheme 一个），**不入库** |
| `scripts/tinty-yazi-flavor{,.template,.tmtheme.template,.glow.template}` | 受管（yazi flavor / glow 样式生成器与模板） |
| `~/.config/yazi/flavors/tinty-{dark,light}.yazi/`、`~/.config/tinted-theming/tinty-glow.json` | 生成器输出，**不入库** |
| `platforms/darwin/home/.config/git/config` | 受管（delta pager + 主题 include，仅 macOS） |
| `home/.config/kitty/kitty.conf` 末尾 `include current-theme.conf` | 受管配置引用运行时文件 |
| `~/.config/kitty/current-theme.conf` | tinty hook 生成，**不入库** |
| `~/.local/share/tinted-theming/tinty/` | tinty 运行时（模板仓库、`current_scheme`、生成的主题文件），**不入库** |

## 安装（macOS/full）

```bash
./scripts/packages full    # 或 brew install tinted-theming/tinted/tinty
./install full             # 链接 config.toml 与 darwin git config
tinty sync                 # 首次同步：克隆 schemes 与各 [[items]] 模板仓库
tinty apply base16-catppuccin-frappe
```

日常切换主题**不需要改仓库**：当前 scheme 记在运行时 `current_scheme` 文件里，
`tinty init`（每个交互式 zsh 启动时自动执行）会恢复。定居某个主题后，再更新
`config.toml` 的 `default-scheme` / `[[rings]]` 并提交。

## 日常使用

| 命令 | 作用 |
|---|---|
| `tinty apply base16-gruvbox-dark-soft` | 切换主题；kitty/tmux 热更新，nvim 聚焦时跟随 |
| `tinty cycle` | 在 ring 中切下一个（默认 frappe(深) ↔ latte(浅)） |
| `tinty list` / `tinty info <scheme>` | 列出 400+ scheme / 查看配色明细 |
| `tinty gallery` | 浏览器交互预览，可直接点击 Apply（`--no-rc` 静态浏览） |
| `theme` | fzf 挑选并应用（`aliases.sh` 提供，需 tinty+fzf） |
| `tinty sync` / `tinty update` | `config.toml` 变更后同步 / 更新 schemes 与模板 |

## 各应用如何接线

- **kitty**：`kitty` item 把主题复制到 `~/.config/kitty/current-theme.conf` 并在
  apply 时 `pkill -USR1 -x kitty` 热重载；`kitty.conf` 末尾
  `include current-theme.conf`（相对 include 按软链接所在目录解析；文件缺失时
  kitty 仅告警并忽略）。
- **zsh**：`.zshrc` 的 `dotfiles_tinty` 包装函数在 `tinty apply/init` 后 source
  数据目录里新生成的 `*.sh`（tinted-shell 16 色 + tinted-fzf 配色），因为 tinty
  的 hook 在子进程中无法改动当前 shell 环境；`alias tinty=dotfiles_tinty`。
  副作用：tinty 的 zsh 补全不可用（需要时用 `command tinty` 调真二进制）。
- **tmux**：`simple_batt.tmux.conf` 只管布局/格式（电池/时间/窗口标签）；
  配色由 `.tmux.conf` 的同步 `if-shell` 二选一——tinty 生成的主题文件存在
  则用 scheme 配色，否则回退 `simple_batt_fallback.tmux.conf`（手工配色，
  server/Termux/首次 apply 前）。apply 时 hook 对运行中的 server 热加载。
- **lazygit**：基础 `config.yml` 主题中立（diffRenderers/pager 不带
  `--light`/`--dark`，delta 明暗完全跟随 tinty）；`lg`（aliases.sh 函数）
  与 nvim `:LazyGit` 按 `tinty current variant` 经 `LG_CONFIG_FILE` 叠加
  `frappe.yml`（dark）/ `latte-theme.yml`（light）UI overlay。无 tinty 时
  裸 lazygit 用内建主题；macOS 由 `platform/darwin.sh` 导出 `CONFIG_DIR`
  统一到 `~/.config/lazygit`（App Support 下不再有重复副本）。
- **yazi**：`[flavor] dark/light` 指向运行时 flavor `tinty-dark/tinty-light`
  （两份同内容，明暗探测结果无关化）；`y`（aliases.sh 函数）启动前调用
  `scripts/tinty-yazi-flavor` 按当前 scheme 渲染
  `~/.config/yazi/flavors/tinty-{dark,light}.yazi/{flavor.toml,tmtheme.xml}`
  （模板为 lavender flavor 参数化 + 简版 16 色 tmtheme，预览高亮跟随）。
  yazi **无 theme 热重载**，切 scheme 后重新打开即生效。markdown 预览
  （`md-preview.sh`，经 piper 调 bat+glow）同样跟随 tinty：glow 用生成的
  `tinty-glow.json`（见下，含新鲜度校验），bat 用内建 `base16-256`。
  无 tinty 时生成器以仓库 catppuccin-frappe-lavender flavor 兜底，glow/bat
  回退内建样式（yazi 仅在 macOS 安装，无服务器场景）。`theme.toml` 仅保留
  无色覆盖（indicator padding/status 分隔符），有色覆盖在模板内用 base 槽位。
- **glow**：`gl`/`glow`（aliases.sh 函数）启动前调用 `scripts/tinty-yazi-flavor`
  刷新 `~/.config/tinted-theming/tinty-glow.json`（glamour 样式 JSON，hex
  真彩；样式刻意「少即是多」：无彩色背景块，避免深浅错配时刺眼）。仅当文件
  内 `_tinty_scheme` 标记与 `current_scheme` 一致才使用（`-s` 显式传绝对
  路径——glow 的 `-s` 只认内建样式名或 JSON 文件**绝对路径**，不支持 `~`
  展开与命名样式查找——并设 `GLAMOUR_STYLE` 覆盖 TUI 模式）；标记不匹配
  （切换 scheme 后生成失败/残留过期文件）回退内建样式，**绝不渲染过期深浅**。
  显式传 `-s` 时不覆盖；无生成物时 darwin 按 macOS 外观选内建 dark/light、
  其余平台透传（yazi 预览走同一回退链）。
- **opencode**：`tui-plugins/tinty-theme.js`（TUI 插件，在 `tui.json` 的
  `plugin` 数组声明——TUI 插件必须列在 tui.json，无目录自动发现）跟随
  tinty 实时换肤：读取 `current_scheme` 与 scheme YAML，把 base16/base24
  调色板转换为 `tinty-<system>-<slug>` 主题（每个 scheme 一个文件，调色板
  不可变故幂等覆写；dark/light 同值，模式探测不再起作用，tmux 内也
  正确）并 `theme.set`；每 3s 轮询，`tinty apply`/`cycle` 后正在运行的
  会话即时切换、无需重启。无 tinty 时插件静默不动作，回落到
  `tui.json` 指定的 `catppuccin-yellow`（合并深/浅主题，`T` vim-normal 可
  手动翻转明暗，`<leader>t` 切换主题）。生成的
  `~/.config/opencode/themes/tinty-*.json` 为运行时产物，绝不入库；
  `mocha/latte-yellow` 单色主题保留可随时选回。
- **nvim/vim**：`init.lua` source `base16-vim-colors-file.vim` 并在 FocusGained
  时跟随切换；无该文件（未装 tinty 的机器）回退 catppuccin-frappe。
- **git-delta**：darwin 的 `~/.config/git/config`（受管）设 `core.pager=delta`
  并 include 生成的 `tinted-delta-configs-file.gitconfig`；include 目标缺失时
  git 静默忽略。
- **bat**：`aliases.sh` 在有 tinty 时提供 `bat --theme=base16-256`（跟随终端
  16 色调色板）；`fr` 预览里显式 `--theme` 仍优先生效。

## 服务器 / Termux

未装 tinty 时所有接线静默降级：kitty/tmux 的 include/source 缺失即忽略、git
include 忽略、nvim 回退 catppuccin、zsh 守卫跳过。如需在 Debian/Termux 使用，
手动 `cargo install tinty`（需 Rust 工具链），配置与数据路径完全一致。

## 排障

```bash
tinty config --config-path    # 确认读取的是受管 config.toml
tinty config --data-dir-path  # 运行时目录；ls 查看生成的主题文件名
```

- 改了 `config.toml` 不生效 → 先 `tinty sync`。
- kitty 没变色 → 确认 `~/.config/kitty/current-theme.conf` 存在，重开 kitty
  或 `Ctrl+Shift+F5` 重载配置。
- tmux 没变色 → hook 只在 tmux server 存在时热加载；新 server 由 `.tmux.conf`
  启动加载；手动 `tmux source-file <数据目录>/tinted-tmux-*.tmuxtheme`。
- 主题在 zsh 没生效 → 当前会话须通过包装函数执行（新开 shell 或
  `tinty init`）。
- lazygit 主题不对 → `tinty current variant` 确认明暗；`lg`/`:LazyGit`
  按 variant 选 overlay，裸 `lazygit` 用内建主题。
- glow 没跟随 → 确认 `~/.config/tinted-theming/tinty-glow.json` 存在、其中
  `_tinty_scheme` 与 `current_scheme` 一致（不一致属回退保护，重跑
  `scripts/tinty-yazi-flavor` 看报错）；显式传了 `-s` 的调用不受包装影响；
  `gl` 的新逻辑需新 shell 加载；yazi 内预览需重开 `y`。
