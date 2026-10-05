# Tinty 特殊主题清单（base16）

从本机 tinty scheme 仓库（`~/.local/share/tinted-theming/tinty/repos/schemes/base16/`，
约 280 个 base16 scheme）扫描出的特殊主题速查：**纯黑背景 / 纯灰度（黑白）/
纯白背景 / 复古仿真**。数据随 `tinty update` 变化，下文附复现命令。

预览与切换：`tinty info base16-<slug>` 看调色板明细、`tinty gallery` 浏览器
预览、`tinty apply base16-<slug>` 应用。下表 slug 均省略 `base16-` 前缀。

## 复现命令

```bash
cd ~/.local/share/tinted-theming/tinty/repos/schemes/base16

grep -l 'base00: "#000000"' *.yaml          # 纯黑背景
grep -l 'base00: "#ffffff"' *.yaml          # 纯白背景
for f in *.yaml; do                          # 全灰度（所有 baseXX 的 R==G==B）
  awk '/^ *base[0-9A-F][0-9A-F]:/ { i = index($0, "#"); if (i) {
         c = tolower(substr($0, i+1, 6)); n++
         if (substr(c,1,2)!=substr(c,3,2) || substr(c,3,2)!=substr(c,5,2)) bad=1 }
       } END { if (n && !bad) print FILENAME }' "$f"
done
```

## 纯黑背景（base00 = `#000000`，28 个）

| Slug | 名称 | 备注 |
|---|---|---|
| `berlin` | Berlin | ★ 同时全灰度，唯一「纯黑 + 黑白」，见下节 |
| `black-metal` 系列（10 个） | Black Metal (+ Bathory / Burzum / Dark Funeral / Gorgoroth / Immortal / Khold / Marduk / Mayhem / Nile / Venom) | 黑金属系，纯黑底 + 暗色 accent |
| `bright` | Bright | |
| `da-one-black` | Da One Black | 浅灰白前景，配色干净 |
| `darkviolet` | Dark Violet | 紫色 accent |
| `digital-rain` | Digital Rain | 黑客帝国绿 |
| `evenok-dark` | Evenok Dark | |
| `irblack` | IR Black | 经典 Vim 配色 |
| `isotope` | Isotope | 黑白底 + 高饱和三原色 accent |
| `linux-vt` | Linux VT | ★ 复古：Linux 控制台白字黑底 |
| `macintosh` | Macintosh | ★ 复古：经典 Mac 风格 |
| `miami` | Miami | |
| `onedark-dark` | OneDark Dark | One Dark 深黑变体 |
| `pico` | Pico | |
| `pop` | Pop | |
| `windows-95` / `windows-nt` / `windows-highcontrast` | Windows 95 / NT / High Contrast | ★ 复古：经典 Windows 控制台，均纯黑底 |

## 纯灰度（黑白，全部 16 色 R==G==B，4 个）

严格双色（仅 `#000000`/`#ffffff`）的主题不存在；灰阶靠亮度差区分语法高亮。

| Slug | base00 | 备注 |
|---|---|---|
| `berlin` | `#000000` | ★ 纯黑底 + 全灰度，最贴近真·黑白终端 |
| `grayscale-dark` | `#101010` | 深灰底，灰阶层次更平滑 |
| `grayscale-light` | `#f7f7f7` | 亮色版 |
| `london` | `#ffffff` | 纯白底亮色 |

## 纯白背景（base00 = `#ffffff`，14 个）

| Slug | 名称 |
|---|---|
| `chinoiserie` | Chinoiserie |
| `cupertino` | Cupertino（★ 复古：macOS 风格） |
| `da-one-white` | Da One White（与 da-one-black 同族） |
| `github` / `github-light-colorblind` / `github-light-high-contrast` | GitHub Light 系 |
| `google-light` | Google Light |
| `london` | London（★ 全灰度，见上节） |
| `precious-light-white` | Precious Light White |
| `selenized-white` | selenized-white |
| `standardized-light` | standardized-light |
| `tomorrow` | Tomorrow |
| `unikitty-light` | Unikitty Light |
| `windows-nt-light` | Windows NT Light（★ 复古） |

## 复古 / 仿真（12 个）

| Slug | base00 | 风格 |
|---|---|---|
| `windows-95` / `windows-95-light` | `#000000` / `#fcfcfc` | Windows 95 控制台 |
| `windows-nt` / `windows-nt-light` | `#000000` / `#fcfcfc` | Windows NT 控制台 |
| `windows-highcontrast` / `windows-highcontrast-light` | `#000000` / `#fcfcfc` | Windows 高对比 |
| `windows-10` / `windows-10-light` | `#0c0c0c` / `#f2f2f2` | Windows 10 控制台（近黑，非纯黑） |
| `macintosh` | `#000000` | 经典 Mac |
| `linux-vt` | `#000000` | Linux 虚拟控制台 |
| `tango` | `#2e3436` | GNOME 经典 Tango |
| `cupertino` | `#ffffff` | macOS 亮色风格 |

仅存在于 base24、无 base16 版的复古主题：`borland`（蓝底 `#0000a4` 经典
IDE）、`embarcadero`、`ubuntu`（紫 `#300a24`）、`man-page`（黄纸底）、
`terminal-basic`；需要时直接 `tinty apply base24-<slug>`。
