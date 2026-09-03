# OpenCode 与 ECC 配置

## 核心结论

本机同时存在两套全局目录：

- `~/.config/opencode`：OpenCode 官方全局配置目录，由 dotfiles 管理。
- `~/.opencode`：ECC 的 OpenCode home 安装目录，由 ECC 管理。

`~/.opencode` 虽不是官方全局配置目录，但 OpenCode `1.18.18` 会在读取项目配置后
继续扫描它，并合并其中的 `opencode.json`、agents、commands 和 plugins。因此，
ECC 配置会覆盖项目中的同名配置字段、agent 和 command。

`~/.opencode/opencode.json` 优先级很高，但不是最高优先级。其后仍有
`OPENCODE_CONFIG_DIR`、`OPENCODE_CONFIG_CONTENT`、活动 Console 组织配置、系统
受管配置和插件 `config()` hook。

## 本机目录

| 路径 | 用途 | 管理方 |
| --- | --- | --- |
| `~/.config/opencode/opencode.json` | Provider、模型定义、权限等个人默认值 | dotfiles |
| `~/.config/opencode/tui.json` | TUI 设置 | dotfiles |
| `~/.config/opencode/themes/*.json` | 自定义主题 | dotfiles |
| `~/.config/opencode/agents/`、`commands/` | 链到 `~/.agents/personal-harness`（另一体系） | personal-harness |
| `~/.config/opencode/plugins/`、`package*.json`、`node_modules/`、`lsp-install-decisions.json`、各 `*.bak*` | 本机插件与运行时产物，不入库 | 本机 |
| `~/.omo/omo.jsonc` | OMO（oh-my-openagent）agent/category 模型路由 | dotfiles |
| `~/.omo/{codegraph,lsp-daemon}/` | OMO 运行时状态 | 本机 |
| `~/.opencode/` | ECC agents、commands、skills、plugins 和安装状态 | ECC |
| `~/.opencode/opencode.json` | ECC 顶层配置和 agent 配置 | ECC |
| `manual/opencode-overrides/` | ECC 模型覆写规则与工具 | dotfiles |

`~/.config/opencode` 与 `~/.omo/omo.jsonc` 以 leaf link 指向本仓库的
`home/.config/opencode`、`home/.omo`；修改会直接进入 Git。`~/.opencode` 是
本机真实目录，不由本仓库链接或清理。

## OMO 注意事项

- `~/.omo/omo.jsonc` 是 OMO 的统一配置（`[opencode].agents/.categories` 模型
  路由）。`omo install` / `omo config migrate` 会原位重写该文件（先落
  `omo.jsonc.bak.*`），可能把软链接替换回真实文件——重跑这类命令后执行
  `scripts/doctor` 检查漂移；如漂移，将新内容拷回仓库后重新 `scripts/link`。
- 仓库根的 `/.omo/`（会话运行时状态）已在 `.gitignore` 锚定忽略；勿改成
  未锚定的 `.omo/`，否则会误忽略 `home/.omo/`。
- OpenCode TUI 退出时可能原子重写 `tui.json`，同样会把链接变回真实文件；
  `scripts/doctor` 会报告该漂移。

运行时状态不在以上配置中：

- 数据库、session、日志：`~/.local/share/opencode/`
- 最近模型：`~/.local/state/opencode/model.json`

## 实际加载流程

OpenCode 深合并各配置源；冲突时后加载者覆盖前者。按本机版本的实际执行顺序
概括如下（弱 → 强）：

1. 远程组织配置
2. `~/.config/opencode/opencode.json`
3. `OPENCODE_CONFIG` 指定的文件
4. 从项目根到当前目录逐级加载的 `opencode.json`、`opencode.jsonc`
5. `~/.config/opencode` 中的 agents、commands、plugins 等组件
6. 项目内沿途 `.opencode` 中的配置和组件
7. `~/.opencode` 中的配置和组件
8. `OPENCODE_CONFIG_DIR` 中的配置和组件
9. `OPENCODE_CONFIG_CONTENT`
10. 活动 Console 组织配置（如有）
11. 系统受管配置和 macOS MDM 配置

插件加载后还可通过 `config()` hook 修改最终配置；这不属于文件加载顺序。

这里最关键的是第 7 步。源码在完成项目配置和项目 `.opencode` 扫描后，显式将
`$HOME/.opencode` 加入目录列表，并读取其中的 `opencode.json` 和
`opencode.jsonc`。所以：

- 项目 `model` 不能覆盖 ECC 中同名的顶层 `model`。
- 项目同名 agent、command 会被 ECC 版本覆盖。
- 相同 npm plugin 身份以后加载者为准；不同路径的本地 plugin 可能同时运行。
- 排查“项目配置为何不生效”时，必须检查 `~/.opencode`。

官方文档只把这类来源统称为“.opencode 目录”，没有单独说明 home 下
`~/.opencode` 的位置；以上细分来自 OpenCode `1.18.18` 源码。升级 OpenCode 后
若行为变化，应重新核对源码。

## 修改原则

- Provider、`baseURL`、模型定义和全局权限改
  `~/.config/opencode/opencode.json`。
- TUI 设置改 `~/.config/opencode/tui.json`。
- 项目专属设置优先放项目 `opencode.json` 或 `.opencode/`。避免与 ECC 定义同名的
  叶子字段、agent 或 command；确需覆盖时，检查 `~/.opencode`。
- 不手工长期维护 `~/.opencode/opencode.json` 的模型字段；使用下节的 `ocor`。
- ECC 的其他手工改动会被 `ecc repair` 或更新覆盖，必须另行记录和恢复。

## ECC 模型覆写

ECC 默认在 `~/.opencode/opencode.json` 中固定 `anthropic/*` 模型。由于该文件
晚于项目配置加载，必须直接覆写 ECC 文件中的模型字段。仓库提供的 `ocor` 会原位
修改该文件，不增加软链接或额外运行时配置层。

首次安装快捷命令并应用规则：

```bash
cd ~/dotfiles
bash manual/opencode-overrides/apply.sh link
ocor show
ocor set pytrio/gpt-5.6-sol
ocor set-small pytrio/gpt-5.6-sol
ocor set-agent planner zhipuai-coding-plan/glm-5.3
ocor models
```

规则保存在 `manual/opencode-overrides/overrides.json`：

- `set` 设置顶层 `model` 和所有 ECC agent 的默认模型。
- `set-small` 单独设置 `small_model`。
- `set-agent` 设置单个 agent，优先于通配规则。
- 工具只修改 `model`、`small_model` 和 `agent.*.model`。

`ecc repair`、`ecc auto-update` 或重装 ECC 后需要重新运行 `ocor`。
`ecc repair` 会恢复整份 ECC 配置，手工加入的 plugin 等字段也会丢失；先恢复这些
字段，再应用模型覆写。`ecc doctor` 对该文件报告 drift 属预期。

检查是否仍有 ECC 默认模型：

```bash
rg -i anthropic ~/.opencode/opencode.json
```

`gpt-5.6-sol` 使用 Responses API，Provider 模型定义需要指定 OpenAI SDK：

```json
"gpt-5.6-sol": {
  "name": "gpt-5.6-sol",
  "provider": { "npm": "@ai-sdk/openai" },
  "options": { "store": false }
}
```

## 验证与排查

OpenCode 启动时加载配置，不会热更新。修改后完全退出，重新启动并新建会话。

查看最终配置和 agent：

```bash
opencode debug config
opencode debug agent build
```

查找所有可能的模型覆盖：

```bash
rg -n 'model|config\.model' ~/.config/opencode ~/.opencode .opencode 2>/dev/null
env | rg '^OPENCODE_(CONFIG|CONFIG_DIR|CONFIG_CONTENT)='
```

查看实际调用的模型：

```bash
rg 'stream providerID=' ~/.local/share/opencode/log/opencode.log | tail
```

若配置正确但模型仍不符，还要检查当前会话保存的模型、agent 自身的 `model` 和
`~/.local/state/opencode/model.json`。agent 显式模型优先于顶层默认模型；已有会话
也可能继续使用原模型。

## 核对依据

- [官方配置优先级](https://opencode.ai/docs/config/#precedence-order)
- [OpenCode `1.18.18` `config.ts`](https://github.com/anomalyco/opencode/blob/v1.18.18/packages/opencode/src/config/config.ts)
- [OpenCode `1.18.18` `paths.ts`](https://github.com/anomalyco/opencode/blob/v1.18.18/packages/opencode/src/config/paths.ts)
- [官方 agents 文档](https://opencode.ai/docs/agents/)
- [`.opencode/opencode.json` 作为配置源的讨论](https://github.com/anomalyco/opencode/issues/18953)
- [配置加载优先级讨论](https://github.com/anomalyco/opencode/issues/28177)
- [Agent 固定模型覆盖讨论](https://github.com/anomalyco/opencode/issues/39319)
- [旧会话沿用模型讨论](https://github.com/anomalyco/opencode/issues/26351)
