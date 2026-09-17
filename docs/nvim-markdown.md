# Neovim Markdown 阅读环境手册（frogmouth 体验版）

由两个插件组成，均通过 `home/.config/nvim/lua/custom/plugins/` 下的 vim.pack 模块加载：

- **render-markdown.nvim** — buffer 内渲染 markdown（正文阅读视图）
- **aerial.nvim** — 大纲侧栏（frogmouth 的 Contents 面板）

前置依赖（kickstart 配置已具备）：markdown / markdown_inline treesitter parser、
mini.icons、Nerd Font、termguicolors。markdown 大纲走 treesitter backend，无需 LSP。

## 开场三步

```bash
nvim ~/dotfiles/README.md   # 打开即渲染
<leader>a                   # 开 TOC 侧栏并聚焦
q                           # 关侧栏回到正文
```

## 一、正文渲染 — render-markdown.nvim

| 操作 | 效果 |
|---|---|
| （无操作） | normal 模式自动渲染：标题底色、表格对齐、真实 checkbox、代码块边框 |
| 光标移动 | anti-conceal：光标行自动还原原文 |
| `i` → `Esc` | 编辑时原文、退出后恢复渲染 |
| `<leader>tm` | 全局开关渲染 |
| `:RenderMarkdown preview` | 侧边常渲染视图（不受模式影响） |
| `:RenderMarkdown expand` / `contract` | 增/减光标周围原文显示范围 |
| `:RenderMarkdown config` | 查看与默认配置的差异（调优起点） |

## 二、TOC 侧栏 — aerial.nvim

开关：`<leader>a`（`:AerialToggle`，无 bang = 打开并聚焦）。

> 注意：aerial 新版语义为 `focus = not bang`，`AerialToggle!` 反而是"打开但不聚焦"，
> 与旧版 README 约定相反。

### 侧栏内按键

| 键 | 行为 |
|---|---|
| `j` / `k` | 移动 TOC 光标 |
| `J` / `K` | TOC 移动 + 文档跟滚 |
| `<PageDown>` / `<PageUp>` | 滚动文档整页，焦点留 TOC，章节高亮同步跟踪 |
| `p` | 文档滚到光标章节，不抢焦点（对位） |
| `Enter` | 跳转并聚焦文档 |
| `<C-j>` / `<C-k>` | （全局语义）焦点移到下/上窗口；侧栏内 C-h/j/k/l 四向导航完整 |
| `}` / `{`、`]]` / `[[` | 下/上一个符号；上/下一层级 |
| `o` / `za`、`l` / `h` | 折叠/展开节点（`L` / `H` 递归） |
| `zR` / `zM` | 全展开 / 全折叠 |
| `q` | 关闭侧栏并回到文档 |
| `?` | 显示全部按键帮助 |

`J`/`K`/`<PageUp>`/`<PageDown>` 为本仓库自定义绑定（见
`custom/plugins/aerial.lua` 的 `keymaps` 表）；`<C-j>`/`<C-k>` 显式置空以恢复
全局窗口导航。

### 推荐阅读流（frogmouth 复刻）

1. `<leader>a` 进 TOC → `J`/`K` 快速浏览章节（文档跟滚预览）
2. 章节内 `<PageUp>`/`<PageDown>` 深读内容（焦点不离开目录）
3. 看准后 `Enter` 落地，或继续 `J` 下一章
4. `q` 收工

诊断：`:AerialInfo`（backend 检测）。

## 三、维护与回滚

- **更新插件**：`:lua vim.pack.update({ 'aerial.nvim' })`（render-markdown.nvim 同理），
  lock file（`home/.config/nvim/nvim-pack-lock.json`）自动更新后随仓库提交
- **调优入口**：侧栏宽度 `layout = { min_width = 20 }`；高亮模式 `highlight.mode`；
  位置 `layout.default_direction = 'prefer_left'`
- **回滚**：删 `custom/plugins/{aerial,render-markdown}.lua` +
  `git checkout home/.config/nvim/nvim-pack-lock.json`，跑一次 `./install` 清链接

## 四、已知注意点

- 自定义按键必须挂在 `setup({ keymaps = ... })` 表上（callback table 形式）；
  `on_attach` 回调的是**源 buffer**（markdown buffer）的 attach 事件，不是侧栏
  buffer——挂错位置按键会注册进 markdown buffer
- tmux 下 `<PageUp>`/`<PageDown>` 正常透传（进 copy-mode 时归 tmux，属预期）
- 侧栏内 PageUp/PageDown 已重定向为滚文档；滚 TOC 本身用 `j`/`k`、`G`/`gg`
