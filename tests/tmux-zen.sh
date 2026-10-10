#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

# zen.sh 契约测试（自 tests/tmux.sh 拆出）：隔离 server（-L zentest-$$，
# 不碰真实会话）驱动 on/off/retheme 全周期——居中几何、无缝着色与全局隔
# 离、主题热切换重染、残留自愈、rebalance、多 pane 整组居中（park/fold
# back/列内新建/精确还原/park 恢复）、主 pane 进程退出自动拆除、窄窗拒
# 绝、容错拆除，以及两项清场不变量：kill-window 绕过 off 后 retheme 全量路径兜
# 底卸载钩子/缓存；off 后在途 retheme（以 force 模拟）不得复活缓存。焦
# 点类钩子无附着客户端不触发（zen.sh 头部注释同款限制），只断言装配不断
# 言行为。需 tmux 运行时，缺失时跳过。
test_zen_lifecycle() {
  command -v tmux >/dev/null 2>&1 || { printf 'skip: tmux not found\n'; return 0; }
  local zsock="zentest-$$" ZEN="$ROOT/home/.tmux/scripts/zen.sh"
  local main win left right lw rw resid tail_p pre_layout post_layout v n
  s() { tmux -L "$zsock" "$@"; }
  z() { ZEN_TMUX="tmux -L $zsock" bash "$ZEN" "$@"; }
  trap "tmux -L $zsock kill-server 2>/dev/null || true" EXIT

  s -f /dev/null new-session -d -x 200 -y 50 -n main || fail 'zen: test server boot'
  s set -g status-style 'fg=#eff1f5,bg=#303446'
  s set -g pane-border-style 'fg=#6c7086'
  main=$(s list-panes -t 0 -F '#{pane_id}' | head -n1)
  win=$(s display-message -pt "$main" '#{window_id}')

  # on：几何 + 着色 + 钩子装配 + 全局隔离
  z on "$win" || fail 'zen: on'
  [ "$(s list-panes -t "$win" -F '#{pane_id}' | grep -c .)" = 3 ] || fail 'zen: 3 panes'
  [ "$(s display-message -pt "$main" '#{pane_width}')" = 120 ] || fail 'zen: width pinned'
  left=$(s show -w -v -t "$win" @zen-left); right=$(s show -w -v -t "$win" @zen-right)
  [ "$(s display-message -pt "$left" '#{pane_left}')" = 0 ] || fail 'zen: left filler at col 0'
  lw=$(s display-message -pt "$left" '#{pane_width}')
  rw=$(s display-message -pt "$right" '#{pane_width}')
  [ "$lw" = 39 ] && [ "$rw" = 39 ] || fail 'zen: symmetric fillers 39/39'
  [ "$(s show -w -v -t "$win" pane-border-style)" = 'fg=#303446,bg=#303446' ] || fail 'zen: border painted'
  [ "$(s show -w -v -t "$win" focus-events)" = on ] || fail 'zen: focus-events local on'
  s show-hooks -p -t "$left" | grep -q "pane-focus-in.*select-pane -t .$main" || fail 'zen: filler focus hook'
  s show-hooks -w -t "$win" | grep -q window-resized || fail 'zen: window-resized hook'
  s show-hooks -g | grep -q 'after-set-option\[90\]' || fail 'zen: global retheme hook'
  [ "$(s show -g -v @zen-painted-bg)" = '#303446' ] || fail 'zen: bg cache'
  [ "$(s show -g -v pane-border-style)" = 'fg=#6c7086' ] || fail 'zen: global border leaked'

  # 主题热切换 → 钩子驱动重染（run-shell 异步，留 spawn 窗口）
  s set -g status-style 'fg=#eff1f5,bg=#232634'
  sleep 0.8
  [ "$(s show -w -v -t "$win" pane-border-style)" = 'fg=#232634,bg=#232634' ] || fail 'zen: retheme repaint on theme change'
  [ "$(s show -g -v @zen-painted-bg)" = '#232634' ] || fail 'zen: retheme cache update'

  # 残留自愈：非 zen 窗口的 zen 着色签名被回收，用户异值配对不受影响
  resid=$(s new-window -d -n resid -P -F '#{window_id}')
  s set -w -t "$resid" pane-border-style 'fg=#303446,bg=#303446'
  s set -w -t "$resid" pane-active-border-style 'fg=#303446,bg=#303446'
  z retheme force || fail 'zen: retheme force'
  v=$(s show -w -v -t "$resid" pane-border-style 2>/dev/null || true)
  [ -z "$v" ] || fail 'zen: residue signature healed'
  s set -w -t "$resid" pane-border-style 'fg=#123456,bg=#123456'
  s set -w -t "$resid" pane-active-border-style 'fg=#654321,bg=#654321'
  z retheme force
  [ "$(s show -w -v -t "$resid" pane-border-style)" = 'fg=#123456,bg=#123456' ] || fail 'zen: heal false positive on user styles'
  s kill-window -t "$resid"

  # rebalance：窗口变宽后仍居中（window-resized 钩子驱动）
  s resize-window -t "$win" -x 240
  sleep 0.8
  [ "$(s display-message -pt "$main" '#{pane_width}')" = 120 ] || fail 'zen: rebalance keeps main width'
  lw=$(s display-message -pt "$left" '#{pane_width}')
  rw=$(s display-message -pt "$right" '#{pane_width}')
  [ "$lw" = 59 ] && [ "$rw" = 59 ] || fail 'zen: rebalance symmetric 59/59'

  # off：还原 + 清场（等待在途 retheme 进程收敛）
  z off "$main" || fail 'zen: off'
  sleep 0.8
  [ "$(s list-panes -t "$win" -F '#{pane_id}' | grep -c .)" = 1 ] || fail 'zen: off pane count'
  v=$(s show -w -v -t "$win" pane-border-style 2>/dev/null || true)
  [ -z "$v" ] || fail 'zen: off border restored'
  v=$(s show -w -v -t "$win" focus-events 2>/dev/null || true)
  { [ -z "$v" ] || [ "$v" = off ]; } || fail 'zen: off focus-events restored'
  [ "$(s show -g -v focus-events)" = off ] || fail 'zen: off global focus-events restored'
  v=$(s show -g -v @zen-painted-bg 2>/dev/null || true)
  [ -z "$v" ] || fail 'zen: off cache removed'
  if s show-hooks -g 2>/dev/null | grep -q 'after-set-option\[90\]'; then
    fail 'zen: off hook removed'
  fi

  # off 后全量 retheme 不得复活缓存（在途 retheme 收敛回归）
  z retheme force
  v=$(s show -g -v @zen-painted-bg 2>/dev/null || true)
  [ -z "$v" ] || fail 'zen: retheme resurrects cache after off'

  # 多 pane 整组居中：park → 单 pane zen → fold back
  tail_p=$(s split-window -h -t "$main" -l 60 -P -F '#{pane_id}' 'tail -f /dev/null')
  s resize-window -t "$win" -x 200  # 单 pane rebalance 测试留了 240，归位
  pre_layout=$(s display-message -pt "$main" '#{window_layout}')
  pre_order=$(s list-panes -t "$win" -F '#{pane_id}' | tr '\n' ' ')
  nwin_pre=$(s list-windows -F '#{window_id}' | grep -c .)
  z on "$main" || fail 'zen: multi on'
  left=$(s show -w -v -t "$win" @zen-left); right=$(s show -w -v -t "$win" @zen-right)
  [ "$(s show -p -v -t "$main" remain-on-exit)" = on ] || fail 'zen: remain-on-exit on main'
  s show-hooks -p -t "$main" | grep -q "pane-died.*main-died $win" || fail 'zen: pane-died hook installed'
  [ "$(s list-panes -t "$win" -F '#{pane_id}' | grep -c .)" = 4 ] || fail 'zen: multi pane count'
  [ "$(s show -w -v -t "$win" @zen-multi)" = 1 ] || fail 'zen: @zen-multi set'
  lw=$(s display-message -pt "$left" '#{pane_width}')
  rw=$(s display-message -pt "$right" '#{pane_width}')
  [ "$lw" = 39 ] && [ "$rw" = 39 ] || fail 'zen: multi fillers 39/39'
  tw=$(s display-message -pt "$tail_p" '#{pane_width}')
  [ "$tw" -ge 30 ] || fail "zen: sibling not crushed (width=$tw)"
  for pp in "$main" "$tail_p"; do
    pl=$(s display-message -pt "$pp" '#{pane_left}')
    pr=$((pl + $(s display-message -pt "$pp" '#{pane_width}')))
    [ "$pl" -ge 40 ] && [ "$pr" -le 160 ] || fail "zen: pane $pp outside column (l=$pl r=$pr)"
  done
  [ "$(s list-windows -F '#{window_id}' | grep -c .)" = "$nwin_pre" ] || fail 'zen: park window cleaned up'
  v=$(s show -w -v -t "$win" @zen-park 2>/dev/null || true)
  [ -z "$v" ] || fail 'zen: multi on clears @zen-park handle'
  # zen 期间新建 pane 落在列内
  extra=$(s split-window -h -t "$main" -l 30 -P -F '#{pane_id}' 'tail -f /dev/null')
  el=$(s display-message -pt "$extra" '#{pane_left}')
  [ "$el" -ge 40 ] || fail "zen: split during zen inside column (left=$el)"
  s kill-pane -t "$extra"
  # 多 pane rebalance：窗口变宽后整组仍居中
  s resize-window -t "$win" -x 240
  sleep 0.8
  lw=$(s display-message -pt "$left" '#{pane_width}')
  rw=$(s display-message -pt "$right" '#{pane_width}')
  [ "$lw" = 59 ] && [ "$rw" = 59 ] || fail 'zen: multi rebalance 59/59'
  for pp in "$main" "$tail_p"; do
    pl=$(s display-message -pt "$pp" '#{pane_left}')
    pr=$((pl + $(s display-message -pt "$pp" '#{pane_width}')))
    [ "$pl" -ge 60 ] && [ "$pr" -le 180 ] || fail "zen: multi rebalance outside column ($pp l=$pl r=$pr)"
  done
  s resize-window -t "$win" -x 200
  sleep 0.8
  z off "$main" || fail 'zen: multi off'
  post_layout=$(s display-message -pt "$main" '#{window_layout}')
  [ "$post_layout" = "$pre_layout" ] || fail 'zen: multi layout restored'
  post_order=$(s list-panes -t "$win" -F '#{pane_id}' | tr '\n' ' ')
  [ "$post_order" = "$pre_order" ] || fail "zen: multi pane order restored (pre=[$pre_order] post=[$post_order])"
  v=$(s show -p -v -t "$main" remain-on-exit 2>/dev/null || true)
  [ -z "$v" ] || fail 'zen: off restores remain-on-exit'
  if s show-hooks -p -t "$main" 2>/dev/null | grep -q pane-died; then
    fail 'zen: off strips pane-died hook'
  fi

  # park 恢复：模拟 on 在寄存后折损（pane 未 fold back、@zen-park 残留）
  z on "$main" || fail 'zen: recovery on'
  recov=$(s break-pane -d -s "$tail_p" -P -F '#{window_id}')
  s set -w -t "$win" @zen-park "$recov"
  z off "$main" || fail 'zen: recovery off'
  [ "$(s list-panes -t "$win" -F '#{pane_id}' | grep -c .)" = 2 ] || fail 'zen: park recovery rejoined pane'
  [ "$(s display-message -pt "$main" '#{window_layout}')" = "$pre_layout" ] || fail 'zen: park recovery layout'
  [ "$(s list-windows -F '#{window_id}' | grep -c .)" = "$nwin_pre" ] || fail 'zen: park recovery window cleaned'

  # 主 pane 进程退出 → pane-died 自动拆除（Can't find pane 根因修复）：
  # remain-on-exit 保留死 pane 触发钩子，off 还原后按原生语义销毁死 pane。
  # 杀的是 pane_pid（进程退出路径），不是 kill-pane（销毁路径，无钩子）。
  qwin=$(s new-window -d -n quit -P -F '#{window_id}' 'sleep 100')
  qmain=$(s display-message -pt "$qwin" -F '#{pane_id}')
  qsib=$(s split-window -h -t "$qmain" -l 40 -P -F '#{pane_id}' 'sleep 9999')
  z on "$qmain" || fail 'zen: quit-path on'
  kill "$(s display-message -pt "$qmain" '#{pane_pid}')"
  sleep 1.2
  n=$(s list-panes -t "$qwin" -F '#{pane_id}' 2>/dev/null | grep -c . || true)
  [ "$n" = 1 ] || fail "zen: quit teardown left $n panes (expect sibling only)"
  v=$(s show -w -v -t "$qwin" @zen-active 2>/dev/null || true)
  [ -z "$v" ] || fail 'zen: quit teardown zen residue'
  v=$(s show -p -v -t "$qsib" remain-on-exit 2>/dev/null || true)
  [ -z "$v" ] || fail 'zen: quit teardown keeps sibling pane options clean'
  if s show-hooks -g 2>/dev/null | grep -q 'after-set-option\['; then
    fail 'zen: quit teardown removed global retheme hook'
  fi
  s kill-window -t "$qwin"
  # 单 pane 变体：退出后窗口随最后 pane 原生关闭
  q2=$(s new-window -d -n q1 -P -F '#{window_id}' 'sleep 100')
  qm=$(s display-message -pt "$q2" -F '#{pane_id}')
  z on "$qm" || fail 'zen: single quit on'
  kill "$(s display-message -pt "$qm" '#{pane_pid}')"
  sleep 1.2
  n=$(s list-panes -t "$q2" -F '#{pane_id}' 2>/dev/null | grep -c . || true)
  [ "$n" = 0 ] || fail "zen: single quit closes window (left $n panes)"

  # 窄窗拒绝
  s resize-window -t "$win" -x 100
  z on "$main"
  v=$(s show -w -v -t "$win" @zen-active 2>/dev/null || true)
  [ -z "$v" ] || fail 'zen: narrow window refused'
  s resize-window -t "$win" -x 200

  # kill-window 绕过 off → retheme 全量路径兜底卸载钩子与缓存
  resid=$(s new-window -d -n leak -P -F '#{window_id}')
  z on "$(s display-message -pt "$resid" -F '#{pane_id}')" || fail 'zen: on leak window'
  s kill-window -t "$resid"
  z retheme force
  if s show-hooks -g 2>/dev/null | grep -q 'after-set-option\[90\]'; then
    fail 'zen: leak fallback removes hook'
  fi
  v=$(s show -g -v @zen-painted-bg 2>/dev/null || true)
  [ -z "$v" ] || fail 'zen: leak fallback removes cache'

  # 容错拆除：main 已死，从 filler 再按 toggle
  s kill-pane -t "$tail_p"
  z on "$main" || fail 'zen: tolerant on'
  left=$(s show -w -v -t "$win" @zen-left)
  s kill-pane -t "$main"
  z toggle "$left" || fail 'zen: tolerant toggle from filler'
  n=$(s list-panes -t "$win" -F '#{pane_id}' 2>/dev/null | grep -c . || true)
  [ "$n" = 0 ] || fail 'zen: tolerant teardown closes window'
}

test_zen_lifecycle
printf 'tmux zen tests passed\n'
