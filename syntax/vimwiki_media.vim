" vim:tabstop=2:shiftwidth=2:expandtab:textwidth=99
" Vimwiki syntax file
" Description: Defines mediaWiki syntax
" Home: https://github.com/vimwiki/vimwiki/


" see the comments in vimwiki_default.vim for some info about this file


let s:media_syntax = g:vimwiki_syntax_variables['media']

" text: $ equation_inline $
let s:media_syntax.rxEqIn = '\$[^$`]\+\$'
let s:media_syntax.char_eqin = '\$'

" text: '''strong'''
let s:media_syntax.rxBold = "'''[^']\\+'''"
let s:media_syntax.char_bold = "'''"

" text: ''emphasis''
let s:media_syntax.rxItalic = "''[^']\\+''"
let s:media_syntax.char_italic = "''"

" text: '''''strong italic'''''
let s:media_syntax.rxBoldItalic = "'''''[^']\\+'''''"
let s:media_syntax.rxItalicBold = s:media_syntax.rxBoldItalic
let s:media_syntax.char_bolditalic = "'''''"
let s:media_syntax.char_italicbold = s:media_syntax.char_bolditalic

" text: `code`
let s:media_syntax.rxCode = '`[^`]\+`'
let s:media_syntax.char_code = '`'

" text: ~~deleted text~~
let s:media_syntax.rxDelText = '\~\~[^~]\+\~\~'
let s:media_syntax.char_deltext = '\~\~'

" text: ^superscript^
let s:media_syntax.rxSuperScript = '\^[^^]\+\^'
let s:media_syntax.char_superscript = '^'

" text: ,,subscript,,
let s:media_syntax.rxSubScript = ',,[^,]\+,,'
let s:media_syntax.char_subscript = ',,'

" generic headers
let s:media_syntax.rxH = '='
let s:media_syntax.symH = 1



" <hr>, horizontal rule
let s:media_syntax.rxHR = '^-----*$'

" Tables. Each line starts and ends with '|'; each cell is separated by '|'
let s:media_syntax.rxTableSep = '|'

" Lists
let s:media_syntax.bullet_types = ['*', '#']
let s:media_syntax.recurring_bullets = 1
let s:media_syntax.number_types = []
let s:media_syntax.list_markers = ['*', '#']
let s:media_syntax.rxListDefine = '^\%(;\|:\)\s'

" Preformatted text
let s:media_syntax.rxPreStart = '<pre>'
let s:media_syntax.rxPreEnd = '<\/pre>'

" Math block
let s:media_syntax.rxMathStart = '{{\$'
let s:media_syntax.rxMathEnd = '}}\$'

let s:media_syntax.rxComment = '^\s*%%.*$'
let s:media_syntax.rxTags = '\%(^\|\s\)\@<=:\%([^:[:space:]]\+:\)\+\%(\s\|$\)\@='

let s:media_syntax.header_search = '^\s*\(=\{1,6}\)\([^=].*[^=]\)\1\s*$'
let s:media_syntax.header_match = '^\s*\(=\{1,6}\)=\@!\s*__Header__\s*\1=\@!\s*$'
let s:media_syntax.bold_search = "'''\\zs[^']\\+\\ze'''"
let s:media_syntax.bold_match = '''''''__Text__'''''''
" ^- this strange looking thing is equivalent to "'''__Text__'''" but since we later
" want to call escape() on this string, we must keep it in single quotes
let s:media_syntax.wikilink = '\[\[\zs[^\\\]|]\+\ze\%(|[^\\\]]\+\)\?\]\]'
let s:media_syntax.tag_search = '\(^\|\s\)\zs:\([^:''[:space:]]\+:\)\+\ze\(\s\|$\)'
let s:media_syntax.tag_match = '\(^\|\s\):\([^:''[:space:]]\+:\)*__Tag__:'.
      \ '\([^:[:space:]]\+:\)*\(\s\|$\)'
