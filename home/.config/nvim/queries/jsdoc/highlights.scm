; 全量替换 runtime 的 jsdoc highlights（不带 extends 即整体接管）：
; tag_name 改用 @keyword.jsdoc（init.lua 按主题 Statement 色定义为非粗），
; 避免 @keyword → Statement 的 bold 泄漏；其余行同步自 nvim-treesitter
; queries/jsdoc/highlights.scm，升级插件时需人工比对同步。

(tag_name) @keyword.jsdoc @nospell

(type) @type @nospell

[
  "{"
  "}"
  "["
  "]"
] @punctuation.bracket

[
  ":"
  "."
  "#"
  "~"
] @punctuation.delimiter

(path_expression
  "/" @punctuation.delimiter)

(identifier) @variable @nospell

(tag
  (tag_name) @_name
  (identifier) @function
  (#any-of? @_name "@callback" "@function" "@func" "@method"))

(tag
  (tag_name) @_name
  (identifier) @variable.parameter
  (#any-of? @_name "@param" "@arg" "@argument"))

(tag
  (tag_name) @_name
  (identifier) @property
  (#any-of? @_name "@prop" "@property"))

(tag
  (tag_name) @_name
  (identifier) @type
  (#eq? @_name "@typedef"))
