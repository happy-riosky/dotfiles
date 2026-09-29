# WSL 使用指南（含 2026-09 首次配置记录）

在 WSL2（Debian/Ubuntu 发行版）上从零安装并验证本 dotfiles。WSL 复用
`server` profile：检测为 `wsl` 平台，走 `scripts/shell/platform/wsl.sh`、
`package-lists/apt.txt` 与全部共享 `home/` 配置。

本文同时记录 2026-09 在一台 Win11 25H2 + WSL2 Ubuntu（resolute）机器上的
真实配置经历，含所有踩坑与解法，供重装时参照。

## 0. 前置条件与网络

WSL 下 GitHub 直连极慢（实测 ~50KB/s，且 clone 会 TLS 中断）。两种方案：

| 方案 | 适用 | 说明 |
|---|---|---|
| **mirrored 网络 + Windows 代理** | Win11 22H2+ | `%UserProfile%\.wslconfig` 写 `[wsl2]` 段 + `networkingMode=mirrored`（可加 `autoProxy=true`），PowerShell `wsl --shutdown` 后生效；WSL 内 `127.0.0.1` 直通 Windows 代理端口 |
| 公共镜像前缀 | 临时救急 | `https://ghfast.top/https://github.com/...`（约 15 倍速，速度不稳时换 `gh-proxy.com`） |

mirrored 的判断与排错：

- `wslinfo --networking-mode` 输出 `mirrored` 才算生效；仍为 `nat` 说明
  `.wslconfig` 改动后没有 `wsl --shutdown`（改动只在 WSL VM 重启时读取）。
- Windows 侧确认代理端口：`Get-Process` 找客户端进程（如 clash-win64），
  `netstat -ano | findstr LISTENING | findstr <PID>`。Clash for Windows
  默认 HTTP 混合端口 `7890`（只绑 127.0.0.1，mirrored 下无需 Allow LAN）。
- `autoProxy=true` 会向新 shell 自动注入 `http_proxy`/`no_proxy` 等环境
  变量；手动开关 `proxy_on`/`proxy_off` 定义在 `~/.zshenv.local` 与
  `~/.bashrc.local`（私有文件，不入库）。
- `api.github.com` 可能对代理出口 IP 返回 403（Varnish 层限流）；不影响
  `git clone` 与 release 下载，别被它误导。

## 1. 骨架文件冲突（首次安装必遇）

Ubuntu 新用户的 `~/.bashrc`、`~/.profile` 是发行版骨架文件，会被
`link` 按设计拒绝覆盖（"target exists and is not managed"）。处理流程：

1. 确认差异：`diff /etc/skel/.bashrc ~/.bashrc`。`.profile` 通常原封；
   `.bashrc` 可能被工具追加过内容。
2. 备份后移走：`mkdir -p ~/preinstall-backup && cp -a ~/.bashrc ~/.profile ~/preinstall-backup/ && rm ~/.bashrc ~/.profile`
3. 追加过的本机内容迁移到私有覆盖文件。本次案例：opencode 安装器写入了
   `export PATH=/home/<user>/.opencode/bin:$PATH`，迁入
   `~/.bashrc.local` 与 `~/.zshenv.local`（写法改为 `$HOME`，避免主机专属路径）。

## 2. 标准安装

```bash
sudo ./scripts/packages server   # zsh/neovim/eza/zoxide/lazygit 等（apt 源都有）
./install server                 # 建立软链接
./scripts/plugins                # oh-my-zsh + p10k + 4 个 zsh 插件 + vim + tmux
```

apt 清单已含 `neovim`、`eza`、`lazygit`（Ubuntu resolute/universe 均有）。
验证：`./install server --dry-run`、`scripts/doctor`、`tests/*.sh`
（`tests/shell.sh`、`tests/termux.sh` 需先装 zsh；`tests/vim.sh`、
`tests/tmux.sh` 无执行位，用 `bash tests/vim.sh` 跑）。

## 3. 版本敏感的工具

| 工具 | 坑 | 解法 |
|---|---|---|
| **Neovim** | apt 是 0.11.x，本仓库 kickstart 配置用 `vim.pack`/`PackChanged`，**需 0.12+**，启动即报 `Invalid 'event': 'PackChanged'` | 官方预编译包：release 下载 `nvim-linux-x86_64.tar.gz` 解压到 `~/.local/opt/`，软链 `~/.local/bin/nvim`（PATH 优先于 `/usr/bin`，apt 版留着无害）。首次交互打开确认插件安装 |
| **yazi** | 不在 Ubuntu apt 源 | 预编译 zip（含 `yazi` 和配套 CLI `ya`）解压到 `~/.local/bin/`。配置、flavor、插件由仓库 `home/.config/yazi/` 链接提供 |
| tmux 插件 | tpm 只装管理器本身 | 进 tmux 后 `prefix + I` 拉取其余 |

## 4. zsh 提示符没有路径？

根因排查链：`.zshrc` 里 oh-my-zsh 块被 `[[ -r "$ZSH/oh-my-zsh.sh" ]]` 守卫，
插件没克隆时整个跳过 → zsh 原生默认提示符（只有 `host%`，本来就不带路径）。
`./scripts/plugins --app zsh` 装上 oh-my-zsh + powerlevel10k 后即恢复；
`~/.p10k.zsh` 已由仓库链接，p10k 直接使用现有配置，不触发配置向导。

## 5. doctor 待办（本机遗留）

- `Git local identity is missing`：按需在 `~/.config/git/config.local`
  写 `user.name`/`user.email`（私有文件，绝不入库）。

## 6. 快速重装清单（网络已解决时）

```bash
sudo ./scripts/packages server && ./install server && ./scripts/plugins
# 例外工具
curl -fsSL -o /tmp/nvim.tar.gz https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
mkdir -p ~/.local/opt && tar -C ~/.local/opt -xzf /tmp/nvim.tar.gz && ln -sfn ~/.local/opt/nvim-linux-x86_64/bin/nvim ~/.local/bin/nvim
curl -fsSL -o /tmp/yazi.zip https://github.com/sxyazi/yazi/releases/latest/download/yazi-x86_64-unknown-linux-gnu.zip
python3 -c "import zipfile,os;[open(os.path.expanduser('~/.local/bin/')+n,'wb').write(zipfile.ZipFile('/tmp/yazi.zip').read([i for i in zipfile.ZipFile('/tmp/yazi.zip').infolist() if i.filename.endswith(n)][0])) for n in ('yazi','ya')]" && chmod +x ~/.local/bin/yazi ~/.local/bin/ya
chsh -s /usr/bin/zsh   # 若默认 shell 尚未是 zsh
```

验收：新开终端提示符带路径（p10k）；`nvim` 交互打开确认插件；`scripts/doctor`
全绿（除可选的 git 身份）。

## 7. Windows Terminal 配置（manual 黄金副本）

Windows Terminal 的用户 `settings.json` 由
[`manual/windows-terminal/`](../manual/windows-terminal/) 以 manual 黄金副本
方式跟踪（只含显式键位，不含 profiles 等机器特定内容），不用软链接：该文件
被设置 UI 整体重写，且位于 WSL `$HOME` 链接域之外。核心键位：`alt+[`/`alt+]`
按创建顺序环绕切换 split pane（1.24 源码确认 wrap-around），`alt+shift+d`
复制当前 pane。应用与回写命令见该目录 README（路径从 `$env:LOCALAPPDATA`
推导，无硬编码用户名）。
