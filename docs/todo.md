# Dotfiles 活跃待办与操作记录

重构收尾的历史记录已归档到 [`archive/process.md`](./archive/process.md)，已完成
的操作记录迁入 [`archive/operations.md`](./archive/operations.md)；本文档只跟踪
仍未完成的事项、备忘与近期操作记录，追加与归档规则见文末。

## 1. 活跃待办

### Neovim AI 补全

- [ ] 接入 GitHub Copilot ghost text（已有订阅）：`vim.pack.add { gh 'github/copilot.vim' }`
      + `:Copilot setup`（需 Node.js），Tab 接受建议；与 blink `preset = 'default'`
      （`<C-y>` 接受）无按键冲突。
- [ ] 可选：从 stash 恢复 minuet/DeepSeek FIM 作手动后备（`<A-y>` 触发；恢复时需把
      minuet 移出 blink `default` sources，避免与 Copilot 双自动请求、双成本）。
      注：本机磁盘克隆残留已清（2026-09-30，见
      [`archive/operations.md`](./archive/operations.md)）；恢复 stash 后 vim.pack
      会按 lock 条目自动重装。

### Termux

- [ ] 确认 doctor 在 Termux 上依赖 `/bin/bash` 的问题（2026-08-14 记录，见
      `archive/process.md` 的真实 Termux 验证节）。

### Neovim Diffview 移除

- [ ] lazygit 浮窗（`3b25917`）已覆盖 diff/stage/历史工作流，移除 diffview.nvim：
      删 `init.lua` 中 diffview 的 `vim.pack.add` 行（plenary 保留，neo-tree 仍
      依赖）与 `<leader>gd/gs/gf/gh` 映射、catppuccin 的 `diffview = true`
      集成项；同步更新 `docs/neovim.md`（受管文件与主题节）；随后
      `:lua vim.pack.del({ 'diffview.nvim' })` 卸载磁盘克隆并清理
      `nvim-pack-lock.json`（`vim.pack.update()` 只更新已装插件，不会移除条目）。

### Server 工具链审计（2026-09-29）

- [ ] gh-dash 扩展无供应机制：`gd` 启动器与 `home/.config/gh-dash/` 配置已入库，
      但扩展本机未装（`gd` 当前不可用）。候选：`plugin-lists/gh.txt` +
      `scripts/plugins --app gh`（走 `gh extension install`）vs docs/wsl.md
      例外工具表记手动安装；gh 二进制（不在 Ubuntu 官方源，本机
      `~/.local/bin/gh` 手动安装）一并入例外表。
- [ ] bat/fd-find 适配：Debian/Ubuntu 命令名为 `batcat`/`fdfind`，`fr`/`fp`
      alias 与 yazi `md-preview.sh` 依赖 bat。候选：apt 加包 + aliases
      fallback 适配 vs 保持可选缺失。
- [ ] Stow 后端隐患：apt.txt 装 stow 后 `scripts/link` 自动选 stow 后端，
      与 direct 后端创建的绝对路径链接冲突（本机 `./install server
      --dry-run` 即 abort，"existing target is not owned by stow"），
      `tests/link.sh` 的绝对路径断言同样假设 direct。候选：apt.txt 移除
      stow / server 强制 direct / 整体迁移 stow；过渡期本机用
      `DOTFILES_LINK_BACKEND=direct` 覆盖。
- [ ] ollama 文档化：`ai-git-commit-message` 的可选后端
      （`OLLAMA_COMMIT_MODEL`，需本机 ollama 服务）。
- [ ] brew 侧已补 `fd`/`git-delta`/`jq`（18131f9），待 macOS 实机
      `brew install` 验证。

## 2. 备忘

- Otty：已退管（2026-09-16）；其保存配置用原子写（temp+rename），rename 不跟随
  软链，会把叶子软链顶回实体文件。若未来需要版本化，改用
  `platforms/darwin/managed/` 黄金文件 + export/restore 模式（参照 macOS
  Preferences），不要软链。
- kitty 标题栏切主题闪青/白（macOS 26 Liquid Glass + kitty 标题栏色 hack，
  2026-10-06）：纯瞬态、最终态正确，暂不处理；完整根因与源码依据见
  `docs/theming.md` 排障节，日后有兴趣可据此报上游 issue。

## 3. 操作记录

每次收尾操作在本文末尾追加一条记录，至少包含：

```text
日期：YYYY-MM-DD
环境：darwin | server | termux | 临时 HOME
操作：执行的命令或结构调整
结果：通过 | 失败 | 部分通过
证据：关键输出、diff 或测试命令
后续：仍需处理的事项
```

归档规则：待办条目完成或记录超过一个季度后，把对应记录整条迁入
[`archive/operations.md`](./archive/operations.md)（按时间正序插入，内容原样
保留，不改写）；本文只保留仍被活跃待办引用的记录。2026-09 的 5 条记录已
归档。

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
