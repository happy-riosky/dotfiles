## 简介

用显式 HOME 软链接管理的跨平台个人 dotfiles。支持 macOS（`full`）、
Debian/Ubuntu（`server`，含 WSL2 内的 Debian/Ubuntu 发行版）与 Termux
（`termux`）；不支持的平台/profile 组合会显式报错。

## 布局

```text
home/                          # 跨平台，链接到 $HOME
platforms/darwin/home/         # macOS 专属可链接配置（Karabiner、Hammerspoon 等）
platforms/darwin/managed/      # macOS Preferences 黄金文件（真实文件，不链接）
package-lists/                 # brew、apt、termux 包清单
plugin-lists/                  # tmux/vim/zsh 插件来源
manual/                        # 手动应用的覆盖配置与脚本（不在受管链接域）
docs/                          # 文档，索引见 docs/README.md
scripts/                       # link、unlink、doctor、plugins、prefs/hotkeys
scripts/shell/                 # 共享 shell 加载器、aliases 与 platform/profile 片段
install                        # 入口：./install {full|server|termux}
```

## 用法

### 链接配置

```bash
./install full --dry-run       # macOS
./install full
./scripts/doctor
```

其他 profile：`./install server`（Debian/Ubuntu 与 WSL）、`./install termux`
（Termux）。不支持的平台/profile 组合会显式失败。

### 安装软件包

包安装是显式入口，链接配置永远不会意外联网或提权；与 `install` 相同的
平台/profile 限制同样适用。

```bash
./scripts/packages full --dry-run       # macOS：Homebrew formulae 与 casks
./scripts/packages server --dry-run     # Debian/Ubuntu：apt
./scripts/packages termux --dry-run     # Termux：pkg
./scripts/packages full
```

每个选中的清单在包管理器运行前都会校验。dry-run 只打印 `RUN ...` 命令。

### 安装插件

插件仓库按宿主应用分组、不锁 commit，新安装用各仓库默认分支。已存在的目标
必须是指定 origin 的真实检出；每个检出都经 `git fsck` 校验。

```bash
./scripts/plugins --dry-run --app tmux
./scripts/plugins --app tmux
```

## 文档

文档索引见 [docs/README.md](docs/README.md)。常用入口：

- 平台指南：[Linux](docs/linux.md) / [macOS](docs/macos.md) /
  [Termux](docs/termux.md) / [WSL](docs/wsl.md)
- 专题：[tinty 主题总纲](docs/theming.md)、[OpenCode/ECC](docs/opencode.md)、
  [Neovim](docs/neovim.md)；活跃待办见 [docs/todo.md](docs/todo.md)

## Neovim

当前基于 Kickstart 的配置位于 `home/.config/nvim/`，含自定义 Diffview 映射与
插件 revision lockfile。版本要求、链接与插件更新见
[Neovim 指南](docs/neovim.md)。

## macOS 应用配置

应用配置路径、Preferences 恢复/导出、Amethyst、AeroSpace、Hammerspoon、
Mouseless（含配置修改后的重启要求）、Docker Desktop 与 TCC 权限见
[macOS 指南](docs/macos.md)。
