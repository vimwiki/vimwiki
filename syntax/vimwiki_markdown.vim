" vim:tabstop=2:shiftwidth=2:expandtab:textwidth=99
" Vimwiki syntax file
" Description: Defines markdown syntax
" Home: https://github.com/vimwiki/vimwiki/


" see the comments in vimwiki_default.vim for some info about this file


let s:markdown_syntax = g:vimwiki_syntax_variables['markdown']


" TODO mutualise
" Get config: possibly concealed chars
let b:vimwiki_syntax_conceal = exists('+conceallevel') ? ' conceal' : ''
let b:vimwiki_syntax_concealends = has('conceal') ? ' concealends' : ''


" Typeface:
let s:markdown_syntax.dTypeface = {}

" text: **bold** or __bold__
let s:markdown_syntax.dTypeface['bold'] = [
      \ ['\S\@<=__\|__\S\@=', '\S\@<=__\|__\S\@='],
      \ ['\S\@<=\*\*\|\*\*\S\@=', '\S\@<=\*\*\|\*\*\S\@='],
      \ ]

" text: *italic* or _italic_
let s:markdown_syntax.dTypeface['italic'] = [
      \ ['\S\@<=\*\|\*\S\@=', '\S\@<=\*\|\*\S\@='],
      \ ['\S\@<=_\|_\S\@=', '\S\@<=_\|_\S\@='],
      \ ]

" text: no underline defined
let s:markdown_syntax.dTypeface['underline'] = []

" text: *_bold italic_* or _*italic bold*_ or ___bi___ or ***bi***
let s:markdown_syntax.dTypeface['bold_italic'] = [
      \ ['\S\@<=\*_\|\*_\S\@=', '\S\@<=_\*\|_\*\S\@='],
      \ ['\S\@<=_\*\|_\*\S\@=', '\S\@<=\*_\|\*_\S\@='],
      \ ['\S\@<=\*\*\*\|\*\*\*\S\@=', '\S\@<=\*\*\*\|\*\*\*\S\@='],
      \ ['\S\@<=___\|___\S\@=', '\S\@<=___\|___\S\@='],
      \ ]


" text: $ equation_inline $
let s:markdown_syntax.rxEqIn = '\$[^$`]\+\$'
let s:markdown_syntax.char_eqin = '\$'

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
