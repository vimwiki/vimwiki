" vim:tabstop=2:shiftwidth=2:expandtab:textwidth=99
" Vimwiki syntax file
" Home: https://github.com/vimwiki/vimwiki/
" Description: Defines markdown syntax
" Called: vars.vim => Many other (common) variables are defined there
" More in u.vim, base.vim (nested_syntax for multiline code)

let s:markdown_syntax = g:vimwiki_syntax_variables['markdown']


" TODO mutualise
" Get config: possibly concealed chars
let b:vimwiki_syntax_conceal = exists('+conceallevel') ? ' conceal' : ''
let b:vimwiki_syntax_concealends = has('conceal') ? ' concealends' : ''


" text: **bold** or __bold__
let s:markdown_syntax.dTypeface.bold = vimwiki#u#hi_expand_regex([
      \ ['__', '__'], ['\*\*', '\*\*']])

" text: *italic* or _italic_
let s:markdown_syntax.dTypeface.italic = vimwiki#u#hi_expand_regex([
      \ ['\*', '\*'], ['_', '_']])

" text: no underline defined
let s:markdown_syntax.dTypeface.underline = []

" text: *_bold italic_* or _*italic bold*_ or ___bi___ or ***bi***
let s:markdown_syntax.dTypeface.bold_italic = vimwiki#u#hi_expand_regex([
      \ ['\*_', '_\*'], ['_\*', '\*_'], ['\*\*\*', '\*\*\*'], ['___', '___']])


" generic headers
let s:markdown_syntax.rxH = '#'
let s:markdown_syntax.symH = 0

" <hr>, horizontal rule
let s:markdown_syntax.rxHR = '\(^---*$\|^___*$\|^\*\*\**$\)'

" Tables. Each line starts and ends with '|'; each cell is separated by '|'
let s:markdown_syntax.rxTableSep = '|'

" Lists
let s:markdown_syntax.recurring_bullets = 0
let s:markdown_syntax.number_types = ['1.']
let s:markdown_syntax.list_markers = ['-', '*', '+', '1.']
let s:markdown_syntax.rxListDefine = '::\%(\s\|$\)'
let s:markdown_syntax.bullet_types = ['*', '-', '+']

" Preformatted text (code blocks)
let s:markdown_syntax.rxPreStart = '\%(`\{3,}\|\~\{3,}\)'
let s:markdown_syntax.rxPreEnd = '\%(`\{3,}\|\~\{3,}\)'
" TODO see syntax/vimwiki_markdown_custom.vim for more info
" let s:markdown_syntax.rxIndentedCodeBlock = '\%(^\n\)\@1<=\%(\%(\s\{4,}\|\t\+\).*\n\)\+'

" Math block
let s:markdown_syntax.rxMathStart = '\$\$'
let s:markdown_syntax.rxMathEnd = '\$\$'

" NOTE: There is no multi-line comment syntax for Markdown
let s:markdown_syntax.rxMultilineCommentStart = ''
let s:markdown_syntax.rxMultilineCommentEnd = ''
let s:markdown_syntax.rxComment = '^\s*%%.*$\|<!--[^>]*-->'
let s:markdown_syntax.rxTags = '\%(^\|\s\)\@<=:\%([^:[:space:]]\+:\)\+\%(\s\|$\)\@='


" Used in code (base.vim)
"""""""""""""""""""""""""

" Header
" TODO mutualise with rxHeader in vars.vim := Define atx_regex only onces
" TODO regex_or function  => (1|2)
let atx_header_search = '^\s*\(#\{1,6}\)\([^#].*\)$'
let atx_header_match  = '^\s*\(#\{1,6}\)#\@!\s*__Header__\s*$'

let setex_header_search = '^\s\{0,3}\zs[^>].*\ze\n'
let setex_header_search .= '^\s\{0,3}[=-]\{2,}$'

let setex_header_match = '^\s\{0,3}>\@!__Header__\n'
let setex_header_match .= '^\s\{0,3}[=-][=-]\+$'

let s:markdown_syntax.header_search = '\%(' . atx_header_search . '\|' . setex_header_search . '\)'
let s:markdown_syntax.header_match = '\%(' . atx_header_match . '\|' . setex_header_match . '\)'

let s:markdown_syntax.bold_search = '\%(^\|\s\|[[:punct:]]\)\@<=\*\zs'.
      \ '\%([^*`[:space:]][^*`]*[^*`[:space:]]\|[^*`[:space:]]\)\ze\*\%([[:punct:]]\|\s\|$\)\@='
let s:markdown_syntax.bold_match = '\%(^\|\s\|[[:punct:]]\)\@<=\*__Text__\*'.
      \ '\%([[:punct:]]\|\s\|$\)\@='
let s:markdown_syntax.wikilink = '\[\[\zs[^\\\]|]\+\ze\%(|[^\\\]]\+\)\?\]\]'
let s:markdown_syntax.tag_search = '\(^\|\s\)\zs:\([^:''[:space:]]\+:\)\+\ze\(\s\|$\)'
let s:markdown_syntax.tag_match = '\(^\|\s\):\([^:''[:space:]]\+:\)*__Tag__:'.
      \ '\([^:[:space:]]\+:\)*\(\s\|$\)'
