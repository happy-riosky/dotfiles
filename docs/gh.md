# gh（GitHub CLI）与 gh-dash

## 概览

`gh` 是 GitHub 官方命令行工具；`gh-dash` 是它的交互式 TUI 扩展（`gh dash`），
本仓库经 `gd` 启动器接入 tinty 主题与 repo 上下文。本文覆盖安装、认证、常用命令，
以及 gh-dash 的配置与调试；主题接线细节见 docs/theming.md。

## 安装

### gh CLI

- **macOS**：`brew install gh`（已在 `package-lists/brew-formulae.txt`）。
- **Linux/WSL（Debian/Ubuntu）**：不在官方 apt 源，手动装到 `~/.local/bin/gh`
  （与 nvim/yazi 同为「例外工具」，见 docs/wsl.md 第 3/6 节）。gh-dash 的
  sub-issues 面板需 ≥ 2026-06 版（`gh issue view --json` 新增 `parent`、
  `subIssues` 等字段）；本机 2.102.0（2026-09-30）已验证。

```bash
# Linux/WSL 手动安装（macOS 用 brew install gh）
VER=$(curl -s https://api.github.com/repos/cli/cli/releases/latest | jq -r .tag_name)
curl -fsSL -o /tmp/gh.tar.gz "https://github.com/cli/cli/releases/download/${VER}/gh_${VER#v}_linux_amd64.tar.gz"
mkdir -p ~/.local/opt && tar -C ~/.local/opt -xzf /tmp/gh.tar.gz
ln -sfn ~/.local/opt/gh_${VER#v}_linux_amd64/bin/gh ~/.local/bin/gh
gh --version
```

### gh-dash 扩展

```bash
gh extension install dlvhdr/gh-dash
gh extension list           # gh dash  dlvhdr/gh-dash  v4.26.x
gh extension upgrade gh-dash
```

## 认证

```bash
gh auth login               # 交互登录：GitHub.com + HTTPS/SSH + token
gh auth status              # 校验
```

个人 Git 身份不进公开树：写入 `~/.config/git/config.local`（见 docs/linux.md
第 7 节）；SSH host 别名写 `~/.ssh/config.d/*.conf`。

## gh CLI 常用命令

```bash
gh repo view OWNER/REPO                 # 仓库概览
gh pr list | gh pr view N | gh pr checkout N
gh issue list | gh issue view N
gh run list | gh run view ID --log
gh search prs -- "query"
```

`gh issue view --json` 字段速查（gh-dash 的 m 面板依赖）：

- `subIssues` 是 `{nodes, totalCount}` 不是数组；
- `subIssuesSummary` 为 `{total, completed, percentCompleted}`，百分比 0–100；
- `parent`、`issueType`、`blockedBy`、`blocking` 自 2026-06-10 起可用。

## gh-dash 使用

经受管启动器 `gd`（`home/.local/bin/gd`）启动，不要裸跑 `gh dash`：

```bash
gd
```

`gd` 的行为：

- GitHub repo 内：`--config` 叠加 repo-context overlay，隐藏 repo 列
  （`smartFilteringAtLaunch` 已把每个 section 收敛到当前 repo）。
- 每次启动前刷新 `scripts/tinty/generate` 产物 `~/.config/gh-dash/tinty.yml`，
  经 `_tinty_scheme` 标记校验后以 `--config` 叠加（详见下「主题跟随」）。
- 显式 `--config`/`-c`、`GH_DASH_CONFIG`、repo 本地 `.gh-dash.y[a]ml` 一律
  原样透传，不被 overlay 覆盖。

常用键位（`home/.config/gh-dash/config.yml`）：

- `?` 帮助；`q` 返回/退出；`pgup`/`pgdown` 翻页
- issue 上按 `m`：弹出 sub-issues 详情面板
- 其余默认键见 gh-dash 文档；自定义键只在 config.yml 声明

## sub-issues 面板（m）

gh dash 上游不支持 sub-issues（dlvhdr/gh-dash#961 仍 open，且该仓库有严格
No-AI 政策，不适合代提 PR）。本仓库用自定义 keybinding 补齐：Issues 视图按 `m`
弹出详情面板，展示 parent、sub-issues 进度与列表、blocked-by/blocking 依赖。
实现是纯 shell 管道，全部位于 `home/.config/gh-dash/config.yml` 的
`keybindings.issues`。

在 issue 上按 `m`，less 全屏显示，`q` 返回：

```text
#128309 Epic: Replace Webpack with Rspack
type: Epic
sub-issues 13/18 (72%)
  ✔ #129726 Add feature flag for Rspack builds
  ☐ #129730 Rollout Rspack builds to prod
⛔ blocked by #98813 Epic: Upgrade to React 19
```

命令尾部 `| LESS= less > /dev/tty` 两个分量缺一不可：

| 修复分量 | 对抗的根因 | 缺它时的症状 |
| --- | --- | --- |
| `> /dev/tty` | bubbletea v2 的 `tea.ExecProcess` 给子进程的 stdout 是管道（v2.0.2 实测 fd1 NOT-TTY），less 检测到非终端后退化为 cat 模式，EOF 即退 | 输出闪一下立刻回到面板 |
| `LESS=` | 环境变量 `LESS=FR` 中的 `F`（quit-if-one-screen）；终端尺寸已知时必触发 | 内容不超过一屏时 less 秒退 |

## 主题跟随（tinty）

UI 颜色由 tinty 驱动（总纲见 docs/theming.md），经 `gd` 启动器接线：

- 受管 `config.yml` 不定义 `theme.colors`——裸 `gh dash` / 标记校验失败时回退
  gh-dash 内建自适应默认色。
- `gd` 以 `--config` 叠加 `tinty.yml`（纯 `theme.colors` 片段）；repo 内用
  `tinty-context.yml`（repo-context + 主题片段，文本拼接）。
- **单文件 override**：gh-dash 的 `--config`/`GH_DASH_CONFIG`/repo `.gh-dash.yml`
  是单槽位（靠深合并叠在全局配置上），无法像 lazygit 的 `LG_CONFIG_FILE` 逗号
  叠多层；`include:` 虽支持递归与 `~` 展开，但目标缺失会硬报错（v4.25.2
  `internal/config/parser.go` 的 `file.Provider` 未设 Optional）——受管 config
  不能无条件 include 运行时文件（无 tinty 机器会炸）。
- 槽位映射对齐上游 catppuccin/gh-dash（frappe/latte lavender 逐值核对，
  `inverted`/`faint` 取最近槽位 base01/base04）；`secondary` 与 `border.primary`
  用语义强调槽 c_emph（深色=base07，浅色=base05，规避 base07 白字白底）。

### 正文渲染的明暗探测坑

PR/issue 正文用 glamour 渲染，dark→内建 CustomDarkStyleConfig、light→LightStyleConfig，
**由运行时 OSC 11 背景探测决定，与 theme.colors 无关**（v4.25.2
`internal/tui/markdown/markdownRenderer.go`：compat 路径 + bubbletea
`tea.BackgroundColorMsg` 路径，无配置可覆写）。

- **tmux 内探测被缓存的 client 背景代答**：tmux 以 attach 时学到的终端背景回答
  pane 的 OSC 11 查询，`tinty apply` 改 kitty 实际背景不会刷新它。实测
  （tmux 3.5a）：attach 于 latte → 切黑底 scheme 后查询仍被代答 `#eff1f5`
  （latte base）→ gh-dash `--debug` 的 debug.log 显示 `HasDarkBackground: false`
  → 暗色终端下正文渲染成暗字。
- **修复**：tmux 对 pane 级 OSC 11 SET 即设即答（OSC 111 复位）。`gd` 在 tmux
  内且 tinty overlay 新鲜时，启动前向本 pane 发 OSC 11 SET = 当前 scheme 的
  base00（overlay 里 `# _tinty_base00:` 标记，HSL 判定与 scheme variant 一致），
  退出后 OSC 111 复位。**仅 tmux 内发**——裸 kitty/Ghostty 收到会真改窗口背景。
- 普适结论：tmux 内一切依赖 OSC 11 探测明暗的 charm/termenv 工具都会被该缓存
  欺骗；需要可靠明暗时参照 gd 的 pane 级 SET 手法。

## 踩坑记录

1. **键位冲突查默认键源码**：文档只列可覆盖的内置命令，不写默认键。Issues 视图
   `s` 默认绑定 `viewPrs`，定义在 `internal/tui/keys/issueKeys.go`；issues 视图已
   占用 `L a A c C x X t s`，universal 已占用 `j k g G p P o r R h l / y Y ? q`
   与方向键。
2. **对照实验对齐真实终端尺寸**：macOS `script(1)` 的 pty 是 0×0，less 拿不到
   尺寸就不会触发 `LESS=FR` 的 `F`。`stty -a` 出现 `0 rows; 0 columns` 是红旗；
   用 `COLUMNS= LINES=` 补尺寸。
3. **bubbletea v2 exec 的 stdout 是管道**：子进程实测 `fd0 TTY, fd1 NOT-TTY`，
   任何交互工具（less、fzf 等 pager）都会退化成 cat 模式秒退。
4. **静态分析自洽 ≠ 事实**：源码推演三轮都推出 child 应拿到真终端，与实测矛盾；
   40 行复现器一轮拿到铁证。尽早写 1:1 最小复现器（模板见附录）。
5. **报障先收敛症状**："没用"至少四种可能（闪一下回来 / 按 q 无效 / 完全没反应 /
   报错）；结构化问答砍掉一半假设空间。

## 自定义命令机制速查

- 执行：`$SHELL -c <cmd>`（`internal/shell/shell.go`；无 SHELL 时回退 sh）。
  自定义命令会带 `name` 显示在 `?` 帮助菜单。
- issues 视图模板变量：`RepoName`、`IssueNumber`、`IssueTitle`、`Author`、
  `RepoPath`。
- issues 自定义键会透传到通知视图中的 issue 类通知。
- 上游现状：#961 open 且无人认领；AI_POLICY.md 禁止外部贡献含任何 LLM 生成
  内容，贡献需亲手编写。

## 参考

- gh-dash keybindings 文档：<https://gh-dash.dev/configuration/keybindings/custom>
- gh CLI changelog（sub-issues 等 JSON 字段，2026-06-10）：
  <https://github.blog/changelog/2026-06-10-manage-sub-issues-types-and-dependencies-from-github-cli>
- bubbletea v2.0.2 exec.go：
  <https://github.com/charmbracelet/bubbletea/blob/v2.0.2/exec.go>
- gh-dash 默认键位源码：`internal/tui/keys/{keys,issueKeys,prKeys,notificationKeys}.go`

## 附录：TUI exec 环境复现器

遇到"TUI 里 exec 的命令行为诡异"时，用下面的最小复现器实测，替代读码猜。
已在本机验证可复现本文全部结论（bubbletea v2.0.2，macOS，go 1.25）。

`main.go`：

```go
package main

import (
	"fmt"
	"os"

	tea "charm.land/bubbletea/v2"
)

type model struct{}

func (m model) Init() tea.Cmd { return nil }

func (m model) View() tea.View {
	return tea.NewView("\n  press m to run exec, q to quit\n")
}

func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyPressMsg:
		switch msg.String() {
		case "q", "ctrl+c":
			return m, tea.Quit
		case "m":
			return m, tea.ExecProcess(execCustom(), func(err error) tea.Msg {
				if err != nil {
					fmt.Fprintf(os.Stderr, "EXEC ERR: %v\n", err)
				}
				return struct{}{}
			})
		}
	}
	return m, nil
}

func main() {
	if _, err := tea.NewProgram(model{}).Run(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
```

`exec.go`（把 `cmdStr` 换成待测命令；fd 探针与三组对照保留）：

```go
package main

import (
	"os"
	"os/exec"
)

func execCustom() *exec.Cmd {
	shell := os.Getenv("SHELL")
	if shell == "" {
		shell = "/bin/sh"
	}
	cmdStr := `{
		for fd in 0 1 2; do [ -t $fd ] && echo "fd$fd TTY" || echo "fd$fd NOT-TTY"; done
		stty -a < /dev/tty | head -2
		export LESS=FR
		a1=$(date +%s); printf 'p\nq\n' | less;                  echo "A plain:      $(( $(date +%s) - a1 ))s"
		b1=$(date +%s); printf 'p\nq\n' | LESS= less;            echo "B LESS= only: $(( $(date +%s) - b1 ))s"
		c1=$(date +%s); printf 'p\nq\n' | LESS= less > /dev/tty; echo "C full fix:   $(( $(date +%s) - c1 ))s"
	} > /tmp/exectest-diag.log 2>&1`
	return exec.Command(shell, "-c", cmdStr)
}
```

用法：

```sh
go mod init exectest && go get charm.land/bubbletea/v2@v2.0.2
go build -o repro .
(printf 'm'; sleep 4; printf 'q'; sleep 1; printf 'q'; sleep 1) \
  | COLUMNS=100 LINES=30 script -q /dev/null /abs/path/repro
cat /tmp/exectest-diag.log
```

判读：`fd1 NOT-TTY` 即 bubbletea v2 exec 管道 stdout 的实证；A/B 为 0s 而
C 为 3s 即"管道 stdout + LESS 含 F"双重问题的复现与修复验证。注意 `script`
的 pty 无 winsize（0×0），与尺寸相关的行为需用 `COLUMNS=`/`LINES=` 对齐。
