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
