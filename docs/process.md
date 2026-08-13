# Dotfiles 重构收尾记录

这份文档记录迁移计划完成后的验证、真实设备反馈和后续优化。计划本身见
[`MIGRATION_PLAN.md`](./MIGRATION_PLAN.md)，OpenCode 配置说明见
[`opencode.md`](./opencode.md)。

## 1. 当前状态

截至 2026-08-13，重构的主要目标已经完成：

- `full`、`server` 和 `termux` 三个安装入口存在。
- 普通配置通过 Stow 或等价的叶子软链接管理。
- `scripts/link` 会拒绝覆盖未由当前仓库管理的目标文件。
- `--dry-run` 不创建目录或链接，只输出计划操作。
- shell 加载顺序为 `core -> platform -> profile -> host -> local`。
- macOS Preferences 保持为真实文件，Karabiner 单独管理。
- 仓库不再依赖旧的 `backup/` 运行链接，Mackup 已移除。

## 2. 已完成验证

### 自动化和模拟环境

2026-08-12 已完成：

- 使用 Multipass Ubuntu 24.04 VM 验证 `server` profile。
- 验证 `server` 的 dry-run、重复安装、`doctor`、Git/SSH/tmux/Vim、shell 静默和安全卸载。
- 使用临时 HOME 和 `DOTFILES_PLATFORM=termux` 验证 `termux` profile。
- 验证重复安装和卸载不会删除未知用户文件。
- 验证 shell 的交互、login 和非交互启动路径。

### 真实 Termux 反馈

Termux 实测命令：

```bash
./install termux --dry-run
```

首次执行时发现已有真实文件：

```text
~/.config/lazygit/config.yml
```

安装器按设计中止，并报告：

```text
link: target exists and is not managed: .../.config/lazygit/config.yml
```

这是防覆盖保护，不是安装失败。对于刚安装且不需要保留的 LazyGit 配置，可以只删除该文件后重新执行安装：

```bash
rm "$HOME/.config/lazygit/config.yml"
./install termux --dry-run
./install termux
```

### Dry-run 输出检查

旧版 Termux dry-run 曾列出 `.config/dotfiles/` 下的共享 shell、全部平台和全部 profile 脚本。`LINK` 和 `MKDIR` 只表示计划操作；当前结构已不再创建这些链接。

## 3. 收尾检查清单

以下项目需要在对应真实环境完成或定期复查：

- [ ] 真实 Termux 新开 Bash/Zsh 后确认 `DOTFILES_PLATFORM=termux` 和 `DOTFILES_PROFILE=termux`。
- [ ] 真实 Termux 验证 Git、SSH、tmux、Vim 和 LazyGit。
- [ ] 真实 Debian/Ubuntu server 验证 Bash、Git、tmux、Vim 和 SSH。
- [ ] macOS 验证 Karabiner UI 修改会产生 Git diff。
- [ ] macOS 验证 Preferences 恢复的确认、备份和失败恢复流程。
- [ ] 对 Rectangle 和一个非关键 Preferences domain 做恢复测试。
- [ ] 稳定运行一段时间后再删除 `legacy/backup` 和残留 `.mackup*`。
- [ ] 继续检查仓库历史中的已知 SSH host/IP 是否需要单独处理。

## 4. 结构问题和优化方向

### 4.1 直接从仓库加载 shell 脚本

系统会自动读取 `~/.zshenv`，交互式 Bash 通常会读取 `~/.bashrc`；系统不会自动搜索
`~/.config/dotfiles/`。目标结构将从公共 shell 结构中移除该目录。

当前调用链为：

```text
~/.zshenv
  -> ~/dotfiles/scripts/shell/load.zsh
  -> ~/dotfiles/scripts/shell/core.sh
  -> ~/dotfiles/scripts/shell/platform/<platform>.sh
  -> ~/dotfiles/scripts/shell/profiles/<profile>.sh
```

公共 shell 启动文件直接依赖 `${DOTFILES_ROOT:-$HOME/dotfiles}`。这明确表达了个人 dotfiles 的实际运行方式，避免额外软链接。

### 4.2 私有覆盖文件

host/local 覆盖文件不再放在 `~/.config/dotfiles/`，而是使用 shell 启动文件旁的明确名称：

```text
~/.zshenv.host
~/.zshenv.local
~/.bashrc.host
~/.bashrc.local
```

它们仍然只由 dotfiles loader 主动加载，系统不会自动搜索这些文件。

### 4.3 结果

file tree refactor 的目标是采用直接加载方案：`~/.config/dotfiles` 不再由安装器创建，平台和 profile 脚本也不会作为 HOME 链接出现。

## 5. 每次优化后的最小验证

修改链接或 shell 加载结构后，至少执行：

```bash
./install "$PROFILE" --dry-run
./scripts/doctor
bash -n install scripts/link scripts/unlink scripts/doctor
git diff --check
```

在可用环境中补充：

```bash
zsh -n home/.zshenv home/.zshrc scripts/shell/load.zsh
./tests/shell.sh
./tests/link.sh
```

并在临时 HOME 中验证三件事：

1. dry-run 不创建文件。
2. 首次安装创建预期链接，重复安装幂等。
3. 未管理的真实文件会阻止安装，`unlink` 不删除该文件。

## 6. 记录格式

后续每次收尾操作追加一条记录，至少包含：

```text
日期：YYYY-MM-DD
环境：darwin | server | termux | 临时 HOME
操作：执行的命令或结构调整
结果：通过 | 失败 | 部分通过
证据：关键输出、diff 或测试命令
后续：仍需处理的事项
```
