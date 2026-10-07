# macOS 应用配置

本指南覆盖 `full` profile 的 macOS 专属应用配置。请在仓库根目录执行仓库命令；
包安装、配置链接与插件安装见 [README](../README.md)。

## 配置管理

macOS Preferences plist 是**真实文件**，绝不是软链接。黄金文件位于
`platforms/darwin/managed/`；普通应用配置文件使用受管软链接。

| 配置 | 形态 | 仓库来源 | 工具 |
|--------|---------|-------------------|------|
| 核心（Git、SSH、tmux、Vim、shell） | 叶子软链接 | `home/` | `install` |
| Karabiner | 目录软链接 | `platforms/darwin/home/.config/karabiner/` | `install` |
| Amethyst | 叶子软链接 | `platforms/darwin/home/.config/amethyst/amethyst.yml` | `install` |
| AeroSpace | 叶子软链接 | `platforms/darwin/home/.config/aerospace/` | `install` |
| Hammerspoon | 叶子软链接 | `platforms/darwin/home/.hammerspoon/init.lua` | `install` |
| Mouseless | 叶子软链接 | `platforms/darwin/home/Library/Application Support/Mouseless/configs/config.yaml` | `install` |
| Git delta + tinty 主题 | 叶子软链接 | `platforms/darwin/home/.config/git/config` | `install` |
| 系统快捷键 | 真实 plist | `platforms/darwin/managed/hotkeys/` | `scripts/hotkeys-*.sh` |
| Rectangle | 真实 plist | `platforms/darwin/managed/hotkeys/` | `scripts/hotkeys-*.sh` |
| 应用 Preferences | 真实 plist | `platforms/darwin/managed/preferences/` | `scripts/prefs-*.sh` |

## 恢复偏好设置

```bash
bash scripts/hotkeys-restore.sh --yes
bash scripts/prefs-restore.sh --yes
```

备份保存到 `~/.local/state/dotfiles/`。省略 `--yes` 时会先要求确认。

## 修改后导出偏好

```bash
bash scripts/hotkeys-export.sh
bash scripts/prefs-export.sh
git add platforms/darwin/managed
git commit -m "chore(macos): update preference goldens"
```

## 配置 Amethyst

Amethyst 的 YAML 配置维护在
`platforms/darwin/home/.config/amethyst/amethyst.yml`，由 `./install full`
链接到 `~/.config/amethyst/amethyst.yml`。支持的位置、设置项与命令语法见
Amethyst [官方配置文件文档](https://github.com/ianyh/Amethyst/blob/development/docs/configuration-files.md)；
[官方示例配置](https://github.com/ianyh/Amethyst/blob/development/.amethyst.sample.yml)
也是有用的参考。

Amethyst 的 GUI 偏好单独存储，自定义 YAML 配置优先于 GUI 设置。每个设置只从
一个来源管理，避免行为混乱；编辑 YAML 后重启 Amethyst，并运行
`./scripts/doctor` 验证受管链接。存在自定义配置时，应用的配置文件警告属预期。

## 配置 AeroSpace

AeroSpace 的 TOML 配置维护在
`platforms/darwin/home/.config/aerospace/aerospace.toml`，由 `./install full`
链接到 `~/.config/aerospace/aerospace.toml`。通过链接文件做的修改会立即反映在
Git 中。

## 配置 Hammerspoon Space 控制

Hammerspoon 配置维护在 `platforms/darwin/home/.hammerspoon/init.lua`，由
`./install full` 链接到 `~/.hammerspoon/init.lua`。用 `./scripts/packages full`
或 `brew install --cask hammerspoon` 显式安装 Hammerspoon。启动应用，在系统
设置中授予辅助功能权限，修改配置后从其菜单栏菜单选择 `Reload Config`。底层
运行时与 Space 操作见 Hammerspoon [入门指南](https://www.hammerspoon.org/go/)
与 [`hs.spaces` API 文档](https://www.hammerspoon.org/docs/hs.spaces.html)。

当前快捷键使用**左 Command+Control+Shift**，避开 Amethyst 绑定与本仓库
Karabiner 既有的右 Command 层：

| 快捷键 | 动作 |
|----------|--------|
| `左 Command+Control+Shift+N` | 创建原生 Space 并切换过去 |
| `左 Command+Control+Shift+E` | 把普通窗口从当前 Space 移到相邻 Space |
| 连按两次 `左 Command+Control+Shift+D` | 切走并删除当前原生 Space |
| `左 Command+Control+Shift+F` | 退出焦点应用的原生全屏模式 |

Hammerspoon 收到的 Command 是聚合修饰键，自身无法区分左右 Command。这些绑定
请使用左 Command；右 Command 保留给既有的 Karabiner 层。

Space 操作使用 Hammerspoon 的 `hs.spaces` 模块，可能短暂显示 Mission Control。
该模块依赖 macOS 辅助功能行为与私有 API；若 macOS 更新后删除 Space 失败，手动
使用 Mission Control，不要盲目关闭窗口。除非已妥善处理未保存的文档，不要把
清除动作绑定到"关闭全部窗口"式的工作流。当前 Space 为全屏或 Split View 时 `N`
同样可用；`E` 和 `D` 刻意拒绝这类 Space，需先按 `F` 或原生
`Control+Command+F` 快捷键退出。

清除动作只移动仅属于当前 Space 的普通窗口。分配给所有桌面（All Desktops）、
全屏应用、Split View 或其他特殊 Space 的窗口会被跳过。删除 Space 会把其剩余
窗口移到另一个 Space，不会关闭这些应用。删除快捷键要求两秒内按两次，且绝不
删除最后一个常规桌面 Space。

## 配置 Homerow

在 Homerow 的 Settings 中配置激活快捷键。以下笔记描述 **2026-09-07** 查证的上游
报告，不是本机已验证的设置；示例绑定尚未应用到 Homerow 或 Karabiner。

### 需按两次的 Space 快捷键

需要按两次才激活 Homerow 不是正常工作流，也不是已配置 double-tap 激活的证据。
[Issue #212](https://github.com/nchudleigh/homerow/issues/212)（2026-03-31 提出）
报告了影响 **1.5.0–1.5.3** 中 `Command+Shift+Space` 的回归，**1.4.x** 正常：

- 第一次按无动作，第二次才激活 Homerow。
- 事先单独按一次 Space，下一次激活第一次就生效。
- 关闭 Homerow 后，其他 Space 快捷键（如 Raycast 的 `Command+Space`）也可能
  需要按两次。
- 报告者禁用 Karabiner 与 BetterTouchTool 后仍可复现；其他用户确认了相同症状，
  包括 macOS Tahoe。

截至查证日该 issue 仍为 open。[官方 changelog](https://www.homerow.app/changelog)
最新条目为 **1.5.3（2026-03-19）**，没有针对此 bug 的明确修复。这些报告并不能
解释所有本机激活失败的原因。

报告的变通方案：

1. 检查无冲突后，改用不含 Space 的快捷键，如 `Command+Shift+F`。issue 作者
   报告这样第一次按键即生效。
2. 或者关闭 **Automatic click**。[有用户报告此方案可行](https://github.com/nchudleigh/homerow/issues/212#issuecomment-4641217347)，
   但之后每次点击目标都需要用 Space 或 Return 确认。

### 单一模式的多个快捷键

不同模式的独立快捷键，不等于一个模式被多个快捷键激活。后者未有原生支持的确
证：请求让 `Command+Shift+J` 与 `Command+Shift+K` 都激活 scroll 模式的
[issue #181](https://github.com/nchudleigh/homerow/issues/181) 截至查证日仍为
open。讨论中推荐用 Karabiner 变通；这是社区建议，不是官方对产品限制的声明。

例如，把想要的 Homerow 模式绑定到 `Command+Shift+F`，再用 Karabiner 把
`左 Command+Shift+Space` 映射到同一快捷键。两个物理快捷键都能进入同一模式，
而 Homerow 收到的是不含 Space 的快捷键。使用左 Command 以避开本仓库的右
Command 层，检查两个快捷键有无冲突，并在已安装版本上实测两个入口。该组合映射
是提议的变通方案，不是本机已验证的修复。

## 配置 Mouseless

Mouseless 的 YAML 配置维护在
`platforms/darwin/home/Library/Application Support/Mouseless/configs/config.yaml`，
由 `./install full` 链接到
`~/Library/Application Support/Mouseless/configs/config.yaml`。通过链接文件
做的修改会反映在 Git 中。

当前 `mac` 键位包含：

| 快捷键 | 动作 |
|----------|--------|
| Meh+M（`Control+Option+Shift+M`） | 切换 overlay（`toggle overlay`） |
| `Escape` | 隐藏 overlay |
| Meh+F（`Control+Option+Shift+F`） | 切换 free mode（`toggle free mode`） |
| `Escape` | 退出 free mode |
| overlay 可见时按 `Tab` | 打开配置编辑器 |

Meh 指 Control+Option+Shift，不含 Command。YAML 绑定为
`toggle overlay: ctrl+alt+shift+M` 与 `toggle free mode: ctrl+alt+shift+F`。
在未被当前 Karabiner profile 忽略的键盘上，Karabiner 把左 Command 的 tap 变成
Meh+M、左 Option 的 tap 变成 Meh+F。按住任一修饰键仍透传原始的左 Command 或左
Option，因此 Mouseless 的 `hold for drag` 与 `hold for move` 依然可用。
Meh+M 与 Meh+F 的透传例外必须排在一般 Control 映射之前。其他 Control 编辑
快捷键不变。

设置也可以从 Mouseless 菜单访问。配置编辑器中的修改立即生效；在编辑器中保存
才会持久化到磁盘。

**在外部编辑 YAML 文件后，重启 Mouseless 才能加载修改。**该文件在启动时读取；
不要指望热重载。即使 Git 已显示期望的修改，运行中的实例及其设置界面仍可能显示
旧绑定。见[官方配置文档](https://mouseless.click/docs/customizing_mouseless.html)。

手动编辑文件前，先优雅退出 Mouseless 并确认它已停止：

```bash
osascript -e 'if application "Mouseless" is running then tell application "Mouseless" to quit'
osascript -e 'application "Mouseless" is running'
```

编辑文件前第二条命令必须输出 `false`。若输出 `true`，先完成保存/确认对话框，
等应用退出后再检查。然后编辑仓库 YAML 文件或其链接的 HOME 路径，并启动应用：

```bash
open -a "Mouseless"
```

对已运行的应用执行 open 不会重启它。启动后确认 Settings 中 `toggle overlay`
显示 Control+Option+Shift+M、`toggle free mode` 显示 Control+Option+Shift+F。
tap 左 Command 切换 overlay，tap 左 Option 开关 free mode，按 Escape 退出两种
状态。分别检查已保存的 diff 与受管链接：

```bash
git diff -- "platforms/darwin/home/Library/Application Support/Mouseless/configs/config.yaml"
./scripts/doctor
```

这些仓库检查不能验证运行中的应用实际加载了哪份配置。YAML 缺失或无效时，
Mouseless 会回退到默认值。

## tinty 主题

tinty 用一条命令把同一个 base16/base24 scheme 应用到 kitty、zsh（含 fzf）、
tmux、Neovim、lazygit、opencode 和 git-delta。scheme 清单位于
`home/.config/tinted-theming/tinty/config.toml`（全平台）；macOS 专属的 delta
pager 设置链接自 `platforms/darwin/home/.config/git/config`。生成的主题文件是
运行时产物，绝不提交。安装与日常使用见 [theming.md](theming.md)。

## Docker Desktop

Docker Desktop 的 `$HOME/.docker/daemon.json` 刻意不由本仓库管理。
[Docker 官方文档](https://docs.docker.com/desktop/settings-and-maintenance/settings/#docker-engine)
把它描述为 Docker Engine 配置文件，并指引用户在 Docker Desktop 或文本编辑器中
修改。它保持为本地真实文件，因为 Docker Desktop 启动时可能拒绝软链接。

## TCC 保护域

`com.apple.Music.plist` 可能拒绝 `cp`（`Operation not permitted`）。给终端授予
完全磁盘访问，或手动从黄金文件复制。
