# Linux Server 使用指南

在 Debian 或 Ubuntu 主机上从零安装并验证本 dotfiles。按顺序执行；不要手动设置
`DOTFILES_PLATFORM` 或 `DOTFILES_PROFILE`，也不要预先删除已有配置。安装器发现冲突时
会主动停止，不会覆盖未受管文件。

本仓库的 Linux profile 名为 `server`。不支持其他 Linux 发行版，也不支持 WSL。

配置分为三个独立入口，不能用其中一个代替另一个：

```text
./scripts/packages server  安装 APT 软件包，需要网络和 sudo
./install server           只建立 HOME 软链接
./scripts/plugins          克隆 tmux、Vim 和 Zsh 插件
```

## 1. 确认系统受支持

```bash
uname -s
. /etc/os-release
printf 'ID=%s\n' "$ID"
grep -i microsoft /proc/version || true
```

确认：

- `uname -s` 输出 `Linux`。
- `ID` 是 `debian` 或 `ubuntu`。
- 最后一条命令没有输出；若包含 `Microsoft`，当前环境是 WSL，不受支持。

若系统尚未安装 Git，先安装最小引导依赖：

```bash
sudo apt-get update
sudo apt-get install -y git
```

以 root 登录时省略 `sudo`。普通用户运行后续包安装脚本需要
`/usr/bin/sudo`；若系统没有 sudo，请由 root 安装，或由 root 直接完成包安装步骤。

## 2. 准备仓库

仓库必须位于 `~/dotfiles`，因为 shell 启动文件默认从这里加载。首次安装：

```bash
git clone https://github.com/happy-riosky/dotfiles.git "$HOME/dotfiles"
cd "$HOME/dotfiles"
```

仓库已存在时更新并确认状态：

```bash
cd "$HOME/dotfiles"
pwd
git status --short
git pull --ff-only
git log -1 --oneline
```

`pwd` 应输出 `$HOME/dotfiles` 的绝对路径，`git status --short` 应为空。若不为空，
先停止并保留输出，不要覆盖本地改动。

## 3. 验证包安装 dry-run

```bash
./scripts/packages server --dry-run
```

普通用户应看到两行计划，类似：

```text
RUN /usr/bin/sudo /usr/bin/apt-get update
RUN /usr/bin/sudo /usr/bin/apt-get install -y ack autojump ... stow ... tmux ... vim ... zsh
```

root 用户的输出没有 `/usr/bin/sudo`。确认：

- 使用的是 `apt-get`，包清单包含 `autojump`、`fzf`、`stow`、`tealdeer`、`tmux`、
  `vim` 和 `zsh`。
- 普通用户的安装计划以 `/usr/bin/sudo /usr/bin/apt-get install -y` 开头；无需再
  手动逐个执行 `sudo apt install`。
- 没有真正刷新索引、下载或安装软件包。
- 没有出现“不支持 Linux 发行版”或 WSL 错误。

## 4. 正式安装包

```bash
./scripts/packages server
```

脚本会先执行 `apt-get update`，再安装 `package-lists/apt.txt` 中的全部软件包。
应正常返回命令提示符，没有 `E:`、`ERROR` 或非零退出。

包安装与配置建链是两个刻意分开的入口：必须先运行 `./scripts/packages server`。
`./install server` 只建立链接，不会联网、提权或补装 `autojump`、Zsh 等软件包。

APT 清单中的某个包不可用时，脚本会先尝试整批安装；整批失败后自动逐包重试，能正常
下载的包仍会继续安装。若仍有包失败，脚本最后以非零状态退出并保留失败包信息；修复
清单或软件源后重新运行即可。

验证主要二进制：

```bash
command -v ack autojump bc clang curl fzf git pipx rg stow tldr tmux tree urlview vim zsh
```

每一项都应输出路径。额外检查：

```bash
autojump --version
git --version
ssh -V
tmux -V
vim --version
zsh --version
```

`tldr` 命令由 APT 的 `tealdeer` 包提供。清单使用 `tealdeer`，是因为 Ubuntu 26.04
不再为名为 `tldr` 的包提供 installation candidate。

Debian/Ubuntu 清单不安装 LazyGit，因此 `command -v lazygit` 没有输出是预期行为；
只有主机另行安装 LazyGit 后，`lg` alias 才会出现。

## 5. 验证链接 dry-run

```bash
./install server --dry-run
```

因为包安装步骤已安装 GNU Stow，通常会看到 Stow 的模拟输出。此时不应创建目录或
软链接。

如果出现：

```text
link: target exists and is not managed: ...
```

这是安全保护生效。不要直接删除该文件，先查看：

```bash
ls -la "错误信息中的完整路径"
```

确认内容需要保留后，将它备份到 HOME 中不与受管目标重名的位置。例如：

```bash
mv "$HOME/.bashrc" "$HOME/.bashrc.before-dotfiles"
```

然后重新运行 dry-run。对错误中列出的每个冲突逐一确认，不要批量删除。

## 6. 正式建立链接

```bash
./install server
./install server
```

第二次执行用于验证幂等性，应成功且不破坏配置。

检查关键目标：

```bash
ls -l \
  "$HOME/.bash_profile" \
  "$HOME/.bashrc" \
  "$HOME/.profile" \
  "$HOME/.zshenv" \
  "$HOME/.zshrc" \
  "$HOME/.gitconfig" \
  "$HOME/.ssh/config" \
  "$HOME/.tmux.conf" \
  "$HOME/.vimrc" \
  "$HOME/.config/lazygit/config.yml"
```

每个目标都应是指向 `~/dotfiles/home/...` 的叶子软链接。LazyGit 本身可以未安装，
它的配置链接仍会正常建立。

## 7. 配置私有 Git 和 SSH 信息

公开 `.gitconfig` 只包含通用设置，个人身份必须写入未纳入仓库的私有文件：

```bash
mkdir -p "$HOME/.config/git"
git config --file "$HOME/.config/git/config.local" user.name "你的名字"
git config --file "$HOME/.config/git/config.local" user.email "你的邮箱"
chmod 600 "$HOME/.config/git/config.local"
git config --global --includes --get user.name
git config --global --includes --get user.email
```

两条读取命令应分别输出刚设置的姓名和邮箱。

公开 SSH 配置也只是 include stub。主机别名、地址和用户名应放在私有目录：

```bash
mkdir -p "$HOME/.ssh/config.d"
chmod 700 "$HOME/.ssh" "$HOME/.ssh/config.d"
vim "$HOME/.ssh/config.d/local.conf"
chmod 600 "$HOME/.ssh/config.d/local.conf"
```

不要把 `~/.config/git/config.local`、SSH 私钥或 `~/.ssh/config.d/*.conf` 提交到
本仓库。

## 8. 验证并安装插件

先运行 dry-run：

```bash
./scripts/plugins --dry-run
```

新主机上应列出准备安装的 tmux、Vim 和 Zsh 插件，包括 TPM、Lightline、
Oh My Zsh 和 powerlevel10k，但不会下载。

如果出现：

```text
plugins: checkout origin mismatch at ...
```

不要删除或覆盖。检查实际来源：

```bash
git -C "错误信息中的目录" remote get-url origin
```

将结果与 `plugin-lists/*.txt` 对比。确认没有冲突后正式安装：

```bash
./scripts/plugins
./scripts/plugins --dry-run
```

第一次会执行网络克隆，并校验 origin 和 Git 对象。第二次 dry-run 应成功；已存在且
正确的插件通常不会再显示安装计划。

抽查插件来源：

```bash
git -C "$HOME/.tmux/plugins/tpm" remote get-url origin
git -C "$HOME/.oh-my-zsh" remote get-url origin
git -C "$HOME/.vim/pack/vendor/start/lightline.vim" remote get-url origin
```

输出应与对应插件清单中的 GitHub URL 完全一致。

## 9. 验证 Bash 和 Zsh

重新登录 SSH 会话，或分别启动新的 login shell，然后执行：

```bash
bash -lic 'printf "platform=%s profile=%s\n" "$DOTFILES_PLATFORM" "$DOTFILES_PROFILE"'
zsh -lic 'printf "platform=%s profile=%s\n" "$DOTFILES_PLATFORM" "$DOTFILES_PROFILE"'
bash -lic 'type j'
zsh -lic 'type j'
```

前两条都应输出：

```text
platform=linux profile=server
```

后两条都应显示 `j` 是函数或命令，而不是 `j: not found`。

验证 autojump 实际跳转：

```bash
autojump --add "$HOME/dotfiles"
cd "$HOME"
j dotfiles
pwd
```

最终 `pwd` 应输出 `$HOME/dotfiles` 的绝对路径。

检查非交互 shell 保持静默：

```bash
test -z "$(bash -c 'true' 2>&1)" && printf 'Bash non-interactive: PASS\n'
test -z "$(zsh -c 'true' 2>&1)" && printf 'Zsh non-interactive: PASS\n'
```

两项都应显示 `PASS`。

## 10. 验证 tmux、Vim 和 SSH

SSH 只解析配置，不发起连接：

```bash
ssh -G github.com >/dev/null && printf 'SSH config: PASS\n'
```

验证独立 tmux server：

```bash
tmux -L dotfiles-verify -f "$HOME/.tmux.conf" new-session -d -s verify
tmux -L dotfiles-verify list-sessions
tmux -L dotfiles-verify kill-server
```

应看到 `verify` session，且没有配置或插件错误。

验证 Vim 和 Lightline：

```bash
cd "$HOME/dotfiles"
bash tests/vim.sh
```

预期：

```text
vim integration tests passed
```

然后实际打开 Vim：

```bash
vim
```

观察没有启动错误，颜色和状态栏正常，再用 `:q` 退出。

## 11. 运行 doctor

```bash
cd "$HOME/dotfiles"
./scripts/doctor
```

理想结果是所有项目显示 `OK`，最后输出：

```text
doctor passed
```

`doctor` 是独立命令，摘要中的 `profile=unset` 不代表失败；shell 自身的 profile 已在
第 9 步验证为 `server`。

如果出现：

```text
FAIL: Git local identity is missing
```

返回第 7 步配置私有 Git 身份，不要把姓名和邮箱写进仓库的 `.gitconfig`。

## 12. 可选：将 Zsh 设为默认 shell

Bash 和 Zsh 配置都会被安装；不更改默认 shell 也可正常使用。普通 Debian/Ubuntu
账户需要将 Zsh 设为默认 login shell 时执行：

```bash
chsh -s "$(command -v zsh)"
```

`chsh zsh` 是错误写法：不带 `-s` 时，`zsh` 会被解释为用户名。

Multipass 默认的 `ubuntu` 账户没有可供 PAM 验证的密码，直接运行上述命令可能失败。
在 Multipass 实例中应通过 sudo 修改当前用户：

```bash
zsh_path="$(command -v zsh)"
sudo chsh -s "$zsh_path" "$USER"
printf 'expected: %s\n' "$zsh_path"
getent passwd "$USER" | cut -d: -f7
```

最后一条命令应输出与 `expected` 相同的 Zsh 绝对路径；Ubuntu 通常是
`/usr/bin/zsh`。

退出当前 Linux 登录会话并重新登录，再验证：

```bash
printf '%s\n' "$SHELL"
```

应输出 Zsh 的绝对路径。若 `chsh` 被主机策略禁用，保留默认 Bash 即可，不要修改
系统级认证配置绕过限制。

## 验收结果

请记录下面五项：

```text
系统与 profile 检查：PASS/FAIL
packages dry-run + 实际安装：PASS/FAIL
install dry-run + 实际链接：PASS/FAIL
plugins dry-run + 实际克隆：PASS/FAIL
Bash/Zsh + tmux/Vim/SSH + doctor：PASS/FAIL
```

若失败，保留完整命令和原始错误输出，不要先删除冲突文件。

## 常见问题

### 报 Linux server profile supports Debian/Ubuntu only

当前系统的 `/etc/os-release` 中 `ID` 不是 `debian` 或 `ubuntu`。本仓库不会把其他
发行版静默当作 Debian 处理；请停止安装，不要手动伪造 `DOTFILES_OS_ID`。

### 报 WSL is not supported

当前环境由 `/proc/version` 识别为 WSL。WSL 不属于受支持的 `linux:server` 组合，
不要手动设置 `DOTFILES_PLATFORM=linux` 绕过检查。

### packages 找不到 sudo

普通用户安装会调用固定路径 `/usr/bin/sudo`。请让管理员安装 sudo 并授予所需权限，
或由 root 直接运行 `./scripts/packages server`。不要修改脚本去静默跳过权限检查。

### 命令提示 can be installed with sudo apt install

例如 `autojump: command not found` 表示 APT 包安装步骤尚未成功完成。不要逐个手动安装，
回到仓库执行完整清单：

```bash
cd "$HOME/dotfiles"
./scripts/packages server --dry-run
./scripts/packages server
command -v autojump zsh
```

最后一条应输出两个绝对路径。`./install server` 只管理软链接，即使执行成功也不会
安装这些命令。

旧版清单在 Ubuntu 26.04 上还可能出现：

```text
Package tldr is not available
E: Package 'tldr' has no installation candidate
```

APT 会在解析阶段中止整批安装，所以随后检查 `autojump`、Zsh 等命令也会显示未安装。
更新仓库后重新运行 `./scripts/packages server`；当前清单使用提供同名 `tldr` 命令的
`tealdeer` 包。

### Multipass 中 chsh 不生效

先检查当前用户和密码状态：

```bash
printf 'user=%s\n' "$USER"
passwd -S "$USER"
```

Multipass 的 `ubuntu` 用户通常显示 `L`，表示密码已锁定，因此普通 `chsh` 无法完成
PAM 密码验证。使用：

```bash
zsh_path="$(command -v zsh)"
sudo chsh -s "$zsh_path" "$USER"
printf 'expected: %s\n' "$zsh_path"
getent passwd "$USER" | cut -d: -f7
```

确认最后一行与 `expected` 路径相同后退出实例，并从宿主机重新执行
`multipass shell <实例名>`。修改不会改变已经运行中的 shell，重新登录后才会生效。

### autojump 的 j 不生效

先确认包和系统脚本存在：

```bash
command -v autojump
ls -l /usr/share/autojump/autojump.sh
bash -lic 'type j'
zsh -lic 'type j'
```

若系统脚本不存在，保留发行版、包版本和以上输出，再检查该发行版的 `autojump` 包
布局。

### powerlevel10k 主题未生效

提示符停留在 Oh My Zsh 默认样式通常表示 powerlevel10k 尚未克隆。运行
`./scripts/plugins` 后重新登录；首次启动可能进入配置向导，按 `q` 可继续使用仓库的
`~/.p10k.zsh`，也可以执行 `p10k configure` 重新生成。后者会写回仓库文件，运行后
应检查 `git diff`。

### lg alias 不存在

这是 Linux `server` profile 的预期行为：APT 清单不安装 LazyGit，shell 只在
`lazygit` 命令存在时定义 `lg`。如有需要，请用可信的软件源另行安装 LazyGit，然后
重新登录 shell。
