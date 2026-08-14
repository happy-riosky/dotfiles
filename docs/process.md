# Dotfiles 重构收尾记录

这份文档记录迁移计划完成后的验证、真实设备反馈和后续优化。迁移计划已归档到
[`archive/MIGRATION_PLAN.md`](./archive/MIGRATION_PLAN.md)，OpenCode 配置说明见
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

### 真实 macOS 验证（2026-08-13）

- 日期：2026-08-13
- 环境：darwin
- 操作：
  - 验证 Karabiner UI 修改会产生 Git diff。
  - 对 Rectangle 和一个非关键 Preferences domain 做恢复测试。
- 结果：通过
- 证据：
  - Karabiner：`~/.config/karabiner` 目录链接，UI 修改后 `git status` 可见 diff。
  - `scripts/hotkeys-restore.sh --yes`：确认提示、备份目录生成、恢复后 `defaults read com.knollsoft.Rectangle` 回到黄金值。
  - `scripts/prefs-restore.sh --yes`：逐 domain 输出 `OK`；`chmod 000` 模拟写入失败时回滚备份并以非零退出。
  - 失败回滚用非 TCC 保护 domain 验证，未触及 `com.apple.Music`。
- 后续：A3 真实 Linux server、A4 真实 Termux 验证待做。

### 真实 Termux 验证（2026-08-14）

- 日期：2026-08-14
- 环境：termux（真实设备）
- 操作：按 `docs/termux.md`（整理自验收清单）完整走完安装与验证流程。
- 结果：通过
- 证据：
  - `packages termux` 安装清单包成功；`install termux` 建链并幂等；`plugins` 克隆并校验全部插件。
  - `doctor passed`（Git 身份按设计手动写入 `~/.config/git/config.local`）。
  - Bash/Zsh 均可用 `j` 跳转、`lg` alias 生效；tmux/Vim/SSH 正常。
  - p10k 主题在 powerlevel10k 加入清单后正常生效。
- 过程中修复的三个真实问题：
  - autojump hook 被拼接（`autojump_chpwdautojump_chpwd`）：Termux 系统 profile 与
    旧版 loader 重复加载所致，已改为 loader 不再 source 系统 profile
    （`58efd0c`）。
  - `zsh-vi-mode` 报 `zvm_cursor_style` 正则错误：Termux zsh 无法编译上游正则，
    新增 `scripts/termux-zvm-fix` 补丁脚本（`30c47ec`）。
  - p10k 不生效：powerlevel10k 缺失于插件清单，已补（`ceff35e`）。
- 后续：A3 真实 Linux server 待做；doctor 在 Termux 上依赖 `/bin/bash` 的问题待确认。

## 3. 收尾待办清单

迁移计划已归档，剩余事项在此跟踪：

### A. 真实环境验收

- [x] macOS：验证 Karabiner UI 修改会产生 Git diff。
- [x] macOS：对 Rectangle 和一个非关键 Preferences domain 做恢复测试（覆盖确认、备份、失败回滚）。
- [ ] Linux server：在真实 Debian/Ubuntu 机器验证 Bash、Git、tmux、Vim 和 SSH。
- [x] Termux：真实设备完成完整安装与验证（2026-08-14，见第 2 节记录与 `docs/termux.md`）。

### B. 收尾清理

- [ ] 稳定运行一段时间后删除 `legacy/backup` 和残留 `.mackup*`。
- [ ] 决定是否清理仓库历史中的已知 SSH host/IP（隐私暴露，非重构前置）。

### D. 包管理

- [x] 填充 `package-lists/{brew-formulae,brew-casks,apt,termux}.txt`。
- [x] 新增显式 `scripts/packages {full|server|termux} [--dry-run]` 入口；`install`
  继续只 link，不隐式提权或联网。清单先完整校验，再批量调用 brew/apt/pkg。

### E. plugins 收尾

- [x] 在真实 Termux 验证 `scripts/plugins`（dry-run 与实际克隆 tmux/vim/zsh 插件，2026-08-14）。
- [x] 自动验证所有清单先预检，未知目标不覆盖，既有/新克隆检出均校验 origin 和 `git fsck`。
- [x] 删除无引用的空目录 `plugin-manifests/`。

### 真实 Debian/Ubuntu 验收

以下命令留给用户在真实 Debian/Ubuntu 主机执行：

```bash
./scripts/packages server --dry-run
./scripts/packages server
./install server --dry-run
./install server
./scripts/plugins --dry-run
./scripts/plugins
./scripts/doctor
command -v git ssh tmux vim zsh autojump
bash -lic 'type j'
zsh -lic 'type j'
command -v lazygit || true
```

Debian/Ubuntu 清单当前不安装 LazyGit，因此最后一项允许 `lazygit` 缺失；若主机已有
同名未受管配置或插件目标，安装器应明确中止且保留原文件。

### 真实 Termux 验收

完整安装与验证步骤已整理为使用指南：[`termux.md`](./termux.md)。2026-08-15 已在
真实设备按该流程验收通过（见第 2 节记录）。

#### 已知 Termux 问题：zsh-vi-mode 光标样式

Termux 的 zsh 无法编译 `zsh-vi-mode` 中 `zvm_cursor_style` 的恢复正则，报错：

```text
zvm_cursor_style:34: failed to compile regex: trailing backslash (\)
```

仅设置 `ZVM_CURSOR_STYLE_ENABLED=false` 不够：`zvm_zle-line-finish` 每次执行命令时
仍会无条件调用该函数。修复由显式脚本完成（写入
`~/.oh-my-zsh/custom/zz-zvm-termux.zsh`，oh-my-zsh 在插件之后加载 custom，因此覆盖生效）：

```bash
./scripts/termux-zvm-fix --dry-run
./scripts/termux-zvm-fix
exec zsh -l
```

验证：启动无报错，`zvm_version` 正常输出，`Esc` 后 `0`/`w`/`b` 移动、`i` 返回插入
均可用；光标形状不随模式变化是已知妥协。若曾手动创建过内容不同的补丁文件，先删除
再运行脚本。

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
./tests/packages.sh
./tests/plugins.sh
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
