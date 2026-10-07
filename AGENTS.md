# AGENTS.md

个人跨平台 dotfiles 仓库，用显式 HOME 软链接管理配置。仅支持 macOS（`full`）、
Debian/Ubuntu（`server`）、WSL Debian/Ubuntu（复用 `server`）、Termux
（`termux`）——其他组合必须明确报错，绝不静默回退到其他 profile。

## 布局

```text
home/                          # 跨平台，链接到 $HOME
platforms/<platform>/home/     # 平台专属可链接配置
platforms/darwin/managed/      # macOS Preferences 黄金文件（真实文件，绝不链接）
package-lists/                 # brew/apt/termux 包名
plugin-lists/                  # tmux/vim/zsh 插件 TARGET+REPO（不锁 commit）
manual/                        # 手动应用的覆盖配置与脚本（不链接，不受 link/unlink/doctor 管理）
scripts/shell/                 # core + aliases + platform/ + profiles/ 加载片段，load.zsh/load.bash
install                        # 入口：./install {full|server|termux} [--dry-run]
tests/                         # link.sh, shell.sh, vim.sh
docs/                          # 文档，索引见 docs/README.md（平台指南/应用专题/参考/归档）
```

## 命令

| 命令 | 用途 |
|---|---|
| `./install {full\|server\|termux} [--dry-run]` | 校验平台/profile，运行 `scripts/link` |
| `scripts/packages {full\|server\|termux} [--dry-run]` | 校验平台/profile，从对应清单安装包 |
| `scripts/link [--dry-run]` | 创建受管软链接（direct 或 Stow 后端） |
| `scripts/unlink [--dry-run]` | 只移除指向本仓库的链接 |
| `scripts/doctor` | 校验链接、秘密卫生、Preferences |
| `scripts/plugins [--dry-run] [--app tmux\|vim\|zsh]` | 从 `plugin-lists/*.txt` 克隆插件 |
| `scripts/termux-zvm-fix [--dry-run]` | Termux：应用 zsh-vi-mode 光标兼容补丁 |
| `scripts/{prefs,hotkeys}-{restore,export}.sh [--yes]` | macOS：恢复/导出偏好与快捷键 |

仅支持组合：`darwin:full`、`linux:server`（Debian/Ubuntu）、
`wsl:server`（Debian/Ubuntu，复用 server 基础设施）、`termux:termux`。

## 不变量（不可破坏；由 link/doctor/tests 强制）

- **绝不覆盖未受管目标**。`link` 在 `$HOME/$rel` 已存在且不指向本仓库时中止；
  `unlink` 绝不删除未知文件。
- **`--dry-run` 零副作用**：不创建目录、链接、克隆或写入。
- **共享 `home/` 与平台 `home/` 不得提供相同目标**（`check_source_collisions` 报错）。
- **macOS Preferences 是真实文件，绝非软链接**。黄金文件位于
  `platforms/darwin/managed/`，经备份 + `defaults import` 恢复（含 `cfprefsd`
  刷新、失败回滚）。TCC 保护域（如 `com.apple.Music`）可能拒绝 `cp`——
  授予完全磁盘访问，不要强行处理。
- **Karabiner 是目录链接**；仅 `direct` 后端可用，Stow 必须拒绝。
- **公开树中不得有秘密/主机专属配置**：不提交 `.netrc`、`auth.json`、
  `*license*`、SSH host 条目、token 或本地身份。私有覆盖放
  `~/.config/git/config.local`、`~/.ssh/config.d/*.conf`、`~/.zshenv.{host,local}`、
  `~/.bashrc.{host,local}`；公开 `.gitconfig`/`.ssh/config` 只 include 它们。
- **共享 shell 代码中不得有主机专属路径**：`/Users/riosky`、`/home/riosky`、
  `/mnt/c`、代理、启动时 `tmux attach|new-session` 会被 `tests/shell.sh` 判定失败。
- **非交互 shell 不得输出**；可选工具用 `command -v` 守卫；缺工具不得破坏启动。

## Shell 加载

`load.zsh`/`load.bash` 按序加载：`core -> platform -> profile -> aliases -> host -> local`。
`core.sh` 设置 PATH（`.local/bin`、`~/bin`、nvm）；然后加载
`platform/{darwin,linux,termux}.sh`、`profiles/{full,server,termux}.sh`、
`aliases.sh`；aliases 之后调用 `dotfiles_default_editor`（定义于 `core.sh`）：
此时 Homebrew 等平台 PATH 已组装完成，GUI login shell 里 `command -v nvim`
才可见——EDITOR/VISUAL 默认值必须在 PATH 就绪后判定，且已设的 EDITOR
（含 tmux 注入）会被尊重，故 PATH 组装不得回退到它之前。host/local 可选
（`~/.zshenv.{host,local}` / `~/.bashrc.{host,local}`），仍可覆盖。
`DOTFILES_ROOT`/`DOTFILES_PLATFORM`/`DOTFILES_PROFILE` 驱动一切。

`aliases.sh` 是自定义 alias 的唯一入口：依赖可选工具的 alias 必须用
`command -v` 守卫；不得含主机专属路径；私有 alias 放
`~/.zshenv.local` / `~/.bashrc.local`（后加载，可覆盖公开定义）。

## 添加受管配置

1. 将文件放到 `home/`（全平台）或 `platforms/<platform>/home/`（单平台），
   镜像其 `$HOME` 路径；确认与另一来源根无冲突。
2. 验证：`./install <profile> --dry-run`，再 `scripts/doctor`。

## Bash 代码风格

- `#!/usr/bin/env bash` + `set -euo pipefail`；source `scripts/lib-dotfiles.sh`
  （`dotfiles_root`、`source_roots`、`link_matches_source`、
  `check_source_collisions`、`karabiner_source` 等）。
- 用法错误向 stderr 打印 `usage: ...` 并 `exit 2`；不支持的 platform/profile
  以非零退出并给出明确信息。
- 有 shellcheck 时运行；保持可移植（bash 3.2、macOS）。

## 验证（任何改动后）

```bash
./install <profile> --dry-run && scripts/doctor
bash -n install scripts/link scripts/unlink scripts/doctor
zsh -n home/.zshenv home/.zshrc scripts/shell/load.zsh scripts/shell/aliases.sh
git diff --check && tests/link.sh && tests/shell.sh && tests/packages.sh && tests/plugins.sh && tests/termux.sh && bash tests/tmux.sh
bash tests/vim.sh # 需要 vim + Lightline 插件
```

测试用临时 HOME 模拟：`HOME=<tmp> DOTFILES_ROOT=<repo>
DOTFILES_PLATFORM=<p> [DOTFILES_PROFILE=<pr>]`；覆盖项：
`DOTFILES_LINK_BACKEND`、`DOTFILES_OS_ID`、`DOTFILES_HOMEBREW_PREFIX`。

## 备注

- Conventional Commits：`feat(<scope>):`、`fix(<scope>):`、`refactor:`、`docs:`、
  `chore:`，小且单一用途。
- `scripts/packages` 是显式入口；`install` 不隐式提权或联网装包。
- `scripts/plugins` 克隆到真实的 `~/.tmux`、`~/.vim/pack`、`~/.oh-my-zsh`，
  并校验 origin 和 Git 对象；插件检出绝不提交。
- Tinty 主题：`home/.config/tinted-theming/tinty/config.toml` 与 darwin 的
  `platforms/darwin/home/.config/git/config` 受管；`~/.local/share/tinted-theming/tinty/`
  与 `~/.config/kitty/current-theme.conf` 为运行时产物，绝不入库。
  delta 样式由 tinty hook `home/.config/tinted-theming/tinty/hooks/delta.sh`（读
  `TINTY_SCHEME_PALETTE_BASE*_RGB_*` env）渲染到 `<data>/delta-scheme-colors.gitconfig`，
  受管 git config 第二个 include 引用；无 tinty 时 include 缺失即忽略（delta
  原生）；槽位语义见 `docs/theming.md`。
  tmux 状态栏黄色阶斜切块由同款 hook `hooks/tmux.sh` 渲染
  `<data>/tmux-status-colors.conf`（`@tp_*` 选项；`simple_batt.tmux.conf`
  布局与 `home/.tmux/scripts/status-line.sh` 宽度门控段引用，几何三角
  U+25E2-E5，无 tinty 时 fallback conf 的 frappe 常量打底）；细节见
  `docs/theming.md`。
  yazi flavor / glow 样式 / lazygit overlay / gh-dash overlay 由
  `scripts/tinty/generate` 生成到
  `~/.config/yazi/flavors/tinty-{dark,light}.yazi/`、
  `~/.config/tinted-theming/tinty-glow.json`、`~/.config/lazygit/tinty.yml`
  与 `~/.config/gh-dash/tinty{,-context}.yml`（运行时产物；gh-dash 经
  `home/.local/bin/gd` 启动器标记校验后 `--config` 叠加）。细节见
  `docs/theming.md`。
- OMO/OpenCode：`home/.omo/omo.jsonc` 与 `home/.config/opencode/` 由本仓库
  leaf-link 管理；`~/.omo/{codegraph,lsp-daemon}/`、`node_modules/`、
  `lsp-install-decisions.json` 与各 `*.bak*` 为本机运行时/备份，绝不入库。
  `.gitignore` 的 `/.omo/` 必须保持锚定（未锚定会误伤 `home/.omo/`）。
  TUI 主题由 `tui-plugins/tinty-theme.js` 实时跟随 tinty（`tui.json` 的
  `plugin` 数组声明加载；生成 `~/.config/opencode/themes/tinty-*.json`，
  运行时产物不入库），回退主题为 frappe 单色版 `catppuccin-frappe-yellow`
  （黄 `#f9e2af` accent）。
  细节见 `docs/opencode.md` 与 `docs/theming.md`。
- 活跃待办与操作记录在 `docs/todo.md`（归档规则见文内）——动手前先读；重构
  历史（迁移计划、收尾记录、已完成操作记录）归档在 `docs/archive/`。
