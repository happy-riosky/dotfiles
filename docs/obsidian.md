# 从命令行打开 Obsidian Vault

## 直接答案

在 macOS 上，**真正打开或聚焦一个已经注册的 vault**，最直接的方法是使用 Obsidian URI：

```bash
# 打开名为 Notes 的 vault
open "obsidian://open?vault=Notes"

# vault 名称包含空格时，空格必须写成 %20
open "obsidian://open?vault=My%20Vault"
```

这里的 `Notes` 或 `My Vault` 是 Obsidian Vault Switcher 中显示的 vault 名称。

如果问题特指“能否用 `obsidian <vault>` 打开”，答案是：**不能**。官方 `obsidian` CLI 的单次命令模式没有“只打开 vault”的子命令。要么使用上面的 URI，要么先执行 `obsidian` 进入 TUI，再使用 `vault:open`。

如果不确定名称，先查看 Obsidian 已注册的所有 vault：

```bash
# 列出 vault 名称及其文件系统路径
obsidian vaults verbose
```

示例输出可能是：

```text
Notes      /Users/me/Documents/Notes
Work       /Users/me/Documents/Work
```

然后使用输出中的名称：

```bash
# 打开上面列出的 Work vault
open "obsidian://open?vault=Work"
```

## 最容易混淆的区别

下面三种方式看起来相似，但作用不同。

### 1. URI：打开或聚焦 vault

```bash
# 推荐：直接打开或聚焦 Notes vault
open "obsidian://open?vault=Notes"
```

这是在普通 shell 中“打开一个 vault”最明确的命令。

### 2. TUI：在 Obsidian CLI 中切换 vault

先进入交互式终端界面：

```bash
# 启动 Obsidian CLI 的交互式界面
obsidian
```

再在 TUI 中输入：

```text
# 将当前 TUI 切换到 My Vault
vault:open name="My Vault"
```

`vault:open` 只能在 TUI 中使用，不能直接写成下面这样：

```bash
# 错误：vault:open 不是单次 shell 命令
obsidian vault:open name="My Vault"
```

### 3. `vault=`：指定某条命令作用于哪个 vault

```bash
# 在 Notes vault 中打开今天的日记
obsidian vault=Notes daily

# 在 Work vault 中搜索 TODO
obsidian vault=Work search query="TODO"
```

`vault=` 不是独立的“打开 vault”命令。它只是指定后面的 `daily`、`search`、`open` 等命令应该作用于哪个 vault，并且必须写在实际命令之前。

## 使用 Vault ID 打开

名称可能重复，自动化时建议使用 vault ID：

```bash
# 使用 16 位 vault ID 打开 vault
open "obsidian://open?vault=ef6ca3e3b524d22f"
```

获取 ID 的方法：

1. 打开 Obsidian Vault Switcher。
2. 右键目标 vault。
3. 选择 **Copy vault ID**。

## 打开 Vault 中的文件

### 按文件名打开

`file=` 使用 Obsidian wikilink 的文件解析方式，可以省略目录和 `.md` 扩展名：

```bash
# 在当前目标 vault 中打开 Recipe.md
obsidian open file=Recipe

# 在 Notes vault 中打开名为 Project plan 的文件
obsidian vault=Notes open file="Project plan"
```

如果有多个同名文件，应该改用精确路径。

### 按 vault 相对路径打开

CLI 的 `path=` 是**从 vault 根目录开始的相对路径**：

```bash
# 打开当前目标 vault 中的 Templates/Recipe.md
obsidian open path="Templates/Recipe.md"

# 在 Notes vault 中打开 Projects/2026/Plan.md
obsidian vault=Notes open path="Projects/2026/Plan.md"

# 在新标签页中打开文件
obsidian vault=Notes open path="Projects/2026/Plan.md" newtab
```

不要把文件系统绝对路径传给 CLI 的 `path=`：

```bash
# 错误：CLI 的 path= 不接受这种文件系统绝对路径
obsidian open path="/Users/me/Documents/Notes/Projects/Plan.md"
```

### 使用 URI 打开文件

```bash
# 打开 Notes vault 中的 Projects/Plan.md
open "obsidian://open?vault=Notes&file=Projects%2FPlan.md"

# 在新标签页中打开同一个文件
open "obsidian://open?vault=Notes&file=Projects%2FPlan.md&paneType=tab"
```

URI 中的 `/` 必须编码为 `%2F`，空格必须编码为 `%20`。

### 使用文件系统绝对路径打开文件

URI 的 `path=` 与 CLI 的 `path=` 不同。URI 接受编码后的文件系统绝对路径：

```bash
# 通过绝对路径打开文件；路径中的 / 已编码为 %2F
open "obsidian://open?path=%2FUsers%2Fme%2FDocuments%2FNotes%2FProjects%2FPlan.md"
```

Obsidian 会查找包含该文件的已注册 vault。文件不属于任何已注册 vault 时，这条命令不会把它所在的目录自动注册为新 vault。

## 当前目录能否像 `code .` 一样打开

不能。以下命令目前都不能把任意当前目录注册并打开为 vault：

```bash
# 不支持：Obsidian 没有 code . 风格的目录参数
obsidian .

# 不支持：open 命令只用于打开 vault 内的文件
obsidian open .

# 不支持：vault 命令用于显示信息，不接受目录参数
obsidian vault .

# 只能启动 Obsidian，不能把当前目录注册为 vault
open -a Obsidian .
```

### 当前目录已经注册为 vault

如果终端当前目录就是一个已注册的 vault 目录，CLI 会自动把后续命令作用于它：

```bash
# 进入已经注册的 Notes vault 根目录
cd "$HOME/Documents/Notes"

# 确认 CLI 当前识别到的 vault 路径
obsidian vault info=path

# 打开该 vault 的今日日记
obsidian daily

# 打开该 vault 中的 Projects/Plan.md
obsidian open path="Projects/Plan.md"
```

这表示 CLI 能根据当前目录选择命令目标，但仍然没有 `obsidian .` 这样的“只打开 vault”命令。若要单纯打开或聚焦窗口，仍建议使用 URI。

### 当前目录尚未注册

先打开 Vault Manager：

```bash
# 打开 Obsidian Vault Manager
open "obsidian://choose-vault"
```

然后选择 **Open folder as vault**，手动选中目标目录。注册一次后，后续就能使用名称、ID 或当前目录识别。

即使目录已经包含 `.obsidian`，只要它还没有出现在 Vault Switcher 中，CLI 和 URI 也不会自动注册它。

## 常用 CLI 命令

### 安装检查和帮助

```bash
# 查看 Obsidian 版本
obsidian version

# 查看全部 CLI 命令
obsidian help

# 查看 open 命令支持的参数
obsidian help open
```

### 查看 vault 信息

```bash
# 列出所有已注册 vault 的名称
obsidian vaults

# 列出所有 vault 的名称和文件系统路径
obsidian vaults verbose

# 显示当前目标 vault 的完整信息
obsidian vault

# 只显示当前目标 vault 的名称
obsidian vault info=name

# 只显示当前目标 vault 的路径
obsidian vault info=path
```

### 查看文件和目录

```bash
# 列出当前目标 vault 中的全部文件
obsidian files

# 只列出 Projects 目录中的文件
obsidian files folder="Projects"

# 列出当前目标 vault 中的全部目录
obsidian folders

# 统计 Projects 目录包含的文件数
obsidian folder path="Projects" info=files
```

### 日记、搜索和创建文件

```bash
# 打开当前目标 vault 的今日日记
obsidian daily

# 在当前目标 vault 中搜索 meeting notes
obsidian search query="meeting notes"

# 在 Notes vault 中搜索 TODO
obsidian vault=Notes search query="TODO"

# 创建 Project plan.md 并在 Obsidian 中打开
obsidian create name="Project plan" open

# 创建文件时写入初始内容，并在新标签页中打开
obsidian create name="Project plan" content="Initial notes" open newtab
```

## 安装 Obsidian CLI

官方 CLI 需要 Obsidian 1.12.7 或更新版本的安装器：

1. 打开 **Settings → General**。
2. 启用 **Command line interface**。
3. 按提示将 `obsidian` 注册到 `PATH`。
4. 重新打开终端。

验证安装：

```bash
# 应输出 Obsidian 版本
obsidian version

# 应输出 CLI 命令列表
obsidian help
```

CLI 需要连接 Obsidian 桌面应用。如果应用尚未运行，执行第一条 CLI 命令会启动它。

macOS 上可以检查注册生成的符号链接：

```bash
# 检查 obsidian CLI 是否已链接到 /usr/local/bin
ls -l /usr/local/bin/obsidian
```

如果自动注册失败，可以按官方文档手动创建：

```bash
# 将 Obsidian 自带的 CLI 链接到 PATH
sudo ln -sf /Applications/Obsidian.app/Contents/MacOS/obsidian-cli \
  /usr/local/bin/obsidian
```

## URI 编码速查

| 原字符 | URI 编码 | 示例用途 |
| --- | --- | --- |
| 空格 | `%20` | `My%20Vault` |
| `/` | `%2F` | `Projects%2FPlan.md` |
| `#` | `%23` | 打开文件中的标题 |
| `^` | `%5E` | 打开文件中的块引用 |

打开文件中的指定标题：

```bash
# 打开 Plan.md 中的 Next steps 标题
open "obsidian://open?vault=Notes&file=Plan%23Next%20steps"
```

## 常见问题

### `obsidian: command not found`

```bash
# 检查 shell 是否能找到 obsidian
command -v obsidian

# 检查 macOS 上的官方符号链接
ls -l /usr/local/bin/obsidian
```

如果没有结果，在 Obsidian 设置中关闭再重新启用 **Command line interface**，然后重新打开终端。

### 命令作用到了错误的 vault

当前目录不是已注册 vault 时，CLI 会使用 Obsidian 当前活动的 vault。执行前先确认路径，或者显式添加 `vault=`：

```bash
# 查看当前命令会作用到哪个 vault
obsidian vault info=path

# 明确指定并确认 My Vault 的路径
obsidian vault="My Vault" vault info=path
```

### 文件名重复

`file=` 会按 wikilink 规则解析文件。存在同名文件时，使用精确的 vault 相对路径：

```bash
# 避免同名文件歧义
obsidian open path="Projects/Plan.md"
```

### URI 无法打开

确认 Obsidian 至少运行过一次，以便 macOS 注册 `obsidian://` 协议。同时检查空格、斜杠和 `#` 等字符是否已编码。

## 参考资料

官方文档：

- [Obsidian CLI](https://obsidian.md/help/cli)
- [Obsidian URI](https://help.obsidian.md/Extending+Obsidian/Obsidian+URI)
- [Obsidian changelog](https://obsidian.md/changelog/)

仍未实现的相关功能请求：

- [Open folder as an Obsidian vault from terminal / command line / CLI](https://forum.obsidian.md/t/open-folder-as-an-obsidian-vault-from-terminal-command-line-cli/111805)
- [Open a folder as a new Obsidian vault using its filepath via the URI](https://forum.obsidian.md/t/open-a-folder-as-a-new-obsidian-vault-using-its-filepath-via-the-uri/112323)
