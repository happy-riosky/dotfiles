# Dotfiles 活跃待办与操作记录

重构收尾的历史记录已归档到 [`archive/process.md`](./archive/process.md)，本文档
只跟踪仍未完成的事项，并按文末格式继续追加操作记录。

## 1. 活跃待办

### Neovim AI 补全

- [ ] 接入 GitHub Copilot ghost text（已有订阅）：`vim.pack.add { gh 'github/copilot.vim' }`
      + `:Copilot setup`（需 Node.js），Tab 接受建议；与 blink `preset = 'default'`
      （`<C-y>` 接受）无按键冲突。
- [ ] 可选：从 stash 恢复 minuet/DeepSeek FIM 作手动后备（`<A-y>` 触发；恢复时需把
      minuet 移出 blink `default` sources，避免与 Copilot 双自动请求、双成本）。

### Termux

- [ ] 确认 doctor 在 Termux 上依赖 `/bin/bash` 的问题（2026-08-14 记录，见
      `archive/process.md` 的真实 Termux 验证节）。

### Neovim Diffview 移除

- [ ] lazygit 浮窗（`3b25917`）已覆盖 diff/stage/历史工作流，移除 diffview.nvim：
      删 `init.lua` 中 diffview 的 `vim.pack.add` 行（plenary 保留，neo-tree 仍
      依赖）与 `<leader>gd/gs/gf/gh` 映射、catppuccin 的 `diffview = true`
      集成项；同步更新 `docs/neovim.md`（Managed Files 与 Theme 节）；随后
      `:lua vim.pack.update()` 确认 `nvim-pack-lock.json` 相应清理。

## 2. 备忘

- Otty：已退管（2026-09-16）；其保存配置用原子写（temp+rename），rename 不跟随
  软链，会把叶子软链顶回实体文件。若未来需要版本化，改用
  `platforms/darwin/managed/` 黄金文件 + export/restore 模式（参照 macOS
  Preferences），不要软链。

## 3. 操作记录

后续每次收尾操作在本文末尾追加一条记录，至少包含：

```text
日期：YYYY-MM-DD
环境：darwin | server | termux | 临时 HOME
操作：执行的命令或结构调整
结果：通过 | 失败 | 部分通过
证据：关键输出、diff 或测试命令
后续：仍需处理的事项
```

### Neovim AI 补全试验（2026-09-16）

- 日期：2026-09-16
- 环境：darwin（真实设备，`full` profile），Neovim 0.12.5，minuet-ai 0.10.x。
- 操作：试验 DeepSeek FIM 补全：minuet-ai.nvim 以 blink.cmp 源接入
  （`openai_fim_compatible` @ `api.deepseek.com/beta/completions`，
  `deepseek-v4-flash`，key 走 `~/.zshenv.local` 的 `DEEPSEEK_API_KEY`，不入库）。
  功能调通后诊断延迟：blink 菜单模式须等整段生成完成才渲染（FIM 后端在 curl
  退出后一次性回调），叠加通用模型长补全（max_tokens=256）生成时间。调优
  （n_completions=1、throttle=1000、debounce=400、context_window=4000、
  blink timeout_ms=3000）后仍约 2s；API 直连实测 0.9s@64token，端点本身不慢，
  差距来自专用小模型+流式渲染的 Copilot/Cursor 架构。
- 结果：功能通过、延迟不达标，相关变更（init.lua、neovim.md、
  nvim-pack-lock.json）已整体 stash，条目名
  "wip(nvim): DeepSeek FIM completion via minuet (latency unsatisfactory)"。
- 后续：见第 1 节 Neovim AI 补全；恢复前先 `git stash list` 确认 ref（另有一个
  obsidian stash）。

### 收尾清理完成（2026-09-16）

- 日期：2026-09-16
- 环境：darwin（真实设备，`full` profile）
- 操作：完成收尾清理前两项。其一，`legacy/backup`（36M）整体迁至
  `~/backup/legacy-backup-20260916` 后删除 `legacy/`，并移除 `.gitignore` 与
  AGENTS.md 的 legacy 条目；`.mackup*` 确认已无残留（`fdb85c9`）。其二，评估
  公开仓库历史隐私清理：历史 `backup/.ssh/config` 含公网 IP `8.130.76.0`
  （已下线）与内网 IP `10.219.88.147`；`backup/.gitconfig` 与全部 commit
  元数据含 QQ 邮箱（135+21 个）。
- 评估证据：全历史敏感词扫描（password/token/api_key/secret/BEGIN）零凭据
  命中；`.docker/config.json` 空 auth；`.wget-hsts` 仅公共域名；历史其余为
  过时 mackup 结构与偏好黄金文件；QQ 邮箱在 GitHub commit 元数据本就公开。
- 结果：决定不做历史重写——无凭据泄露、唯一公网 IP 已下线，收益小于 force
  push 与多机重 clone 的成本；commit 时间线本就不受影响，亦无必要。
- 后续（可选）：GitHub 默认分支仍为旧 `darwin`（mackup 结构，main 的祖先），
  建议网页切默认分支到 `main` 后删除 `darwin`；stash 补丁双备份在
  `~/backup/stash/`，恢复方式见 Neovim AI 补全待办。

### lazygit × Neovim 联动（2026-09-17）

- 日期：2026-09-17
- 环境：darwin（真实设备，`full` profile），lazygit 0.64.1，Neovim 0.12.5。
- 操作：lazygit 共享配置加 `os.editPreset: nvim-remote`（`e` 在父 Neovim 新
  tab 回开、staging 面板跳行），修复 customCommands 主机路径并给剪贴板命令加
  pbcopy/wl-copy/xclip 级联守卫；新增 nvim 浮窗插件
  `lua/custom/plugins/lazygit.lua`（`<leader>gg`，仓库根 cwd，`q`/TermClose
  关窗，缺二进制仅警告）；新增 `home/.config/lazygit/frappe.yml` 片段，浮窗内
  经 `LG_CONFIG_FILE` 多文件合并切换 catppuccin frappe 深色（delta 去
  `--light`），终端裸跑仍 Latte；`tests/shell.sh` 将
  `home/.config/{lazygit,nvim}` 纳入主机路径扫描。
- 结果：通过（`6d38d87`、`9593629`、`3b25917`）。
- 证据：`install full --dry-run` / `scripts/link` / `scripts/doctor` 与
  link/shell/packages/plugins/termux/vim 六套集成测试全过；`nvim --headless`
  断言 `:LazyGit`/`:LazyGitConfig` 注册且片段已链接。
- 后续：浮窗内 `e` 回开链路与 frappe 配色需真实终端交互确认；diffview.nvim
  移除见第 1 节。
