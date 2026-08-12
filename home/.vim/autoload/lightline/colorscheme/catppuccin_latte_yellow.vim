" =============================================================================
" Filename: autoload/lightline/colorscheme/catppuccin_latte_yellow.vim
" Description: Catppuccin Latte with yellow accent for lightline
" =============================================================================

let s:red = [ "#D20F39", 211 ]
let s:yellow = [ "#DF8E1D", 223 ]
let s:teal = [ "#179299", 152 ]
let s:text = [ "#4C4F69", 239 ]
let s:subtext1 = [ "#5C5F77", 240 ]
let s:subtext0 = [ "#6C6F85", 243 ]
let s:overlay0 = [ "#9CA0B0", 243 ]
let s:surface1 = [ "#BCC0CC", 250 ]
let s:surface0 = [ "#CCD0DA", 236 ]
let s:base = [ "#EFF1F5", 235 ]
let s:crust = [ "#DCE0E8", 253 ]

let s:p = {'normal': {}, 'inactive': {}, 'insert': {}, 'replace': {}, 'visual': {}, 'tabline': {}}
let s:p.normal.left = [ [ s:text, s:yellow ], [ s:text, s:surface1 ] ]
let s:p.normal.right = [ [ s:text, s:yellow ], [ s:text, s:surface1 ], [ s:subtext1, s:crust ] ]
let s:p.inactive.right = [ [ s:overlay0, s:crust ], [ s:overlay0, s:crust ] ]
let s:p.inactive.left =  [ [ s:overlay0, s:crust ], [ s:overlay0, s:crust ] ]
let s:p.insert.left = [ [ s:base, s:teal ], [ s:text, s:surface1 ] ]
let s:p.replace.left = [ [ s:base, s:red ], [ s:text, s:surface1 ] ]
let s:p.visual.left = [ [ s:text, s:yellow ], [ s:text, s:surface1 ] ]
let s:p.normal.middle = [ [ s:subtext1, s:crust ] ]
let s:p.inactive.middle = [ [ s:overlay0, s:crust ] ]
let s:p.tabline.left = [ [ s:subtext0, s:crust ], [ s:subtext0, s:crust ] ]
let s:p.tabline.tabsel = [ [ s:text, s:yellow ], [ s:text, s:surface0 ] ]
let s:p.tabline.middle = [ [ s:overlay0, s:crust ] ]
let s:p.tabline.right = copy(s:p.inactive.right)
let s:p.normal.error = [ [ s:base, s:red ] ]
let s:p.normal.warning = [ [ s:text, s:yellow ] ]

let g:lightline#colorscheme#catppuccin_latte_yellow#palette = lightline#colorscheme#flatten(s:p)
