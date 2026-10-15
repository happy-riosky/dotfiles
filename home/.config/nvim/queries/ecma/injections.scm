; extends

((comment) @injection.content
  (#lua-match? @injection.content "^//%s*@%a")
  (#set! injection.language "jsdoc"))

((comment) @injection.content
  (#lua-match? @injection.content "^/[*][^*].*[*]/$")
  (#set! injection.language "jsdoc"))
