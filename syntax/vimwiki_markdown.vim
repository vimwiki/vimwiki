" vim:tabstop=2:shiftwidth=2:expandtab:textwidth=99
" Vimwiki syntax file
" Description: Defines markdown syntax
" Home: https://github.com/vimwiki/vimwiki/


" see the comments in vimwiki_default.vim for some info about this file


let s:markdown_syntax = g:vimwiki_syntax_variables['markdown']

" text: $ equation_inline $
let s:markdown_syntax.rxEqIn = '\$[^$`]\+\$'
let s:markdown_syntax.char_eqin = '\$'

" text: **strong** or __strong__
let s:markdown_syntax.rxBold = '\%(^\|\s\|[[:punct:]]\)\@<='.
      \'\(\*\|_\)\{2\}'.
      \'\%([^*_`[:space:]][^*_`]*[^*_`[:space:]]\|[^*_`[:space:]]\)'.
      \'\1\{2\}'.
      \'\%([[:punct:]]\|\s\|$\)\@='
let s:markdown_syntax.char_bold = '\*\*\|__'

" text: _emphasis_ or *emphasis*
let s:markdown_syntax.rxItalic = '\%(^\|\s\|[[:punct:]]\)\@<='.
      \'\(\*\|_\)'.
      \'\%([^*_`[:space:]][^*_`]*[^*_`[:space:]]\|[^*_`[:space:]]\)'.
      \'\1'.
      \'\%([[:punct:]]\|\s\|$\)\@='
let s:markdown_syntax.char_italic = '\*\|_'

" text: *_bold italic_* or _*italic bold*_
let s:markdown_syntax.rxBoldItalic = '\%(^\|\s\|[[:punct:]]\)\@<='.
      \'\(\*\)\{3\}'.
      \'\%([^*`[:space:]][^*`]*[^*`[:space:]]\|[^*`[:space:]]\)'.
      \'\1\{3\}'.
      \'\%([[:punct:]]\|\s\|$\)\@='
let s:markdown_syntax.char_bolditalic = '\*\*\*'

let s:markdown_syntax.rxItalicBold = '\%(^\|\s\|[[:punct:]]\)\@<='.
      \'\(_\)\{3\}'.
      \'\%([^_`[:space:]][^_`]*[^_`[:space:]]\|[^_`[:space:]]\)'.
      \'\1\{3\}'.
      \'\%([[:punct:]]\|\s\|$\)\@='
let s:markdown_syntax.char_italicbold = '___'

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
let s:markdown_syntax.rxHR = '\(^---*$\|^___*$\|^\*\*\**$\)'

" Tables. Each line starts and ends with '|'; each cell is separated by '|'
let s:markdown_syntax.rxTableSep = '|'

" Lists
let s:markdown_syntax.bullet_types = ['-', '*', '+']
let s:markdown_syntax.recurring_bullets = 0
let s:markdown_syntax.number_types = ['1.']
let s:markdown_syntax.list_markers = ['-', '*', '+', '1.']
let s:markdown_syntax.rxListDefine = '::\%(\s\|$\)'

" Preformatted text (code blocks)
let s:markdown_syntax.rxPreStart = '\%(`\{3,}\|\~\{3,}\)'
let s:markdown_syntax.rxPreEnd = '\%(`\{3,}\|\~\{3,}\)'
" TODO see syntax/vimwiki_markdown_custom.vim for more info
" let s:markdown_syntax.rxIndentedCodeBlock = '\%(^\n\)\@1<=\%(\%(\s\{4,}\|\t\+\).*\n\)\+'

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
