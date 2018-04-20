" vim:tabstop=2:shiftwidth=2:expandtab:textwidth=99
" Vimwiki syntax file
" Description: Defines markdown syntax
" Home: https://github.com/vimwiki/vimwiki/


" see the comments in vimwiki_default.vim for some info about this file


let s:markdown_syntax = g:vimwiki_syntax_variables['markdown']

" text: $ equation_inline $
let s:markdown_syntax.rxEqIn = '\$[^$`]\+\$'
let s:markdown_syntax.char_eqin = '\$'

" text: *strong*
" let s:markdown_syntax.rxBold = '\*[^*]\+\*'
let s:markdown_syntax.rxBold = '\%(^\|\s\|[[:punct:]]\)\@<='.
      \'\*'.
      \'\%([^*`[:space:]][^*`]*[^*`[:space:]]\|[^*`[:space:]]\)'.
      \'\*'.
      \'\%([[:punct:]]\|\s\|$\)\@='
let s:markdown_syntax.char_bold = '*'

" text: _emphasis_
" let s:markdown_syntax.rxItalic = '_[^_]\+_'
let s:markdown_syntax.rxItalic = '\%(^\|\s\|[[:punct:]]\)\@<='.
      \'_'.
      \'\%([^_`[:space:]][^_`]*[^_`[:space:]]\|[^_`[:space:]]\)'.
      \'_'.
      \'\%([[:punct:]]\|\s\|$\)\@='
let s:markdown_syntax.char_italic = '_'

" text: *_bold italic_* or _*italic bold*_
let s:markdown_syntax.rxBoldItalic = '\%(^\|\s\|[[:punct:]]\)\@<='.
      \'\*_'.
      \'\%([^*_`[:space:]][^*_`]*[^*_`[:space:]]\|[^*_`[:space:]]\)'.
      \'_\*'.
      \'\%([[:punct:]]\|\s\|$\)\@='
let s:markdown_syntax.char_bolditalic = '\*_'

let s:markdown_syntax.rxItalicBold = '\%(^\|\s\|[[:punct:]]\)\@<='.
      \'_\*'.
      \'\%([^*_`[:space:]][^*_`]*[^*_`[:space:]]\|[^*_`[:space:]]\)'.
      \'\*_'.
      \'\%([[:punct:]]\|\s\|$\)\@='
let s:markdown_syntax.char_italicbold = '_\*'

" text: `code`
let s:markdown_syntax.rxCode = '`[^`]\+`'
let s:markdown_syntax.char_code = '`'

" text: ~~deleted text~~
let s:markdown_syntax.rxDelText = '\~\~[^~`]\+\~\~'
let s:markdown_syntax.char_deltext = '\~\~'

" text: ^superscript^
let s:markdown_syntax.rxSuperScript = '\^[^^`]\+\^'
let s:markdown_syntax.char_superscript = '^'

" text: ,,subscript,,
let s:markdown_syntax.rxSubScript = ',,[^,`]\+,,'
let s:markdown_syntax.char_subscript = ',,'

" generic headers
let s:markdown_syntax.rxH = '#'
let s:markdown_syntax.symH = 0



" <hr>, horizontal rule
let s:markdown_syntax.rxHR = '^-----*$'

" Tables. Each line starts and ends with '|'; each cell is separated by '|'
let s:markdown_syntax.rxTableSep = '|'

" Lists
let s:markdown_syntax.bullet_types = ['-', '*', '+']
let s:markdown_syntax.recurring_bullets = 0
let s:markdown_syntax.number_types = ['1.']
let s:markdown_syntax.list_markers = ['-', '*', '+', '1.']
let s:markdown_syntax.rxListDefine = '::\%(\s\|$\)'

" Preformatted text
let s:markdown_syntax.rxPreStart = '```'
let s:markdown_syntax.rxPreEnd = '```'

" Math block
let s:markdown_syntax.rxMathStart = '\$\$'
let s:markdown_syntax.rxMathEnd = '\$\$'

let s:markdown_syntax.rxComment = '^\s*%%.*$\|<!--[^>]*-->'
let s:markdown_syntax.rxTags = '\%(^\|\s\)\@<=:\%([^:[:space:]]\+:\)\+\%(\s\|$\)\@='

let s:markdown_syntax.header_search = '^\s*\(#\{1,6}\)\([^#].*\)$'
let s:markdown_syntax.header_match = '^\s*\(#\{1,6}\)#\@!\s*__Header__\s*$'
let s:markdown_syntax.bold_search = '\%(^\|\s\|[[:punct:]]\)\@<=\*\zs'.
      \ '\%([^*`[:space:]][^*`]*[^*`[:space:]]\|[^*`[:space:]]\)\ze\*\%([[:punct:]]\|\s\|$\)\@='
let s:markdown_syntax.bold_match = '\%(^\|\s\|[[:punct:]]\)\@<=\*__Text__\*'.
      \ '\%([[:punct:]]\|\s\|$\)\@='
let s:markdown_syntax.wikilink = '\[\[\zs[^\\\]|]\+\ze\%(|[^\\\]]\+\)\?\]\]'
let s:markdown_syntax.tag_search = '\(^\|\s\)\zs:\([^:''[:space:]]\+:\)\+\ze\(\s\|$\)'
let s:markdown_syntax.tag_match = '\(^\|\s\):\([^:''[:space:]]\+:\)*__Tag__:'.
      \ '\([^:[:space:]]\+:\)*\(\s\|$\)'
