# OpenCode 配置

## 权威修改位置

| 内容 | 修改位置 |
| --- | --- |
| Provider、`baseURL`、模型定义、全局权限 | `~/.config/opencode/opencode.json` |
| 模型覆写 | `~/dotfiles/manual/opencode-overrides/`，见「模型覆写」 |
| `small_model`、ECC agents/commands | `~/.opencode/opencode.json` |
| TUI | `~/.config/opencode/tui.json` |

`~/.config/opencode` 的公共配置链接到 `~/dotfiles/home/.config/opencode`，
修改后会直接进入 dotfiles。`~/.opencode` 仍是本机真实目录，运行时数据库、
session、cache、日志和安装内容不由此仓库管理。

## 模型覆写

`~/.opencode/opencode.json` 由 ECC 管理，出厂钉死 `anthropic/*` 模型，且
ECC 更新或 `ecc repair` 会重新安装该文件。统一改法是 dotfiles 里的
`manual/opencode-overrides/`：`apply.sh` 直接就地改写
`~/.opencode/opencode.json`（只动 `model`、`small_model`、
`agent.*.model`，其余字段原样保留），没有软链、环境变量或拷贝中间层。

```bash
cd ~/dotfiles
bash manual/opencode-overrides/apply.sh link    # 一次性安装 ~/bin/ocor 快捷命令
ocor show
ocor set pytrio/gpt-5.6-sol
ocor set-small pytrio/gpt-5.6-sol
ocor set-agent planner zhipuai-coding-plan/glm-5.3
ocor models                                    # 生效模型速览（按模型分组）
```

规则保存在 `manual/opencode-overrides/overrides.json`（由 CLI 维护，进
git）。`set` 只改 `model` 和 `agents."*"`；`small_model` 由 `set-small`
单独管理；`set-agent` 的精确规则优先于 `"*"`。ECC 新增 agent 后重跑一次
`apply.sh` 即自动覆盖（`"*"` 匹配所有 agent 名）。检查是否漏配：

```bash
rg -i anthropic ~/.opencode/opencode.json
```

修改后完全退出 OpenCode，重新启动并新建会话。确认最终配置：

```bash
opencode debug config
opencode debug agent build
```

`ecc repair`/`ecc auto-update`/重装 ECC 后需要重跑 `ocor`。注意
`ecc repair` 会把整份文件还原为 ECC 出厂内容——除了模型，还会丢掉手工
合并的 `opencode-models-discovery` plugin 条目和其他手改，还原后先重新
合并再跑 `ocor`。`ecc doctor` 对该文件报 drift 属预期。

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
