# AGENTS.md

个人跨平台 dotfiles 仓库，用显式 HOME 软链接管理配置。仅支持 macOS（`full`）、
Debian/Ubuntu（`server`）、Termux（`termux`）——其他组合（含 WSL）必须明确
报错，绝不静默回退到其他 profile。

## 布局

```text
home/                          # 跨平台，链接到 $HOME
platforms/<platform>/home/     # 平台专属可链接配置
platforms/darwin/managed/      # macOS Preferences 黄金文件（真实文件，绝不链接）
package-lists/                 # brew/apt/termux 包名
plugin-lists/                  # tmux/vim/zsh 插件 TARGET+REPO（不锁 commit）
scripts/shell/                 # core + platform/ + profiles/ 加载片段，load.zsh/load.bash
install                        # 入口：./install {full|server|termux} [--dry-run]
tests/                         # link.sh, shell.sh, vim.sh
docs/                          # process.md, opencode.md, archive/MIGRATION_PLAN.md
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
| `scripts/{prefs,hotkeys}-{restore,export}.sh [--yes]` | macOS：恢复/导出偏好与快捷键 |

仅支持组合：`darwin:full`、`linux:server`（Debian/Ubuntu）、`termux:termux`。

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

`load.zsh`/`load.bash` 按序加载：`core -> platform -> profile -> host -> local`。
`core.sh` 设置 PATH（`.local/bin`、`~/bin`、nvm）与 EDITOR/VISUAL；然后加载
`platform/{darwin,linux,termux}.sh`、`profiles/{full,server,termux}.sh`；
host/local 可选（`~/.zshenv.{host,local}` / `~/.bashrc.{host,local}`）。
`DOTFILES_ROOT`/`DOTFILES_PLATFORM`/`DOTFILES_PROFILE` 驱动一切。

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
zsh -n home/.zshenv home/.zshrc scripts/shell/load.zsh
git diff --check && tests/link.sh && tests/shell.sh && tests/packages.sh && tests/plugins.sh
bash tests/vim.sh # 需要 vim + Lightline 插件
```

测试用临时 HOME 模拟：`HOME=<tmp> DOTFILES_ROOT=<repo>
DOTFILES_PLATFORM=<p> [DOTFILES_PROFILE=<pr>]`；覆盖项：
`DOTFILES_LINK_BACKEND`、`DOTFILES_OS_ID`、`DOTFILES_HOMEBREW_PREFIX`。

## 备注

- Conventional Commits：`feat(<scope>):`、`fix(<scope>):`、`refactor:`、`docs:`、
  `chore:`，小且单一用途。
- `legacy/` 是 gitignored 的迁移暂存区——绝不链接它。
- `scripts/packages` 是显式入口；`install` 不隐式提权或联网装包。
- `scripts/plugins` 克隆到真实的 `~/.tmux`、`~/.vim/pack`、`~/.oh-my-zsh`，
  并校验 origin 和 Git 对象；插件检出绝不提交。
- `docs/process.md` 为收尾记录（含 A–E 待办清单）；迁移计划已归档到
  `docs/archive/MIGRATION_PLAN.md`——动手前先读。
