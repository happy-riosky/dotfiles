# rmpc / MPD 音乐播放

rmpc 是 MPD（Music Player Daemon）的 TUI 客户端；MPD 由 brew services（launchd）
常驻，监听 `localhost:6600`。

## 受管文件与本机目录

| 路径 | 用途 | 管理方 |
| --- | --- | --- |
| `platforms/darwin/home/.mpdconf` → `~/.mpdconf` | MPD 配置：music 目录 `~/Music`、`osx` 输出（插件名是 `osx` 不是 `coreaudio`）、运行时数据 `~/.local/state/mpd/` | dotfiles |
| `platforms/darwin/home/.config/rmpc/config.ron` → `~/.config/rmpc/config.ron` | 仅设 `lyrics_dir: Some("~/Music")`（rmpc 支持 `~` 展开，省略字段用默认值） | dotfiles |
| `platforms/darwin/home/.config/rmpc/config-popup.ron` → `~/.config/rmpc/config-popup.ron` | popup 专用（C-f 经 `rmpc -c` 加载）：Queue 去 AlbumArt、左列整列 Lyrics、tabs 仅 Queue/Directories/Search | dotfiles |
| `~/.local/state/mpd/` | database/state/sticker/playlists，运行时产物 | 本机 |
| `~/Music/` | 音乐库根（即 MPD music 目录），任意子目录均会被扫描；同名 `.lrc` 放在歌曲旁 | 本机 |
| `package-lists/brew-formulae.txt` | `mpd`、`rmpc` 两行 | dotfiles |

## 日常工作流（新增音乐）

1. 音乐放进 `~/Music` 任意子目录（同名 `.lrc` 与歌曲同目录）
2. `.lrc` 补 `[ti:]/[ar:]` 头（下载器不带 tags，从同名 flac 提取）：

   ```bash
   for f in ~/Music/<目录>/*.flac; do
     lrc="${f%.flac}.lrc"; [ -f "$lrc" ] || continue
     head -1 "$lrc" | grep -q '^\[ti:' && continue
     t=$(ffprobe -v error -show_entries format_tags=title -of default=nokey=1:noprint_wrappers=1 "$f")
     a=$(ffprobe -v error -show_entries format_tags=artist -of default=nokey=1:noprint_wrappers=1 "$f")
     { printf '[ti:%s]\n[ar:%s]\n' "$t" "$a"; cat "$lrc"; } > "$lrc.tmp" && mv "$lrc.tmp" "$lrc"
   done
   ```

3. `mpu`（= `rmpc update`，见 `scripts/shell/aliases.sh`；macOS 无 inotify，
   `auto_update` 不生效，必须手动刷）
4. rmpc TUI 里播放；歌词显示在默认 Queue tab 的 Lyrics pane

库里只出现部分目录是正常的：MPD 扫描整个 `~/Music`，但只索引可解码音频——
GarageBand / Audio Music Apps 是工程文件非音频，网易云音乐的 `.ncm` 加密
不可解码，Apple Music 目录为流媒体缓存（且受 TCC 保护）。

## 排障（高频）

- **`brew services list` 只显示 `error`、无任何原因**：launchd plist 不捕获
  stderr。前台跑 `/opt/homebrew/opt/mpd/bin/mpd --no-daemon --stderr` 看真实报错。
- **改 MPD 配置不生效**：配置在 `~/.mpdconf`（MPD 不搜索
  `~/.config/mpd/mpd.conf`）；改完 `brew services restart mpd`。
- **TUI 无歌词且 `rmpc lyricsindex` 报 "Lyrics dir is not configured"**：
  `~/.config/rmpc/config.ron` 链接消失（TUI 原子重写或误删，与 opencode
  `tui.json` 同类 drift）。恢复：`./install full` 重新链接，`scripts/doctor`
  查其他漂移。
- **歌词不显示**：① 内嵌在 flac 里的 lyrics tag，rmpc（≤0.11）不读，只认外部
  `.lrc`；② `.lrc` 必须带 `[ti:]/[ar:]`（大小写不敏感精确匹配），下载器的
  原始文件没有，需按上文补头；③ `lyrics_dir` 未配置则完全不解析——本仓库已在
  config.ron 配好，且等于 music 根目录，同目录同名 `.lrc` 直接命中。用
  `rmpc lyricsindex` 验证（`"title": null` 即缺 tags）。
- **popup（C-f）里没有专辑封面**：tmux display-popup 丢弃一切图像转义序列
  （sixel 与 passthrough 均不支持，tmux/tmux#4329）。弹窗因此经
  `rmpc -c ~/.config/rmpc/config-popup.ron` 启动，布局无 AlbumArt pane
  （自然也不会触发 rmpc≤0.11 在 tmux 内 sixel 超 1MB 的报错）。普通
  窗口/pane 直接 `rmpc`（默认配置）封面正常：kitty 经 tmux passthrough
  走 kitty 图形协议；若探测退到 sixel 且封面过大，仍可能报 1MB 上限
  （需 rmpc>0.11 + tmux≥3.6 的 `input-buffer-size` 才能解开）。

## 命令速查

| 命令 | 用途 |
| --- | --- |
| `mpu` | 扫描 `~/Music` 新增文件（`rmpc update`） |
| `rmpc lyricsindex` | 查看歌词索引与匹配 tags |
| `rmpc listall` | 列出 MPD 库全部曲目 |
| `brew services restart mpd` | 改 `.mpdconf` 后重启守护 |
