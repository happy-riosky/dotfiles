# gh-dash 配置与调试记录

## 核心结论

gh dash 上游不支持 sub-issues（dlvhdr/gh-dash#961 仍 open，且该仓库有严格
No-AI 政策，不适合代提 PR）。本仓库用自定义 keybinding 补齐：Issues 视图按
`m` 弹出详情面板，展示 parent、sub-issues 进度与列表、blocked-by/blocking
依赖。实现是纯 shell 管道，全部位于 `home/.config/gh-dash/config.yml`。

命令尾部 `| LESS= less > /dev/tty` 是两轮调试的成果，两个分量缺一不可：

| 修复分量 | 对抗的根因 | 缺它时的症状 |
| --- | --- | --- |
| `> /dev/tty` | bubbletea v2 的 `tea.ExecProcess` 给子进程的 stdout 是管道（v2.0.2 实测 fd1 NOT-TTY），less 检测到非终端后退化为 cat 模式，EOF 即退 | 输出闪一下立刻回到面板 |
| `LESS=` | 环境变量 `LESS=FR` 中的 `F`（quit-if-one-screen）；终端尺寸已知时必触发 | 内容不超过一屏时 less 秒退 |

## m 面板

依赖：gh 不低于 2026-06 版本（`gh issue view --json` 新增 `parent`、
`subIssues`、`subIssuesSummary`、`issueType`、`blockedBy`、`blocking` 字段；
本机 2.101.0 已验证）。

在 issue 上按 `m`，less 全屏显示，`q` 返回面板：

```text
#128309 Epic: Replace Webpack with Rspack
type: Epic
sub-issues 13/18 (72%)
  ✔ #129726 Add feature flag for Rspack builds
  ☐ #129730 Rollout Rspack builds to prod
⛔ blocked by #98813 Epic: Upgrade to React 19
```

## tinty 主题跟随

UI 颜色由 tinty 驱动（总纲见 docs/theming.md），经 `gd` 启动器接线：

- 受管 `config.yml` 不定义 `theme.colors`——裸 `gh dash` / 标记校验失败时
  回退 gh-dash 内建自适应默认色。
- `gd` 启动前刷新 `scripts/tinty/generate` 产物 `~/.config/gh-dash/
  tinty.yml`（纯 `theme.colors` 片段，`# _tinty_scheme:` 标记校验同
  lazygit/glow），以 `--config` 叠加在全局 config 之上。
- **repo 内组合**：gh-dash 的 `--config`/`GH_DASH_CONFIG`/repo
  `.gh-dash.yml` 同为**单文件** override（靠深合并叠在全局配置上），无法
  像 lazygit 的 `LG_CONFIG_FILE` 逗号叠多层；`include:` 语法虽支持递归与
  `~` 展开，但**目标缺失会硬报错**（v4.25.2 `internal/config/parser.go`
  的 `file.Provider` 未设 Optional）——受管 config 不能无条件 include
  运行时文件（无 tinty 机器会炸）。故 generate 直接产出拼接版
  `~/.config/gh-dash/tinty-context.yml`（repo-context.yml + 主题片段，
  顶层键 `defaults`/`theme` 不相交，文本拼接即合法单文档 YAML）。
- 槽位映射对齐上游 catppuccin/gh-dash（frappe/latte lavender 逐值核对，
  `inverted`/`faint` 取最近槽位 base01/base04）；`secondary` 与
  `border.primary` 用语义强调槽 c_emph（深色=base07，catppuccin 系恰为
  lavender；浅色=base05，规避 base07=bright white 的 scheme 白字白底）。

### 正文（markdown）渲染的明暗探测坑

PR/issue 正文用 glamour 渲染，dark→内建 CustomDarkStyleConfig（浅字）、
light→glamour LightStyleConfig（深字），**由运行时 OSC 11 背景探测决定，
与 theme.colors 无关**（v4.25.2 `internal/tui/markdown/markdownRenderer.go`：
compat 路径 + bubbletea `tea.BackgroundColorMsg` 路径，无任何配置可覆写）。

- **tmux 内探测被缓存的 client 背景代答**：tmux 以 attach 时学到的终端
  背景回答 pane 的 OSC 11 查询，`tinty apply` 改 kitty 实际背景不会刷新
  它。实测（tmux 3.5a）：attach 于 latte 时期 → 切黑底 scheme 后 pane 查
  询仍被代答 `#eff1f5`（latte base）→ gh-dash `--debug` 的 debug.log 显示
  `HasDarkBackground: false` → 暗色终端下正文渲染成暗字。
- **修复**：tmux 对 pane 级 **OSC 11 SET** 即设即答（实测设 `#123456`
  后查询即答 `rgb:1212/3434/5656`，OSC 111 复位回缓存值）。`gd` 在 tmux
  内且 tinty overlay 新鲜时，启动 gh dash 前向本 pane 发
  OSC 11 SET = 当前 scheme 的 base00（overlay 里 `# _tinty_base00:` 标记
  行，IsDark 的 HSL 判定与 scheme variant 语义一致），退出后 OSC 111
  复位。**仅 tmux 内发**——裸 kitty/Ghostty 收到 OSC 11 SET 会真改窗口
  背景色。经 gd 复验 debug.log 两条路径均 `HasDarkBackground: true`。
- 普适结论：tmux 内一切依赖 OSC 11 探测明暗的 charm/termenv 工具都会被
  该缓存欺骗（tmux 内 OSC 11 不可靠的老经验即此根因）；需要可靠明暗时
  参照 gd 的 pane 级 SET 手法。

## 踩坑记录

### 1. 键位冲突要查默认键位源码，不是内置命令清单

文档只列"可覆盖的内置命令"（label/assign/.../viewPrs），不写默认键。选键时
差点占用 `s`——实际上 Issues 视图 `s` 默认绑定 `viewPrs`（切换视图），定义在
`internal/tui/keys/issueKeys.go` 的 `key.WithKeys(...)`。键位取舍以源码为准：
issues 视图已占用 `L a A c C x X t s`，universal 已占用
`j k g G p P o r R h l / y Y ? q` 与方向键。

### 2. 对照实验必须与真实环境关键维度一致

macOS `script(1)` 造的 pty 是 0 rows × 0 columns（`stty -a` 可见）。less 在
拿不到终端尺寸时不会应用 `LESS=FR` 里的 `F`，因此第一轮 pty 对照实验"证伪"
了 FR——纯属测试环境伪差异。真实终端尺寸恒已知，`F` 必触发。教训：
`stty -a` 输出出现 `0 rows; 0 columns` 要当红旗；对齐真实环境可用
`COLUMNS= LINES=` 环境变量补尺寸。

### 3. bubbletea v2 的 ExecProcess 给子进程的 stdout 是管道

gh-dash v4.25.2（bubbletea v2.0.2）执行自定义命令时，子进程实测
`fd0 TTY, fd1 NOT-TTY`。任何"自以为在终端里"的交互工具（less、fzf 等
pager）都会退化成 cat 模式秒退。这也解释了接 pager 之前的输出闪退。

### 4. 静态分析自洽不等于事实：尽早写 1:1 最小复现器

静态读 bubbletea 源码三轮都推出"p.output = os.Stdout，child 应拿到真终端"，
与实测矛盾。40 行复现器（同版本 bubbletea + 同 ExecProcess 路径 + pty）
一次拿到铁证：fd 探针 + less 前后时间戳三组对照。源码推演三轮的成本远超写
复现器一轮；复现器模板见附录。

### 5. 报障先收敛症状

"没用"两个字至少有四种可能：闪一下回来 / 出来了但按 q 无效 / 完全没反应 /
报错。一次结构化问答（症状分类 + 是否重启加载新配置）直接砍掉一半假设空间。

## 可复用排查链路

```text
命令 shell 单测 → YAML 折叠后字符串校验 → 执行机制确认（$SHELL -c）
→ pty 隔离复现 → 同版本框架 1:1 复现器（fd/stty/winsize/env 逐项实测）
→ 三组对照验证修复
```

## gh-dash 自定义命令机制速查

- 执行：`$SHELL -c <cmd>`（`internal/shell/shell.go`；无 SHELL 时回退 sh）。
  自定义命令会带 `name` 显示在 `?` 帮助菜单。
- issues 视图模板变量：`RepoName`、`IssueNumber`、`IssueTitle`、`Author`、
  `RepoPath`。
- issues 自定义键会透传到通知视图中的 issue 类通知。
- `gh issue view --json`：`subIssues` 是 `{nodes, totalCount}` 不是数组；
  `subIssuesSummary` 为 `{total, completed, percentCompleted}`，百分比取值
  0–100。
- 上游现状：#961（sub-issues 支持）open 且无人认领；AI_POLICY.md 禁止外部
  贡献含任何 LLM 生成内容，贡献需亲手编写。

## 参考

- gh-dash keybindings 文档：<https://gh-dash.dev/configuration/keybindings/custom>
- gh CLI changelog（sub-issues 等 JSON 字段，2026-06-10）：
  <https://github.blog/changelog/2026-06-10-manage-sub-issues-types-and-dependencies-from-github-cli>
- bubbletea v2.0.2 exec.go：
  <https://github.com/charmbracelet/bubbletea/blob/v2.0.2/exec.go>
- gh-dash 默认键位源码：
  `internal/tui/keys/{keys,issueKeys,prKeys,notificationKeys}.go`

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
