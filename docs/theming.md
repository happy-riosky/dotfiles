# Tinty 主题管理（tinted-theming）

[tinty](https://github.com/tinted-theming/tinty) 统一管理 base16/base24 配色，
一条命令同时切换 kitty、zsh（含 fzf）、tmux、nvim/vim、git-delta 的主题；
opencode/lazygit/yazi/glow/gh-dash 经 `scripts/tinty/generate` 与启动器跟随。

## 布局：受管 vs 运行时

| 路径 | 性质 |
|---|---|
| `home/.config/tinted-theming/tinty/config.toml` | 受管 leaf link（本仓库） |
| `home/.config/lazygit/{config,frappe,latte-theme}.yml`、`home/.tmux/colors/simple_batt*.tmux.conf` | 受管（lazygit 基础+overlay / tmux 布局与回退配色） |
| `home/.config/gh-dash/config.yml`、`home/.local/bin/gd` | 受管（gh-dash 主题中立基础配置 / tinty 感知启动器） |
| `home/.config/opencode/tui-plugins/tinty-theme.js`、`home/.config/opencode/themes/catppuccin-frappe-yellow.json` | 受管（实时跟随插件 / 无 tinty 回退主题） |
| `home/.vim/autoload/lightline/colorscheme/tinty.vim` | 受管（vim lightline 动态配色：tinty 调色板 / frappe 兜底双态） |
| `~/.config/opencode/themes/tinty-*.json` | tinty-theme 插件生成（每 scheme 一个），**不入库** |
| `scripts/tinty/{generate,yazi-flavor.template,yazi-tmtheme.template,glow.template,lazygit.template,gh-dash.template}` | 受管（运行时主题产物生成器与模板：yazi flavor / glow 样式 / lazygit overlay / gh-dash overlay） |
| `~/.config/yazi/flavors/tinty-{dark,light}.yazi/`、`~/.config/tinted-theming/tinty-glow.json`、`~/.config/lazygit/tinty.yml`、`~/.config/gh-dash/tinty{,-context}.yml` | 生成器输出，**不入库** |
| `platforms/darwin/home/.config/git/config` | 受管（delta pager + 主题 include，仅 macOS） |
| `home/.config/kitty/kitty.conf` 末尾 `include current-theme.conf` | 受管配置引用运行时文件 |
| `~/.config/kitty/current-theme.conf` | tinty hook 生成，**不入库** |
| `~/.local/share/tinted-theming/tinty/` | tinty 运行时（模板仓库、`current_scheme`、生成的主题文件），**不入库** |

## 安装与日常

```bash
./scripts/packages full    # 或 brew install tinted-theming/tinted/tinty
./install full             # 链接 config.toml 与 darwin git config
tinty sync                 # 首次同步：克隆 schemes 与各 [[items]] 模板仓库
tinty apply base16-catppuccin-frappe
```

| 命令 | 作用 |
|---|---|
| `tinty apply <scheme>` / `tinty cycle` | 切换 / 在 ring 中轮换（默认 frappe(深) ↔ latte(浅)）；kitty/tmux 热更新，nvim/vim 聚焦时跟随 |
| `tinty list` / `tinty info <scheme>` / `tinty gallery` | 列出 400+ scheme / 查配色明细 / 浏览器预览可直接 Apply |
| `theme` | fzf 挑选并应用（`aliases.sh` 提供，需 tinty+fzf） |
| `tinty sync` / `tinty update` | `config.toml` 变更后同步 / 更新 schemes 与模板 |

日常切换**不需要改仓库**：当前 scheme 记在运行时 `current_scheme`，`tinty
init`（每个交互式 zsh 启动）恢复。定居某个主题后，再更新 `config.toml` 的
`default-scheme` / `[[rings]]` 并提交。

## 各应用如何接线

- **kitty**：item 把主题复制到 `~/.config/kitty/current-theme.conf`
  （`kitty.conf` 末尾 include）。刷色必须 `kitten @ set-colors --all
  --configured`——reload/SIGUSR1 只热应用 fg/bg/ANSI 调色板，**不重应用
  cursor/tab bar 等 UI 色**（0.48 实测）；为此 kitty.conf 开
  `allow_remote_control socket-only` + `listen_on unix:kitty`（这两项
  reload 不生效，改动后需冷启动）。socket 不可用（如 Ghostty 内切主题）时
  hook 回退 SIGUSR1 半量重载，回 kitty 跑一次 `theme` 即全量追平。macOS
  标题栏不在 set-colors 词汇表内，靠 include 之后的
  `macos_titlebar_color background` 跟随背景（顺序颠倒会被主题文件的
  显式 hex 覆盖）。
- **zsh**：`.zshrc` 的 `dotfiles_tinty` 包装函数在 apply/init 后 source
  数据目录新生成的 `*.sh`（tinted-shell 16 色 + fzf 配色；hook 只影响
  子进程）；nvim `:terminal` 里以 `$NVIM` 判定、经不可写 TTY 静默 source
  （防 `Ptmux` 包装被渲染成乱码；非交互子命令屏蔽 stdin 防 hook 写屏；
  `tests/shell.sh` 的 `test_tinty_nvim_guard` 守护）。**启动只 source 磁盘
  产物、不跑 `tinty init`**——每个 shell 各自 init 会与 `cycle/apply` 竞态，
  迟到的 init 把旧 scheme 覆写回全局（曾实测连环闪变）；`*.sh` 全缺失才
  init 一次引导。副作用：zsh 补全不可用，需要时 `command tinty`。
- **tmux**：`simple_batt.tmux.conf` 只管布局/格式；配色先无条件 source
  `simple_batt_fallback.tmux.conf` 打底（frappe 中性面 + 黄 `#da831b`，
  消灭内建绿色状态栏的启动一闪，覆盖 server/Termux/首次 apply 前），
  tinty 生成的主题文件存在则覆盖。apply 时 hook 对运行中的 server 热加载。
- **lazygit**：基础 `config.yml` 主题中立（delta 明暗完全跟随 tinty）。
  `lg`（aliases.sh）启动前刷新 `~/.config/lazygit/tinty.yml`（generate 按
  当前 scheme 渲染，`_tinty_scheme` 标记须与 `current_scheme` 一致，防
  切换后陈旧深浅错配）；不符按 `tinty current variant` 回退
  `frappe.yml`(dark)/`latte-theme.yml`(light)，无 tinty 时统一
  `frappe.yml`（对齐 `:LazyGit` 兜底）；不经 `lg` 的裸 lazygit 用内建主题。
  macOS 经 `platform/darwin.sh` 的 `CONFIG_DIR` 统一到 `~/.config/lazygit`
  （App Support 下无重复副本）。
- **gh-dash**：`gd`（受管启动器）启动前刷新 `~/.config/gh-dash/tinty.yml`
  （标记校验同上）；GitHub repo 内改用文本拼接的 `tinty-context.yml`
  （`--config` 是单槽 override、`include:` 目标缺失会硬报错，故不走
  include）；槽位语义对齐上游 catppuccin/gh-dash（强调槽 c_emph，浅色
  退 base05）。PR/issue 正文明暗由 OSC 11 探测，tmux 内由 gd 发 pane 级
  SET/复位修正。机制与实测详见 `docs/gh-dash.md`。
- **yazi**：`[flavor] dark/light` 同指生成的 `tinty-{dark,light}`（明暗
  探测无关化）；`y` 启动前刷新。模板 base16 槽位外有语义强调槽 `c_emph`
  （浅色取 base05，防 kissa-latte 这类 base07=bright white 的白字白底）。
  无热重载，重开生效；markdown 预览同链路（glow 用生成样式、bat 用内建
  `base16-256`）。无 tinty 时生成器以仓库 catppuccin-frappe-lavender
  flavor 兜底。
- **glow**：`gl`/`glow` 启动前刷新 `~/.config/tinted-theming/tinty-glow.json`
  并做同款标记校验，**绝不渲染过期深浅**（样式刻意少即是多，无彩色
  背景块，防深浅错配刺眼）；glow 的 `-s` 只认内建样式名或 JSON 绝对路径
  （不支持 `~` 展开与命名查找），显式 `-s` 不覆盖。无生成物时 darwin 按
  macOS 外观选内建 dark/light、其余平台透传。
- **opencode**：`tinty-theme.js`（TUI 插件，必须列在 `tui.json` 的
  `plugin` 数组，无目录自动发现）读 `current_scheme` 生成
  `tinty-<system>-<slug>`（每 scheme 一个，dark/light 同值，tmux 内也
  正确）并 `theme.set`；每 3s 轮询，apply/cycle 后运行中会话即时切换。
  无 tinty 时静默回落 `catppuccin-frappe-yellow`（frappe 单色：双槽同值，
  黄 `#f9e2af` 保留，`T` 翻转明暗无视觉效果）。
- **nvim/vim**：同构接线——source 生成的 `base16-vim-colors-file.vim`
  （暴露 `g:tinted_gui*` 调色板）+ FocusGained 跟随切换；无 tinty 回退
  catppuccin-frappe。vim 的 lightline 用 `tinty` colorscheme（受管
  `tinty.vim`）动态取当前 scheme 的黄槽 gui0A 作 accent，无 tinty 时
  内置 frappe 常量兜底。
- **git-delta**：darwin 的 `~/.config/git/config`（受管）设
  `core.pager=delta` 并 include 生成的 `tinted-delta-configs-file.gitconfig`；
  目标缺失时 git 静默忽略。
- **bat**：有 tinty 时 alias `bat --theme=base16-256`（跟随终端 16 色
  调色板）；`fr` 预览里显式 `--theme` 仍优先生效。

## 服务器 / Termux

未装 tinty 时所有接线静默降级，兜底为**单一 frappe 观感**：kitty/tmux 的
include/source 缺失即忽略、git include 忽略、nvim/vim/opencode/lazygit 回退
catppuccin-frappe、zsh 守卫跳过。黄 accent 各处保留（tmux `#da831b` /
opencode `#f9e2af` / lazygit·vim `#e5c890`）；`latte-theme.yml` 属 tinty
在场时的 variant 陈旧保护，不是无 tinty 兜底；无受管资产的应用
（glow/gh-dash/kitty/bat/zsh）用内建默认。如需在 Debian/Termux 使用，手动
`cargo install tinty`（需 Rust 工具链），配置与数据路径完全一致。

## 排障

```bash
tinty config --config-path    # 确认读取的是受管 config.toml
tinty config --data-dir-path  # 运行时目录；ls 查看生成的主题文件名
```

- 改 `config.toml` 不生效 → 先 `tinty sync`。
- 主题连环闪变/被切回旧 scheme → 启动已只 source 磁盘产物；检查是否有
  东西在并发跑 `tinty init/apply`。
- kitty 没变色/光标与 tab bar 停在旧 scheme → set-colors 未走通：冷启动
  kitty（`listen_on` 等 reload 不生效，`echo $KITTY_LISTEN_ON` 应有值），
  或 kitty 内跑 `theme`/手动 `kitten @ set-colors --all --configured` 追平。
- tmux 没变色 → hook 只热加载存活的 server；新 server 由 `.tmux.conf`
  加载；手动 `tmux source-file <数据目录>/tinted-tmux-*.tmuxtheme`。
- zsh 没生效 → 新开 shell 或 `tinty init`（须经包装函数）。
- vim/lightline 没跟随 → 跟随靠 FocusGained（tmux 需 `focus-events on`，
  tmux-sensible 默认开）；SSH 裸终端无焦点事件，重开 vim 即刷新。
- lazygit 主题不对 → `tinty current variant` 确认明暗；无 tinty 统一
  frappe；裸 `lazygit` 用内建主题。
- gh dash 没跟随/正文错深浅 → 确认经 `gd` 启动；`_tinty_scheme` 标记与
  `current_scheme` 一致（不符重跑 `scripts/tinty/generate`）；详见
  `docs/gh-dash.md`。
- glow 没跟随 → 同款标记校验；显式传 `-s` 不受包装影响；`gl` 新逻辑需
  新 shell；yazi 内预览需重开 `y`。
