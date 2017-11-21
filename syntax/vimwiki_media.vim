" vim:tabstop=2:shiftwidth=2:expandtab:foldmethod=marker:textwidth=79
" Vimwiki syntax file
" Desc: Defines mediaWiki syntax
" Home: https://github.com/vimwiki/vimwiki/

" text: $ equation_inline $
let g:vimwiki_rxEqIn = '\$[^$`]\+\$'
let g:vimwiki_char_eqin = '\$'

" text: '''strong'''
let g:vimwiki_rxBold = "'''[^']\\+'''"
let g:vimwiki_char_bold = "'''"

" text: ''emphasis''
let g:vimwiki_rxItalic = "''[^']\\+''"
let g:vimwiki_char_italic = "''"

" text: '''''strong italic'''''
let g:vimwiki_rxBoldItalic = "'''''[^']\\+'''''"
let g:vimwiki_rxItalicBold = g:vimwiki_rxBoldItalic
let g:vimwiki_char_bolditalic = "'''''"
let g:vimwiki_char_italicbold = g:vimwiki_char_bolditalic

" text: `code`
let g:vimwiki_rxCode = '`[^`]\+`'
let g:vimwiki_char_code = '`'

" text: ~~deleted text~~
let g:vimwiki_rxDelText = '\~\~[^~]\+\~\~'
let g:vimwiki_char_deltext = '\~\~'

" text: ^superscript^
let g:vimwiki_rxSuperScript = '\^[^^]\+\^'
let g:vimwiki_char_superscript = '^'

" text: ,,subscript,,
let g:vimwiki_rxSubScript = ',,[^,]\+,,'
let g:vimwiki_char_subscript = ',,'

" generic headers
let g:vimwiki_rxH = '='
let g:vimwiki_symH = 1



" <hr>, horizontal rule
let g:vimwiki_rxHR = '^-----*$'

" Tables. Each line starts and ends with '|'; each cell is separated by '|'
let g:vimwiki_rxTableSep = '|'

" Lists
let g:vimwiki_bullet_types = { '*':1, '#':1 }
let g:vimwiki_number_types = []
let g:vimwiki_list_markers = ['*', '#']
let g:vimwiki_rxListDefine = '^\%(;\|:\)\s'
call vimwiki#lst#setup_marker_infos()

let g:vimwiki_rxListItemWithoutCB = '^\s*\%(\('.g:vimwiki_rxListBullet.'\)\|\('.g:vimwiki_rxListNumber.'\)\)\s'
let g:vimwiki_rxListItem = g:vimwiki_rxListItemWithoutCB . '\+\%(\[\(['.g:vimwiki_listsyms.g:vimwiki_listsym_rejected.']\)\]\s\)\?'
let g:vimwiki_rxListItemAndChildren = '^\('.g:vimwiki_rxListBullet.'\)\s\+\['.g:vimwiki_listsyms_list[-1].'\]\s.*\%(\n\%(\1\%('.g:vimwiki_rxListBullet.'\).*\|^$\|\s.*\)\)*'

" Preformatted text
let g:vimwiki_rxPreStart = '<pre>'
let g:vimwiki_rxPreEnd = '<\/pre>'

" Math block
let g:vimwiki_rxMathStart = '{{\$'
let g:vimwiki_rxMathEnd = '}}\$'

let g:vimwiki_rxComment = '^\s*%%.*$'
let g:vimwiki_rxTags = '\%(^\|\s\)\@<=:\%([^:[:space:]]\+:\)\+\%(\s\|$\)\@='
