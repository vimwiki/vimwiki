" vim:tabstop=2:shiftwidth=2:expandtab:textwidth=99
" Vimwiki syntax file
" Description: Defines markdown custom syntax
" Home: https://github.com/vimwiki/vimwiki/


function! s:add_target_syntax_ON(target, type) abort
  let prefix0 = 'syntax match '.a:type.' `'
  let suffix0 = '` display contains=@NoSpell,VimwikiLinkRest,'.a:type.'Char'
  let prefix1 = 'syntax match '.a:type.'T `'
  let suffix1 = '` display contained'
  execute prefix0. a:target. suffix0
  execute prefix1. a:target. suffix1
endfunction


function! s:add_target_syntax_OFF(target, type) abort
  let prefix0 = 'syntax match VimwikiNoExistsLink `'
  let suffix0 = '` display contains=@NoSpell,VimwikiLinkRest,'.a:type.'Char'
  let prefix1 = 'syntax match VimwikiNoExistsLinkT `'
  let suffix1 = '` display contained'
  execute prefix0. a:target. suffix0
  execute prefix1. a:target. suffix1
endfunction


function! s:wrap_wikilink1_rx(target) abort
  return vimwiki#vars#get_syntaxlocal('rxWikiLink1InvalidPrefix') . a:target.
        \ vimwiki#vars#get_syntaxlocal('rxWikiLink1InvalidSuffix')
endfunction


function! s:existing_mkd_refs() abort
  return keys(vimwiki#markdown_base#scan_reflinks())
endfunction


function! s:highlight_existing_links() abort
  " Wikilink1
  " Conditional highlighting that depends on the existence of a wiki file or
  "   directory is only available for *schemeless* wiki links
  " Links are set up upon BufEnter (see plugin/...)
  let safe_links = '\%('.
        \ vimwiki#base#file_pattern(vimwiki#vars#get_bufferlocal('existing_wikifiles')) .
        \ '\%(#[^|]*\)\?\|#[^|]*\)'
  " Wikilink1 Dirs set up upon BufEnter (see plugin/...)
  let safe_dirs = vimwiki#base#file_pattern(vimwiki#vars#get_bufferlocal('existing_wikidirs'))
  " Ref links are cached
  let safe_reflinks = vimwiki#base#file_pattern(s:existing_mkd_refs())


  " match [URL][]
  let target = vimwiki#base#apply_template(
        \ vimwiki#u#escape(vimwiki#vars#get_syntaxlocal('WikiLink1Template1')),
        \ safe_links, vimwiki#vars#get_syntaxlocal('rxWikiLink1Descr'), '')
  call s:add_target_syntax_ON(s:wrap_wikilink1_rx(target), 'VimwikiWikiLink1')
  " match [DESCRIPTION][URL]
  let target = vimwiki#base#apply_template(
        \ vimwiki#u#escape(vimwiki#vars#get_syntaxlocal('WikiLink1Template2')),
        \ safe_links, vimwiki#vars#get_syntaxlocal('rxWikiLink1Descr'), '')
  call s:add_target_syntax_ON(s:wrap_wikilink1_rx(target), 'VimwikiWikiLink1')

  " match [DIRURL][]
  let target = vimwiki#base#apply_template(
        \ vimwiki#u#escape(vimwiki#vars#get_syntaxlocal('WikiLink1Template1')),
        \ safe_dirs, vimwiki#vars#get_syntaxlocal('rxWikiLink1Descr'), '')
  call s:add_target_syntax_ON(s:wrap_wikilink1_rx(target), 'VimwikiWikiLink1')
  " match [DESCRIPTION][DIRURL]
  let target = vimwiki#base#apply_template(
        \ vimwiki#u#escape(vimwiki#vars#get_syntaxlocal('WikiLink1Template2')),
        \ safe_dirs, vimwiki#vars#get_syntaxlocal('rxWikiLink1Descr'), '')
  call s:add_target_syntax_ON(s:wrap_wikilink1_rx(target), 'VimwikiWikiLink1')

  " match [MKDREF][]
  let target = vimwiki#base#apply_template(
        \ vimwiki#u#escape(vimwiki#vars#get_syntaxlocal('WikiLink1Template1')),
        \ safe_reflinks, vimwiki#vars#get_syntaxlocal('rxWikiLink1Descr'), '')
  call s:add_target_syntax_ON(s:wrap_wikilink1_rx(target), 'VimwikiWikiLink1')
  " match [DESCRIPTION][MKDREF]
  let target = vimwiki#base#apply_template(
        \ vimwiki#u#escape(vimwiki#vars#get_syntaxlocal('WikiLink1Template2')),
        \ safe_reflinks, vimwiki#vars#get_syntaxlocal('rxWikiLink1Descr'), '')
  call s:add_target_syntax_ON(s:wrap_wikilink1_rx(target), 'VimwikiWikiLink1')
endfunction


" use max highlighting - could be quite slow if there are too many wikifiles
if vimwiki#vars#get_wikilocal('maxhi')
  " WikiLink
  call s:add_target_syntax_OFF(vimwiki#vars#get_syntaxlocal('rxWikiLink1'), 'VimwikiWikiLink1')

  " Subsequently, links verified on vimwiki's path are highlighted as existing
  call s:highlight_existing_links()
else
  " Wikilink
  call s:add_target_syntax_ON(vimwiki#vars#get_syntaxlocal('rxWikiLink1'), 'VimwikiWikiLink1')
endif


" Weblink
call s:add_target_syntax_ON(vimwiki#vars#get_syntaxlocal('rxWeblink1'), 'VimwikiWeblink1')
call s:add_target_syntax_ON(vimwiki#vars#get_syntaxlocal('rxImage'), 'VimwikiImage')


" WikiLink
" All remaining schemes are highlighted automatically
let s:rxSchemes = '\%('.
      \ vimwiki#vars#get_global('schemes') . '\|'.
      \ vimwiki#vars#get_global('web_schemes1').
      \ '\):'

" a) match [nonwiki-scheme-URL]
let s:target = vimwiki#base#apply_template(
      \ vimwiki#u#escape(vimwiki#vars#get_syntaxlocal('WikiLink1Template1')),
      \ s:rxSchemes . vimwiki#vars#get_syntaxlocal('rxWikiLink1Url'),
      \ vimwiki#vars#get_syntaxlocal('rxWikiLink1Descr'), '')
call s:add_target_syntax_ON(s:wrap_wikilink1_rx(s:target), 'VimwikiWikiLink1')
" b) match [DESCRIPTION][nonwiki-scheme-URL]
let s:target = vimwiki#base#apply_template(
      \ vimwiki#u#escape(vimwiki#vars#get_syntaxlocal('WikiLink1Template2')),
      \ s:rxSchemes . vimwiki#vars#get_syntaxlocal('rxWikiLink1Url'),
      \ vimwiki#vars#get_syntaxlocal('rxWikiLink1Descr'), '')
call s:add_target_syntax_ON(s:wrap_wikilink1_rx(s:target), 'VimwikiWikiLink1')



" Header levels, 1-6
for s:i in range(1,6)
  execute 'syntax match VimwikiHeader'.s:i.' /'.vimwiki#vars#get_syntaxlocal('rxH'.s:i).
              \ '/ contains=VimwikiTodo,VimwikiHeaderChar,VimwikiNoExistsLink,VimwikiCode,'.
              \ 'VimwikiLink,VimwikiWeblink1,VimwikiWikiLink1,@Spell'
endfor



" concealed chars
if exists('+conceallevel')
  syntax conceal on
endif

syntax spell toplevel

" VimwikiWikiLink1Char is for syntax markers (and also URL when a description
" is present) and may be concealed
let s:options = ' contained transparent contains=NONE'
" conceal wikilink1
execute 'syn match VimwikiWikiLink1Char /'.
            \ vimwiki#vars#get_syntaxlocal('rx_wikilink_md_prefix').'/'.s:options
execute 'syn match VimwikiWikiLink1Char /'.
            \ vimwiki#vars#get_syntaxlocal('rx_wikilink_md_suffix').'/'.s:options
execute 'syn match VimwikiWikiLink1Char /'.
            \ vimwiki#vars#get_syntaxlocal('rxWikiLink1Prefix1').'/'.s:options
execute 'syn match VimwikiWikiLink1Char /'.
            \ vimwiki#vars#get_syntaxlocal('rxWikiLink1Suffix1').'/'.s:options

" conceal weblink1
execute 'syn match VimwikiWeblink1Char "'.
            \ vimwiki#vars#get_syntaxlocal('rxWeblink1Prefix1').'"'.s:options
execute 'syn match VimwikiWeblink1Char "'.
            \ vimwiki#vars#get_syntaxlocal('rxWeblink1Suffix1').'"'.s:options
"image
execute 'syn match VimwikiImageChar "!"'.s:options
execute 'syn match VimwikiImageChar "'.
            \ vimwiki#vars#get_syntaxlocal('rxWeblink1Prefix1').'"'.s:options
execute 'syn match VimwikiImageChar "'.
            \ vimwiki#vars#get_syntaxlocal('rxWeblink1Suffix1').'"'.s:options

if exists('+conceallevel')
  syntax conceal off
endif



" Tables
syntax match VimwikiTableRow /^\s*|.\+|\s*$/
      \ transparent contains=VimwikiCellSeparator,
                           \ VimwikiLinkT,
                           \ VimwikiWeblink1T,
                           \ VimwikiWikiLink1T,
                           \ VimwikiNoExistsLinkT,
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

" TODO fix behavior within lists https://github.github.com/gfm/#list-items
" indented code blocks https://github.github.com/gfm/#indented-code-blocks
" execute 'syntax match VimwikiIndentedCodeBlock /' . vimwiki#vars#get_syntaxlocal('rxIndentedCodeBlock') . '/'
" hi def link VimwikiIndentedCodeBlock VimwikiPre

" syntax group highlighting
hi def link VimwikiImage VimwikiLink
hi def link VimwikiImageT VimwikiLink
hi def link VimwikiWeblink1 VimwikiLink
hi def link VimwikiWeblink1T VimwikiLink

hi def link VimwikiWikiLink1 VimwikiLink
hi def link VimwikiWikiLink1T VimwikiLink

