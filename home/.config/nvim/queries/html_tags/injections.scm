; extends

((comment) @injection.content
  (#lua-match? @injection.content "@%a")
  (#set! injection.language "jsdoc"))
