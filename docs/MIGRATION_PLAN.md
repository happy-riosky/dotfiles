# Dotfiles 重构计划

## 1. 目标

将当前 Mackup + `backup/` 的 HOME 快照改为明确、可读、跨平台的配置仓库：

- 普通配置直接链接到 Git 真源，应用修改后立即形成 `git diff`。
- macOS、Linux server 和 Termux 共享 core，但只加载各自平台配置。
- macOS Preferences 使用真实文件，不使用软链接。
- SSH hosts、token、license、`.netrc` 和本地身份不进入公共仓库。
- 删除 Mackup、损坏 Gitlink、运行时状态和无价值快照。

这是一套个人 dotfiles。执行策略以简单、可恢复为先，不引入复杂事务系统或多代理并行协调。

## 2. 当前问题

必须先处理：

- `backup/.gitconfig:18` 设置了 `http.sslVerify = false`。
- `backup/.ssh/config` 已被 Git 跟踪；`.gitignore` 不会自动取消跟踪。
- `backup/.netrc`、`backup/.pi/agent/auth.json` 和 license 类文件不应留在公共仓库工作树。
- 当前 `setup` 无条件执行 Apt upgrade、Homebrew 安装、pipx 和 `mackup restore`。
- 仓库有 9 个没有 `.gitmodules` 的 mode `160000` Gitlink。
- shell 配置包含 `/Users/riosky`、`/home/riosky`、`/opt/homebrew`、`/mnt/c` 等平台或主机路径。
- LibreOffice lock、Wireshark recent、Jupyter workspace、`.wget-hsts` 等运行时状态被跟踪。
- Preferences 恢复脚本仍可能创建 `~/.mackup` 链接。

## 3. 最终架构

```text
dotfiles/
├── README.md
├── docs/
│   ├── MIGRATION_PLAN.md
│   ├── opencode.md
│   └── process.md
├── install
├── home/                              # 跨平台，可链接，镜像 $HOME
│   ├── .zshenv
│   ├── .zprofile
│   ├── .zshrc
│   ├── .bash_profile
│   ├── .bashrc
│   ├── .inputrc
│   ├── .gitconfig                     # 公共配置，只 include 本地身份
│   ├── .ssh/config                    # 公共 stub，只 include config.d
│   ├── .tmux.conf
│   ├── .tmux/colors/
│   ├── .vimrc
│   ├── .vim/colors/
│   ├── .config/opencode/              # 审计后的公共配置
│   └── .opencode/                     # 只保留跨设备静态资产
├── platforms/
│   ├── darwin/
│   │   ├── home/                      # macOS 专属、可链接
│   │   │   └── .config/karabiner/
│   │   └── managed/                   # 不链接，由脚本 copy/import
│   │       ├── preferences/
│   │       ├── hotkeys/
│   │       └── apps/
│   ├── linux/home/
│   └── termux/home/
├── package-lists/
│   ├── brew-formulae.txt
│   ├── brew-casks.txt
│   ├── apt.txt
│   └── termux.txt
├── plugin-manifests/
├── scripts/
│   ├── shell/
│   │   ├── core.sh
│   │   ├── load.{bash,zsh}
│   │   ├── platform/{darwin,linux,termux}.sh
│   │   └── profiles/{full,server,termux}.sh
│   ├── doctor
│   ├── link
│   ├── unlink
│   ├── plugins
│   ├── prefs-*.sh
│   └── hotkeys-*.sh
├── tests/
└── legacy/                            # 迁移期暂存，稳定后删除
```

## 4. 管理规则

### 4.1 普通配置直接链接

使用 GNU Stow 批量创建软链接：

```bash
stow --no-folding --dir="$DOTFILES_ROOT" --target="$HOME" --restow home
stow --no-folding --dir="$DOTFILES_ROOT/platforms/darwin" --target="$HOME" --restow home
```

映射保持直观：

```text
home/.vimrc                   -> ~/.vimrc
home/.tmux.conf               -> ~/.tmux.conf
home/.config/kitty/kitty.conf -> ~/.config/kitty/kitty.conf
```

必须使用 `--no-folding`，避免把整个 `~/.config`、`~/.vim` 或 `~/.tmux` 链入仓库。

共享 `home/` 和平台 `home/` 不得提供同名目标；`scripts/link --dry-run` 发现冲突时直接失败。

### 4.2 Karabiner 目录链接

Karabiner 保留当前低心智负担模式：

```text
~/.config/karabiner
  -> ~/dotfiles/platforms/darwin/home/.config/karabiner
```

Karabiner UI 修改配置后立即产生 Git diff。`automatic_backups/` 等运行时子目录使用精确 `.gitignore` 排除。

Karabiner 目录由 `scripts/link` 单独链接，不由 `stow --no-folding` 创建叶子链接。

### 4.3 macOS Preferences 使用真实文件

以下内容不能使用 Stow 或手工软链接：

- `~/Library/Preferences/*.plist`
- Rectangle preference domain
- 系统快捷键 plist
- 必须通过 `defaults import` 或应用导入的配置

仓库中的 golden 位于：

```text
platforms/darwin/managed/preferences/
platforms/darwin/managed/hotkeys/
platforms/darwin/managed/apps/
```

首批迁移映射：

```text
backup/manual/prefs/*.plist
  -> platforms/darwin/managed/preferences/*.plist

backup/manual/symbolichotkeys.plist
  -> platforms/darwin/managed/hotkeys/symbolichotkeys.plist

backup/manual/RectangleConfig.json
  -> platforms/darwin/managed/hotkeys/RectangleConfig.json
```

恢复流程：退出相关应用、备份现有真实文件、copy/import、刷新 `cfprefsd`、验证关键值。失败时恢复备份。`./install full` 默认不恢复 Preferences；必须显式运行：

```bash
./install full --macos-prefs
```

### 4.4 私有配置

以下内容保留在原生运行路径，但不进入公共 Git：

```text
~/.config/git/config.local
~/.ssh/config.d/hosts.conf
~/.zshenv.host
~/.zshenv.local
~/.bashrc.host
~/.bashrc.local
```

以及：

- SSH 私钥和真实 hosts
- `.netrc`
- API token、auth 文件和 license
- 工作代理、内部网络和私人工作路径

公共 Git 配置 include `~/.config/git/config.local`；公共 SSH stub include `~/.ssh/config.d/*.conf`。

OpenCode 的 provider/model/TUI 等可移植配置迁入 `home/.config/opencode/`；`~/.opencode` 只迁移明确需要跨设备同步的 commands、agents 等静态资产。auth、session、数据库、`node_modules`、cache、log 和运行生成文件不进入 `home/`。

### 4.5 不管理的内容

默认不迁入新架构：

- cache、log、lock、recent、workspace、数据库和 WAL
- tmux/Vim/OMZ 插件目录
- mode `160000` Gitlink 内容
- 未主动选择管理的 GUI/App Support

插件由固定 commit 的清单重新安装到真实目录：

```text
~/.tmux/plugins/
~/.vim/pack/
```

## 5. 平台和 Profile

首版只支持：

| 平台 | Profile | 命令 | 默认 shell |
|---|---|---|---|
| macOS | `full` | `./install full` | zsh |
| Debian/Ubuntu | `server` | `./install server` | bash |
| Termux | `termux` | `./install termux` | 保持现状 |

WSL、Linux desktop/full 和 macOS/server 首版不支持，检测到后明确报错，不静默套用其他 profile。

Shell 加载顺序：

```text
core -> platform -> profile -> host -> local
```

host/local 文件固定为：

```text
~/.zshenv.host
~/.bashrc.host
```

local 最后加载。所有可选命令先用 `command -v` 检查；非交互 shell 不得输出内容或自动 attach tmux。

## 6. Git 分支和备份

从最新 `darwin` 创建一个重构分支：

```bash
git switch darwin
git pull --ff-only
git switch -c refactor/dotfiles-layout
```

如果本地 `darwin` 仍有未推送提交，先确认这些提交应该 push，或直接以当前 `darwin` 为基线创建分支；不要为了“干净”丢弃它们。

重构分支的收益：

- 每个阶段可以单独提交和回看 diff。
- 当前 `darwin` 保持可工作的回退点。
- 完成后再合并回 `darwin`。

开始前做两个简单备份即可：

1. 将当前 dotfiles 目录复制到仓库外或确认 Time Machine 有最新快照。
2. 记录当前重要链接：

```bash
ls -ld ~/.zshrc ~/.zprofile ~/.gitconfig ~/.tmux.conf ~/.tmux \
  ~/.vimrc ~/.inputrc ~/.config/karabiner
```

Git 历史不默认重写。先修复当前 HEAD 并运行 secret scan；只有确认历史里存在真实 token、私钥或密码时，再单独决定是否重写历史和轮换凭证。SSH host/IP 已进入历史应记录为隐私暴露，但不把历史重写作为布局重构的前置条件。

## 7. 执行步骤

### Phase 0：止血和备份

- [x] 创建 `refactor/dotfiles-layout` 分支。
- [x] 保存当前工作，确认没有其他 dotfiles 操作并行进行。
- [x] 备份 dotfiles 和关键 HOME 配置路径。
- [x] 删除 `backup/.gitconfig` 的 `sslVerify=false`，并验证生效配置。
- [x] 先让当前 `~/.gitconfig` include `~/.config/git/config.local`，验证 include 生效后再将 `[user]` 身份迁入 local 文件。
- [x] 将 SSH host 配置、`.netrc`、Pi auth 和 license 移出仓库并停止跟踪。
- [x] 禁用旧 `setup` 和插件脚本，停止执行 Mackup。
- [x] 从 Preferences 脚本删除创建 `~/.mackup` 的副作用。
- [x] 导出最新 Preferences 和 hotkeys golden。
- [x] 运行 secret scan，记录是否确有凭证需要轮换或历史清理。

验收：当前 Git 配置不关闭 TLS；HEAD 不跟踪已知秘密和 SSH hosts；现有 shell、Git、SSH、tmux 和 Vim 仍可用。

执行记录（2026-08-12）：当前工作树 secret scan 通过；历史中已有的 SSH host/IP
按第 6 节作为已知隐私暴露记录，是否重写历史留待后续单独决定。

### Phase 1：建立新目录并迁移 core

- [x] 创建 `home/`、`platforms/`、`package-lists/` 和脚本骨架。
- [x] 先复制 `.inputrc`、公共 Git、SSH stub、tmux 和 Vim 配置到新目录。
- [x] 将第三方 Gitlink 改为固定 commit 插件清单，不复制插件目录。
- [x] 对每组目标先运行 Stow dry-run。
- [x] 备份现有目标，然后切换到新链接。
- [x] 每组切换后立即验证对应工具。
- [x] 迁移 Preferences/hotkeys golden 到 `platforms/darwin/managed/`。
- [x] 所有运行时链接切换完成后，将原 `backup/` 改名为只读的 `legacy/backup/`；不要在仍有链接指向它时移动。

验收：core 配置从新目录运行；重复执行 link 不报错；没有链接指向 `legacy/backup`；Preferences 仍是真实文件。

执行记录（2026-08-12）：本机未安装 GNU Stow，`scripts/link` 使用等价的
叶子链接后端并保留 Stow 后端支持；Phase 2/3 切换完成并确认 HOME 零残留
链接后，旧快照已归档到只读的 `legacy/backup/`。

### Phase 2：拆分 shell

- [x] 拆分 zsh/bash 的 core、platform、profile、host 和 local。
- [x] 移除硬编码主机路径和代理。
- [x] 为 Homebrew、Conda、NVM、Go、PostgreSQL、OpenClaw 等增加 guard。
- [x] 验证交互、login 和非交互 shell。
- [x] 验证远程命令、scp 和 cron 场景无输出污染。

验收：缺少可选工具时 shell 正常启动；只加载当前 platform/profile。

### Phase 3：迁移 macOS 应用配置

- [x] 将 Karabiner 切换到新的 Darwin 目录链接。
- [ ] 验证 Karabiner UI 修改会产生 Git diff。
- [x] 更新 prefs/hotkeys export/restore 脚本的新路径。
- [ ] 为 Preferences 恢复增加确认、备份和失败恢复。
- [ ] 对 Rectangle 和一个非关键 domain 做恢复测试。

验收：Karabiner 无需手动同步；Rectangle 和 Preferences 使用真实文件且重启后生效。

### Phase 4：验证其他平台

- [x] 在临时 HOME 或 Debian/Ubuntu 容器测试 `server`。
- [ ] 在真实 server 验证 bash、Git、tmux、Vim 和 SSH。
- [x] 在模拟环境验证 `termux` profile；真实 Termux 待设备测试。
- [x] 验证重复安装和卸载不会删除未知用户文件。

执行记录（2026-08-12）：使用 Multipass Ubuntu 24.04 VM 完整测试 server
profile（dry-run、幂等安装、doctor、Git/SSH/tmux/Vim、shell 静默、unlink
安全）；使用 DOTFILES_PLATFORM=termux 在临时 HOME 测试 termux profile。
两者均通过。

### Phase 5：移除 Mackup 和 legacy

- [x] 确认 `$HOME` 不再有链接指向 `backup/`。
- [x] 卸载 Mackup，移除 `~/.mackup` 和 `~/.mackup.cfg`。
- [x] 删除旧 `setup`、旧插件脚本和损坏 Gitlink。
- [x] 将暂不管理的 GUI/App Support 留在原生路径并从仓库移除。
- [x] 更新 README。
- [ ] 稳定使用一段时间后删除 `legacy/backup` 和 `.mackup*`。

## 8. 执行期间使用 OpenCode

可以全程使用 OpenCode，但迁移 OpenCode 自己的配置时需要短暂停机：

1. 先保存当前会话。
2. 退出其他 OpenCode TUI、`opencode serve` 和 Zed OpenCode agents。
3. 备份 `~/.config/opencode` 与 `~/.opencode`。
4. 切换 OpenCode 配置链接。
5. 运行 `opencode debug config` 和一次普通启动验证。
6. 验证通过后继续当前计划；失败则恢复原链接。

不需要为整个重构维护三套 OpenCode 控制面。保留当前终端，并确认以下恢复入口可用即可：

```bash
/bin/zsh -f
/opt/homebrew/bin/opencode --pure
```

维护窗口前先记录 `command -v opencode` 的结果；若不是 `/opt/homebrew/bin/opencode`，恢复命令使用实际绝对路径。`--pure` 只用于插件故障时启动恢复会话，不代表外部插件已经通过验证。

## 9. 使用影响

- 备份、复制文件、编写脚本和 dry-run 时可以正常使用终端和应用。
- 切换 shell 配置时保留当前终端，几分钟内不要新开大量 shell。
- 切换 tmux 配置时现有 session 可以保留，但不要同时更新插件。
- 切换 Karabiner 时暂停修改规则；键盘映射可能短暂重载。
- 恢复 Rectangle/Preferences 时先退出对应应用。
- 切换 OpenCode 配置时退出其他 OpenCode 进程，通常只需一个短维护窗口。

## 10. 最小检查

本地 `scripts/doctor` 只需先实现高价值检查：

- 当前 platform/profile。
- 受管链接是否指向当前仓库。
- 是否仍有链接指向 `backup/`。
- macOS Preferences 是否误为软链接。
- Git TLS 是否被关闭。
- SSH hosts、`.netrc`、token 和 license 是否被跟踪。
- shell 交互和非交互启动是否正常。

CI 在安装脚本稳定后再增加：

```text
shellcheck
bash/zsh 语法检查
git diff --check
secret scan
临时 HOME 的 link/unlink 测试
Debian/Ubuntu server 测试
```

CI 不测试真实 Mac Preferences、Karabiner UI 或 Termux 设备。

## 11. 完成定义

- [x] `./install full` 可以重复配置 macOS 核心环境。
- [x] `./install server` 可以配置 Debian/Ubuntu core。
- [x] `./install termux` 可以配置 Termux core。
- [x] 普通配置修改可以直接形成 Git diff。
- [x] 非目标平台配置不加载。
- [x] Preferences 始终是真实文件。
- [x] 公共 HEAD 不跟踪秘密、真实 SSH hosts 和主机私有配置。
- [x] `$HOME` 不再依赖 `backup/`，Mackup 已移除。
- [x] README 与实际命令一致。
