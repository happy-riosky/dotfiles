" =============================================================================
" Filename: autoload/lightline/colorscheme/catppuccin_latte_yellow.vim
" Description: Catppuccin Latte with yellow accent for lightline
" =============================================================================

let s:mauve = [ "#8839EF", 183 ]
let s:red = [ "#D20F39", 211 ]
let s:yellow = [ "#DF8E1D", 223 ]
let s:teal = [ "#179299", 152 ]
let s:blue = [ "#1E66F5", 117 ]
let s:overlay0 = [ "#9CA0B0", 243 ]
let s:surface1 = [ "#BCC0CC", 240 ]
let s:surface0 = [ "#CCD0DA", 236 ]
let s:base = [ "#EFF1F5", 235 ]
let s:mantle = [ "#E6E9EF", 234 ]
let s:highlight = [ "#DDE0E7", 253 ]

let s:p = {'normal': {}, 'inactive': {}, 'insert': {}, 'replace': {}, 'visual': {}, 'tabline': {}}
let s:p.normal.left = [ [ s:mantle, s:yellow ], [ s:yellow, s:highlight ] ]
let s:p.normal.right = [ [ s:overlay0, s:base ], [ s:yellow, s:highlight ] ]
let s:p.inactive.right = [ [ s:surface1, s:base ], [ s:overlay0, s:base ] ]
let s:p.inactive.left =  [ [ s:yellow, s:base ], [ s:overlay0, s:base ] ]
let s:p.insert.left = [ [ s:mantle, s:teal ], [ s:yellow, s:highlight ] ]
let s:p.replace.left = [ [ s:mantle, s:red ], [ s:yellow, s:highlight ] ]
let s:p.visual.left = [ [ s:mantle, s:mauve ], [ s:yellow, s:highlight ] ]
let s:p.normal.middle = [ [ s:yellow, s:highlight ] ]
let s:p.inactive.middle = [ [ s:surface1, s:base ] ]
let s:p.tabline.left = [ [ s:overlay0, s:base ], [ s:overlay0, s:base ] ]
let s:p.tabline.tabsel = [ [ s:yellow, s:highlight ], [ s:overlay0, s:base] ]
let s:p.tabline.middle = [ [ s:surface1, s:base ] ]
let s:p.tabline.right = copy(s:p.inactive.right)
let s:p.normal.error = [ [ s:mantle, s:red ] ]
let s:p.normal.warning = [ [ s:mantle, s:yellow ] ]

let g:lightline#colorscheme#catppuccin_latte_yellow#palette = lightline#colorscheme#flatten(s:p)
