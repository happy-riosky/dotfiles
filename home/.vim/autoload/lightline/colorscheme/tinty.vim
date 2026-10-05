" =============================================================================
" Filename: autoload/lightline/colorscheme/tinty.vim
" Description: 跟随 tinty 的 lightline 配色——tinted-vim 生成文件暴露的
" g:tinted_gui*/g:tinted_cterm* 存在时按当前 scheme 动态构建：中性面取
" gui00-07，accent 恒取黄槽 gui0A（黄 identity 贯穿所有 scheme，深浅
" scheme 皆自动翻转）；否则内置 catppuccin-frappe 常量兜底（黄 #e5c890）。
" FocusGained 重建手法见 .vimrc 的 s:TintyRefresh：unlet palette →
" runtime 本文件 → call lightline#colorscheme()。
" =============================================================================

let s:p = {'normal': {}, 'inactive': {}, 'insert': {}, 'replace': {}, 'visual': {}, 'tabline': {}}

if exists('g:tinted_gui00')
  let s:accent = [ '#' . g:tinted_gui0A, str2nr(g:tinted_cterm0A) ]
  let s:text   = [ '#' . g:tinted_gui05, str2nr(g:tinted_cterm05) ]
  let s:subtle = [ '#' . g:tinted_gui03, str2nr(g:tinted_cterm03) ]
  let s:faint  = [ '#' . g:tinted_gui02, str2nr(g:tinted_cterm02) ]
  let s:base   = [ '#' . g:tinted_gui00, str2nr(g:tinted_cterm00) ]
  let s:red    = [ '#' . g:tinted_gui08, str2nr(g:tinted_cterm08) ]
  let s:teal   = [ '#' . g:tinted_gui0C, str2nr(g:tinted_cterm0C) ]
else
  let s:accent = [ '#e5c890', 222 ]
  let s:text   = [ '#c6d0f5', 189 ]
  let s:subtle = [ '#51576d', 61 ]
  let s:faint  = [ '#414559', 238 ]
  let s:base   = [ '#303446', 236 ]
  let s:red    = [ '#e78284', 210 ]
  let s:teal   = [ '#81c8be', 152 ]
endif

let s:p.normal.left = [ [ s:text, s:accent ], [ s:text, s:faint ] ]
let s:p.normal.right = [ [ s:text, s:accent ], [ s:text, s:faint ], [ s:subtle, s:base ] ]
let s:p.inactive.right = [ [ s:subtle, s:base ], [ s:subtle, s:base ] ]
let s:p.inactive.left =  [ [ s:subtle, s:base ], [ s:subtle, s:base ] ]
let s:p.insert.left = [ [ s:base, s:teal ], [ s:text, s:faint ] ]
let s:p.replace.left = [ [ s:base, s:red ], [ s:text, s:faint ] ]
let s:p.visual.left = [ [ s:text, s:accent ], [ s:text, s:faint ] ]
let s:p.normal.middle = [ [ s:subtle, s:base ] ]
let s:p.inactive.middle = [ [ s:subtle, s:base ] ]
let s:p.tabline.left = [ [ s:subtle, s:base ], [ s:subtle, s:base ] ]
let s:p.tabline.tabsel = [ [ s:text, s:accent ], [ s:text, s:faint ] ]
let s:p.tabline.middle = [ [ s:subtle, s:base ] ]
let s:p.tabline.right = copy(s:p.inactive.right)
let s:p.normal.error = [ [ s:base, s:red ] ]
let s:p.normal.warning = [ [ s:text, s:accent ] ]

let g:lightline#colorscheme#tinty#palette = lightline#colorscheme#flatten(s:p)
