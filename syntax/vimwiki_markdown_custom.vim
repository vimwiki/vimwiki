" vim:tabstop=2:shiftwidth=2:expandtab:foldmethod=marker:textwidth=79
" Vimwiki syntax file
" Desc: Special stuff for markdown syntax
" Home: https://github.com/vimwiki/vimwiki/

" LINKS: assume this is common to all syntaxes "{{{

" }}}

" -------------------------------------------------------------------------
" Load concrete Wiki syntax: sets regexes and templates for headers and links

" -------------------------------------------------------------------------



" LINKS: setup of larger regexes {{{




" *. ANY wikilink {{{
" *c) match DESCRIPTION within ANY wikilink
let g:vimwiki_rxWikiLinkMatchDescr = ''.
    \ g:vimwiki_rxWikiLink0MatchDescr.'\|'.
    \ g:vimwiki_rxWikiLink1MatchDescr
" }}}

" LINKS: Setup weblink0 regexps {{{
" 0. URL : free-standing links: keep URL UR(L) strip trailing punct: URL; URL) UR(L)) 
let g:vimwiki_rxWeblink0 = g:vimwiki_rxWeblink
" 0a) match URL within URL
let g:vimwiki_rxWeblinkMatchUrl0 = g:vimwiki_rxWeblinkMatchUrl
" 0b) match DESCRIPTION within URL
let g:vimwiki_rxWeblinkMatchDescr0 = g:vimwiki_rxWeblinkMatchDescr
" }}}

" LINKS: Setup weblink1 regexps {{{
let g:vimwiki_rxWeblink1Prefix = '['
let g:vimwiki_rxWeblink1Suffix = ')'
let g:vimwiki_rxWeblink1Separator = ']('
" [DESCRIPTION](URL)
let g:vimwiki_Weblink1Template = g:vimwiki_rxWeblink1Prefix . '__LinkDescription__'. 
      \ g:vimwiki_rxWeblink1Separator. '__LinkUrl__'.
      \ g:vimwiki_rxWeblink1Suffix

let s:valid_chars = '[^\\]'

let g:vimwiki_rxWeblink1Prefix = vimwiki#u#escape(g:vimwiki_rxWeblink1Prefix)
let g:vimwiki_rxWeblink1Suffix = vimwiki#u#escape(g:vimwiki_rxWeblink1Suffix)
let g:vimwiki_rxWeblink1Separator = vimwiki#u#escape(g:vimwiki_rxWeblink1Separator)
let g:vimwiki_rxWeblink1Url = s:valid_chars.'\{-}'
let g:vimwiki_rxWeblink1Descr = s:valid_chars.'\{-}'

"
" " 2012-02-04 TODO not starting with [[ or ][ ?  ... prefix = '[\[\]]\@<!\[' 
" 1. [DESCRIPTION](URL)
" 1a) match [DESCRIPTION](URL)
let g:vimwiki_rxWeblink1 = g:vimwiki_rxWeblink1Prefix.
      \ g:vimwiki_rxWeblink1Url.g:vimwiki_rxWeblink1Separator.
      \ g:vimwiki_rxWeblink1Descr.g:vimwiki_rxWeblink1Suffix
" 1b) match URL within [DESCRIPTION](URL)
let g:vimwiki_rxWeblink1MatchUrl = g:vimwiki_rxWeblink1Prefix.
      \ g:vimwiki_rxWeblink1Descr. g:vimwiki_rxWeblink1Separator.
      \ '\zs'.g:vimwiki_rxWeblink1Url.'\ze'. g:vimwiki_rxWeblink1Suffix
" 1c) match DESCRIPTION within [DESCRIPTION](URL)
let g:vimwiki_rxWeblink1MatchDescr = g:vimwiki_rxWeblink1Prefix.
      \ '\zs'.g:vimwiki_rxWeblink1Descr.'\ze'. g:vimwiki_rxWeblink1Separator.
      \ g:vimwiki_rxWeblink1Url. g:vimwiki_rxWeblink1Suffix
" }}}

" Syntax helper {{{
" TODO: image links too !!
" let g:vimwiki_rxWeblink1Prefix1 = '!\?'. g:vimwiki_rxWeblink1Prefix
let g:vimwiki_rxWeblink1Prefix1 = g:vimwiki_rxWeblink1Prefix
let g:vimwiki_rxWeblink1Suffix1 = g:vimwiki_rxWeblink1Separator.
      \ g:vimwiki_rxWeblink1Url.g:vimwiki_rxWeblink1Suffix
" }}}

" *. ANY weblink {{{
" *a) match ANY weblink
let g:vimwiki_rxWeblink = ''.
    \ g:vimwiki_rxWeblink1.'\|'.
    \ g:vimwiki_rxWeblink0
" *b) match URL within ANY weblink
let g:vimwiki_rxWeblinkMatchUrl = ''.
    \ g:vimwiki_rxWeblink1MatchUrl.'\|'.
    \ g:vimwiki_rxWeblinkMatchUrl0
" *c) match DESCRIPTION within ANY weblink
let g:vimwiki_rxWeblinkMatchDescr = ''.
    \ g:vimwiki_rxWeblink1MatchDescr.'\|'.
    \ g:vimwiki_rxWeblinkMatchDescr0
" }}}


" LINKS: Setup anylink regexps {{{
let g:vimwiki_rxAnyLink = g:vimwiki_rxWikiLink.'\|'. 
      \ g:vimwiki_rxWikiIncl.'\|'.g:vimwiki_rxWeblink
" }}}


" LINKS: setup wikilink1 reference link definitions {{{
let g:vimwiki_rxMkdRef = '\['.g:vimwiki_rxWikiLinkDescr.']:\%(\s\+\|\n\)'.
      \ g:vimwiki_rxWeblink0
let g:vimwiki_rxMkdRefMatchDescr = '\[\zs'.g:vimwiki_rxWikiLinkDescr.'\ze]:\%(\s\+\|\n\)'.
      \ g:vimwiki_rxWeblink0
let g:vimwiki_rxMkdRefMatchUrl = '\['.g:vimwiki_rxWikiLinkDescr.']:\%(\s\+\|\n\)\zs'.
      \ g:vimwiki_rxWeblink0.'\ze'
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

function! s:add_target_syntax_OFF(target, type) " {{{
  let prefix0 = 'syntax match VimwikiNoExistsLink `'
  let suffix0 = '` display contains=@NoSpell,VimwikiLinkRest,'.a:type.'Char'
  let prefix1 = 'syntax match VimwikiNoExistsLinkT `'
  let suffix1 = '` display contained'
  execute prefix0. a:target. suffix0
  execute prefix1. a:target. suffix1
endfunction "}}}

function! s:wrap_wikilink1_rx(target) "{{{
  return g:vimwiki_rxWikiLink1InvalidPrefix.a:target.
        \ g:vimwiki_rxWikiLink1InvalidSuffix
endfunction "}}}

function! s:existing_mkd_refs() "{{{
  call vimwiki#markdown_base#reset_mkd_refs()
  return keys(vimwiki#markdown_base#get_reflinks())
endfunction "}}}

function! s:highlight_existing_links() "{{{
  " Wikilink1
  " Conditional highlighting that depends on the existence of a wiki file or
  "   directory is only available for *schemeless* wiki links
  " Links are set up upon BufEnter (see plugin/...)
  let safe_links = '\%('.vimwiki#base#file_pattern(b:existing_wikifiles) .
        \ '\%(#[^|]*\)\?\|#[^|]*\)'
  " Wikilink1 Dirs set up upon BufEnter (see plugin/...)
  let safe_dirs = vimwiki#base#file_pattern(b:existing_wikidirs)
  " Ref links are cached
  let safe_reflinks = vimwiki#base#file_pattern(s:existing_mkd_refs())


  " match [URL][]
  let target = vimwiki#base#apply_template(
        \ vimwiki#u#escape(g:vimwiki_WikiLink1Template1),
        \ safe_links, g:vimwiki_rxWikiLink1Descr, '')
  call s:add_target_syntax_ON(s:wrap_wikilink1_rx(target), 'VimwikiWikiLink1')
  " match [DESCRIPTION][URL]
  let target = vimwiki#base#apply_template(
        \ vimwiki#u#escape(g:vimwiki_WikiLink1Template2),
        \ safe_links, g:vimwiki_rxWikiLink1Descr, '')
  call s:add_target_syntax_ON(s:wrap_wikilink1_rx(target), 'VimwikiWikiLink1')

  " match [DIRURL][]
  let target = vimwiki#base#apply_template(
        \ vimwiki#u#escape(g:vimwiki_WikiLink1Template1),
        \ safe_dirs, g:vimwiki_rxWikiLink1Descr, '')
  call s:add_target_syntax_ON(s:wrap_wikilink1_rx(target), 'VimwikiWikiLink1')
  " match [DESCRIPTION][DIRURL]
  let target = vimwiki#base#apply_template(
        \ vimwiki#u#escape(g:vimwiki_WikiLink1Template2),
        \ safe_dirs, g:vimwiki_rxWikiLink1Descr, '')
  call s:add_target_syntax_ON(s:wrap_wikilink1_rx(target), 'VimwikiWikiLink1')

  " match [MKDREF][]
  let target = vimwiki#base#apply_template(
        \ vimwiki#u#escape(g:vimwiki_WikiLink1Template1),
        \ safe_reflinks, g:vimwiki_rxWikiLink1Descr, '')
  call s:add_target_syntax_ON(s:wrap_wikilink1_rx(target), 'VimwikiWikiLink1')
  " match [DESCRIPTION][MKDREF]
  let target = vimwiki#base#apply_template(
        \ vimwiki#u#escape(g:vimwiki_WikiLink1Template2),
        \ safe_reflinks, g:vimwiki_rxWikiLink1Descr, '')
  call s:add_target_syntax_ON(s:wrap_wikilink1_rx(target), 'VimwikiWikiLink1')
endfunction "}}}


" use max highlighting - could be quite slow if there are too many wikifiles
if vimwiki#vars#get_wikilocal('maxhi')
  " WikiLink
  call s:add_target_syntax_OFF(g:vimwiki_rxWikiLink1, 'VimwikiWikiLink1')

  " Subsequently, links verified on vimwiki's path are highlighted as existing
  call s:highlight_existing_links()
else
  " Wikilink
  call s:add_target_syntax_ON(g:vimwiki_rxWikiLink1, 'VimwikiWikiLink1')
endif

" Weblink
call s:add_target_syntax_ON(g:vimwiki_rxWeblink1, 'VimwikiWeblink1')

" WikiLink
" All remaining schemes are highlighted automatically
let s:rxSchemes = '\%('.
      \ join(split(vimwiki#vars#get_global('schemes'), '\s*,\s*'), '\|').'\|'.
      \ join(split(vimwiki#vars#get_global('web_schemes1'), '\s*,\s*'), '\|').
      \ '\):'

" a) match [nonwiki-scheme-URL]
let s:target = vimwiki#base#apply_template(
      \ vimwiki#u#escape(g:vimwiki_WikiLink1Template1),
      \ s:rxSchemes.g:vimwiki_rxWikiLink1Url, g:vimwiki_rxWikiLink1Descr, '')
call s:add_target_syntax_ON(s:wrap_wikilink1_rx(s:target), 'VimwikiWikiLink1')
" b) match [DESCRIPTION][nonwiki-scheme-URL]
let s:target = vimwiki#base#apply_template(
      \ vimwiki#u#escape(g:vimwiki_WikiLink1Template2),
      \ s:rxSchemes.g:vimwiki_rxWikiLink1Url, g:vimwiki_rxWikiLink1Descr, '')
call s:add_target_syntax_ON(s:wrap_wikilink1_rx(s:target), 'VimwikiWikiLink1')
" }}}


" generic headers "{{{

" Header levels, 1-6
for s:i in range(1,6)
  execute 'syntax match VimwikiHeader'.s:i.' /'.g:vimwiki_rxH{s:i}.'/ contains=VimwikiTodo,VimwikiHeaderChar,VimwikiNoExistsLink,VimwikiCode,VimwikiLink,VimwikiWeblink1,VimwikiWikiLink1,@Spell'
endfor

" }}}

" concealed chars " {{{
if exists("+conceallevel")
  syntax conceal on
endif

syntax spell toplevel

" VimwikiWikiLink1Char is for syntax markers (and also URL when a description
" is present) and may be concealed
let s:options = ' contained transparent contains=NONE'
" conceal wikilink1
execute 'syn match VimwikiWikiLink1Char /'.s:rx_wikilink_md_prefix.'/'.s:options
execute 'syn match VimwikiWikiLink1Char /'.s:rx_wikilink_md_suffix.'/'.s:options
execute 'syn match VimwikiWikiLink1Char /'.vimwiki#vars#get_syntaxlocal('rxWikiLink1Prefix1').'/'.s:options
execute 'syn match VimwikiWikiLink1Char /'.vimwiki#vars#get_syntaxlocal('rxWikiLink1Suffix1').'/'.s:options

" conceal weblink1
execute 'syn match VimwikiWeblink1Char "'.vimwiki#vars#get_syntaxlocal('rxWeblink1Prefix1').'"'.s:options
execute 'syn match VimwikiWeblink1Char "'.vimwiki#vars#get_syntaxlocal('rxWeblink1Suffix1').'"'.s:options

if exists("+conceallevel")
  syntax conceal off
endif
" }}}

" non concealed chars " {{{
" }}}

" main syntax groups {{{

" Tables
syntax match VimwikiTableRow /^\s*|.\+|\s*$/ 
      \ transparent contains=VimwikiCellSeparator,
                           \ VimwikiLinkT,
                           \ VimwikiWeblink1T,
                           \ VimwikiWikiLink1T,
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

" }}}

" header groups highlighting "{{{
"}}}


" syntax group highlighting "{{{ 
hi def link VimwikiWeblink1 VimwikiLink
hi def link VimwikiWeblink1T VimwikiLink

hi def link VimwikiWikiLink1 VimwikiLink
hi def link VimwikiWikiLink1T VimwikiLink
"}}}



" EMBEDDED syntax setup "{{{
"}}}
"
