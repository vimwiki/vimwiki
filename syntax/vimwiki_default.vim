" vim:tabstop=2:shiftwidth=2:expandtab:foldmethod=marker:textwidth=79
" Vimwiki syntax file
" Desc: Defines default syntax
" Home: https://github.com/vimwiki/vimwiki/

" text: $ equation_inline $
let g:vimwiki_rxEqIn = '\$[^$`]\+\$'
let g:vimwiki_char_eqin = '\$'

" text: *strong*
" let g:vimwiki_rxBold = '\*[^*]\+\*'
let g:vimwiki_rxBold = '\%(^\|\s\|[[:punct:]]\)\@<='.
      \'\*'.
      \'\%([^*`[:space:]][^*`]*[^*`[:space:]]\|[^*`[:space:]]\)'.
      \'\*'.
      \'\%([[:punct:]]\|\s\|$\)\@='
let g:vimwiki_char_bold = '*'

" text: _emphasis_
" let g:vimwiki_rxItalic = '_[^_]\+_'
let g:vimwiki_rxItalic = '\%(^\|\s\|[[:punct:]]\)\@<='.
      \'_'.
      \'\%([^_`[:space:]][^_`]*[^_`[:space:]]\|[^_`[:space:]]\)'.
      \'_'.
      \'\%([[:punct:]]\|\s\|$\)\@='
let g:vimwiki_char_italic = '_'

" text: *_bold italic_* or _*italic bold*_
let g:vimwiki_rxBoldItalic = '\%(^\|\s\|[[:punct:]]\)\@<='.
      \'\*_'.
      \'\%([^*_`[:space:]][^*_`]*[^*_`[:space:]]\|[^*_`[:space:]]\)'.
      \'_\*'.
      \'\%([[:punct:]]\|\s\|$\)\@='
let g:vimwiki_char_bolditalic = '\*_'

let g:vimwiki_rxItalicBold = '\%(^\|\s\|[[:punct:]]\)\@<='.
      \'_\*'.
      \'\%([^*_`[:space:]][^*_`]*[^*_`[:space:]]\|[^*_`[:space:]]\)'.
      \'\*_'.
      \'\%([[:punct:]]\|\s\|$\)\@='
let g:vimwiki_char_italicbold = '_\*'

" text: `code`
let g:vimwiki_rxCode = '`[^`]\+`'
let g:vimwiki_char_code = '`'

" text: ~~deleted text~~
let g:vimwiki_rxDelText = '\~\~[^~`]\+\~\~'
let g:vimwiki_char_deltext = '\~\~'

" text: ^superscript^
let g:vimwiki_rxSuperScript = '\^[^^`]\+\^'
let g:vimwiki_char_superscript = '^'

" text: ,,subscript,,
let g:vimwiki_rxSubScript = ',,[^,`]\+,,'
let g:vimwiki_char_subscript = ',,'

" generic headers
let g:vimwiki_rxH = '='
let g:vimwiki_symH = 1



" <hr>, horizontal rule
let g:vimwiki_rxHR = '^-----*$'

" Tables. Each line starts and ends with '|'; each cell is separated by '|'
let g:vimwiki_rxTableSep = '|'

" Lists
"1 means multiple bullets, like * ** ***
let g:vimwiki_bullet_types = { '-':0, '*':0, '#':0 }
let g:vimwiki_number_types = ['1)', '1.', 'i)', 'I)', 'a)', 'A)']
"this should contain at least one element
"it is used for i_<C-L><C-J> among other things
let g:vimwiki_list_markers = ['-', '1.', '*', 'I)', 'a)']
let g:vimwiki_rxListDefine = '::\(\s\|$\)'
call vimwiki#lst#setup_marker_infos()

let g:vimwiki_rxListItemWithoutCB = '^\s*\%(\('.g:vimwiki_rxListBullet.'\)\|\('.g:vimwiki_rxListNumber.'\)\)\s'
let g:vimwiki_rxListItem = g:vimwiki_rxListItemWithoutCB . '\+\%(\[\(['.g:vimwiki_listsyms.g:vimwiki_listsym_rejected.']\)\]\s\)\?'
let g:vimwiki_rxListItemAndChildren = '^\(\s*\)\%('.g:vimwiki_rxListBullet.'\|'.g:vimwiki_rxListNumber.'\)\s\+\['.g:vimwiki_listsyms_list[-1].'\]\s.*\%(\n\%(\1\s.*\|^$\)\)*'

" Preformatted text
let g:vimwiki_rxPreStart = '{{{'
let g:vimwiki_rxPreEnd = '}}}'

" Math block
let g:vimwiki_rxMathStart = '{{\$'
let g:vimwiki_rxMathEnd = '}}\$'

let g:vimwiki_rxComment = '^\s*%%.*$'
let g:vimwiki_rxTags = '\%(^\|\s\)\@<=:\%([^:''[:space:]]\+:\)\+\%(\s\|$\)\@='
" see also g:vimwiki_default_tag_search
