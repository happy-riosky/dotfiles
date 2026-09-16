# piper.yazi

Yazi 通用管道预览器（把任意 shell 命令的输出作为预览内容），`main.lua` 逐字节取自上游：

| 文件 | 来源 | Pin |
|---|---|---|
| `main.lua` | https://github.com/yazi-rs/plugins `piper.yazi/main.lua` | `58c4f4e2f4835cc9bf6751f39e3f7c574fc7f55a`（2026-09-09，MIT） |

本地用途：`yazi.toml` 的 markdown 预览（`glow -w=$w -s=$t`，`$t` 随 yazi 终端深浅色检测联动）。
要求 Yazi ≥ 26.8.15（本机 26.9.1）。
更新方式：按上表 URL（raw.githubusercontent.com，替换 commit）重新下载同名文件即可。
