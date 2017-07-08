" vim:tabstop=2:shiftwidth=2:expandtab:foldmethod=marker:textwidth=79
" Vimwiki syntax file
" Home: https://github.com/vimwiki/vimwiki/

" Quit if syntax file is already loaded
if version < 600
  syntax clear
elseif exists("b:current_syntax")
  finish
endif

"TODO do nothing if ...? (?)
if VimwikiGet('maxhi')
  let b:existing_wikifiles =
        \ vimwiki#base#get_wikilinks(g:vimwiki_current_idx, 1)
  let b:existing_wikidirs  =
        \ vimwiki#base#get_wiki_directories(g:vimwiki_current_idx)
endif
  "let b:xxx = 1
  "TODO ? update wikilink syntax group here if really needed (?) for :e and such
  "if VimwikiGet('maxhi')
  " ...
  "endif

" LINKS: assume this is common to all syntaxes "{{{

" LINKS: WebLinks {{{
" match URL for common protocols;
" see http://en.wikipedia.org/wiki/URI_scheme  http://tools.ietf.org/html/rfc3986
let g:vimwiki_rxWebProtocols = ''.
      \ '\%('.
        \ '\%('.
          \ '\%('.join(split(g:vimwiki_web_schemes1, '\s*,\s*'), '\|').'\):'.
          \ '\%(//\)'.
        \ '\)'.
      \ '\|'.
        \ '\%('.join(split(g:vimwiki_web_schemes2, '\s*,\s*'), '\|').'\):'.
      \ '\)'
"
let g:vimwiki_rxWeblinkUrl = g:vimwiki_rxWebProtocols .
    \ '\S\{-1,}'. '\%(([^ \t()]*)\)\='
" }}}

" }}}

call vimwiki#u#reload_regexes()

" LINKS: setup of larger regexes {{{

" LINKS: setup wikilink regexps {{{
let s:wikilink_prefix = '[['
let s:wikilink_suffix = ']]'
let s:wikilink_separator = '|'
let s:rx_wikilink_prefix = vimwiki#u#escape(s:wikilink_prefix)
let s:rx_wikilink_suffix = vimwiki#u#escape(s:wikilink_suffix)
let s:rx_wikilink_separator = vimwiki#u#escape(s:wikilink_separator)

" templates for the creation of wiki links
" [[URL]]
let g:vimwiki_WikiLinkTemplate1 = s:wikilink_prefix . '__LinkUrl__'.
      \ s:wikilink_suffix
" [[URL|DESCRIPTION]]
let g:vimwiki_WikiLinkTemplate2 = s:wikilink_prefix . '__LinkUrl__'.
      \ s:wikilink_separator . '__LinkDescription__' . s:wikilink_suffix

" template for matching all wiki links with a given target file
let g:vimwiki_WikiLinkMatchUrlTemplate =
      \ s:rx_wikilink_prefix .
      \ '\zs__LinkUrl__\ze\%(#.*\)\?' .
      \ s:rx_wikilink_suffix .
      \ '\|' .
      \ s:rx_wikilink_prefix .
      \ '\zs__LinkUrl__\ze\%(#.*\)\?' .
      \ s:rx_wikilink_separator .
      \ '.*' .
      \ s:rx_wikilink_suffix

let s:valid_chars = '[^\\\]]'
let g:vimwiki_rxWikiLinkUrl = s:valid_chars.'\{-}'
let g:vimwiki_rxWikiLinkDescr = s:valid_chars.'\{-}'

" this regexp defines what can form a link when the user presses <CR> in the
" buffer (and not on a link) to create a link
" basically, it's Ascii alphanumeric characters plus #|./@-_~ plus all
" non-Ascii characters
let g:vimwiki_rxWord = '[^[:blank:]!"$%&''()*+,:;<=>?\[\]\\^`{}]\+'


" [[URL]], or [[URL|DESCRIPTION]]
" a) match [[URL|DESCRIPTION]]
let g:vimwiki_rxWikiLink = s:rx_wikilink_prefix.
      \ g:vimwiki_rxWikiLinkUrl.'\%('.s:rx_wikilink_separator.
      \ g:vimwiki_rxWikiLinkDescr.'\)\?'.s:rx_wikilink_suffix
" b) match URL within [[URL|DESCRIPTION]]
let g:vimwiki_rxWikiLinkMatchUrl = s:rx_wikilink_prefix.
      \ '\zs'. g:vimwiki_rxWikiLinkUrl.'\ze\%('. s:rx_wikilink_separator.
      \ g:vimwiki_rxWikiLinkDescr.'\)\?'.s:rx_wikilink_suffix
" c) match DESCRIPTION within [[URL|DESCRIPTION]]
let g:vimwiki_rxWikiLinkMatchDescr = s:rx_wikilink_prefix.
      \ g:vimwiki_rxWikiLinkUrl.s:rx_wikilink_separator.'\%('.
      \ '\zs'. g:vimwiki_rxWikiLinkDescr. '\ze\)\?'. s:rx_wikilink_suffix
" }}}

" LINKS: Syntax helper {{{
let s:rx_wikilink_prefix1 = s:rx_wikilink_prefix . g:vimwiki_rxWikiLinkUrl .
      \ s:rx_wikilink_separator
let s:rx_wikilink_suffix1 = s:rx_wikilink_suffix
" }}}


" LINKS: setup of wikiincl regexps {{{
let g:vimwiki_rxWikiInclPrefix = '{{'
let g:vimwiki_rxWikiInclSuffix = '}}'
let g:vimwiki_rxWikiInclSeparator = '|'
"
" '{{__LinkUrl__}}'
let g:vimwiki_WikiInclTemplate1 = g:vimwiki_rxWikiInclPrefix . '__LinkUrl__'. 
      \ g:vimwiki_rxWikiInclSuffix
" '{{__LinkUrl____LinkDescription__}}'
let g:vimwiki_WikiInclTemplate2 = g:vimwiki_rxWikiInclPrefix . '__LinkUrl__'. 
      \ '__LinkDescription__'.
      \ g:vimwiki_rxWikiInclSuffix


let s:valid_chars = '[^\\\}]'
let g:vimwiki_rxWikiInclUrl = s:valid_chars.'\{-}'
let g:vimwiki_rxWikiInclArg = s:valid_chars.'\{-}'
let g:vimwiki_rxWikiInclArgs = '\%('. g:vimwiki_rxWikiInclSeparator. g:vimwiki_rxWikiInclArg. '\)'.'\{-}'
"
"
" *. {{URL}[{...}]}  - i.e.  {{URL}}, {{URL|ARG1}}, {{URL|ARG1|ARG2}}, etc.
" *a) match {{URL}[{...}]}
let g:vimwiki_rxWikiIncl = g:vimwiki_rxWikiInclPrefix.
      \ g:vimwiki_rxWikiInclUrl. 
      \ g:vimwiki_rxWikiInclArgs. g:vimwiki_rxWikiInclSuffix
" *b) match URL within {{URL}[{...}]}
let g:vimwiki_rxWikiInclMatchUrl = g:vimwiki_rxWikiInclPrefix.
      \ '\zs'. g:vimwiki_rxWikiInclUrl. '\ze'.
      \ g:vimwiki_rxWikiInclArgs. g:vimwiki_rxWikiInclSuffix
" }}}

" LINKS: Syntax helper {{{
let g:vimwiki_rxWikiInclPrefix1 = g:vimwiki_rxWikiInclPrefix.
      \ g:vimwiki_rxWikiInclUrl.g:vimwiki_rxWikiInclSeparator
let g:vimwiki_rxWikiInclSuffix1 = g:vimwiki_rxWikiInclArgs.
      \ g:vimwiki_rxWikiInclSuffix
" }}}

" LINKS: Setup weblink regexps {{{
" 0. URL : free-standing links: keep URL UR(L) strip trailing punct: URL; URL) UR(L)) 
" let g:vimwiki_rxWeblink = '[\["(|]\@<!'. g:vimwiki_rxWeblinkUrl .
      " \ '\%([),:;.!?]\=\%([ \t]\|$\)\)\@='
" Maxim:
" Simplify free-standing links: URL starts with non(letter|digit)scheme till
" the whitespace.
" Stuart, could you check it with markdown templated links? [](http://...), as
" the last bracket is the part of URL now?
let g:vimwiki_rxWeblink = '\<'. g:vimwiki_rxWeblinkUrl . '\S*'
" 0a) match URL within URL
let g:vimwiki_rxWeblinkMatchUrl = g:vimwiki_rxWeblink
" 0b) match DESCRIPTION within URL
let g:vimwiki_rxWeblinkMatchDescr = ''
" }}}


" LINKS: Setup anylink regexps {{{
let g:vimwiki_rxAnyLink = g:vimwiki_rxWikiLink.'\|'. 
      \ g:vimwiki_rxWikiIncl.'\|'.g:vimwiki_rxWeblink
" }}}


" }}} end of Links

" LINKS: highlighting is complicated due to "nonexistent" links feature {{{
function! s:add_target_syntax_ON(target, type) " {{{
  let prefix0 = 'syntax match '.a:type.' `'
  let suffix0 = '` display contains=@NoSpell,VimwikiLinkRest,'.a:type.'Char'
  let prefix1 = 'syntax match '.a:type.'T `'
  let suffix1 = '` display contained'
  execute prefix0. a:target. suffix0
  execute prefix1. a:target. suffix1
endfunction "}}}

function! s:add_target_syntax_OFF(target) " {{{
  let prefix0 = 'syntax match VimwikiNoExistsLink `'
  let suffix0 = '` display contains=@NoSpell,VimwikiLinkRest,VimwikiLinkChar'
  let prefix1 = 'syntax match VimwikiNoExistsLinkT `'
  let suffix1 = '` display contained'
  execute prefix0. a:target. suffix0
  execute prefix1. a:target. suffix1
endfunction "}}}

function! s:highlight_existing_links() "{{{
  " Wikilink
  " Conditional highlighting that depends on the existence of a wiki file or
  "   directory is only available for *schemeless* wiki links
  " Links are set up upon BufEnter (see plugin/...)
  let safe_links = '\%('.vimwiki#base#file_pattern(b:existing_wikifiles) .
        \ '\%(#[^|]*\)\?\|#[^|]*\)'
  " Wikilink Dirs set up upon BufEnter (see plugin/...)
  let safe_dirs = vimwiki#base#file_pattern(b:existing_wikidirs)

  " match [[URL]]
  let target = vimwiki#base#apply_template(
        \ vimwiki#u#escape(g:vimwiki_WikiLinkTemplate1),
        \ safe_links, g:vimwiki_rxWikiLinkDescr, '')
  call s:add_target_syntax_ON(target, 'VimwikiLink')
  " match [[URL|DESCRIPTION]]
  let target = vimwiki#base#apply_template(
        \ vimwiki#u#escape(g:vimwiki_WikiLinkTemplate2),
        \ safe_links, g:vimwiki_rxWikiLinkDescr, '')
  call s:add_target_syntax_ON(target, 'VimwikiLink')

  " match {{URL}}
  let target = vimwiki#base#apply_template(
        \ vimwiki#u#escape(g:vimwiki_WikiInclTemplate1),
        \ safe_links, g:vimwiki_rxWikiInclArgs, '')
  call s:add_target_syntax_ON(target, 'VimwikiLink')
  " match {{URL|...}}
  let target = vimwiki#base#apply_template(
        \ vimwiki#u#escape(g:vimwiki_WikiInclTemplate2),
        \ safe_links, g:vimwiki_rxWikiInclArgs, '')
  call s:add_target_syntax_ON(target, 'VimwikiLink')
  " match [[DIRURL]]
  let target = vimwiki#base#apply_template(
        \ vimwiki#u#escape(g:vimwiki_WikiLinkTemplate1),
        \ safe_dirs, g:vimwiki_rxWikiLinkDescr, '')
  call s:add_target_syntax_ON(target, 'VimwikiLink')
  " match [[DIRURL|DESCRIPTION]]
  let target = vimwiki#base#apply_template(
        \ vimwiki#u#escape(g:vimwiki_WikiLinkTemplate2),
        \ safe_dirs, g:vimwiki_rxWikiLinkDescr, '')
  call s:add_target_syntax_ON(target, 'VimwikiLink')
endfunction "}}}


" use max highlighting - could be quite slow if there are too many wikifiles
if VimwikiGet('maxhi')
  " WikiLink
  call s:add_target_syntax_OFF(g:vimwiki_rxWikiLink)
  " WikiIncl
  call s:add_target_syntax_OFF(g:vimwiki_rxWikiIncl)

  " Subsequently, links verified on vimwiki's path are highlighted as existing
  call s:highlight_existing_links()
else
  " Wikilink
  call s:add_target_syntax_ON(g:vimwiki_rxWikiLink, 'VimwikiLink')
  " WikiIncl
  call s:add_target_syntax_ON(g:vimwiki_rxWikiIncl, 'VimwikiLink')
endif

" Weblink
call s:add_target_syntax_ON(g:vimwiki_rxWeblink, 'VimwikiLink')

" WikiLink
" All remaining schemes are highlighted automatically
let s:rxSchemes = '\%('.
      \ join(split(g:vimwiki_schemes, '\s*,\s*'), '\|').'\|'. 
      \ join(split(g:vimwiki_web_schemes1, '\s*,\s*'), '\|').
      \ '\):'

" a) match [[nonwiki-scheme-URL]]
let s:target = vimwiki#base#apply_template(
      \ vimwiki#u#escape(g:vimwiki_WikiLinkTemplate1),
      \ s:rxSchemes.g:vimwiki_rxWikiLinkUrl, g:vimwiki_rxWikiLinkDescr, '')
call s:add_target_syntax_ON(s:target, 'VimwikiLink')
" b) match [[nonwiki-scheme-URL|DESCRIPTION]]
let s:target = vimwiki#base#apply_template(
      \ vimwiki#u#escape(g:vimwiki_WikiLinkTemplate2),
      \ s:rxSchemes.g:vimwiki_rxWikiLinkUrl, g:vimwiki_rxWikiLinkDescr, '')
call s:add_target_syntax_ON(s:target, 'VimwikiLink')

" a) match {{nonwiki-scheme-URL}}
let s:target = vimwiki#base#apply_template(
      \ vimwiki#u#escape(g:vimwiki_WikiInclTemplate1),
      \ s:rxSchemes.g:vimwiki_rxWikiInclUrl, g:vimwiki_rxWikiInclArgs, '')
call s:add_target_syntax_ON(s:target, 'VimwikiLink')
" b) match {{nonwiki-scheme-URL}[{...}]}
let s:target = vimwiki#base#apply_template(
      \ vimwiki#u#escape(g:vimwiki_WikiInclTemplate2),
      \ s:rxSchemes.g:vimwiki_rxWikiInclUrl, g:vimwiki_rxWikiInclArgs, '')
call s:add_target_syntax_ON(s:target, 'VimwikiLink')

" }}}

" generic headers "{{{
if g:vimwiki_symH
  "" symmetric
  for s:i in range(1,6)
    let g:vimwiki_rxH{s:i}_Template = repeat(g:vimwiki_rxH, s:i).' __Header__ '.repeat(g:vimwiki_rxH, s:i)
    let g:vimwiki_rxH{s:i} = '^\s*'.g:vimwiki_rxH.'\{'.s:i.'}[^'.g:vimwiki_rxH.'].*[^'.g:vimwiki_rxH.']'.g:vimwiki_rxH.'\{'.s:i.'}\s*$'
    let g:vimwiki_rxH{s:i}_Start = '^\s*'.g:vimwiki_rxH.'\{'.s:i.'}[^'.g:vimwiki_rxH.'].*[^'.g:vimwiki_rxH.']'.g:vimwiki_rxH.'\{'.s:i.'}\s*$'
    let g:vimwiki_rxH{s:i}_End = '^\s*'.g:vimwiki_rxH.'\{1,'.s:i.'}[^'.g:vimwiki_rxH.'].*[^'.g:vimwiki_rxH.']'.g:vimwiki_rxH.'\{1,'.s:i.'}\s*$'
  endfor
  let g:vimwiki_rxHeader = '^\s*\('.g:vimwiki_rxH.'\{1,6}\)\zs[^'.g:vimwiki_rxH.'].*[^'.g:vimwiki_rxH.']\ze\1\s*$'
else
  " asymmetric
  for s:i in range(1,6)
    let g:vimwiki_rxH{s:i}_Template = repeat(g:vimwiki_rxH, s:i).' __Header__'
    let g:vimwiki_rxH{s:i} = '^\s*'.g:vimwiki_rxH.'\{'.s:i.'}[^'.g:vimwiki_rxH.'].*$'
    let g:vimwiki_rxH{s:i}_Start = '^\s*'.g:vimwiki_rxH.'\{'.s:i.'}[^'.g:vimwiki_rxH.'].*$'
    let g:vimwiki_rxH{s:i}_End = '^\s*'.g:vimwiki_rxH.'\{1,'.s:i.'}[^'.g:vimwiki_rxH.'].*$'
  endfor
  let g:vimwiki_rxHeader = '^\s*\('.g:vimwiki_rxH.'\{1,6}\)\zs[^'.g:vimwiki_rxH.'].*\ze$'
endif

" Header levels, 1-6
for s:i in range(1,6)
  execute 'syntax match VimwikiHeader'.s:i.' /'.g:vimwiki_rxH{s:i}.'/ contains=VimwikiTodo,VimwikiHeaderChar,VimwikiNoExistsLink,VimwikiCode,VimwikiLink,@Spell'
  execute 'syntax region VimwikiH'.s:i.'Folding start=/'.g:vimwiki_rxH{s:i}_Start.
        \ '/ end=/'.g:vimwiki_rxH{s:i}_End.'/me=s-1 transparent fold'
endfor


" }}}

let g:vimwiki_rxPreStart = '^\s*'.g:vimwiki_rxPreStart
let g:vimwiki_rxPreEnd = '^\s*'.g:vimwiki_rxPreEnd.'\s*$'

let g:vimwiki_rxMathStart = '^\s*'.g:vimwiki_rxMathStart
let g:vimwiki_rxMathEnd = '^\s*'.g:vimwiki_rxMathEnd.'\s*$'

" possibly concealed chars " {{{
let s:conceal = exists("+conceallevel") ? ' conceal' : ''

execute 'syn match VimwikiEqInChar contained /'.g:vimwiki_char_eqin.'/'.s:conceal
execute 'syn match VimwikiBoldChar contained /'.g:vimwiki_char_bold.'/'.s:conceal
execute 'syn match VimwikiItalicChar contained /'.g:vimwiki_char_italic.'/'.s:conceal
execute 'syn match VimwikiBoldItalicChar contained /'.g:vimwiki_char_bolditalic.'/'.s:conceal
execute 'syn match VimwikiItalicBoldChar contained /'.g:vimwiki_char_italicbold.'/'.s:conceal
execute 'syn match VimwikiCodeChar contained /'.g:vimwiki_char_code.'/'.s:conceal
execute 'syn match VimwikiDelTextChar contained /'.g:vimwiki_char_deltext.'/'.s:conceal
execute 'syn match VimwikiSuperScript contained /'.g:vimwiki_char_superscript.'/'.s:conceal
execute 'syn match VimwikiSubScript contained /'.g:vimwiki_char_subscript.'/'.s:conceal
" }}}

" concealed link parts " {{{

" define the conceal attribute for links only if Vim is new enough to handle it
" and the user has g:vimwiki_url_maxsave > 0

let s:options = ' contained transparent contains=NONE'
"
" A shortener for long URLs: LinkRest (a middle part of the URL) is concealed
" VimwikiLinkRest group is left undefined if link shortening is not desired
if exists("+conceallevel") && g:vimwiki_url_maxsave > 0
  let s:options .= s:conceal
  execute 'syn match VimwikiLinkRest `\%(///\=[^/ \t]\+/\)\zs\S\+\ze'
        \.'\%([/#?]\w\|\S\{'.g:vimwiki_url_maxsave.'}\)`'.' cchar=~'.s:options
endif

" VimwikiLinkChar is for syntax markers (and also URL when a description
" is present) and may be concealed

" conceal wikilinks
execute 'syn match VimwikiLinkChar /'.s:rx_wikilink_prefix.'/'.s:options
execute 'syn match VimwikiLinkChar /'.s:rx_wikilink_suffix.'/'.s:options
execute 'syn match VimwikiLinkChar /'.s:rx_wikilink_prefix1.'/'.s:options
execute 'syn match VimwikiLinkChar /'.s:rx_wikilink_suffix1.'/'.s:options

" conceal wikiincls
execute 'syn match VimwikiLinkChar /'.g:vimwiki_rxWikiInclPrefix.'/'.s:options
execute 'syn match VimwikiLinkChar /'.g:vimwiki_rxWikiInclSuffix.'/'.s:options
execute 'syn match VimwikiLinkChar /'.g:vimwiki_rxWikiInclPrefix1.'/'.s:options
execute 'syn match VimwikiLinkChar /'.g:vimwiki_rxWikiInclSuffix1.'/'.s:options
" }}}

" non concealed chars " {{{
execute 'syn match VimwikiHeaderChar contained /\%(^\s*'.g:vimwiki_rxH.'\+\)\|\%('.g:vimwiki_rxH.'\+\s*$\)/'
execute 'syn match VimwikiEqInCharT contained /'.g:vimwiki_char_eqin.'/'
execute 'syn match VimwikiBoldCharT contained /'.g:vimwiki_char_bold.'/'
execute 'syn match VimwikiItalicCharT contained /'.g:vimwiki_char_italic.'/'
execute 'syn match VimwikiBoldItalicCharT contained /'.g:vimwiki_char_bolditalic.'/'
execute 'syn match VimwikiItalicBoldCharT contained /'.g:vimwiki_char_italicbold.'/'
execute 'syn match VimwikiCodeCharT contained /'.g:vimwiki_char_code.'/'
execute 'syn match VimwikiDelTextCharT contained /'.g:vimwiki_char_deltext.'/'
execute 'syn match VimwikiSuperScriptT contained /'.g:vimwiki_char_superscript.'/'
execute 'syn match VimwikiSubScriptT contained /'.g:vimwiki_char_subscript.'/'

" Emoticons
"syntax match VimwikiEmoticons /\%((.)\|:[()|$@]\|:-[DOPS()\]|$@]\|;)\|:'(\)/

let g:vimwiki_rxTodo = '\C\%(TODO:\|DONE:\|STARTED:\|FIXME:\|FIXED:\|XXX:\)'
execute 'syntax match VimwikiTodo /'. g:vimwiki_rxTodo .'/'
" }}}

" main syntax groups {{{

" Tables
syntax match VimwikiTableRow /^\s*|.\+|\s*$/ 
      \ transparent contains=VimwikiCellSeparator,
                           \ VimwikiLinkT,
                           \ VimwikiNoExistsLinkT,
                           \ VimwikiEmoticons,
                           \ VimwikiTodo,
                           \ VimwikiBoldT,
                           \ VimwikiItalicT,
                           \ VimwikiBoldItalicT,
                           \ VimwikiItalicBoldT,
                           \ VimwikiDelTextT,
                           \ VimwikiSuperScriptT,
                           \ VimwikiSubScriptT,
                           \ VimwikiCodeT,
                           \ VimwikiEqInT,
                           \ @Spell
syntax match VimwikiCellSeparator 
      \ /\%(|\)\|\%(-\@<=+\-\@=\)\|\%([|+]\@<=-\+\)/ contained

" Lists
execute 'syntax match VimwikiList /'.g:vimwiki_rxListItemWithoutCB.'/'
execute 'syntax match VimwikiList /'.g:vimwiki_rxListDefine.'/'
execute 'syntax match VimwikiListTodo /'.g:vimwiki_rxListItem.'/'

if g:vimwiki_hl_cb_checked == 1
  execute 'syntax match VimwikiCheckBoxDone /'.g:vimwiki_rxListItemWithoutCB.'\s*\['.g:vimwiki_listsyms_list[-1].'\]\s.*$/ '.
        \ 'contains=VimwikiNoExistsLink,VimwikiLink,@Spell'
elseif g:vimwiki_hl_cb_checked == 2
  execute 'syntax match VimwikiCheckBoxDone /'.g:vimwiki_rxListItemAndChildren.'/ contains=VimwikiNoExistsLink,VimwikiLink,@Spell'
endif


execute 'syntax match VimwikiEqIn /'.g:vimwiki_rxEqIn.'/ contains=VimwikiEqInChar'
execute 'syntax match VimwikiEqInT /'.g:vimwiki_rxEqIn.'/ contained contains=VimwikiEqInCharT'

execute 'syntax match VimwikiBold /'.g:vimwiki_rxBold.'/ contains=VimwikiBoldChar,@Spell'
execute 'syntax match VimwikiBoldT /'.g:vimwiki_rxBold.'/ contained contains=VimwikiBoldCharT,@Spell'

execute 'syntax match VimwikiItalic /'.g:vimwiki_rxItalic.'/ contains=VimwikiItalicChar,@Spell'
execute 'syntax match VimwikiItalicT /'.g:vimwiki_rxItalic.'/ contained contains=VimwikiItalicCharT,@Spell'

execute 'syntax match VimwikiBoldItalic /'.g:vimwiki_rxBoldItalic.'/ contains=VimwikiBoldItalicChar,VimwikiItalicBoldChar,@Spell'
execute 'syntax match VimwikiBoldItalicT /'.g:vimwiki_rxBoldItalic.'/ contained contains=VimwikiBoldItalicChatT,VimwikiItalicBoldCharT,@Spell'

execute 'syntax match VimwikiItalicBold /'.g:vimwiki_rxItalicBold.'/ contains=VimwikiBoldItalicChar,VimwikiItalicBoldChar,@Spell'
execute 'syntax match VimwikiItalicBoldT /'.g:vimwiki_rxItalicBold.'/ contained contains=VimwikiBoldItalicCharT,VimsikiItalicBoldCharT,@Spell'

execute 'syntax match VimwikiDelText /'.g:vimwiki_rxDelText.'/ contains=VimwikiDelTextChar,@Spell'
execute 'syntax match VimwikiDelTextT /'.g:vimwiki_rxDelText.'/ contained contains=VimwikiDelTextChar,@Spell'

execute 'syntax match VimwikiSuperScript /'.g:vimwiki_rxSuperScript.'/ contains=VimwikiSuperScriptChar,@Spell'
execute 'syntax match VimwikiSuperScriptT /'.g:vimwiki_rxSuperScript.'/ contained contains=VimwikiSuperScriptCharT,@Spell'

execute 'syntax match VimwikiSubScript /'.g:vimwiki_rxSubScript.'/ contains=VimwikiSubScriptChar,@Spell'
execute 'syntax match VimwikiSubScriptT /'.g:vimwiki_rxSubScript.'/ contained contains=VimwikiSubScriptCharT,@Spell'

execute 'syntax match VimwikiCode /'.g:vimwiki_rxCode.'/ contains=VimwikiCodeChar'
execute 'syntax match VimwikiCodeT /'.g:vimwiki_rxCode.'/ contained contains=VimwikiCodeCharT'

" <hr> horizontal rule
execute 'syntax match VimwikiHR /'.g:vimwiki_rxHR.'/'

execute 'syntax region VimwikiPre start=/'.g:vimwiki_rxPreStart.
      \ '/ end=/'.g:vimwiki_rxPreEnd.'/ contains=@Spell'

execute 'syntax region VimwikiMath start=/'.g:vimwiki_rxMathStart.
      \ '/ end=/'.g:vimwiki_rxMathEnd.'/ contains=@Spell'


" placeholders
syntax match VimwikiPlaceholder /^\s*%nohtml\s*$/
syntax match VimwikiPlaceholder /^\s*%title\ze\%(\s.*\)\?$/ nextgroup=VimwikiPlaceholderParam skipwhite
syntax match VimwikiPlaceholder /^\s*%date\ze\%(\s.*\)\?$/ nextgroup=VimwikiPlaceholderParam skipwhite
syntax match VimwikiPlaceholder /^\s*%template\ze\%(\s.*\)\?$/ nextgroup=VimwikiPlaceholderParam skipwhite
syntax match VimwikiPlaceholderParam /.*/ contained

" html tags
if g:vimwiki_valid_html_tags != ''
  let s:html_tags = join(split(g:vimwiki_valid_html_tags, '\s*,\s*'), '\|')
  exe 'syntax match VimwikiHTMLtag #\c</\?\%('.s:html_tags.'\)\%(\s\{-1}\S\{-}\)\{-}\s*/\?>#'
  execute 'syntax match VimwikiBold #\c<b>.\{-}</b># contains=VimwikiHTMLTag'
  execute 'syntax match VimwikiItalic #\c<i>.\{-}</i># contains=VimwikiHTMLTag'
  execute 'syntax match VimwikiUnderline #\c<u>.\{-}</u># contains=VimwikiHTMLTag'

  execute 'syntax match VimwikiComment /'.g:vimwiki_rxComment.'/ contains=@Spell'
endif

" tags
execute 'syntax match VimwikiTag /'.g:vimwiki_rxTags.'/'

" }}}

" header groups highlighting "{{{

if g:vimwiki_hl_headers == 0
  " Strangely in default colorscheme Title group is not set to bold for cterm...
  if !exists("g:colors_name")
    hi Title cterm=bold
  endif
  for s:i in range(1,6)
    execute 'hi def link VimwikiHeader'.s:i.' Title'
  endfor
else
  " default colors when headers of different levels are highlighted differently 
  " not making it yet another option; needed by ColorScheme autocommand
  let g:vimwiki_hcolor_guifg_light = ['#aa5858','#507030','#1030a0','#103040','#505050','#636363']
  let g:vimwiki_hcolor_ctermfg_light = ['DarkRed','DarkGreen','DarkBlue','Black','Black','Black']
  let g:vimwiki_hcolor_guifg_dark = ['#e08090','#80e090','#6090e0','#c0c0f0','#e0e0f0','#f0f0f0']
  let g:vimwiki_hcolor_ctermfg_dark = ['Red','Green','Blue','White','White','White']
  for s:i in range(1,6)
    execute 'hi def VimwikiHeader'.s:i.' guibg=bg guifg='.g:vimwiki_hcolor_guifg_{&bg}[s:i-1].' gui=bold ctermfg='.g:vimwiki_hcolor_ctermfg_{&bg}[s:i-1].' term=bold cterm=bold'
  endfor
endif
"}}}

" syntax group highlighting "{{{ 

hi def link VimwikiMarkers Normal

hi def link VimwikiEqIn Number
hi def link VimwikiEqInT VimwikiEqIn

hi def VimwikiBold term=bold cterm=bold gui=bold
hi def link VimwikiBoldT VimwikiBold

hi def VimwikiItalic term=italic cterm=italic gui=italic
hi def link VimwikiItalicT VimwikiItalic

hi def VimwikiBoldItalic term=bold cterm=bold gui=bold,italic
hi def link VimwikiItalicBold VimwikiBoldItalic
hi def link VimwikiBoldItalicT VimwikiBoldItalic
hi def link VimwikiItalicBoldT VimwikiBoldItalic

hi def VimwikiUnderline gui=underline

hi def link VimwikiCode PreProc
hi def link VimwikiCodeT VimwikiCode

hi def link VimwikiPre PreProc
hi def link VimwikiPreT VimwikiPre

hi def link VimwikiMath Number
hi def link VimwikiMathT VimwikiMath

hi def link VimwikiNoExistsLink SpellBad
hi def link VimwikiNoExistsLinkT VimwikiNoExistsLink

hi def link VimwikiLink Underlined
hi def link VimwikiLinkT VimwikiLink

hi def link VimwikiList Identifier
hi def link VimwikiListTodo VimwikiList
hi def link VimwikiCheckBoxDone Comment
hi def link VimwikiEmoticons Character
hi def link VimwikiHR Identifier
hi def link VimwikiTag Keyword

hi def link VimwikiDelText Constant
hi def link VimwikiDelTextT VimwikiDelText

hi def link VimwikiSuperScript Number
hi def link VimwikiSuperScriptT VimwikiSuperScript

hi def link VimwikiSubScript Number
hi def link VimwikiSubScriptT VimwikiSubScript

hi def link VimwikiTodo Todo
hi def link VimwikiComment Comment

hi def link VimwikiPlaceholder SpecialKey
hi def link VimwikiPlaceholderParam String
hi def link VimwikiHTMLtag SpecialKey

hi def link VimwikiEqInChar VimwikiMarkers
hi def link VimwikiCellSeparator VimwikiMarkers
hi def link VimwikiBoldChar VimwikiMarkers
hi def link VimwikiItalicChar VimwikiMarkers
hi def link VimwikiBoldItalicChar VimwikiMarkers
hi def link VimwikiItalicBoldChar VimwikiMarkers
hi def link VimwikiDelTextChar VimwikiMarkers
hi def link VimwikiSuperScriptChar VimwikiMarkers
hi def link VimwikiSubScriptChar VimwikiMarkers
hi def link VimwikiCodeChar VimwikiMarkers
hi def link VimwikiHeaderChar VimwikiMarkers

hi def link VimwikiEqInCharT VimwikiMarkers
hi def link VimwikiBoldCharT VimwikiMarkers
hi def link VimwikiItalicCharT VimwikiMarkers
hi def link VimwikiBoldItalicCharT VimwikiMarkers
hi def link VimwikiItalicBoldCharT VimwikiMarkers
hi def link VimwikiDelTextCharT VimwikiMarkers
hi def link VimwikiSuperScriptCharT VimwikiMarkers
hi def link VimwikiSubScriptCharT VimwikiMarkers
hi def link VimwikiCodeCharT VimwikiMarkers
hi def link VimwikiHeaderCharT VimwikiMarkers
hi def link VimwikiLinkCharT VimwikiLinkT
hi def link VimwikiNoExistsLinkCharT VimwikiNoExistsLinkT
"}}}

" Load syntax-specific functionality
call vimwiki#u#reload_regexes_custom()

" FIXME it now does not make sense to pretend there is a single syntax "vimwiki"
let b:current_syntax="vimwiki"

" EMBEDDED syntax setup "{{{
let s:nested = VimwikiGet('nested_syntaxes')
if VimwikiGet('automatic_nested_syntaxes')
  let s:nested = extend(s:nested, vimwiki#base#detect_nested_syntax(), "keep")
endif
if !empty(s:nested)
  for [s:hl_syntax, s:vim_syntax] in items(s:nested)
    call vimwiki#base#nested_syntax(s:vim_syntax,
          \ g:vimwiki_rxPreStart.'\%(.*[[:blank:][:punct:]]\)\?'.
          \ s:hl_syntax.'\%([[:blank:][:punct:]].*\)\?',
          \ g:vimwiki_rxPreEnd, 'VimwikiPre')
  endfor
endif
" LaTeX
call vimwiki#base#nested_syntax('tex', 
      \ g:vimwiki_rxMathStart.'\%(.*[[:blank:][:punct:]]\)\?'.
      \ '\%([[:blank:][:punct:]].*\)\?',
      \ g:vimwiki_rxMathEnd, 'VimwikiMath')
"}}}


syntax spell toplevel
