# OpenCode 配置

## 权威修改位置

| 内容 | 修改位置 |
| --- | --- |
| Provider、`baseURL`、模型定义、全局权限 | `~/.config/opencode/opencode.json` |
| 默认模型 | 个人覆盖目录，见“设置默认模型” |
| `small_model`、ECC agents/commands | `~/.opencode/opencode.json` |
| TUI | `~/.config/opencode/tui.json` |

`~/.config/opencode` 的公共配置链接到 `~/dotfiles/home/.config/opencode`，
修改后会直接进入 dotfiles。`~/.opencode` 仍是本机真实目录，运行时数据库、
session、cache、日志和安装内容不由此仓库管理。

## 设置默认模型

`~/.opencode/opencode.json` 由 ECC 管理，ECC 更新时可能被重新安装，不要把
个人默认模型直接改在这里。建立一个 ECC 不管理、加载优先级更高的覆盖目录：

```bash
export OPENCODE_CONFIG_DIR="$HOME/.config/opencode-overrides"
```

把这行写入 `~/.zshrc`，然后创建
`~/.config/opencode-overrides/opencode.json`。默认模型应同时覆盖顶层模型和
ECC 的 `build` agent 模型：

```json
{
  "$schema": "https://opencode.ai/config.json",
  "model": "pytrio/deepseek-v4-flash",
  "agent": {
    "build": {
      "model": "pytrio/deepseek-v4-flash"
    }
  }
}
```

修改后完全退出 OpenCode，重新启动并新建会话。用以下命令确认最终配置：

```bash
opencode debug config
opencode debug agent build
```

相关讨论：

- [`.opencode/opencode.json` 也是配置源](https://github.com/anomalyco/opencode/issues/18953)
- [配置加载优先级问题](https://github.com/anomalyco/opencode/issues/28177)
- [Agent 固定模型覆盖手动选择](https://github.com/anomalyco/opencode/issues/39319)
- [恢复旧会话时沿用旧模型](https://github.com/anomalyco/opencode/issues/26351)

`gpt-5.6-sol` 必须使用 Responses API，因此在 provider 模型定义中覆盖 npm 包：

```json
"gpt-5.6-sol": {
  "name": "gpt-5.6-sol",
  "provider": { "npm": "@ai-sdk/openai" },
  "options": { "store": false }
}
```

## 加载与覆盖顺序

后加载的同名字段覆盖先加载的字段：

1. `~/.config/opencode/opencode.json`
2. 当前项目的 `.opencode/opencode.json`
3. `~/.opencode/opencode.json`
4. `OPENCODE_CONFIG*` 环境覆盖
5. 插件 `config()` hook

不要用插件 `config()` 设置默认模型。此前的 `default-model.ts` 会强制使用
`sq/grok-4.5`，现已删除。

## 模型选择优先级

1. UI、命令或 API 显式选择
2. `agent.<name>.model`
3. 当前会话保留的模型
4. 顶层 `model`
5. `~/.local/state/opencode/model.json` 中的最近模型

修改配置后必须完全重启 OpenCode，并新建会话验证。

## 排查

```bash
# 查找所有模型覆盖
rg -n 'model|config\.model' ~/.config/opencode ~/.opencode .opencode 2>/dev/null

# 检查环境覆盖
env | rg '^OPENCODE_(CONFIG|CONFIG_DIR|CONFIG_CONTENT)='

# 查看实际调用模型
rg 'stream providerID=' ~/.local/share/opencode/log/opencode.log | tail
```

`~/.local/state/opencode/model.json` 和 `~/.local/share/opencode/opencode.db`
属于运行时状态，不是权威配置来源。
