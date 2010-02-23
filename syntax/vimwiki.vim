" Vimwiki syntax file
" Author: Maxim Kim <habamax@gmail.com>
" Home: http://code.google.com/p/vimwiki/
" vim:tw=79:

" Quit if syntax file is already loaded
if version < 600
  syntax clear
elseif exists("b:current_syntax")
  finish
endif

"" use max highlighting - could be quite slow if there are too many wikifiles
if VimwikiGet('maxhi')
  " Every WikiWord is nonexistent
  if g:vimwiki_camel_case
    execute 'syntax match VimwikiNoExistsWord /\%(^\|[^!]\)\@<='.g:vimwiki_word1.'/'
  endif
  execute 'syntax match VimwikiNoExistsWord /'.g:vimwiki_word2.'/'
  execute 'syntax match VimwikiNoExistsWord /'.g:vimwiki_word3.'/'
  " till we find them in vimwiki's path
  call vimwiki#WikiHighlightWords()
else
  " A WikiWord (unqualifiedWikiName)
  execute 'syntax match VimwikiWord /\%(^\|[^!]\)\@<=\<'.g:vimwiki_word1.'\>/'
  " A [[bracketed wiki word]]
  execute 'syntax match VimwikiWord /'.g:vimwiki_word2.'/'
endif

execute 'syntax match VimwikiLink `'.g:vimwiki_rxWeblink.'`'

" Emoticons
syntax match VimwikiEmoticons /\%((.)\|:[()|$@]\|:-[DOPS()\]|$@]\|;)\|:'(\)/

let g:vimwiki_rxTodo = '\C\%(TODO:\|DONE:\|STARTED:\|FIXME:\|FIXED:\|XXX:\)'
execute 'syntax match VimwikiTodo /'. g:vimwiki_rxTodo .'/'

" Load concrete Wiki syntax
execute 'runtime! syntax/vimwiki_'.VimwikiGet('syntax').'.vim'

" Tables
" execute 'syntax match VimwikiTable /'.g:vimwiki_rxTable.'/'
syntax match VimwikiTableRow /\s*|.\+|\s*/
      \ transparent contains=VimwikiCellSeparator,VimwikiWord,
      \ VimwikiNoExistsWord,VimwikiEmoticons,VimwikiTodo,
      \ VimwikiBold,VimwikiItalic,VimwikiBoldItalic,VimwikiItalicBold,
      \ VimwikiDelText,VimwikiSuperScript,VimwikiSubScript,VimwikiCode
syntax match VimwikiCellSeparator
      \ /\%(|\)\|\%(-\@<=+\-\@=\)\|\%([|+]\@<=-\+\)/ contained

" List items
execute 'syntax match VimwikiList /'.g:vimwiki_rxListBullet.'/'
execute 'syntax match VimwikiList /'.g:vimwiki_rxListNumber.'/'
execute 'syntax match VimwikiList /'.g:vimwiki_rxListDefine.'/'

execute 'syntax match VimwikiBold /'.g:vimwiki_rxBold.'/'

execute 'syntax match VimwikiItalic /'.g:vimwiki_rxItalic.'/'

execute 'syntax match VimwikiBoldItalic /'.g:vimwiki_rxBoldItalic.'/'

execute 'syntax match VimwikiItalicBold /'.g:vimwiki_rxItalicBold.'/'

execute 'syntax match VimwikiDelText /'.g:vimwiki_rxDelText.'/'

execute 'syntax match VimwikiSuperScript /'.g:vimwiki_rxSuperScript.'/'

execute 'syntax match VimwikiSubScript /'.g:vimwiki_rxSubScript.'/'

execute 'syntax match VimwikiCode /'.g:vimwiki_rxCode.'/'

" <hr> horizontal rule
execute 'syntax match VimwikiHR /'.g:vimwiki_rxHR.'/'

execute 'syntax region VimwikiPre start=/'.g:vimwiki_rxPreStart.
      \ '/ end=/'.g:vimwiki_rxPreEnd.'/ contains=VimwikiComment'

" List item checkbox
syntax match VimwikiCheckBox /\[.\?\]/
if g:vimwiki_hl_cb_checked
  execute 'syntax match VimwikiCheckBoxDone /'.
        \ g:vimwiki_rxListBullet.'\s*\['.g:vimwiki_listsyms[4].'\].*$/'
  execute 'syntax match VimwikiCheckBoxDone /'.
        \ g:vimwiki_rxListNumber.'\s*\['.g:vimwiki_listsyms[4].'\].*$/'
endif

syntax region VimwikiComment start='<!--' end='-->'

if !vimwiki#hl_exists("VimwikiHeader1")
  execute 'syntax match VimwikiHeader /'.g:vimwiki_rxHeader.'/ contains=VimwikiTodo'
else
  " Header levels, 1-6
  execute 'syntax match VimwikiHeader1 /'.g:vimwiki_rxH1.'/ contains=VimwikiTodo'
  execute 'syntax match VimwikiHeader2 /'.g:vimwiki_rxH2.'/ contains=VimwikiTodo'
  execute 'syntax match VimwikiHeader3 /'.g:vimwiki_rxH3.'/ contains=VimwikiTodo'
  execute 'syntax match VimwikiHeader4 /'.g:vimwiki_rxH4.'/ contains=VimwikiTodo'
  execute 'syntax match VimwikiHeader5 /'.g:vimwiki_rxH5.'/ contains=VimwikiTodo'
  execute 'syntax match VimwikiHeader6 /'.g:vimwiki_rxH6.'/ contains=VimwikiTodo'
endif

" group names "{{{
if !vimwiki#hl_exists("VimwikiHeader1")
  hi def link VimwikiHeader Title
else
  hi def link VimwikiHeader1 Title
  hi def link VimwikiHeader2 Title
  hi def link VimwikiHeader3 Title
  hi def link VimwikiHeader4 Title
  hi def link VimwikiHeader5 Title
  hi def link VimwikiHeader6 Title
endif

hi def VimwikiBold term=bold cterm=bold gui=bold
hi def VimwikiItalic term=italic cterm=italic gui=italic
hi def VimwikiBoldItalic term=bold cterm=bold gui=bold,italic
hi def link VimwikiItalicBold VimwikiBoldItalic

hi def link VimwikiCode PreProc
hi def link VimwikiWord Underlined
hi def link VimwikiNoExistsWord Error

hi def link VimwikiPre SpecialComment
hi def link VimwikiLink Underlined
hi def link VimwikiList Function
hi def link VimwikiCheckBox VimwikiList
hi def link VimwikiCheckBoxDone Comment
hi def link VimwikiEmoticons Character
hi def link VimwikiDelText Constant
hi def link VimwikiSuperScript Number
hi def link VimwikiSubScript Number
hi def link VimwikiTodo Todo
hi def link VimwikiComment Comment

hi def link VimwikiCellSeparator SpecialKey
"}}}

let b:current_syntax="vimwiki"

" EMBEDDED syntax setup "{{{
let nested = VimwikiGet('nested_syntaxes')
if !empty(nested)
  for [hl_syntax, vim_syntax] in items(nested)
    call vimwiki#nested_syntax(vim_syntax,
          \ '^{{{\%(.*[[:blank:][:punct:]]\)\?'.
          \ hl_syntax.'\%([[:blank:][:punct:]].*\)\?',
          \ '^}}}', 'VimwikiPre')
  endfor
endif
"}}}
