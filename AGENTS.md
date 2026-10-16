# AGENTS.md

个人跨平台 dotfiles 仓库，用显式 HOME 软链接管理配置。仅支持 macOS（`full`）、Debian/Ubuntu（`server`）、
WSL Debian/Ubuntu（复用 `server`）、Termux（`termux`）——其他组合必须明确报错，绝不静默回退。

待办与操作记录在 `docs/todo.md`、`docs/progress.md`（动手前先读）；专题文档索引见 `docs/README.md`。

## 布局

```text
home/                       # 跨平台，链接到 $HOME
platforms/<p>/home/         # 平台专属可链接配置
platforms/darwin/managed/   # macOS Preferences 黄金文件（真实文件，绝不链接）
package-lists/              # brew/apt/termux 包名
plugin-lists/               # tmux/vim/zsh 插件 TARGET+REPO（不锁 commit）
manual/                     # 手动覆盖，不链接、不受 link/unlink/doctor 管理
scripts/shell/              # core + aliases + platform/ + profiles/ 加载片段
install / tests/ / docs/    # 入口 / 测试 / 文档（索引见 docs/README.md）
```

## 命令

| 命令 | 用途 |
|---|---|
| `./install {full\|server\|termux} [--dry-run]` | 校验平台/profile，运行 `scripts/link` |
| `scripts/packages {full\|server\|termux} [--dry-run]` | 校验后从对应清单安装包 |
| `scripts/link [--dry-run]` | 创建受管软链接（direct 或 Stow 后端） |
| `scripts/unlink [--dry-run]` | 只移除指向本仓库的链接 |
| `scripts/doctor` | 校验链接、秘密卫生、Preferences |
| `scripts/plugins [--dry-run] [--app tmux\|vim\|zsh]` | 从 `plugin-lists/*.txt` 克隆插件 |
| `scripts/termux-zvm-fix [--dry-run]` | Termux：zsh-vi-mode 光标兼容补丁 |
| `scripts/{prefs,hotkeys}-{restore,export}.sh [--yes]` | macOS：恢复/导出偏好与快捷键 |

仅支持组合：`darwin:full`、`linux:server`、`wsl:server`（后两者 Debian/Ubuntu）、`termux:termux`。

## 不变量（不可破坏；由 link/doctor/tests 强制）

- **绝不覆盖未受管目标**：`link` 遇已存在且不指向本仓库的目标即中止；`unlink` 绝不删未知文件。
- **`--dry-run` 零副作用**：不建目录、链接、克隆或写入。
- **共享 `home/` 与平台 `home/` 不得提供相同目标**（`check_source_collisions` 报错）。
- **macOS Preferences 是真实文件，绝非软链接**：黄金文件在 `platforms/darwin/managed/`，备份 +
  `defaults import` 恢复（cfprefsd 刷新、失败回滚）；TCC 域拒绝 `cp` 时授予完全磁盘访问，不强攻。
- **Karabiner 是目录链接**：仅 `direct` 后端，Stow 必须拒绝。
- **公开树无秘密/主机专属配置**：不提交 `.netrc`、`auth.json`、`*license*`、SSH host 条目、token；
  私有覆盖放 `~/.config/git/config.local`、`~/.ssh/config.d/*.conf`、`~/.zshenv.{host,local}`、
  `~/.bashrc.{host,local}`，公开配置只 include。
- **运行时产物/本机数据绝不入库**：tinty 渲染产物、`~/.omo/` 运行时目录、`~/.local/state/mpd/`、
  `~/Music/` 等不入库；`.gitignore` 的 `/.omo/` 必须保持锚定（未锚定会误伤 `home/.omo/`）。
- **共享 shell 代码无主机专属路径/代理/启动时 tmux attach**（`tests/shell.sh` 判失败）。
- **非交互 shell 不输出**；可选工具 `command -v` 守卫；缺工具不破坏启动。

## Shell 加载

`load.zsh`/`load.bash` 顺序：`core -> platform -> profile -> aliases -> host -> local`。`core.sh`
组装 PATH（`.local/bin`、`~/bin`、nvm）；aliases 之后才调用 `dotfiles_default_editor` 判定
EDITOR/VISUAL 默认值——必须在平台 PATH 就绪后（GUI login shell 才见 nvim），已设的 EDITOR
（含 tmux 注入）被尊重，故 PATH 组装不得回退到它之前。host/local 可选，仍可覆盖。
`DOTFILES_ROOT`/`DOTFILES_PLATFORM`/`DOTFILES_PROFILE` 驱动一切。

`aliases.sh` 是自定义 alias 唯一入口：可选工具 alias 用 `command -v` 守卫；无主机专属路径；
私有 alias 放 `~/.zshenv.local` / `~/.bashrc.local`（后加载可覆盖）。

## 添加受管配置

放文件到 `home/`（全平台）或 `platforms/<p>/home/`（单平台），镜像 `$HOME` 路径且与另一来源根
无冲突；验证 `./install <profile> --dry-run` + `scripts/doctor`。

## Bash 风格

`#!/usr/bin/env bash` + `set -euo pipefail`；source `scripts/lib-dotfiles.sh`（`source_roots`、
`check_source_collisions` 等）；用法错误 stderr `usage: ...` + `exit 2`；不支持组合非零退出；
可移植 bash 3.2/macOS；有 shellcheck 就跑。

## 验证（任何改动后）

```bash
./install <profile> --dry-run && scripts/doctor
bash -n install scripts/link scripts/unlink scripts/doctor
zsh -n home/.zshenv home/.zshrc scripts/shell/load.zsh scripts/shell/aliases.sh
git diff --check && tests/link.sh && tests/shell.sh && tests/packages.sh && tests/plugins.sh && tests/termux.sh && bash tests/tmux.sh && bash tests/tmux-zen.sh && bash tests/askai.sh
bash tests/vim.sh # 需要 vim + Lightline 插件
```

测试用临时 HOME：`HOME=<tmp> DOTFILES_ROOT=<repo> DOTFILES_PLATFORM=<p> [DOTFILES_PROFILE=<pr>]`；
覆盖项：`DOTFILES_LINK_BACKEND`、`DOTFILES_OS_ID`、`DOTFILES_HOMEBREW_PREFIX`。
