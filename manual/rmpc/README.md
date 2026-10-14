# nemdl — NetEase Music 下载器

`nemdl` 是网易云音乐下载入口，底层由 [vncmd](https://github.com/Vanadiry/vncmd)
完成实际下载（元数据/歌词/封面/断点续传），账号内容枚举直接调网易云 web API。
配合 rmpc/MPD：下载收尾自动 `rmpc update`（即 `mpu`，见 `scripts/shell/aliases.sh`）。

## 曲库布局

```text
~/Music/net-ease-music/          # 根目录，可用 -o 或 VNCMD_DL_DIR 覆盖
├── playlists/<歌单名>/          # 账号自建歌单
└── albums/<专辑名>/             # 账号收藏专辑
    └── 艺人 - 歌名.flac|.lrc|.jpg    # 文件名「艺人 - 歌名」
```

目录以音乐命名，无任何工具痕迹。vncmd 批量下载产生的时间戳批次目录
（如 `2026-10-08_14-30-05/`）会在下载完成后自动并入命名目录，并改写
vncmd checkpoint（`~/.vSoft/vncmd/cache/download/*.json`）的 `download_dir`
指向它——重跑同名歌单依然精准续传，只补新增/缺失曲目。

## 命令

```bash
nemdl p list [--mine|--liked]        # 账号歌单一览（自建/收藏/我喜欢标记）
nemdl p show <ID|名称>              # 歌单曲目表 + 本地 ✓/✗ 状态列
nemdl p dl <ID|名称>…               # 下载歌单（可多个）
nemdl p all [--mine|--liked|--favorites]
                                      # 批量：默认仅自建；--liked 加收藏他人；
                                      # --favorites 加「喜欢的音乐」

nemdl a list                         # 收藏专辑一览
nemdl a show <ID|名称>              # 专辑曲目表 + ✓/✗
nemdl a dl <ID|名称>…               # 下载专辑
nemdl a all                          # 批量下载全部收藏专辑

nemdl status                         # 本地总览：每项目录、进度 x/y、实际文件数
nemdl sync                           # 增量补齐所有已下载项（歌单新增曲目同步）
```

`p`/`a` 是 `playlist`/`album` 的短别名。名称支持不区分大小写的子串匹配，
命中多条时列出候选要求改用 ID。

## 全局选项

| 选项 | 说明 |
|---|---|
| `-o, --output <dir>` | 曲库根目录；env `VNCMD_DL_DIR` 同效，默认 `~/Music/net-ease-music` |
| `-q, --quality` | 音质 128/192/320/999，透传 vncmd（默认读 vncmd 配置） |
| `--dry-run` | 下载类命令只显示计划，不执行 |
| `--no-update` | 跳过收尾 `rmpc update` |

## 依赖与前置

- `vncmd`（`pip install vncmd` 或官方二进制）在 PATH 中；cookie 已设置
  （`vncmd cookie "..."`，须含 `MUSIC_U`）。高音质/VIP 曲目要求账号本身有权限。
- vncmd 配置 `~/.vSoft/vncmd/config.toml` 建议 `filename_format = "01"`
  （文件名「艺人 - 歌名」）；不符时 nemdl 会提示但仍可下载。
- `VNCMD_HOME` 可覆盖 vncmd 数据目录（默认 `~/.vSoft/vncmd`）。
- vncmd 同一时刻只允许一个实例，nemdl 串行调用；单项失败不中断批量，
  结束时汇总失败项并以非零码退出。

## 已知问题：本地 vncmd 补丁（pipx 升级会丢失）

vncmd 1.x 的 `get_type_from_url` 对无扩展名的流 URL 兜底猜成 `mp3`，而网易云
实际可能下发 FLAC —— `eyed3.load()` 返回 None 后在 `metadata.py` 崩溃
（`AttributeError: 'NoneType' object has no attribute 'tag'`），文件虽下载
完成但丢失且 checkpoint 不标记。

已在 pipx venv（`~/.local/pipx/venvs/vncmd/.../function/`）打两处补丁：

- `audio.py`：新增 `sniff_music_type()`（按魔数识别 flac/mp3/m4a/wav/ogg）；
- `downloader.py`：下载完成后按魔数校正 `music_type` 与临时文件名（导入
  `sniff_music_type`）；
- `metadata.py`：`eyed3.load()` 返回 None 时抛明确错误而非 AttributeError。

**`pipx upgrade vncmd` 后若单曲下载报 AttributeError，需重新打上述补丁**
（或等上游修复后再升级）。

## 示例

```bash
nemdl p list                          # 看看账号里有哪些歌单
nemdl p show 母语羞耻                  # 预览曲目与本地进度
nemdl p dl 母语羞耻 17370836935        # 下载两个歌单
nemdl a all                            # 收藏专辑全部拉下来
nemdl sync                             # 之后歌单有更新时增量同步
nemdl status                           # 总览本地状态
```
