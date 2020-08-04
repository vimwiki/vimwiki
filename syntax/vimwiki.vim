" vim:tabstop=2:shiftwidth=2:expandtab:textwidth=99
" Vimwiki syntax file
" Home: https://github.com/vimwiki/vimwiki/


" Quit if syntax file is already loaded
if v:version < 600
  syntax clear
elseif exists('b:current_syntax')
  finish
endif


let s:current_syntax = vimwiki#vars#get_wikilocal('syntax')

<<<<<<< HEAD
" Get config: possibly concealed chars
let b:vimwiki_syntax_conceal = exists('+conceallevel') ? ' conceal' : ''
let b:vimwiki_syntax_concealends = has('conceal') ? ' concealends' : ''


" Populate all syntax vars
" Include syntax/vimwiki_markdown.vim as "side effect"
call vimwiki#vars#populate_syntax_vars(s:current_syntax)

let syntax_dic = g:vimwiki_syntax_variables[s:current_syntax]

" text: `code` or ``code`` only inline
" Note: `\%(^\|[^`]\)\@<=` means after a new line or a non `
let syntax_dic.dTypeface.code = [
      \ ['\%(^\|[^`]\)\@<=`\%($\|[^`]\)\@=',
      \  '\%(^\|[^`]\)\@<=`\%($\|[^`]\)\@='],
      \ ['\%(^\|[^`]\)\@<=``\%($\|[^`]\)\@=',
      \  '\%(^\|[^`]\)\@<=``\%($\|[^`]\)\@='],
      \ ]

" text: ~~deleted text~~
let syntax_dic.dTypeface.del = ([
      \ ['\~\~', '\~\~']])

" text: $ equation_inline $
" Match only one $
" ( ^ or not $) before $ and after: not $
let syntax_dic.dTypeface.eq = ([
      \ ['\%(^\|[^$]\)\@<=\$\%($\|[^$]\)\@=',
      \  '\%(^\|[^$]\)\@<=\$\%($\|[^$]\)\@=']])

" text: ^superscript^
let syntax_dic.dTypeface.sup = ([
      \ ['\^', '\^']])

" text: ,,subscript,,
let syntax_dic.dTypeface.sub = ([
      \ [',,', ',,']])

=======

call vimwiki#vars#populate_syntax_vars(s:current_syntax)

>>>>>>> Bump version number – release 2.5

" LINKS: highlighting is complicated due to "nonexistent" links feature
function! s:add_target_syntax_ON(target, type) abort
  let prefix0 = 'syntax match '.a:type.' `'
  let suffix0 = '` display contains=@NoSpell,VimwikiLinkRest,'.a:type.'Char'
  let prefix1 = 'syntax match '.a:type.'T `'
  let suffix1 = '` display contained'
  execute prefix0. a:target. suffix0
  execute prefix1. a:target. suffix1
endfunction


function! s:add_target_syntax_OFF(target) abort
  let prefix0 = 'syntax match VimwikiNoExistsLink `'
  let suffix0 = '` display contains=@NoSpell,VimwikiLinkRest,VimwikiLinkChar'
  let prefix1 = 'syntax match VimwikiNoExistsLinkT `'
  let suffix1 = '` display contained'
  execute prefix0. a:target. suffix0
  execute prefix1. a:target. suffix1
endfunction


function! s:highlight_existing_links() abort
  " Wikilink
  " Conditional highlighting that depends on the existence of a wiki file or
  "   directory is only available for *schemeless* wiki links
  " Links are set up upon BufEnter (see plugin/...)
  let safe_links = '\%('.vimwiki#base#file_pattern(
        \ vimwiki#vars#get_bufferlocal('existing_wikifiles')) . '\%(#[^|]*\)\?\|#[^|]*\)'
  " Wikilink Dirs set up upon BufEnter (see plugin/...)
  let safe_dirs = vimwiki#base#file_pattern(vimwiki#vars#get_bufferlocal('existing_wikidirs'))

  " match [[URL]]
  let target = vimwiki#base#apply_template(
        \ vimwiki#u#escape(vimwiki#vars#get_global('WikiLinkTemplate1')),
<<<<<<< HEAD
        \ safe_links, vimwiki#vars#get_global('rxWikiLinkDescr'), '', '')
=======
        \ safe_links, vimwiki#vars#get_global('rxWikiLinkDescr'), '')
>>>>>>> Bump version number – release 2.5
  call s:add_target_syntax_ON(target, 'VimwikiLink')
  " match [[URL|DESCRIPTION]]
  let target = vimwiki#base#apply_template(
        \ vimwiki#u#escape(vimwiki#vars#get_global('WikiLinkTemplate2')),
<<<<<<< HEAD
        \ safe_links, vimwiki#vars#get_global('rxWikiLinkDescr'), '', '')
=======
        \ safe_links, vimwiki#vars#get_global('rxWikiLinkDescr'), '')
>>>>>>> Bump version number – release 2.5
  call s:add_target_syntax_ON(target, 'VimwikiLink')

  " match {{URL}}
  let target = vimwiki#base#apply_template(
        \ vimwiki#u#escape(vimwiki#vars#get_global('WikiInclTemplate1')),
<<<<<<< HEAD
        \ safe_links, vimwiki#vars#get_global('rxWikiInclArgs'), '', '')
=======
        \ safe_links, vimwiki#vars#get_global('rxWikiInclArgs'), '')
>>>>>>> Bump version number – release 2.5
  call s:add_target_syntax_ON(target, 'VimwikiLink')
  " match {{URL|...}}
  let target = vimwiki#base#apply_template(
        \ vimwiki#u#escape(vimwiki#vars#get_global('WikiInclTemplate2')),
<<<<<<< HEAD
        \ safe_links, vimwiki#vars#get_global('rxWikiInclArgs'), '', '')
=======
        \ safe_links, vimwiki#vars#get_global('rxWikiInclArgs'), '')
>>>>>>> Bump version number – release 2.5
  call s:add_target_syntax_ON(target, 'VimwikiLink')
  " match [[DIRURL]]
  let target = vimwiki#base#apply_template(
        \ vimwiki#u#escape(vimwiki#vars#get_global('WikiLinkTemplate1')),
<<<<<<< HEAD
        \ safe_dirs, vimwiki#vars#get_global('rxWikiLinkDescr'), '', '')
=======
        \ safe_dirs, vimwiki#vars#get_global('rxWikiLinkDescr'), '')
>>>>>>> Bump version number – release 2.5
  call s:add_target_syntax_ON(target, 'VimwikiLink')
  " match [[DIRURL|DESCRIPTION]]
  let target = vimwiki#base#apply_template(
        \ vimwiki#u#escape(vimwiki#vars#get_global('WikiLinkTemplate2')),
<<<<<<< HEAD
        \ safe_dirs, vimwiki#vars#get_global('rxWikiLinkDescr'), '', '')
=======
        \ safe_dirs, vimwiki#vars#get_global('rxWikiLinkDescr'), '')
>>>>>>> Bump version number – release 2.5
  call s:add_target_syntax_ON(target, 'VimwikiLink')
endfunction


" use max highlighting - could be quite slow if there are too many wikifiles
if vimwiki#vars#get_wikilocal('maxhi')
  " WikiLink
  call s:add_target_syntax_OFF(vimwiki#vars#get_syntaxlocal('rxWikiLink'))
  " WikiIncl
  call s:add_target_syntax_OFF(vimwiki#vars#get_global('rxWikiIncl'))

  " Subsequently, links verified on vimwiki's path are highlighted as existing
  call s:highlight_existing_links()
else
  " Wikilink
  call s:add_target_syntax_ON(vimwiki#vars#get_syntaxlocal('rxWikiLink'), 'VimwikiLink')
  " WikiIncl
  call s:add_target_syntax_ON(vimwiki#vars#get_global('rxWikiIncl'), 'VimwikiLink')
endif


" Weblink
call s:add_target_syntax_ON(vimwiki#vars#get_syntaxlocal('rxWeblink'), 'VimwikiLink')


" WikiLink
" All remaining schemes are highlighted automatically
let s:rxSchemes = '\%('.
      \ vimwiki#vars#get_global('schemes') . '\|'.
      \ vimwiki#vars#get_global('web_schemes1').
      \ '\):'

" a) match [[nonwiki-scheme-URL]]
let s:target = vimwiki#base#apply_template(
      \ vimwiki#u#escape(vimwiki#vars#get_global('WikiLinkTemplate1')),
      \ s:rxSchemes.vimwiki#vars#get_global('rxWikiLinkUrl'),
<<<<<<< HEAD
      \ vimwiki#vars#get_global('rxWikiLinkDescr'), '', '')
=======
      \ vimwiki#vars#get_global('rxWikiLinkDescr'), '')
>>>>>>> Bump version number – release 2.5
call s:add_target_syntax_ON(s:target, 'VimwikiLink')
" b) match [[nonwiki-scheme-URL|DESCRIPTION]]
let s:target = vimwiki#base#apply_template(
      \ vimwiki#u#escape(vimwiki#vars#get_global('WikiLinkTemplate2')),
      \ s:rxSchemes.vimwiki#vars#get_global('rxWikiLinkUrl'),
<<<<<<< HEAD
      \ vimwiki#vars#get_global('rxWikiLinkDescr'), '', '')
=======
      \ vimwiki#vars#get_global('rxWikiLinkDescr'), '')
>>>>>>> Bump version number – release 2.5
call s:add_target_syntax_ON(s:target, 'VimwikiLink')

" a) match {{nonwiki-scheme-URL}}
let s:target = vimwiki#base#apply_template(
      \ vimwiki#u#escape(vimwiki#vars#get_global('WikiInclTemplate1')),
      \ s:rxSchemes.vimwiki#vars#get_global('rxWikiInclUrl'),
<<<<<<< HEAD
      \ vimwiki#vars#get_global('rxWikiInclArgs'), '', '')
=======
      \ vimwiki#vars#get_global('rxWikiInclArgs'), '')
>>>>>>> Bump version number – release 2.5
call s:add_target_syntax_ON(s:target, 'VimwikiLink')
" b) match {{nonwiki-scheme-URL}[{...}]}
let s:target = vimwiki#base#apply_template(
      \ vimwiki#u#escape(vimwiki#vars#get_global('WikiInclTemplate2')),
      \ s:rxSchemes.vimwiki#vars#get_global('rxWikiInclUrl'),
<<<<<<< HEAD
      \ vimwiki#vars#get_global('rxWikiInclArgs'), '', '')
=======
      \ vimwiki#vars#get_global('rxWikiInclArgs'), '')
>>>>>>> Bump version number – release 2.5
call s:add_target_syntax_ON(s:target, 'VimwikiLink')



" Header levels, 1-6
for s:i in range(1,6)
  execute 'syntax match VimwikiHeader'.s:i
      \ . ' /'.vimwiki#vars#get_syntaxlocal('rxH'.s:i, s:current_syntax).
      \ '/ contains=VimwikiTodo,VimwikiHeaderChar,VimwikiNoExistsLink,VimwikiCode,'.
      \ 'VimwikiLink,@Spell'
  execute 'syntax region VimwikiH'.s:i.'Folding start=/'.
        \ vimwiki#vars#get_syntaxlocal('rxH'.s:i.'_Start', s:current_syntax).'/ end=/'.
        \ vimwiki#vars#get_syntaxlocal('rxH'.s:i.'_End', s:current_syntax).
        \ '/me=s-1 transparent fold'
endfor

<<<<<<< HEAD
" SetExt header
" TODO mutualise SetExt Regexp
let setex_header1_re = '^\s\{0,3}[^>].*\n\s\{0,3}==\+$'
let setex_header2_re = '^\s\{0,3}[^>].*\n\s\{0,3}--\+$'
execute 'syntax match VimwikiHeader1'
    \ . ' /'. setex_header1_re . '/ '
    \ 'contains=VimwikiTodo,VimwikiHeaderChar,VimwikiNoExistsLink,VimwikiCode,'.
    \ 'VimwikiLink,@Spell'
execute 'syntax match VimwikiHeader2'
    \ . ' /'. setex_header2_re . '/ ' .
    \ 'contains=VimwikiTodo,VimwikiHeaderChar,VimwikiNoExistsLink,VimwikiCode,'.
    \ 'VimwikiLink,@Spell'
=======


" possibly concealed chars
let s:conceal = exists('+conceallevel') ? ' conceal' : ''

if vimwiki#vars#get_global('conceal_onechar_markers')
  execute 'syn match VimwikiEqInChar contained /'.
        \ vimwiki#vars#get_syntaxlocal('char_eqin').'/'.s:conceal
  execute 'syn match VimwikiBoldChar contained /'.
        \ vimwiki#vars#get_syntaxlocal('char_bold').'/'.s:conceal
  execute 'syn match VimwikiItalicChar contained /'.
        \ vimwiki#vars#get_syntaxlocal('char_italic').'/'.s:conceal
  execute 'syn match VimwikiBoldItalicChar contained /'.
        \ vimwiki#vars#get_syntaxlocal('char_bolditalic').'/'.s:conceal
  execute 'syn match VimwikiItalicBoldChar contained /'.
        \ vimwiki#vars#get_syntaxlocal('char_italicbold').'/'.s:conceal
  execute 'syn match VimwikiCodeChar contained /'.
        \ vimwiki#vars#get_syntaxlocal('char_code').'/'.s:conceal
  execute 'syn match VimwikiDelTextChar contained /'.
        \ vimwiki#vars#get_syntaxlocal('char_deltext').'/'.s:conceal
  execute 'syn match VimwikiSuperScript contained /'.
        \ vimwiki#vars#get_syntaxlocal('char_superscript').'/'.s:conceal
  execute 'syn match VimwikiSubScript contained /'.
        \ vimwiki#vars#get_syntaxlocal('char_subscript').'/'.s:conceal
endif
>>>>>>> Bump version number – release 2.5


let s:options = ' contained transparent contains=NONE'
if exists('+conceallevel')
<<<<<<< HEAD
  let s:options .= b:vimwiki_syntax_conceal
=======
  let s:options .= s:conceal
>>>>>>> Bump version number – release 2.5
endif

" A shortener for long URLs: LinkRest (a middle part of the URL) is concealed
" VimwikiLinkRest group is left undefined if link shortening is not desired
if exists('+conceallevel') && vimwiki#vars#get_global('url_maxsave') > 0
  execute 'syn match VimwikiLinkRest `\%(///\=[^/ \t]\+/\)\zs\S\+\ze'
        \.'\%([/#?]\w\|\S\{'.vimwiki#vars#get_global('url_maxsave').'}\)`'.' cchar=~'.s:options
endif

" VimwikiLinkChar is for syntax markers (and also URL when a description
" is present) and may be concealed

" conceal wikilinks
execute 'syn match VimwikiLinkChar /'.vimwiki#vars#get_global('rx_wikilink_prefix').'/'.s:options
execute 'syn match VimwikiLinkChar /'.vimwiki#vars#get_global('rx_wikilink_suffix').'/'.s:options
execute 'syn match VimwikiLinkChar /'.vimwiki#vars#get_global('rx_wikilink_prefix1').'/'.s:options
execute 'syn match VimwikiLinkChar /'.vimwiki#vars#get_global('rx_wikilink_suffix1').'/'.s:options

" conceal wikiincls
execute 'syn match VimwikiLinkChar /'.vimwiki#vars#get_global('rxWikiInclPrefix').'/'.s:options
execute 'syn match VimwikiLinkChar /'.vimwiki#vars#get_global('rxWikiInclSuffix').'/'.s:options
execute 'syn match VimwikiLinkChar /'.vimwiki#vars#get_global('rxWikiInclPrefix1').'/'.s:options
execute 'syn match VimwikiLinkChar /'.vimwiki#vars#get_global('rxWikiInclSuffix1').'/'.s:options


" non concealed chars
execute 'syn match VimwikiHeaderChar contained /\%(^\s*'.
      \ vimwiki#vars#get_syntaxlocal('rxH').'\+\)\|\%('.vimwiki#vars#get_syntaxlocal('rxH').
      \ '\+\s*$\)/'
<<<<<<< HEAD
=======
execute 'syn match VimwikiEqInCharT contained /'
      \ .vimwiki#vars#get_syntaxlocal('char_eqin').'/'
execute 'syn match VimwikiBoldCharT contained /'
      \ .vimwiki#vars#get_syntaxlocal('char_bold').'/'
execute 'syn match VimwikiItalicCharT contained /'
      \ .vimwiki#vars#get_syntaxlocal('char_italic').'/'
execute 'syn match VimwikiBoldItalicCharT contained /'
      \ .vimwiki#vars#get_syntaxlocal('char_bolditalic').'/'
execute 'syn match VimwikiItalicBoldCharT contained /'
      \ .vimwiki#vars#get_syntaxlocal('char_italicbold').'/'
execute 'syn match VimwikiCodeCharT contained /'
      \ .vimwiki#vars#get_syntaxlocal('char_code').'/'
execute 'syn match VimwikiDelTextCharT contained /'
      \ .vimwiki#vars#get_syntaxlocal('char_deltext').'/'
execute 'syn match VimwikiSuperScriptT contained /'
      \ .vimwiki#vars#get_syntaxlocal('char_superscript').'/'
execute 'syn match VimwikiSubScriptT contained /'
      \ .vimwiki#vars#get_syntaxlocal('char_subscript').'/'
>>>>>>> Bump version number – release 2.5


execute 'syntax match VimwikiTodo /'. vimwiki#vars#get_global('rxTodo') .'/'



" Tables
syntax match VimwikiTableRow /^\s*|.\+|\s*$/
      \ transparent contains=VimwikiCellSeparator,
                           \ VimwikiLinkT,
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
<<<<<<< HEAD

=======
>>>>>>> Bump version number – release 2.5
syntax match VimwikiCellSeparator
      \ /\%(|\)\|\%(-\@<=+\-\@=\)\|\%([|+]\@<=-\+\)/ contained


" Lists
<<<<<<< HEAD
execute 'syntax match VimwikiList /'.vimwiki#vars#get_wikilocal('rxListItemWithoutCB').'/'
execute 'syntax match VimwikiList /'.vimwiki#vars#get_syntaxlocal('rxListDefine').'/'
execute 'syntax match VimwikiListTodo /'.vimwiki#vars#get_wikilocal('rxListItem').'/'

if vimwiki#vars#get_global('hl_cb_checked') == 1
  execute 'syntax match VimwikiCheckBoxDone /'.vimwiki#vars#get_wikilocal('rxListItemWithoutCB')
        \ . '\s*\[['.vimwiki#vars#get_wikilocal('listsyms_list')[-1]
=======
execute 'syntax match VimwikiList /'.vimwiki#vars#get_syntaxlocal('rxListItemWithoutCB').'/'
execute 'syntax match VimwikiList /'.vimwiki#vars#get_syntaxlocal('rxListDefine').'/'
execute 'syntax match VimwikiListTodo /'.vimwiki#vars#get_syntaxlocal('rxListItem').'/'

if vimwiki#vars#get_global('hl_cb_checked') == 1
  execute 'syntax match VimwikiCheckBoxDone /'.vimwiki#vars#get_syntaxlocal('rxListItemWithoutCB')
        \ . '\s*\[['.vimwiki#vars#get_syntaxlocal('listsyms_list')[-1]
>>>>>>> Bump version number – release 2.5
        \ . vimwiki#vars#get_global('listsym_rejected')
        \ . ']\]\s.*$/ contains=VimwikiNoExistsLink,VimwikiLink,VimwikiWeblink1,VimwikiWikiLink1,@Spell'
elseif vimwiki#vars#get_global('hl_cb_checked') == 2
  execute 'syntax match VimwikiCheckBoxDone /'
<<<<<<< HEAD
        \ . vimwiki#vars#get_wikilocal('rxListItemAndChildren')
=======
        \ . vimwiki#vars#get_syntaxlocal('rxListItemAndChildren')
>>>>>>> Bump version number – release 2.5
        \ .'/ contains=VimwikiNoExistsLink,VimwikiLink,VimwikiWeblink1,VimwikiWikiLink1,@Spell'
endif


<<<<<<< HEAD
=======
execute 'syntax match VimwikiEqIn /'.vimwiki#vars#get_syntaxlocal('rxEqIn').
      \ '/ contains=VimwikiEqInChar,@NoSpell'
execute 'syntax match VimwikiEqInT /'.vimwiki#vars#get_syntaxlocal('rxEqIn').
      \ '/ contained contains=VimwikiEqInCharT,@NoSpell'

execute 'syntax match VimwikiBold /'.vimwiki#vars#get_syntaxlocal('rxBold').
      \ '/ contains=VimwikiBoldChar,@Spell'
execute 'syntax match VimwikiBoldT /'.vimwiki#vars#get_syntaxlocal('rxBold').
      \ '/ contained contains=VimwikiBoldCharT,@Spell'

execute 'syntax match VimwikiItalic /'.vimwiki#vars#get_syntaxlocal('rxItalic').
      \ '/ contains=VimwikiItalicChar,@Spell'
execute 'syntax match VimwikiItalicT /'.vimwiki#vars#get_syntaxlocal('rxItalic').
      \ '/ contained contains=VimwikiItalicCharT,@Spell'

execute 'syntax match VimwikiBoldItalic /'.vimwiki#vars#get_syntaxlocal('rxBoldItalic').
      \ '/ contains=VimwikiBoldItalicChar,VimwikiItalicBoldChar,@Spell'
execute 'syntax match VimwikiBoldItalicT /'.vimwiki#vars#get_syntaxlocal('rxBoldItalic').
      \ '/ contained contains=VimwikiBoldItalicChatT,VimwikiItalicBoldCharT,@Spell'

execute 'syntax match VimwikiItalicBold /'.vimwiki#vars#get_syntaxlocal('rxItalicBold').
      \ '/ contains=VimwikiBoldItalicChar,VimwikiItalicBoldChar,@Spell'
execute 'syntax match VimwikiItalicBoldT /'.vimwiki#vars#get_syntaxlocal('rxItalicBold').
      \ '/ contained contains=VimwikiBoldItalicCharT,VimsikiItalicBoldCharT,@Spell'

execute 'syntax match VimwikiDelText /'.vimwiki#vars#get_syntaxlocal('rxDelText').
      \ '/ contains=VimwikiDelTextChar,@Spell'
execute 'syntax match VimwikiDelTextT /'.vimwiki#vars#get_syntaxlocal('rxDelText').
      \ '/ contained contains=VimwikiDelTextCharT,@Spell'

execute 'syntax match VimwikiSuperScript /'.vimwiki#vars#get_syntaxlocal('rxSuperScript').
      \ '/ contains=VimwikiSuperScriptChar,@Spell'
execute 'syntax match VimwikiSuperScriptT /'.vimwiki#vars#get_syntaxlocal('rxSuperScript').
      \ '/ contained contains=VimwikiSuperScriptCharT,@Spell'

execute 'syntax match VimwikiSubScript /'.vimwiki#vars#get_syntaxlocal('rxSubScript').
      \ '/ contains=VimwikiSubScriptChar,@Spell'
execute 'syntax match VimwikiSubScriptT /'.vimwiki#vars#get_syntaxlocal('rxSubScript').
      \ '/ contained contains=VimwikiSubScriptCharT,@Spell'

execute 'syntax match VimwikiCode /'.vimwiki#vars#get_syntaxlocal('rxCode').
      \ '/ contains=VimwikiCodeChar,@NoSpell'
execute 'syntax match VimwikiCodeT /'.vimwiki#vars#get_syntaxlocal('rxCode').
      \ '/ contained contains=VimwikiCodeCharT'


>>>>>>> Bump version number – release 2.5
" <hr> horizontal rule
execute 'syntax match VimwikiHR /'.vimwiki#vars#get_syntaxlocal('rxHR').'/'

let concealpre = vimwiki#vars#get_global('conceal_pre') ? ' concealends' : ''
execute 'syntax region VimwikiPre matchgroup=VimwikiPreDelim start=/'.vimwiki#vars#get_syntaxlocal('rxPreStart').
      \ '/ end=/'.vimwiki#vars#get_syntaxlocal('rxPreEnd').'/ contains=@NoSpell'.concealpre

execute 'syntax region VimwikiMath start=/'.vimwiki#vars#get_syntaxlocal('rxMathStart').
      \ '/ end=/'.vimwiki#vars#get_syntaxlocal('rxMathEnd').'/ contains=@NoSpell'


" placeholders
syntax match VimwikiPlaceholder /^\s*%nohtml\s*$/
syntax match VimwikiPlaceholder
      \ /^\s*%title\ze\%(\s.*\)\?$/ nextgroup=VimwikiPlaceholderParam skipwhite
syntax match VimwikiPlaceholder
      \ /^\s*%date\ze\%(\s.*\)\?$/ nextgroup=VimwikiPlaceholderParam skipwhite
syntax match VimwikiPlaceholder
      \ /^\s*%template\ze\%(\s.*\)\?$/ nextgroup=VimwikiPlaceholderParam skipwhite
syntax match VimwikiPlaceholderParam /.*/ contained


" html tags
if vimwiki#vars#get_global('valid_html_tags') !=? ''
<<<<<<< HEAD
  " Include: Source html file here
  execute 'source ' . expand('<sfile>:h') . '/vimwiki_html.vim'
endif


=======
  let s:html_tags = join(split(vimwiki#vars#get_global('valid_html_tags'), '\s*,\s*'), '\|')
  exe 'syntax match VimwikiHTMLtag #\c</\?\%('.s:html_tags.'\)\%(\s\{-1}\S\{-}\)\{-}\s*/\?>#'
  execute 'syntax match VimwikiBold #\c<b>.\{-}</b># contains=VimwikiHTMLTag'
  execute 'syntax match VimwikiItalic #\c<i>.\{-}</i># contains=VimwikiHTMLTag'
  execute 'syntax match VimwikiUnderline #\c<u>.\{-}</u># contains=VimwikiHTMLTag'

  execute 'syntax match VimwikiComment /'.vimwiki#vars#get_syntaxlocal('rxComment').
        \ '/ contains=@Spell,VimwikiTodo'
endif

>>>>>>> Bump version number – release 2.5
" tags
execute 'syntax match VimwikiTag /'.vimwiki#vars#get_syntaxlocal('rxTags').'/'


<<<<<<< HEAD
=======

>>>>>>> Bump version number – release 2.5
" header groups highlighting
if vimwiki#vars#get_global('hl_headers') == 0
  " Strangely in default colorscheme Title group is not set to bold for cterm...
  if !exists('g:colors_name')
    hi Title cterm=bold
  endif
  for s:i in range(1,6)
    execute 'hi def link VimwikiHeader'.s:i.' Title'
  endfor
else
  for s:i in range(1,6)
    execute 'hi def VimwikiHeader'.s:i.' guibg=bg guifg='
          \ .vimwiki#vars#get_global('hcolor_guifg_'.&background)[s:i-1].' gui=bold ctermfg='
          \ .vimwiki#vars#get_global('hcolor_ctermfg_'.&background)[s:i-1].' term=bold cterm=bold'
  endfor
endif



<<<<<<< HEAD
" Highlight Typefaces -> u.vim
let s:typeface_dic = vimwiki#vars#get_syntaxlocal('dTypeface')
call vimwiki#u#hi_typeface(s:typeface_dic)

hi def link VimwikiMarkers Normal
hi def link VimwikiError Normal
=======
hi def link VimwikiMarkers Normal
>>>>>>> Bump version number – release 2.5

hi def link VimwikiEqIn Number
hi def link VimwikiEqInT VimwikiEqIn

<<<<<<< HEAD
" Typeface 1
=======
>>>>>>> Bump version number – release 2.5
hi def VimwikiBold term=bold cterm=bold gui=bold
hi def link VimwikiBoldT VimwikiBold

hi def VimwikiItalic term=italic cterm=italic gui=italic
hi def link VimwikiItalicT VimwikiItalic

<<<<<<< HEAD
hi def VimwikiUnderline term=underline cterm=underline gui=underline

" Typeface 2
" Bold > Italic > Underline
=======
>>>>>>> Bump version number – release 2.5
hi def VimwikiBoldItalic term=bold,italic cterm=bold,italic gui=bold,italic
hi def link VimwikiItalicBold VimwikiBoldItalic
hi def link VimwikiBoldItalicT VimwikiBoldItalic
hi def link VimwikiItalicBoldT VimwikiBoldItalic

<<<<<<< HEAD
hi def VimwikiBoldUnderline term=bold,underline cterm=bold,underline gui=bold,underline
hi def link VimwikiUnderlineBold VimwikiBoldUnderline

hi def VimwikiItalicUnderline term=italic,underline cterm=italic,underline gui=italic,underline
hi def link VimwikiUnderlineItalic VimwikiItalicUnderline

" Typeface 3
hi def VimwikiItalicUnderline term=italic,underline cterm=italic,underline gui=italic,underline
hi def link VimwikiBoldUnderlineItalic VimwikiBoldItalicUnderline
hi def link VimwikiItalicBoldUnderline VimwikiBoldItalicUnderline
hi def link VimwikiItalicUnderlineBold VimwikiBoldItalicUnderline
hi def link VimwikiUnderlineBoldItalic VimwikiBoldItalicUnderline
hi def link VimwikiUnderlineItalicBold VimwikiBoldItalicUnderline

" Typeface 2
hi def VimwikiBoldUnderlineItalic term=bold,italic,underline cterm=bold,italic,underline gui=bold,italic,underline

" Code
=======
hi def VimwikiUnderline gui=underline

>>>>>>> Bump version number – release 2.5
hi def link VimwikiCode PreProc
hi def link VimwikiCodeT VimwikiCode

hi def link VimwikiPre PreProc
hi def link VimwikiPreT VimwikiPre
hi def link VimwikiPreDelim VimwikiPre

hi def link VimwikiMath Number
hi def link VimwikiMathT VimwikiMath

hi def link VimwikiNoExistsLink SpellBad
hi def link VimwikiNoExistsLinkT VimwikiNoExistsLink

hi def link VimwikiLink Underlined
hi def link VimwikiLinkT VimwikiLink

hi def link VimwikiList Identifier
hi def link VimwikiListTodo VimwikiList
hi def link VimwikiCheckBoxDone Comment
hi def link VimwikiHR Identifier
hi def link VimwikiTag Keyword

<<<<<<< HEAD

" Deleted called strikethrough
" See $VIMRUTIME/syntax/html.vim
if v:version > 800 || v:version == 800 && has('patch1038')
  hi def VimwikiDelText term=strikethrough cterm=strikethrough gui=strikethrough
else
  hi def link VimwikiDelText Constant
endif
=======
hi def link VimwikiDelText Constant
>>>>>>> Bump version number – release 2.5
hi def link VimwikiDelTextT VimwikiDelText

hi def link VimwikiSuperScript Number
hi def link VimwikiSuperScriptT VimwikiSuperScript

hi def link VimwikiSubScript Number
hi def link VimwikiSubScriptT VimwikiSubScript

hi def link VimwikiTodo Todo
hi def link VimwikiComment Comment
<<<<<<< HEAD
hi def link VimwikiMultilineComment Comment
=======
>>>>>>> Bump version number – release 2.5

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

<<<<<<< HEAD
" TODO remove unsued due to region refactoring
=======
>>>>>>> Bump version number – release 2.5
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


" Load syntax-specific functionality
call vimwiki#u#reload_regexes_custom()


" FIXME it now does not make sense to pretend there is a single syntax "vimwiki"
let b:current_syntax='vimwiki'


<<<<<<< HEAD
" Include: Code: EMBEDDED syntax setup -> base.vim
=======
" EMBEDDED syntax setup
>>>>>>> Bump version number – release 2.5
let s:nested = vimwiki#vars#get_wikilocal('nested_syntaxes')
if vimwiki#vars#get_wikilocal('automatic_nested_syntaxes')
  let s:nested = extend(s:nested, vimwiki#base#detect_nested_syntax(), 'keep')
endif
if !empty(s:nested)
  for [s:hl_syntax, s:vim_syntax] in items(s:nested)
    call vimwiki#base#nested_syntax(s:vim_syntax,
          \ vimwiki#vars#get_syntaxlocal('rxPreStart').'\%(.*[[:blank:][:punct:]]\)\?'.
          \ s:hl_syntax.'\%([[:blank:][:punct:]].*\)\?',
          \ vimwiki#vars#get_syntaxlocal('rxPreEnd'), 'VimwikiPre')
  endfor
endif


" LaTeX
call vimwiki#base#nested_syntax('tex',
      \ vimwiki#vars#get_syntaxlocal('rxMathStart').'\%(.*[[:blank:][:punct:]]\)\?'.
      \ '\%([[:blank:][:punct:]].*\)\?',
      \ vimwiki#vars#get_syntaxlocal('rxMathEnd'), 'VimwikiMath')


syntax spell toplevel
<<<<<<< HEAD
=======

>>>>>>> Bump version number – release 2.5
