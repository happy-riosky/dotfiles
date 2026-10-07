# obs（Obsidian CLI 包装命令）

`obs.sh` 是官方 Obsidian CLI 的 vault 安全封装：vault 名统一从注册表解析（避免
CLI 对已关闭 vault 开窗的副作用）、路径沙箱化（拒绝软链组件与逃逸）、URI 自动
百分号编码。仅 macOS。

## 安装

```bash
bash manual/obsidian/obs.sh link --dry-run   # 预览
bash manual/obsidian/obs.sh link             # 创建 ~/bin/obs -> 本脚本
```

`~/bin` 已由 `scripts/shell/core.sh` 加入 PATH。`manual/` 不受
link/unlink/doctor 管理，因此由脚本自建软链（拒绝覆盖已有 `~/bin/obs`）。

## 命令速查

| 命令 | 作用 |
|---|---|
| `obs vaults` | 列出已注册 vault 及其路径 |
| `obs status [vault]` | 全部/单个 vault 的 Git 状态与窗口开闭（窗口探测需辅助功能权限，缺失时降级为 unknown） |
| `obs files <vault> [folder]` | 列 vault 或其子目录中的文件 |
| `obs folders <vault>` | 列 vault 内目录 |
| `obs launch` | 启动 Obsidian 但不前置（`open -g`） |
| `obs open <vault>` | 打开或聚焦一个 vault（URI） |
| `obs open-file <vault> <file>` | 打开 vault 相对路径文件（URI，自动编码） |
| `obs vim <vault> [path]` | 用 Vim 打开 vault 或 vault 相对路径/目录 |
| `obs path <vault> [dir]` | 打印 vault/子目录绝对路径（可 `cd "$(obs path …)"`） |
| `obs choose` | 打开 Obsidian Vault Manager |
| `obs version` | 官方 CLI 版本 |

官方 CLI 与 URI 的完整用法手册见 [`docs/obsidian.md`](../../docs/obsidian.md)。

## 设计要点

- **注册表解析**：所有 vault→路径换算走 `obsidian vaults verbose` 注册表，
  不经 CLI 的 `vault=` 定位——对已关闭 vault 执行部分 CLI 命令会开窗。
- **路径沙箱**：vault 相对路径逐组件检查，拒绝软链（保证操作都落在注册的
  真实目录内）并拒绝 `..` 逃逸出 vault 根。
- **URI 编码**：vault/文件名按 RFC 3986 逐字节编码（含中文与空格），
  免去手写 `%20`/`%2F`。
- **零依赖**：bash 3.2 + 官方 `obsidian` CLI（1.12.7+，在 Obsidian 设置中启用
  Command line interface）；`status` 的窗口探测用 osascript（System Events），
  需给终端辅助功能权限。
