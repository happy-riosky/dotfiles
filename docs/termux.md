# Termux 使用指南

在真实 Termux 设备上从零安装并验证本 dotfiles。按顺序执行；不要手动设置
`DOTFILES_PLATFORM` 或 `DOTFILES_PROFILE`，也不要预先删除已有配置——安装器发现
冲突时会主动停止。

## 1. 确认仓库

仓库必须位于 `~/dotfiles`，因为 shell 启动文件默认从这里加载：

```bash
cd "$HOME/dotfiles"
pwd
git status --short
git pull --ff-only
git log -1 --oneline
```

观察：

```text
/data/data/com.termux/files/home/dotfiles
```

`git status --short` 应为空。若不为空，先停止并保留输出。

## 2. 验证包安装 dry-run

```bash
./scripts/packages termux --dry-run
```

应只出现一行计划：

```text
RUN pkg install -y ack-grep autojump ... lazygit ... tmux ... vim ... zsh
```

确认：

- 包含 autojump 和 lazygit。
- 没有 sudo。
- 没有真正下载或安装输出。

## 3. 真实安装包

先从与当前 Termux 相同的来源安装并打开 Android 端的 Termux:API 应用；
`termux-api` 包只提供命令行客户端，两者必须来源匹配。

先刷新 Termux 软件源索引：

```bash
pkg update
./scripts/packages termux
```

应看到 Termux 安装包，最终正常返回命令提示符，没有 `E:`、`ERROR` 或非零退出。

验证二进制：

```bash
command -v ack autojump git jq ssh termux-battery-status tmux urlview vim zsh lazygit
```

每一项都应输出 `$PREFIX/bin/...` 路径。

额外检查：

```bash
autojump --version
git --version
ssh -V
tmux -V
vim --version
lazygit --version
```

`jq` 和 `termux-battery-status` 分别由 `jq`、`termux-api` 提供；它们是
tmux 电池状态栏的运行时依赖。若 `termux-battery-status` 不存在，请确认
Termux:API 应用也已安装并与当前 Termux 来源匹配。

`urlview` 不是包，而是本仓库提供的脚本（`platforms/termux/home/.local/bin/urlview`，
基于 fzf），由 `./install termux` 链接到 `~/.local/bin/urlview`，供
tmux-urlview 使用。

## 4. 验证链接 dry-run

```bash
./install termux --dry-run
```

首次安装时应看到准备创建的链接，或者 Stow 的模拟输出。此时不应真正创建链接。

如果出现：

```text
link: target exists and is not managed: ...
```

这是安全保护生效。不要直接删除该文件，先查看：

```bash
ls -la "错误信息中的完整路径"
```

例如 LazyGit 冲突可先备份：

```bash
mv "$HOME/.config/lazygit/config.yml" \
  "$HOME/.config/lazygit/config.yml.before-dotfiles"
```

然后重新运行 dry-run。

## 5. 正式建立链接

```bash
./install termux
./install termux
```

第二次执行用于验证幂等性，应成功且不重复破坏配置。

检查关键目标：

```bash
ls -l \
  "$HOME/.bash_profile" \
  "$HOME/.bashrc" \
  "$HOME/.zshenv" \
  "$HOME/.zshrc" \
  "$HOME/.gitconfig" \
  "$HOME/.ssh/config" \
  "$HOME/.tmux.conf" \
  "$HOME/.vimrc" \
  "$HOME/.config/lazygit/config.yml"
```

每个目标应是指向 `~/dotfiles/home/...` 的软链接。

## 6. 验证插件 dry-run

```bash
./scripts/plugins --dry-run
```

新设备上应列出准备安装的 tmux、Vim 和 Zsh 插件（含 powerlevel10k），但不会下载。

如果出现：

```text
plugins: checkout origin mismatch at ...
```

不要删除或覆盖。检查实际来源：

```bash
git -C "错误信息中的目录" remote get-url origin
```

将结果与 `plugin-lists/*.txt` 对比。

## 7. 正式安装插件

```bash
./scripts/plugins
./scripts/plugins --dry-run
```

第一次会执行网络克隆并进行 origin 和 git fsck 校验。

第二次 dry-run 应成功；已存在且正确的插件通常不会再显示安装计划。

抽查：

```bash
git -C "$HOME/.tmux/plugins/tpm" remote get-url origin
git -C "$HOME/.oh-my-zsh" remote get-url origin
git -C "$HOME/.vim/pack/vendor/start/lightline.vim" remote get-url origin
```

应分别输出与清单完全相同的 GitHub URL。

## 8. 应用 Termux 专属补丁

```bash
./scripts/termux-zvm-fix --dry-run
./scripts/termux-zvm-fix
exec zsh -l
```

修复 `zsh-vi-mode` 光标样式在 Termux 上的报错（详见
[process.md](./process.md) 的已知问题章节）。验证：启动无报错，`zvm_version`
正常输出，`Esc` 后 `0`/`w`/`b` 移动、`i` 返回插入均可用。

## 9. 验证 Bash 和 Zsh

最好新开一个 Termux 会话，然后执行：

```bash
bash -lic 'type j'
zsh -lic 'type j'
```

两者都应显示 j 是函数或命令，而不是：

```text
j: not found
```

验证 autojump 实际跳转：

```bash
autojump --add "$HOME/dotfiles"
cd "$HOME"
j dotfiles
pwd
```

最终 pwd 应输出：

```text
/data/data/com.termux/files/home/dotfiles
```

检查 LazyGit alias：

```bash
bash -lic 'alias lg'
zsh -lic 'alias lg'
```

应显示 lg 指向 lazygit。

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

应看到 verify session，且没有配置错误。

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

理想结果是所有项目显示 OK，最后：

```text
doctor passed
```

真实 Termux 需要特别观察两类失败：

```text
/bin/bash: No such file or directory
FAIL: clean Bash startup failed
```

这表示 doctor 使用了 macOS/Linux 的固定 /bin/bash 路径，是需要回报并修复的真实
Termux 兼容问题；不要自行创建 /bin 软链接。

```text
FAIL: Git local identity is missing
```

这表示设备尚未创建私有 Git 身份，不代表链接失败。身份应写到私有文件：

```bash
git config --file "$HOME/.config/git/config.local" user.name "你的名字"
git config --file "$HOME/.config/git/config.local" user.email "你的邮箱"
```

## 验收结果

请记录下面五项：

```text
packages dry-run：PASS/FAIL
packages 实际安装：PASS/FAIL
install dry-run + 实际链接：PASS/FAIL
plugins dry-run + 实际克隆：PASS/FAIL
Bash/Zsh + autojump + doctor：PASS/FAIL
```

若失败，保留完整命令和原始错误输出，不要先删除冲突文件。

## 常见问题

### autojump 的 j 不生效

`j` 存在但无法跳转，且 `print -r -- "$chpwd_functions"` 输出
`autojump_chpwdautojump_chpwd`：说明 autojump 被加载了两次（Termux 系统
profile 与旧版 dotfiles loader），hook 名被拼接。当前版本 loader 已不再重复
加载；更新仓库后重新打开 shell 即可。

### zsh-vi-mode 报 zvm_cursor_style 正则错误

```text
zvm_cursor_style:34: failed to compile regex: trailing backslash (\)
```

Termux 的 zsh 无法编译该正则，且仅设 `ZVM_CURSOR_STYLE_ENABLED=false` 不够。
运行第 8 步的 `./scripts/termux-zvm-fix` 即可。

### powerlevel10k 主题未生效

提示符停留在 oh-my-zsh 默认样式：说明 powerlevel10k 未克隆。运行
`./scripts/plugins` 后重新打开 shell；首次启动可能进入配置向导，按 `q` 跳过
即用仓库的 `~/.p10k.zsh` 配置，或用 `p10k configure` 重新生成（注意它会写回
仓库文件，记得提交）。
