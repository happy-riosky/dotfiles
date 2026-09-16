# Karabiner Miryoku（内置键盘实验）

把 Miryoku 风格的 Vial(.vil) 键位方案移植为 Karabiner-Elements complex
modifications：零 UI 操作、仅内置键盘生效、随时秒级回退。

## 文件

| 文件 | 作用 |
|---|---|
| `miryoku-refactor.vil` | 键位源档（唯一事实源；alike Corne 类 vil 可重命名后覆盖替换） |
| `gen.py` | 生成器：vil → Karabiner asset |
| `rules.sh` | 启停开关（jq 注入/移出 karabiner.json，热重载 ~1s） |
| `rollback-manifest.txt` | 回退基线（commit `279b8f4` + 原 14 条规则清单与校验命令） |
| `~/.config/karabiner/assets/…/miryoku.json` | 生成物（勿手改，重新生成即可） |

## 触发键（拇指层直译；纯层键，不发射修饰键）

| hold | 层 | tap |
|---|---|---|
| `⌘L` | L1 数字/符号 | `⇥` |
| `␣` | L2 导航 | `␣` |
| `⌘R` | L3 shifted 符号 | `⌫` |
| `⌥R` | L4 残留层 | `⏎` |

⌘ 只能经层获得：L2-`A`（按住）、L3-`;`（按住），及层内现成快捷键
（L2 的 `Z/X/C/V` = ⌘Z/X/C/V，L3 的 `G` = ⌘␣）。

## 层速查

- **L1（⌘L）**：`U I O / J K L / M , .` = 789/456/123（numpad 方位）；
  `E R` = `[ ]`，`C V` = `{ }`，`W` = ⌃W，`A` = ⌃A；`S D F` = ⌥⇧⌃（按住）；
  层内 `⌘R/⌥R` 键 = `0` / `.`
- **L2（␣）**：`H J K L ;` = `←↓↑→ ⌥⌫`；`Y U I O P` = `⌘← ⌘↓ ⌘↑ ⌘→ ⌦`；
  `N M , . /` = `⌥← PgDn PgUp ⌥→ ⌥⌦`；`Q W` = ⌘⇥/⇧⇥；`E R` = ⌘⇧[/⌘⇧]；
  `T` = ⌃;，`G` = ⌘[；`Z X C V` = ⌘Z/X/C/V；`A S D F` = ⌘⌥⇧⌃（按住）
  - **kitty 前台特例**：`E/R/G` → `⌃⌥p / ⌃⌥n / ⌃l`（补链，见踩坑 2）
- **L3（⌘R）**：左半 = `` ` ~ ' " : ! @ # $ % ^ & * ( ) ``；
  右半 = `- = [ ] \ | _ + < > ?`；`J K L ;` = 右⌃⇧⌥⌘（按住）；层内 `␣` 键 = ⌘␣
- **L4（⌥R）**：`H J K L` = `←↓↑→`；`U I O` = ⌃⌘J/K/L；`Q` = ⌃1，`R` = ⌃;，
  `T/G` = ⌃↑/⌃↓，`, .` = ⌃←/⌃→；`A ;` = MEH M/H；`Z` = ⌘⇧␣；层内 `⌘L`/`␣` 键 = ⇥/␣
- **combos**：`S+D` = Esc，`F+J` = CapsLock，`D+F` = ⇧（按住），`J+K` = 右⇧（按住）

## 翻译规则

- `KC_NO` → 屏蔽键（按下无输出）；鼠标/滚轮/音量/亮度键 Karabiner 无法合成 → 屏蔽或跳过
- `OSM`（one-shot）→ 按住式修饰键
- 全部规则限定 `device_if: is_built_in_keyboard`，外接键盘不受影响

## 日常操作

```bash
manual/karabiner-miryoku/rules.sh status    # 状态（0/6 或 6/6）
manual/karabiner-miryoku/rules.sh disable   # 回退·轻（移出规则，热重载）
git restore platforms/darwin/home/.config/karabiner/karabiner.json  # 回退·硬（基线 279b8f4）
# 回退校验：rollback-manifest.txt 中的 jq 命令应恢复为 14 条

# 官方校验生成物（曾抓出 spacebar/equal_sign 键名 bug，勿跳过）
/Library/Application\ Support/org.pqrs/Karabiner-Elements/bin/karabiner_cli \
  --lint-complex-modifications ~/.config/karabiner/assets/complex_modifications/miryoku.json

# 免按住测试某层（系统变量会持久，测完必须置 0）
karabiner_cli --set-variables '{"miryoku_l2":1}'   # 强开导航层
karabiner_cli --set-variables '{"miryoku_l2":0}'   # 恢复
```

## 同步新键位方案

```bash
cp /path/to/new.vil manual/karabiner-miryoku/miryoku-refactor.vil   # 覆盖源档
python3 manual/karabiner-miryoku/gen.py                             # 重新生成
# → 上节 lint → rules.sh disable && rules.sh enable                 # 刷新注入
```

输入要求：alike（3×6+拇指、12 列矩阵、字母区列位一致）的 Corne 类 vil
导出均可直接用；键盘几何不同的需先改 `gen.py` 的 `LETTER_COLS`/`TRIGGERS`。

需要手改 `gen.py` 的情形：

- 拇指 tap 键或层↔拇指对应变化（`TRIGGERS`；tap 不读 vil 的 `LTn` 参数）
- `⌘⇧[/]`、`⌘[` 在新方案中挪位（`CHAIN_OVERRIDES` 同步改）
- 新 keycode 记号（`KEYS`/`MODS` 白名单补表；未知 token 会直接报错，安全）

非 vil 来源的方案：直接编辑 `miryoku-refactor.vil` 的层数组。

## 踩坑

1. **键名**：Karabiner 用 `spacebar`/`equal_sign`（非 `space`/`equal`）；
   `jq` 校验不出，必须走 `--lint-complex-modifications`
2. **合成事件不二次处理**：层规则合成的 `to` 事件不会再经过 complex
   modifications，物理键盘上「⌘⇧[ → kitty 规则 → ⌃⌥p」的链会断，
   需 `CHAIN_OVERRIDES` + `frontmost_application_if` 显式补链
3. **karabiner.json 格式**：jq `--indent 4` 会归一化格式（diff 变大但语义
   不变）；大改后可做「减去 Miryoku 规则与基线语义 diff」校验
4. **combos 延迟**：同按检测给 `s d f j k` 五键带来 ~50ms 延迟
   （profile 级 `simultaneous_threshold_milliseconds` 可调）
