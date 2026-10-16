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
日期：2026-10-13
环境：darwin
操作：接入 opencode-claude-code-bridge@latest：home/.config/opencode/
      opencode.json 增顶层 plugin 数组（与 tui.json 的 tinty-theme 数组按
      官方语义合并，不互覆盖）；AGENTS.md OMO/OpenCode 节与 docs/opencode.md
      新增「Claude Code bridge 插件」说明（MCP 导入/skill 桥接/TUI 斜杠
      命令、mcp:false 选项、调试开关、ecc repair 不受影响）。
结果：通过
证据：python3 -m json.tool 经 ~/.config/opencode/opencode.json 软链校验
      通过；./install full --dry-run 与 scripts/doctor 全绿（opencode.json
      链接在位）；git diff --check 干净。
后续：重启 OpenCode 后在 TUI 斜杠面板确认 /lark-doc 等 skill 命令可补全
      （可加 OPENCODE_CLAUDE_CODE_BRIDGE_DEBUG=1 看 injected wrappers）。
``````text
日期：2026-10-13
环境：darwin
操作：opencode.json 的 permission.external_directory 增
      "~/.claude/skills/**": "allow"——skill 兼容根 ~/.claude/skills 未
      放行，agent 读该根加载的 skill 会命中 "*": "ask" 触发授权弹窗；
      docs/opencode.md bridge 节补权限说明。
结果：通过
证据：python3 -m json.tool 校验通过；install full --dry-run 与
      scripts/doctor 绿；git diff --check 干净。
后续：重启 OpenCode 生效。
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
```text
日期：2026-10-14
环境：darwin
操作：chat-popup 更名 askai：脚本与测试 git mv（home/.tmux/scripts/
      askai.sh、tests/askai.sh，历史保留），banner 改「askai  model:」，
      .tmux.conf C-g 绑定路径与 AGENTS.md 验证链同步；历史 progress
      记录按归档规则不改写；~/.tmux/scripts/ 旧悬挂链接清除、新链接
      就位。
结果：通过
证据：bash tests/askai.sh 绿（banner 新字面量断言）；install full
      --dry-run 与 doctor 绿（askai.sh 链接 OK）；git diff --check
      干净；home/tests/AGENTS.md/docs 无 chat-popup 残留引用。
后续：运行中 tmux server 需 prefix+: source-file ~/.tmux.conf 或重启
      后新路径生效。
```
```text
日期：2026-10-14
环境：darwin
操作：ymdl 入库（YouTube/Bilibili 音频下载，rmpc 曲库配套）：新建
      manual/rmpc/ymdl bash wrapper（yt-dlp -f bestaudio/best -x 原始
      音质不重编码，--embed-metadata/--embed-thumbnail，输出模板逗号
      交替字段 %(playlist_title,channel,uploader,title)s 等注意：| 是
      默认字面量不是交替；--trim-filenames 按"整路径"计数且会截断，
      已弃用；--download-archive ~/.local/state/ymdl/ 需先 mkdir 父
      目录；失败下载的孤立封面自动清理），来源分流
      ~/Music/stream-rip/{youtube,bilibili}/，收尾 rmpc update，
      YMDL_COOKIES_FROM_BROWSER 透传会员 cookies；brew-formulae.txt
      加 yt-dlp；manual/rmpc/README.md 重构为 nemdl+ymdl 双下载器
      （含 Bilibili PCDN 海外代理不可达排障）；docs/rmpc.md 日常工作流
      加下载入口指引。
结果：部分通过
证据：YouTube e2e 绿：opus 入库 ~/Music/stream-rip/youtube/Rick
      Astley/、tags/封面内嵌、archive 增量（重跑 skip）、rmpc listall
      可见；bash -n + tests/packages.sh + install full --dry-run +
      doctor 全绿。Bilibili：提取/模板/封面全对，音频流被 mcdn PCDN
      （仅 CN 可达）+ 本机 clash 日本出口阻断（TLS SSL_ERROR_SYSCALL，
      curl 直连/代理均复现，upos CDN 可达），排障与对策记 README。
后续：Bilibili 音频流待网络侧修复后复验（clash 把 bilivideo.cn 改
      DIRECT 或等 B 站改发可达 CDN）；无 .lrc 抓取（两站无歌词源），
      歌词仍走 docs/rmpc.md 手动流程。
```
```text
日期：2026-10-15
环境：darwin
操作：① ymdl 失败诊断升级：BV14J8F6sEqN 复现 mcdn PCDN 阻断
      （音频流仅发 xy*.mcdn.bilivideo.cn:8082，元数据/封面正常），
      wrapper 增加 SSL 特征检测（UNEXPECTED_EOF_WHILE_READING/
      SSL_ERROR_SYSCALL + bilibili 来源），命中即打印指向 README
      已知问题的对策提示，孤立封面清理照常。② link 抗 Finder 噪音：
      用户浏览仓库后 home/ 出现 .DS_Store，source_entries 把
      ~/.DS_Store 当受管目标触发 check_target_conflicts 中止；
      lib-dotfiles.sh source_entries 按basename 跳过任意深度的
      .DS_Store，仓库内现存 7 个已删，tests/link.sh 新增
      test_ds_store_is_ignored（顶层+嵌套+用户已有 ~/.DS_Store
      三态断言）。
结果：通过
证据：诊断输出（mcdn host + 10×SSL EOF）；ymdl 对 BV14J8F6sEqN
      打印对策提示；tests/link.sh 含新用例全绿；全套件（link/shell/
      packages/plugins/termux/tmux/tmux-zen/askai）+ install full
      --dry-run + doctor + git diff --check 全绿。
后续：PCDN 阻断本体属网络侧（clash 日本出口 + CN-only PCDN 节点），
      待用户在 clash 加 bilivideo.cn DIRECT 规则或 B 站改发 upos
      CDN 后复验；YouTube 路径不受影响。
```

```text
日期：2026-10-15
环境：darwin
操作：tmux 窗口换号/位移键位。① prefix+. 重定义：目标号被占不报错、不
      交换——先 park 到 :999（renumber-windows 收敛到末尾）再
      move-window -b 插到目标窗口之前，精确落位 n、其余窗口顺位补号
      （-b 是"紧邻目标之前"语义，左侧邻位是 no-op、左侧远处只贴前一格，
      park 保证恒从右侧插入；3.5a 隔离 server 逐条实测）；号空缺（超界）
      则直接 move-window 收敛到末尾；焦点随窗口走。② prefix+S-Left/
      S-Right：当前窗口左/右移一位，swap -d 让焦点随窗口走（无 -d 焦点
      留在原槽位，实测确认），首/末窗口守卫防 -1/+1 环绕（实测会环绕）；
      run 绑定参数触发时做格式展开，#{window_index} 必须 ## 双写留给
      内层 tmux 逐窗口展开。③ tests/tmux.sh 加两条静态契约
      （test_prefix_dot_renumber_binding / test_relative_shift_bindings）；
      新增 tests/tmux-window-move.sh 运行时测试（zen 模式：隔离 server，
      从 conf 提取真实绑定串驱动，断言占位落位/顺位补号/超界收敛/自指
      稳定/焦点跟随/边界不环绕）；AGENTS.md 验证清单加该测试。
结果：通过
证据：bash tests/tmux-window-move.sh / tmux.sh / tmux-zen.sh 绿；全套件
      （link/shell/packages/plugins/termux/tmux/tmux-zen/tmux-window-move/
      askai）+ install full --dry-run + doctor + git diff --check 全绿；
      活跃 server source-file 重载后 list-keys 确认三键就位。
后续：无
```

```text
日期：2026-10-15
环境：darwin
操作：修复 prefix+. 换号键 "can't find window: %%"。根因：command-prompt
      模板占位符语义——%% 只替换首个出现、%1 才全替换（man 原文），原
      模板三处 %% 仅 grep 里那处拿到数字，两处 move-window 收到字面 %%。
      测试漏网原因：提取路径自行替换占位符，绕过了 command-prompt 替换
      层。修复：① 模板三处 %% → %1（conf 注释记录该语义）；②
      tests/tmux.sh 静态契约加禁用 %% / 至少两处 %1 守卫；③
      tests/tmux-window-move.sh 新增 pty 端到端（script(1) 附着真实客户端
      按键驱动 prefix+. → 提示符 → 提交，断言拼接落位）：pty 驱动三个
      实测陷阱——先到的字节被 canonical 行规程吃 \r、与 prefix 同批的
      正文被提示符接管输入时丢弃（须分批 0.3s 间隔）、按键丢失 attach
      不退（后台 + 10s 看门狗）；script 语法 BSD/util-linux 探测，缺失
      跳过。用旧 %% 模板回归验证 e2e 确实失败（布局不变）。
结果：通过
证据：bash tests/tmux-window-move.sh（含 e2e）/ tmux.sh 绿；旧 %% 模板
      下 e2e 场景布局不变（bug 复现）；全套件 + git diff --check 绿；
      活跃 server 重载后 list-keys 确认模板已是 %1。
后续：无
```

```text
日期：2026-10-15
环境：darwin
操作：按用户要求移除 tests/tmux-window-move.sh（提取式运行时断言与 pty
      端到端覆盖随之放弃——command-prompt %1 替换链路失去 e2e 守卫，静态
      契约（tests/tmux.sh 禁 %%、要求 %1）仍在）。AGENTS.md 验证清单与
      .tmux.conf 注释中的引用同步回退。
结果：通过
证据：bash tests/tmux.sh / tmux-zen.sh 绿；AGENTS.md、.tmux.conf 无残留
      tmux-window-move 引用（progress.md 历史记录除外）。
 后续：无
```

```text
日期：2026-10-15
环境：darwin
操作：① treesitter 安装清单加 jsdoc parser；用户查询扩展注入——
      queries/ecma/injections.scm（// 与 /* */ 注释含 @tag 时注入
      jsdoc）、queries/html_tags/injections.scm（<!-- --> 同理，vue/
      html 经 html_tags 继承一并覆盖）。
      ② queries/jsdoc/highlights.scm 整体替换 runtime 查询（无 extends
      即接管）：tag_name → @keyword.jsdoc，init.lua 按主题 Statement
      色定义为非粗（去除 Keyword→Statement 的 bold 泄漏），FocusGained
      随 tinty 换主题重放。
      ③ todo-comments：TSDIRECTIVE（alt=ts-expect-error 等，canonical
      名做组名）整词补齐 @ts-* 高亮——\v 正则关键词含裸 @ 会炸且
      pcall 吞错、wide 风格 finish+1 行尾越界毁全 buffer，故 alt 不带
      @ + 模式自带 [@] 前缀组 + keyword=bg 精确 span；TodoBgTSDIRECTIVE
      在延迟 colors() 前重定义为前景红，豁免大写关键词的色块风格。
结果：通过
证据：headless nvim 实测 6 种注释形态（/** */、//、/* */、<!-- -->、
      @param、@ts-expect-error）capture=keyword.jsdoc 无旧捕获泄漏；
      todo extmark 精确 span（TODO 青绿底块加粗、@ts-* 前景红非粗、
      行尾关键词不越界）；install full --dry-run + doctor 通过。
后续：queries/jsdoc/highlights.scm 为 runtime 查询的 fork，插件升级时
      需人工比对同步；本记录待与 rmpc/.DS_Store 流的 progress.md 改动
      一并提交。
```

```text
日期：2026-10-15
环境：darwin
操作：opencode TUI 时间戳显示落地：自研本地插件
      home/.config/opencode/tui-plugins/timestamps.tsx（id
      riosky.timestamps）注册 sidebar_content（操作时间线，新到旧，
      user/thinking/response/tool 纯文字标签，主题色区分，默认折叠，
      maxRows 15）与 session_prompt_right（dim "user · ai" 时间对）两个
      slot；时钟当天 HH:MM:SS、跨天 MM-DD HH:MM；message.updated /
      message.part.updated 事件 + 5s 自愈轮询驱动重渲染。
      先用第三方 spec（github:gmammolo/opencode-timestamps、
      @aii4all/opencode-show-timestamps）验证可行性后弃用：@latest/
      github: spec 每次启动走 npm/git 网络解析，慢路由卡启动（用户实测
      launch 挂起）；github: 能装不能载（加载 pass 解析不出入口）；
      aii4all 的 pkg/tui 子路径 spec 是非法包名，安装静默失败。已清
      ~/.cache/opencode/packages 对应目录与 plugin-meta.json 残留条目。
      TSX 运行时依赖一次性装进 ~/.config/opencode/node_modules
      （solid-js/@opentui/core/@opentui/solid，运行时产物不入库）。
      AGENTS.md OMO 节、docs/opencode.md「时间戳显示插件」同步改写
      （含远程 spec 教训）。插件加载确认后修 prompt 对配色：opentui
      <text> 无 dim prop（静默忽略落回默认白），改用
      api.theme.current.textMuted（与输入框 footer provider 标签同色，
      参照 v1.18.26 prompt/index.tsx fadeColor(textMuted, 1) 的稳态）。
结果：通过
证据：python3 -m json.tool 校验 tui.json 通过；./install full
      --dry-run 与 scripts/doctor 全绿（timestamps.tsx 叶子链接由
      link 建立）；npm install 102 包成功；plugin-meta.json 残留
      aii4all 条目已 prune。重启后 plugin-meta 出现 riosky.timestamps
      条目、侧栏 Timestamps 区块与 prompt 时间对可见。
后续：次日正式启用前按用户要求 git stash 整体存档（wip(opencode):
      riosky.timestamps TUI plugin）：tui.json 撤下 spec、HOME 侧叶子链接
      已摘、plugin-meta 再 prune riosky.timestamps 条目；node_modules
      依赖保留在 ~/.config/opencode。恢复 = stash pop + scripts.link +
      tui.json plugin 数组重加 ["./tui-plugins/timestamps.tsx",
      {"maxRows": 15}]。AGENTS.md 精简改版后不再记应用细节；应用文档按
      用户要求不写（仅 docs/todo.md 备忘几行）；opencode 原生支持全消息
      时间戳（issue #41589）后可考虑退役。
```

```text
日期：2026-10-16
环境：darwin
操作：Neovim 片段补全启用：uncomment init.lua LuaSnip 节预留的
      friendly-snippets 两行（vim.pack.add + from_vscode.lazy_load）。
      其 global.json 跨 filetype 提供 date（YYYY-MM-DD）/datetime/time 等
      日期片段（$CURRENT_* 变量展开时取值），blink 菜单 <C-y> 展开即插入
      今日日期；经评估未新增自定义片段模块（内置 date 前缀已满足需求）。
      docs/neovim.md 增「片段（friendly-snippets）」一节。
结果：通过
证据：nvim --headless 首启克隆 friendly-snippets（首次尝试 transient
      git config 锁失败且目录自清，重试成功）；nvim-pack-lock.json 新增
      friendly-snippets 条目（rev b4d01b0，git diff 仅此一条）；headless
      校验 setf markdown 后 get_snippets('all') 含 trig=date，
      snip_expand 输出与 os.date('%Y-%m-%d') 同值（2026-10-16）、markdown
      片段 76 个；scripts/doctor 通过；git diff --check 干净；
      tests/{link,shell,packages,plugins,termux}.sh 与 tmux/tmux-zen/
      askai 测试全绿。
后续：server/Termux 机器各自首启 nvim 时克隆该插件（安装状态按机器隔离）；
      若上游 global.json 的 date 格式变化，再考虑自定义 LuaSnip 片段覆盖。
```

```text
日期：2026-10-16
环境：darwin
操作：swansay/swanthink 入库：aliases.sh 新增两个 command -v 守卫别名，
      经 -f 直接指向 $DOTFILES_ROOT/manual/cowsay/swan.cow（manual/ 不
      参与 link/unlink/doctor），不拷贝、不设 COWPATH；manual/cowsay/
      README.md 重写——移除 ~/.cows + COWPATH 方案，改为别名即用，并记录
      为何不装进 cowsay 默认 cow 目录（/opt/homebrew/share/cowsay/cows/
      是 Cellar 符号链接，拷入文件随 brew upgrade/reinstall 丢失）。
结果：通过
证据：cowsay/cowthink -f manual/cowsay/swan.cow 直渲正常；zsh/bash 经
      load.{zsh,bash} source 后 swansay 输出天鹅气泡；zsh -n aliases.sh；
      git diff --check 干净；tests/shell.sh（含 scripts/shell 主机路径
      grep）全绿。
后续：无。
```

```text
日期：2026-10-16
环境：darwin
操作：swanhonk 入库：新增 manual/cowsay/swanhonk.cow（swan.cow 自制变体，
      闭合喙 _ 张开为 <<，朝气泡 honk 姿态，仍纯 / 线条零转义）；
      aliases.sh 增 swanhonk 别名（-f 直指仓库文件，守卫/注释同步三个
      别名）；manual/cowsay/README.md 改为双 cowfile 文档（新增变体说明、
      swanhonk 用法与预览，修正 swansay 预览缩进）。
结果：通过
证据：cowsay -f manual/cowsay/swanhonk.cow "HONK!" 渲染 <<o) 喙形正常，
      输出与 README 预览一致（三个别名逐一比对）；zsh -n aliases.sh；
      git diff --check 干净；tests/shell.sh 全绿。
后续：无。
```
