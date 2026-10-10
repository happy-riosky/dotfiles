#!/usr/bin/env bash
# zen.sh - tmux zen 模式：prefix+Z 把当前 pane 居中（VSCode Zen 同款观感）
#
# 机制：左右各开一个空白 filler pane（tail -f /dev/null，无 shell 噪音），
# 主 pane 钉在 @zen-width 列（resize-pane -x 精确对齐）；边框临时染成
# status-style 的 bg（无缝，bg=default 或解析失败则保持原样）；filler 上挂
# pane-focus-in 钩子把选择弹到下一 pane——C-l 轮转/HJKL 方向键不会停留在
# 空白上；window-resized 钩子在窗口尺寸变化时重新居中。
# 状态全部存目标窗口的 @zen-* 窗口选项（运行时状态，绝不入库）；关闭时按
# 打开瞬间的 #{window_layout} 快照精确还原（含边框样式与活动 pane）。单
# pane 场景经 kill-pane -a 一步到终宽，主 pane 只收一次 SIGWINCH、app 整
# 屏重绘一次即净——多次中间宽度会让异步重绘的 app 交错成乱码，而事后
# send-keys -R 会把刚重绘好的画面清掉（实测），故两者都不做。on/off 不发 display-message
# （时长受全局 display-time 支配，观感拖沓；zen 状态本身可见）。
#
# 多 pane 窗口整组居中：非 main pane 先寄存后台 park 窗口、窗口归一后走
# 单 pane 几何、再 join 回 main 侧——全部内容（含 zen 期间新建的 pane）
# 落在居中列内；off 经 select-layout 快照（按 pane index 映射槽位，实测）
# + swap-pane 复原 index 顺序精确还原。进入时列内比例会漂移（join 均
# 分），退出精确复原；zen 期间新建/死亡 pane 使计数失配时降级为杀
# filler 保留现状，绝不杀用户 pane。park 寄存期间 on 折损由 off 的
# @zen-park 恢复通道接回（见 zen_off）。
#
# 无缝边框随主题热切换：zen_on 安装全局数组钩子 after-set-option[90] →
# 任何 set-option（含任何主题工具重设 status-style）触发 retheme 快路径
# 比对，bg 变了才重染各 zen 窗口边框；retheme 自身的 set 再触发钩子时比对
# 相等即零写入，回环自断。retheme 同时自愈非 zen 窗口残留的 zen 着色签名
# （历史泄漏无自愈通道，本地值遮蔽全局，reload 配置也无效）。最后一个
# zen 窗口 off 时按索引卸载钩子，不动用户同名列其他槽位；kill-window/
# 会话销毁绕过 off（销毁路径无钩子可用），全量 retheme 发现 zen 窗口绝迹
# 时兜底卸载钩子并清缓存（下次主题切换自愈；兜底前钩子受门控约束，每次
# set 仅 2 次调用，无扇出代价）。主题工具零耦合（发布为独立插件亦可用）。
#
# 用法: zen.sh toggle [pane_id]    绑定里经 #{pane_id} 展开（见 .tmux.conf）
#       zen.sh on|off|rebalance [pane_id|window_id]
#       zen.sh retheme [force]    全量重染 zen 窗口无缝边框（公开 API，可选接
#                                 任意主题切换工具；正常由钩子自动驱动）
#       主 pane 进程退出：pane-scoped remain-on-exit（3.5a 实测支持）让
#       死 pane 保留并触发 pane-died（销毁路径才无钩子）→ main-died 自动
#       拆除并按原生语义销毁死 pane——zen 存续期 %main 永不被销毁，filler
#       弹回钩子不可能打到已销毁目标（Can't find pane 根因消除）。显式
#       kill-pane 不走此通道（销毁即生效），若弹回偶发报错一次，容错拆除
#       （窗口内任意 pane 再按 toggle）仍是兜底。
# 覆写: @zen-width（set -g 全局 / tmux set -w 按窗；默认 120）
# 调试: ZEN_TMUX="tmux -L zentest" 换隔离 server 驱动，不碰真实会话
#       （焦点类钩子无附着客户端不触发，只能断言装配）
# CLI 陷阱（tmux 3.5a 实测）: display-message 取值必须 -p（无 -p 不产出
#       stdout，空串进算术变 0，曾致 rebalance 静默早退）；-t 给 pane 或
#       window id 均可——window 解析为其活动 pane（本脚本 -pt @win 即用此）；不带 -t 的 list-panes/show -w 解析到会话
#       "当前窗口"（附着客户端所在窗口），后台窗口排查必须显式 -t；
#       show -w -v 对无窗口本地值的选项返回空串（无全局回退），而
#       set -w 却接受空串 style——写回捕获值必须先经哨兵判断，空值只
#       能 set -w -u 删除本地项，否则空值本地选项遮蔽全局（边框渲染成
#       default fg/base05、active 边框无区分，已踩）。
#       focus-events 的 set -w 会连带翻转 global（border/user option 不会，
#       3.5a 实测）——zen 存续期全服务器窗口的 app 都收到焦点转义序列，
#       off 的 set -w -u 同样连带还原 global（见 zen_on 内注释）。
#       show-hooks 在无已装钩子时输出完整钩子名目录（无 [N] 索引）——
#       断言已装状态必须匹配 '名字[' 带索引形式，裸名 grep 必假阳性（踩）。
set -euo pipefail

DEFAULT_WIDTH=120
HOOK_IDX=90   # after-set-option 数组槽位：固定索引，卸载按索引精准移除

usage() {
  printf 'usage: %s {toggle|on|off|rebalance} [pane_id|window_id] | retheme [force] | main-died <window_id>\n' "$0" >&2
  exit 2
}

[ $# -ge 1 ] || usage
cmd=$1
case $cmd in
  toggle|on|off|rebalance|retheme|main-died) ;;
  *) usage ;;
esac

tmux_cmd=(${ZEN_TMUX:-tmux})
t() { "${tmux_cmd[@]}" "$@"; }

is_num() { case ${1:-} in ''|*[!0-9]*) return 1 ;; esac; return 0; }

# 钩子回调需要绝对路径：run-shell 经 sh 已把 ~ 展开为绝对路径；手动相对
# 调用时补 $PWD。
case $0 in
  /*) self=$0 ;;
  *)  self=$PWD/$0 ;;
esac

# ---- 目标解析 -------------------------------------------------------------
# pane id（%N）→ 所属窗口；window id（@N）直接用。缺省取 $TMUX_PANE。
# retheme 面向全服务器，无需目标（钩子回调也没有 pane 上下文）。
# 死 pane 目标（如 main 死后仍触发的 rebalance 钩子）：无从解析窗口，
# 无事可做，静默退出——不泄漏 can't find pane 到 run-shell stderr。
target=${2:-${TMUX_PANE:-}}
if [ -z "$target" ] && [ "$cmd" != retheme ]; then usage; fi
if [ "$cmd" != retheme ] && [ -n "$target" ]; then
  case $target in
    @*) win=$target ;;
    *)  win=$(t display-message -pt "$target" '#{window_id}' 2>/dev/null || true) ;;
  esac
fi
[ -n "${win:-}" ] || [ "$cmd" = retheme ] || exit 0

opt_w() { t show -w -v -t "$win" "$1" 2>/dev/null || true; }
opt_g() { t show -g -v "$1" 2>/dev/null || true; }

pane_alive() { t list-panes -t "$win" -F '#{pane_id}' 2>/dev/null | grep -qx "$1"; }

# 当前 status-style 的 bg（default/解析失败输出空）
status_bg() {
  t show -g -v status-style 2>/dev/null | tr ',' '\n' | sed -n 's/^bg=//p' | head -n 1
}

# 无缝边框：染成 status-style 的 bg（空/default 跳过，保持原样）
seamless_paint() {
  local bg
  bg=$(status_bg)
  if [ -n "$bg" ] && [ "$bg" != default ]; then
    t set -w -t "$win" pane-border-style "fg=$bg,bg=$bg"
    t set -w -t "$win" pane-active-border-style "fg=$bg,bg=$bg"
  fi
}

any_zen() { # 服务器上是否还有 zen 窗口
  local w
  for w in $(t list-windows -a -F '#{window_id}' 2>/dev/null); do
    if [ "$(t show -w -v -t "$w" @zen-active 2>/dev/null)" = on ]; then
      return 0
    fi
  done
  return 1
}

zen_width() {
  local w
  w=$(opt_w @zen-width)
  is_num "$w" || w=$(opt_g @zen-width)
  is_num "$w" || w=$DEFAULT_WIDTH
  printf '%s' "$w"
}

zen_on() {
  local main width ww avail left right left_id right_id
  local order npanes park p last cur
  [ "$(opt_w @zen-active)" = on ] && return 0

  case $target in
    @*) main=$(t display-message -pt "$win" -F '#{pane_id}') ;;
    *)  main=$target ;;
  esac

  width=$(zen_width)
  ww=$(t display-message -pt "$main" '#{window_width}' 2>/dev/null || true)
  [ -n "$ww" ] || return 0  # main 已死（竞态窗口）：尚无任何突变，静默退出
  if [ $((ww - width)) -lt 4 ]; then
    t display-message -t "$main" "zen: window too narrow (${ww} cols) for ${width}" || true
    return 0
  fi

  avail=$((ww - width - 2))
  left=$((avail / 2))
  right=$((avail - left))

  t set -w -t "$win" @zen-active on
  t set -w -t "$win" @zen-main "$main"
  # 快照必须在 parking 之前：@zen-layout 是多 pane 原始树，off 靠它精确
  # 还原；@zen-order 记录 index 顺序（select-layout 按 index 映射槽位，
  # fold back 的 join 会改变 index，off 需 swap 复原内容到原槽位）。
  t set -w -t "$win" @zen-layout "$(t display-message -pt "$main" '#{window_layout}')"
  order=$(t list-panes -t "$win" -F '#{pane_id}' 2>/dev/null | tr '\n' ' ')
  npanes=$(printf '%s\n' $order 2>/dev/null | grep -c . || true)
  park=
  if [ "$npanes" -gt 1 ]; then
    t set -w -t "$win" @zen-order "$order"
    t set -w -t "$win" @zen-multi 1
  fi

  # 窗口选项保存语义：show -w -v 对"无窗口本地值"返回空串（无全局回退，
  # 实测）；空值一律存哨兵 __unset__，off 时 set -w -u 删本地值、回退全局。
  # 绝不能把空串写回：tmux 3.5a 接受空 style，会生成空值本地选项遮蔽全局
  # ——边框渲染成 default fg（base05）且 active 边框无区分（已踩）。
  # 保存必须在 seamless_paint 之前：先染后存会把染色值当原值捕获。
  save_opt() { # save_opt <user-option> <option>
    local v
    v=$(t show -w -v -t "$win" "$2" 2>/dev/null || true)
    t set -w -t "$win" "$1" "${v:-__unset__}"
  }
  save_opt @zen-focus-events   focus-events
  save_opt @zen-border         pane-border-style
  save_opt @zen-active-border  pane-active-border-style

  # 主 pane 进程退出保护（3.5a 实测）：pane-scoped remain-on-exit 让死 pane
  # 保留并触发 pane-died（销毁路径才无钩子）→ main-died 自动拆除。zen 存
  # 续期 %main 永不被销毁——filler 弹回钩子（select-pane -t $main）不可能
  # 打到已销毁目标（Can't find pane 根因消除）。必须装在 split 之前：
  # zen_on 装配期退出的竞态也受保护。
  save_opt_p() { # save_opt_p <user-option> <option> <pane>
    local v
    v=$(t show -p -v -t "$3" "$2" 2>/dev/null || true)
    t set -w -t "$win" "$1" "${v:-__unset__}"
  }
  save_opt_p @zen-remain remain-on-exit "$main"
  t set -p -t "$main" remain-on-exit on
  t set-hook -p -t "$main" pane-died "run-shell '$self main-died $win'" || true

  # pane-focus-in 只在窗口 focus-events=on 且有附着客户端时触发（tmux 手册）：
  # 临时开启，off 删本地值还原。副作用（3.5a 实测）：focus-events 的 set -w
  # 会连带翻转 global——zen 存续期全服务器窗口的 app 均收到焦点进出转义
  # 序列（vim FocusGained/Lost，通常更合意），off 的 -u 同样连带还原。
  t set -w -t "$win" focus-events on

  # 无缝着色必须在 split 之前：单 pane 期无边框渲染、染色不可见，split
  # 诞生的边框"生而无缝"——若 split 后再染，3 pane 以全局主题色渲染边框
  # ~0.1-0.2s 即启动闪烁（off 侧残留问题的镜像）。同时缓存当前 bg，
  # retheme 无变化时 2 次调用即出（防钩子扇出，见 zen_retheme）。
  seamless_paint
  t set -g @zen-painted-bg "$(status_bg)" 2>/dev/null || true

  # 多 pane 整组居中：tmux 无「包裹布局树」原语（split/join 只能细分某只
  # pane 的 cell，顶层侧翼 filler 要求内容独占窗口），故先把非 main pane
  # 寄存到后台 park 窗口（存活 ~百 ms），窗口归一后走既有单 pane 几何，
  # 再把寄存 pane join 回来——全部内容落在居中列容器内，zen 期间新建的
  # pane 也自然在列内。break-pane 自 3.5 起 -s 才是待拆 pane、-t 是目标
  # 窗口（pane 目标给 -t 报 can't specify pane here，实测）。寄存竞态失败
  # 容忍：off 的快照还原降级、不丢 pane。
  if [ "$npanes" -gt 1 ]; then
    for p in $order; do
      [ "$p" = "$main" ] && continue
      if [ -z "$park" ]; then
        # 首只 break 失败（pane 恰死/瞬时失败）不 set -e 中止：park 留空，
        # 顺延用下一只作种子；全败则整个跳过寄存，后续 fold back 自愈。
        park=$(t break-pane -d -s "$p" -P -F '#{window_id}' 2>/dev/null || true)
      else
        t join-pane -h -t "$park" -s "$p" 2>/dev/null || true
      fi
    done
    [ -n "$park" ] && t set -w -t "$win" @zen-park "$park" 2>/dev/null || true
  fi

  left_id=$(t split-window -hbd -P -F '#{pane_id}' -l "$left" -t "$main" 'tail -f /dev/null')
  right_id=$(t split-window -hd -P -F '#{pane_id}' -l "$right" -t "$main" 'tail -f /dev/null')
  t resize-pane -t "$main" -x "$width" || true

  # fold back：寄存 pane 依次 join 回（链式切上一只，main 约保留半列而非
  # 逐次减半）；join 细分的是 pane cell，与 filler 同层的只有装着全部内容
  # 的容器。join 失败的活 pane 留在 park，@zen-park 只在 park 已空时才删
  # ——off 的恢复通道据此把它接回，无条件删会把 pane 困在孤儿后台窗口。
  if [ -n "$park" ]; then
    last=$main
    for p in $order; do
      [ "$p" = "$main" ] && continue
      if t join-pane -h -s "$p" -t "$last" 2>/dev/null; then
        last=$p
      fi
    done
    cur=$(t list-panes -t "$park" -F '#{pane_id}' 2>/dev/null | grep -c . || true)
    [ "$cur" = 0 ] && t set -w -u -t "$win" @zen-park 2>/dev/null || true
  fi

  t set -w -t "$win" @zen-left "$left_id"
  t set -w -t "$win" @zen-right "$right_id"

  # 导航跳过 filler：被选中瞬间弹回主 pane。必须 -p（pane 作用域）+ 绝对
  # 目标——窗口作用域会让两个钩子互相覆盖且波及主 pane，钩子上下文里
  # `:.+` 等相对选择器无基准 pane、静默失败（tmux 3.5a 实测）。
  t set-hook -p -t "$left_id"  pane-focus-in "select-pane -t $main" || true
  t set-hook -p -t "$right_id" pane-focus-in "select-pane -t $main" || true

  t set-hook -g "after-set-option[$HOOK_IDX]" "run-shell '$self retheme'" || true

  # 窗口尺寸变化重平衡（window-resized 实测可靠触发）
  t set-hook -w -t "$win" window-resized "run-shell '$self rebalance $main'" || true

  t select-pane -t "$main"
}

zen_off() {
  local main left right layout b_border b_active b_focus state ids p fast
  local zorder zmulti zpark zremain cur want at i
  [ "$(opt_w @zen-active)" = on ] || return 0

  # ---- 读阶段（纯读不触发 after-set-option 钩子）--------------------------
  # 状态批量读回压成一次 display-message（分隔符 |：layout/style 值只含
  # 逗号不含竖线，order 只含空格），一次 list-panes 替代三次 pane_alive
  # ——翻转状态前仅 3 次 tmux 调用，按键→杀 filler ~40-60ms。
  state=$(t display-message -pt "$win" \
    '#{@zen-main}|#{@zen-left}|#{@zen-right}|#{@zen-layout}|#{@zen-border}|#{@zen-active-border}|#{@zen-focus-events}|#{@zen-order}|#{@zen-multi}|#{@zen-park}|#{@zen-remain}')
  IFS='|' read -r main left right layout b_border b_active b_focus zorder zmulti zpark zremain <<<"$state"
  ids=$(t list-panes -t "$win" -F '#{pane_id}' 2>/dev/null || true)

  # ---- 状态翻转 + 杀 filler 背靠背（中间零 tmux 调用）--------------------
  # 先摘 @zen-active（retheme 钩子此后不再把本窗口当 zen），紧接着杀
  # filler：异步 retheme 的 spawn 延迟（≥30ms）必然落在 kill 之后——单
  # pane 无边框渲染，自愈清扫即使剥掉本地着色也不可见。若中间穿插读/
  # 校验调用，retheme 会在 filler 存活期剥掉无缝着色，边框以全局色亮起
  # ~0.1-0.3s（实测残留路径）。
  t set -w -u -t "$win" @zen-active 2>/dev/null || true

  # park 恢复：on 在 parking 与 fold back 之间折损时（@zen-park 残留），
  # 寄存 pane 先接回窗口再走正常还原（join 目标给窗口 id 即其活动 pane）。
  # 接不回的（已死）留在 park——计数失配只是快照还原降级；park 仍有
  # pane 时绝不杀窗口，空壳/已消亡才清（清空即自动关闭，实测）。
  if [ -n "$zpark" ]; then
    for p in $zorder; do
      [ "$p" = "$main" ] && continue
      t join-pane -h -s "$p" -t "$win" 2>/dev/null || true
    done
    cur=$(t list-panes -t "$zpark" -F '#{pane_id}' 2>/dev/null | grep -c . || true)
    if [ "$cur" = 0 ]; then
      t kill-window -t "$zpark" 2>/dev/null || true
    fi
  fi

  # 单 pane 快照且窗口内恰为 main+两 filler 时 kill-pane -a 一步到位：
  # 主 pane 只收一次 SIGWINCH 直达终宽（多次中间宽度会让异步重绘的 app
  # 交错成乱码）；其余场景（多 pane / filler 已死）逐个杀后按快照
  # select-layout 还原。
  fast=1
  [ -n "$main" ] && [ -n "$left" ] && [ -n "$right" ] || fast=0
  [ "$fast" = 1 ] && printf '%s\n' "$ids" | grep -qx "$main" || fast=0
  [ "$fast" = 1 ] && printf '%s\n' "$ids" | grep -qx "$left" || fast=0
  [ "$fast" = 1 ] && printf '%s\n' "$ids" | grep -qx "$right" || fast=0
  [ "$fast" = 1 ] && [ "$(printf '%s\n' "$ids" | grep -c .)" = 3 ] || fast=0
  { [ "$fast" = 1 ] && ! printf '%s' "$layout" | grep -q '[{[]'; } || fast=0
  if [ "$fast" = 1 ]; then
    t kill-pane -a -t "$main" 2>/dev/null || true
  else
    for p in "$left" "$right"; do
      if [ -n "$p" ] && printf '%s\n' "$ids" | grep -qx "$p"; then
        t kill-pane -t "$p" 2>/dev/null || true
      fi
    done
    [ -n "$layout" ] && t select-layout -t "$win" "$layout" 2>/dev/null || true
  fi

  # select-layout 按 pane index 映射槽位（实测）：pane 数与快照吻合（zen
  # 期间无新建/死亡）时按 @zen-order swap 复原内容到原槽位；失配时跳过，
  # 不搅动用户现场。swap-pane 交换两 pane 内容、index 不变语义见此。
  if [ -n "$zorder" ]; then
    cur=$(t list-panes -t "$win" -F '#{pane_id}' 2>/dev/null | grep -c . || true)
    want=$(printf '%s\n' $zorder | grep -c . || true)
    if [ "$cur" = "$want" ] && [ "$want" -gt 0 ]; then
      i=0
      for p in $zorder; do
        at=$(t list-panes -t "$win" -F '#{pane_id}' 2>/dev/null | sed -n "$((i+1))p")
        if [ -n "$at" ] && [ "$at" != "$p" ]; then
          t swap-pane -d -s "$p" -t "$at" 2>/dev/null || true
        fi
        i=$((i+1))
      done
    fi
  fi

  # ---- 杀后收尾（视觉无关顺序）-------------------------------------------
  t set-hook -w -t "$win" -u window-resized 2>/dev/null || true
  if [ -n "$main" ] && pane_alive "$main"; then
    t select-pane -t "$main" 2>/dev/null || true
  fi

  # 主 pane 退出保护拆除：pane-died 钩子与 remain-on-exit 成对还原（哨兵/
  # 空值删本地回退全局），不留「退出后残留死 pane」隐患——off 后用户退出
  # main 应与从未进过 zen 的行为一致。
  if [ -n "$main" ]; then
    t set-hook -p -u -t "$main" pane-died 2>/dev/null || true
    if [ "$zremain" = "__unset__" ] || [ -z "$zremain" ]; then
      t set -p -u -t "$main" remain-on-exit 2>/dev/null || true
    else
      t set -p -t "$main" remain-on-exit "$zremain" 2>/dev/null || true
    fi
  fi

  # 还原 = 哨兵/空值删本地（回退全局），非空写回原值——与 zen_on 配对。
  # 位于杀 filler 之后：单 pane 已无边框渲染，样式还原不可见。
  restore_opt() { # restore_opt <saved-value> <option>
    if [ "$1" = "__unset__" ] || [ -z "$1" ]; then
      t set -w -u -t "$win" "$2" 2>/dev/null || true
    else
      t set -w -t "$win" "$2" "$1" 2>/dev/null || true
    fi
  }
  restore_opt "$b_focus"    focus-events
  restore_opt "$b_border"   pane-border-style
  restore_opt "$b_active"   pane-active-border-style

  for o in @zen-main @zen-left @zen-right @zen-layout @zen-border \
           @zen-active-border @zen-focus-events @zen-order @zen-multi \
           @zen-park @zen-remain; do
    t set -w -u -t "$win" "$o" 2>/dev/null || true
  done

  # 最后一个 zen 窗口退场：卸载全局重渲染钩子与 bg 缓存（按索引卸载，
  # 不动用户同名列其他槽位）
  any_zen || {
    t set-hook -g -u "after-set-option[$HOOK_IDX]" 2>/dev/null || true
    t set -g -u @zen-painted-bg 2>/dev/null || true
  }
}

zen_main_died() { # main 进程退出（remain-on-exit 保留死 pane）→ pane-died 入口
  # 先走完整 off 还原（filler 先死，其引用 %main 的弹回钩子随之消亡），
  # 最后按原生语义销毁死 pane：单 pane 窗口随最后 pane 关闭，多 pane 还原
  # 布局后由剩余 pane 吸收——与 zen 外直接退出别无二致。竞态：手动 off
  # 先到则 @zen-active 已摘、此处自然空转；用户 respawn 抢先则 pane_dead=0，
  # 绝不杀活 pane。
  local main
  main=$(opt_w @zen-main)
  zen_off
  if [ -n "$main" ] && [ "$(t display-message -pt "$main" '#{pane_dead}' 2>/dev/null || true)" = 1 ]; then
    t kill-pane -t "$main" 2>/dev/null || true
  fi
}

zen_retheme() { # 按当前 status bg 重染 zen 窗口无缝边框 + 自愈残留着色
  # 门控：bg 未变（与全局缓存 @zen-painted-bg 一致）即 2 次调用退出。
  # 必要性：off/on 各 ~10 次 set 都触发本钩子，若每次全量扫 N 窗口×2 读，
  # 扇出的 bash×tmux 进程互相挤兑 socket，off 后台拖尾秒级（实测 3s）。
  # 变化才走全量路径（重染 + 自愈清扫——历史泄漏恰在主题切换时刻暴露）。
  # 公开 API 强制全量：zen.sh retheme force。全量路径兼兜底清场：zen 窗口
  # 绝迹（kill-window/会话销毁绕过 off，无钩子可用）或在途 retheme 追上
  # off 的清理时，卸载全局钩子并清缓存收敛——顺序必须「先卸钩、后清缓
  # 存」：set-hook -g -u 不触发 after-set-option，钩子卸掉后 set -g -u 也
  # 无从触发（均实测）；反序先清缓存会触发钩子，在途 retheme 以空缓存走
  # 全量路径、其 no-op unset 再次点火，fork 风暴（实测 128 进程 wedged）。
  # 缓存只在还有 zen 窗口时写回，否则会把 off 刚清掉的缓存复活。卸载前
  # fresh 复查 any_zen，把与并发 zen_on 的竞态窗口压到毫秒级；偶发失手仅
  # 丢一次热切换，下次 on 会重装钩子。
  local cur w style zb zab cached found
  cur=$(status_bg)
  cached=$(t show -g -v @zen-painted-bg 2>/dev/null || true)
  if [ "${1:-}" != force ] && [ "$cur" = "$cached" ]; then
    return 0
  fi
  found=0
  for w in $(t list-windows -a -F '#{window_id}' 2>/dev/null); do
    if [ "$(t show -w -v -t "$w" @zen-active 2>/dev/null)" = on ]; then
      found=1
      if [ -n "$cur" ] && [ "$cur" != default ]; then
        style="fg=$cur,bg=$cur"
        if [ "$(t show -w -v -t "$w" pane-border-style 2>/dev/null)" != "$style" ]; then
          t set -w -t "$w" pane-border-style "$style" || true
          t set -w -t "$w" pane-active-border-style "$style" || true
        fi
      else
        # bg=default：清除着色回退全局，本就未着色（空值）则零操作
        if [ -n "$(t show -w -v -t "$w" pane-border-style 2>/dev/null)" ]; then
          t set -w -u -t "$w" pane-border-style 2>/dev/null || true
          t set -w -u -t "$w" pane-active-border-style 2>/dev/null || true
        fi
      fi
    else
      # 自愈清扫：非 zen 窗口残留的 zen 着色签名（border/active 两本地值
      # 存在、完全相同且 fg==bg）——历史泄漏（中期代码钩子与拆除打架、
      # 手动 set -w -u @zen-active 清态）无自愈通道，本地值遮蔽全局致
      # "reload 配置也无效"；retheme 顺手回收，用户异值/异色本地不受影响。
      zb=$(t show -w -v -t "$w" pane-border-style 2>/dev/null)
      zab=$(t show -w -v -t "$w" pane-active-border-style 2>/dev/null)
      if [ -n "$zb" ] && [ "$zb" = "$zab" ] \
         && printf '%s' "$zb" | grep -qE '^fg=(#[0-9a-fA-F]{6}),bg=\1$'; then
        t set -w -u -t "$w" pane-border-style 2>/dev/null || true
        t set -w -u -t "$w" pane-active-border-style 2>/dev/null || true
      fi
    fi
  done
  if [ "$found" = 1 ]; then
    t set -g @zen-painted-bg "$cur" 2>/dev/null || true
  elif ! any_zen; then
    t set-hook -g -u "after-set-option[$HOOK_IDX]" 2>/dev/null || true
    t set -g -u @zen-painted-bg 2>/dev/null || true
  fi
}

zen_rebalance() {
  [ "$(opt_w @zen-active)" = on ] || return 0
  local main width ww target_w avail left right
  main=$(opt_w @zen-main)
  [ -n "$main" ] || return 0
  width=$(zen_width)
  ww=$(t display-message -pt "$main" '#{window_width}' 2>/dev/null || true)
  [ -n "$ww" ] || return 0  # main 已死：钩子上下文静默退出，off 负责收尾
  target_w=$width
  [ $((ww - target_w)) -lt 4 ] && target_w=$((ww - 4))
  [ "$target_w" -lt 10 ] && return 0
  avail=$((ww - target_w - 2))
  left=$((avail / 2))
  right=$((avail - left))
  t resize-pane -t "$(opt_w @zen-left)"  -x "$left"  2>/dev/null || true
  t resize-pane -t "$(opt_w @zen-right)" -x "$right" 2>/dev/null || true
  # 多 pane 模式不 pin main（resize 会向列内 sibling 抢列宽）；列宽由顶层
  # filler 尺寸算术锁定：ww = left+1+C+1+right → C = target_w（实测精确）。
  if [ -z "$(opt_w @zen-multi)" ]; then
    t resize-pane -t "$main" -x "$target_w" 2>/dev/null || true
  fi
}

case $cmd in
  toggle) if [ "$(opt_w @zen-active)" = on ]; then zen_off; else zen_on; fi ;;
  on)         zen_on ;;
  off)        zen_off ;;
  rebalance)  zen_rebalance ;;
  retheme)    zen_retheme "${2:-}" ;;
  main-died)  zen_main_died ;;
esac
