# Dotfiles 活跃待办

重构收尾的历史记录已归档到 [`archive/progress.md`](./archive/progress.md)，已完成
的操作记录迁入 [`archive/operations.md`](./archive/operations.md)；本文档只跟踪
仍未完成的事项与备忘，操作记录（开发日志）见 [`progress.md`](./progress.md)。

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
      `archive/progress.md` 的真实 Termux 验证节）。

### Neovim Diffview 移除

- [ ] lazygit 浮窗（`3b25917`）已覆盖 diff/stage/历史工作流，移除 diffview.nvim：
      删 `init.lua` 中 diffview 的 `vim.pack.add` 行（plenary 保留，neo-tree 仍
      依赖）与 `<leader>gd/gs/gf/gh` 映射、catppuccin 的 `diffview = true`
      集成项；同步更新 `docs/neovim.md`（受管文件与主题节）；随后
      `:lua vim.pack.del({ 'diffview.nvim' })` 卸载磁盘克隆并清理
      `nvim-pack-lock.json`（`vim.pack.update()` 只更新已装插件，不会移除条目）。

### Server 工具链审计（2026-09-29）

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

- opencode 时间戳 TUI 插件已整体 stash（2026-10-16，`wip(opencode):
  riosky.timestamps TUI plugin`）：侧栏操作时间线 + 输入框旁 user/ai 时间对。
  恢复：`git stash pop` → `./scripts/link` → `tui.json` plugin 数组重加
  `["./tui-plugins/timestamps.tsx", {"maxRows": 15}]`（TSX 依赖已装在
  `~/.config/opencode/node_modules`；教训：远程 spec 每次启动走网络解析会卡
  启动，只用本地 file spec）。原生全消息时间戳跟踪：opencode#41589。
- Otty：已退管（2026-09-16）；其保存配置用原子写（temp+rename），rename 不跟随
  软链，会把叶子软链顶回实体文件。若未来需要版本化，改用
  `platforms/darwin/managed/` 黄金文件 + export/restore 模式（参照 macOS
  Preferences），不要软链。
- kitty 标题栏切主题闪青/白（macOS 26 Liquid Glass + kitty 标题栏色 hack，
  2026-10-06）：纯瞬态、最终态正确，暂不处理；完整根因与源码依据见
  `docs/theming.md` 排障节，日后有兴趣可据此报上游 issue。
