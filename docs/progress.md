# Dotfiles 操作记录（开发日志）

每次收尾操作在本文末尾追加一条记录；活跃待办与备忘见
[`todo.md`](./todo.md)，已完成待办的历史记录归档在 [`archive/`](./archive/)。

## 记录格式

每条记录至少包含：

```text
日期：YYYY-MM-DD
环境：darwin | server | termux | 临时 HOME
操作：执行的命令或结构调整
结果：通过 | 失败 | 部分通过
证据：关键输出、diff 或测试命令
后续：仍需处理的事项
```

## 归档规则

待办条目完成或记录超过一个季度后，把对应记录整条迁入
[`archive/operations.md`](./archive/operations.md)（按时间正序插入，内容原样
保留，不改写）；本文只保留仍被活跃待办引用的记录。2026-09 的 5 条记录已
归档。

## 记录

```text
日期：2026-10-07
环境：darwin
操作：rmpc/MPD 入库：platforms/darwin/home/.mpdconf（osx 输出、
      ~/.local/state/mpd 运行时数据）与 platforms/darwin/home/.config/rmpc/
      config.ron（lyrics_dir=~/Music）leaf-link 管理；brew-formulae.txt 加
      mpd/rmpc；aliases.sh 加 mpu；下载 .lrc 批量补 [ti:]/[ar:] 头；新增
      docs/rmpc.md 并在 README/AGENTS 加引用。
结果：通过
证据：rmpc lyricsindex 18/18 匹配（title/artist 非空）、rmpc listall
      19 曲、scripts/doctor 与 tests/link|shell|packages 全绿。
后续：rmpc TUI 原子重写会吃掉 ~/.config/rmpc/config.ron 叶子链接
      （2026-10-07 已复现一次，./install full 恢复；同备忘节 Otty 原子写
      问题），恢复法见 docs/rmpc.md 排障节。
```

```text
日期：2026-10-08
环境：darwin
操作：yazi 原地重启入库：keymap.toml 绑 R → quit --code=99（默认键位无
      单键 R；进程无法自行重启，见 sxyazi/yazi#1757，须由外层拉起），
      aliases.sh 的 y() 改哨兵循环——退出码 99 时重刷 tinty/generate 并经
      --cwd-file 回到最后浏览目录重新拉起（重启后原显式参数丢弃；正常
      退出仍不改 shell cwd）；theming.md yazi 节与排障同步。
结果：通过
证据：tests/shell.sh 新增 test_yazi_restart_wrapper（zsh+bash：99 重启、
      cwd 恢复、generate 每次启动前重跑、退出码透传、无 cwd 文件时保留
      原参数）；隔离 tmux server 真机 smoke：R 后进程参数为
      `yazi ~/dotfiles --cwd-file=…`，R→q 往返 YRC:0；全套件（link/shell/
      packages/plugins/termux/tmux/vim）与 install --dry-run、doctor 绿。
后续：yazi 26.9.1 在 tmux pane 内启动后前数秒吞键（裸 yazi 同样复现，
      与本改动无关，输入就绪后一切正常）；macOS mktemp -t 不展开 XXXXXX
      （BSD 前缀语义），cwd 临时文件名含字面 XXXXXX 但唯一，无功能影响。
```

```text
日期：2026-10-10
环境：darwin
操作：chat-popup 六项增强（.local/chat-popup.md）：Human prompt 染
      tinty 蓝（ANSI 34=color4=base0D，随 tinty apply 自动跟随，无 tinty
      降级终端蓝；\001/\002 防 readline 折行错乱）；AI 前缀染 ANSI 33=
      color3=base0A 黄锚点（仅显示侧 printf，convo 转写保持纯文本协议，
      普通 printf 无需 \001/\002）；PgUp copy-mode 绑定曾实现后按需移除
      （tmux 3.x key table server 全局、key 名须 PPage、PageUp rc=0 静默
      无效，实测 3.5a——留档备查；弹窗内滚轮/prefix+[ 原生翻滚 scrollback
      已覆盖需求，脚本回归零 tmux 耦合）；Ctrl-D EOF 直接退出（免
      尾部复制提示，/q 保留）；read -e 输入历史（启动 history -c 防 ↑
      翻出 shell 历史、unset HISTFILE 防退出写回 bash_history，聊天不留
      本地痕迹；连续重复去重；非交互 tty 直跑自动 re-exec bash -i）；
      /tr 自动 zh↔en 与 /po 同语言润色（均一次性 aichat，按普通回复格式
      打印并更新 resp 供 /y 复制，不进 convo 转写）。banner 热键清单外移 /h 帮助命令（banner 只
      留 "(/h for help)"）。尾部复制键改读 stdin（弹窗内等价、headless
      可测）。新增 tests/chat-popup.sh（stub aichat/pbcopy + 隔离 tmux
      server 绑定断言——随 PgUp 移除一并删除；prompt 着色与 ↑/C-r 历史需
      真 tty，经 BSD script
      pty 烟测覆盖）。
结果：通过
证据：bash tests/chat-popup.sh 绿（对话/复制/转写/EOF 直退//tr //po
      prompt+convo 纯净/AI 前缀 ESC[33m 字节断言/usage//h 帮助与 banner
      外移）；
      全套件 link/shell/
      packages/plugins/termux/tmux/tmux-zen 与 install full --dry-run +
      doctor 绿；pty 烟测：prompt 含 ESC[34m 且无 \001 泄漏、↑ 召回重发、
      Ctrl-D 无尾提示直退。
后续：候选——经 ~/.config 配置自定义 /xx 一次性命令（prompt 替换类，
      /tr /po 同款机制），需要时再设计。
```

```text
日期：2026-10-11
环境：wsl（Ubuntu，复用 server profile）
操作：gh + gh-dash 安装与使用文档化。gh 二进制手动装到 ~/.local/bin/gh
      （预编译 tarball → ~/.local/opt/，软链），gh-dash 经
      `gh extension install dlvhdr/gh-dash` 安装（v4.26.1）。docs/gh-dash.md
      改名为 docs/gh.md 并重写（gh CLI + gh-dash）；docs/wsl.md 第 3/6 节补
      gh/gh-dash 例外工具条目；
      关闭 Server 工具链审计的 gh-dash 供应机制待办（采用「例外工具表记手动
      安装」方案，不做 plugin-lists/gh.txt + scripts/plugins --app gh）。
结果：通过
证据：gh version 2.102.0 (2026-09-30)；gh extension list 输出
      `gh dash dlvhdr/gh-dash v4.26.1`；which -a gh 仅 ~/.local/bin/gh
      （先前 ~/.opencode/bin/gh 冗余软链已删）。
后续：macOS 侧 gh 走 brew（brew-formulae.txt 已有），gh-dash 扩展需在 macOS
      实机 `gh extension install dlvhdr/gh-dash` 后经 gd 验证。
```

```text
日期：2026-10-12
环境：darwin
操作：Telescope 项目切换接入：新增 lua/custom/plugins/project.lua
      （DrKJeff16/project.nvim 维护 fork，vim.pack 自动安装，lock 入库），
      <leader>sp → :Telescope projects；<CR>/w 仅切 cwd（无 session
      集成），picker 内 f/s/r/b/d/n 找文件/grep/最近/浏览/删除/重命名；
      docs/neovim.md 增插件列表与「项目切换」节。
结果：通过
证据：nvim --headless 启动零报错并自动安装 project.nvim；
      :checkhealth project 全绿（setup OK、git 检测、历史文件创建，
      dotfiles 已入史）；<leader>sp 映射在位；lock diff 仅新增
      project.nvim 条目；install --dry-run 与 doctor 绿。
后续：无。
```

```text
日期：2026-10-13
环境：darwin
操作：prefix+O ocv→opencode 兜底：home/.tmux.conf 改为 run-shell 先探测
      （zsh -c "command -v ocv || command -v opencode"，非交互 .zshenv 亦
      组装 nvm/Homebrew PATH），有则 new-window 经 zsh -c exec 绝对路径
      （ocv launcher 为 #!/usr/bin/env node 需 node 上 PATH），都缺则零
      副作用不开窗；弃 zsh -ic（无 tty 污染 stderr "zle"）。tests/tmux.sh
      增 test_prefix_o_fallback_chain 契约。
结果：通过
证据：tests/tmux.sh 与 tmux-zen.sh 绿、git diff --check 干净；隔离
      server e2e：真 HOME 按键路径开新窗（cmd=node、cwd=目标 pane 路径），
      HOME+PATH 双清环境零开窗（仅剩初始 1 窗），仅 opencode 时探测返回
      /opt/homebrew/bin/opencode（exec 路径与 ocv 分支同一机制）。
后续：无。
```
```text
日期：2026-10-14
环境：darwin
操作：tests/chat-popup.sh 补两条变异实验证实的覆盖缺口：(1) /q 尾部
      y/Y 复制路径（此前尾部按键只发过 n，chat-popup.sh 内联复制分支
      0% 覆盖）——断言 close... (copied) 标记与 pbcopy 字节，空回复时
      静默；(2) aichat 失败路径——stub 遇 prompt 含 boom 即 exit 1，
      覆盖主循环与 oneshot 的 [error] 输出及 set -e 下循环存活。
结果：通过
证据：bash -n + bash tests/chat-popup.sh 全绿；变异复核：尾部 == y 改
      == x、两处 [error] %s 改 BOOM %s 均由原「存活」转为「被抓」；
      git diff --check 干净（shellcheck 未装）。
后续：banner head -n 4 启发式检查（Nit）可换 banner 逐字节前缀精确
      断言；错误路径的 resp 残留语义（/y 复制到错误文本）仍未钉。
```
