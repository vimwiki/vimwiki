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

" Get config: possibly concealed chars
let b:vimwiki_syntax_conceal = exists('+conceallevel') ? ' conceal' : ''
let b:vimwiki_syntax_concealends = has('conceal') ? ' concealends' : ''


" Populate all syntax vars
" Include syntax/vimwiki_markdown.vim as "side effect"
call vimwiki#vars#populate_syntax_vars(s:current_syntax)
let syntax_dic = g:vimwiki_syntaxlocal_vars[s:current_syntax]

" Declare nesting capabilities
" -- to be embedded in standard: bold, italic, underline

" text: `code` or ``code`` only inline
" Note: `\%(^\|[^`]\)\@<=` means after a new line or a non `

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
        \ safe_links, vimwiki#vars#get_global('rxWikiLinkDescr'), '', '')
  call s:add_target_syntax_ON(target, 'VimwikiLink')
  " match [[URL|DESCRIPTION]]
  let target = vimwiki#base#apply_template(
        \ vimwiki#u#escape(vimwiki#vars#get_global('WikiLinkTemplate2')),
        \ safe_links, vimwiki#vars#get_global('rxWikiLinkDescr'), '', '')
  call s:add_target_syntax_ON(target, 'VimwikiLink')

  " match {{URL}}
  let target = vimwiki#base#apply_template(
        \ vimwiki#u#escape(vimwiki#vars#get_global('WikiInclTemplate1')),
        \ safe_links, vimwiki#vars#get_global('rxWikiInclArgs'), '', '')
  call s:add_target_syntax_ON(target, 'VimwikiLink')
  " match {{URL|...}}
  let target = vimwiki#base#apply_template(
        \ vimwiki#u#escape(vimwiki#vars#get_global('WikiInclTemplate2')),
        \ safe_links, vimwiki#vars#get_global('rxWikiInclArgs'), '', '')
  call s:add_target_syntax_ON(target, 'VimwikiLink')
  " match [[DIRURL]]
  let target = vimwiki#base#apply_template(
        \ vimwiki#u#escape(vimwiki#vars#get_global('WikiLinkTemplate1')),
        \ safe_dirs, vimwiki#vars#get_global('rxWikiLinkDescr'), '', '')
  call s:add_target_syntax_ON(target, 'VimwikiLink')
  " match [[DIRURL|DESCRIPTION]]
  let target = vimwiki#base#apply_template(
        \ vimwiki#u#escape(vimwiki#vars#get_global('WikiLinkTemplate2')),
        \ safe_dirs, vimwiki#vars#get_global('rxWikiLinkDescr'), '', '')
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


" Weblink: [DESCRIPTION](FILE)
call s:add_target_syntax_ON(vimwiki#vars#get_syntaxlocal('rxWeblink'), 'VimwikiLink')


" WikiLink:
" All remaining schemes are highlighted automatically
let s:rxSchemes = '\%('.
      \ vimwiki#vars#get_global('schemes_local') . '\|'.
      \ vimwiki#vars#get_global('schemes_web').
      \ '\):'


" a) match [[nonwiki-scheme-URL]]
let s:target = vimwiki#base#apply_template(
      \ vimwiki#u#escape(vimwiki#vars#get_global('WikiLinkTemplate1')),
      \ s:rxSchemes.vimwiki#vars#get_global('rxWikiLinkUrl'),
      \ vimwiki#vars#get_global('rxWikiLinkDescr'), '', '')
call s:add_target_syntax_ON(s:target, 'VimwikiLink')
" b) match [[nonwiki-scheme-URL|DESCRIPTION]]
let s:target = vimwiki#base#apply_template(
      \ vimwiki#u#escape(vimwiki#vars#get_global('WikiLinkTemplate2')),
      \ s:rxSchemes.vimwiki#vars#get_global('rxWikiLinkUrl'),
      \ vimwiki#vars#get_global('rxWikiLinkDescr'), '', '')
call s:add_target_syntax_ON(s:target, 'VimwikiLink')

" a) match {{nonwiki-scheme-URL}}
let s:target = vimwiki#base#apply_template(
      \ vimwiki#u#escape(vimwiki#vars#get_global('WikiInclTemplate1')),
      \ s:rxSchemes.vimwiki#vars#get_global('rxWikiInclUrl'),
      \ vimwiki#vars#get_global('rxWikiInclArgs'), '', '')
call s:add_target_syntax_ON(s:target, 'VimwikiLink')
" b) match {{nonwiki-scheme-URL}[{...}]}
let s:target = vimwiki#base#apply_template(
      \ vimwiki#u#escape(vimwiki#vars#get_global('WikiInclTemplate2')),
      \ s:rxSchemes.vimwiki#vars#get_global('rxWikiInclUrl'),
      \ vimwiki#vars#get_global('rxWikiInclArgs'), '', '')
call s:add_target_syntax_ON(s:target, 'VimwikiLink')


" List:
execute 'syntax match VimwikiList /'.vimwiki#vars#get_wikilocal('rxListItemWithoutCB').'/'
execute 'syntax match VimwikiList /'.vimwiki#vars#get_syntaxlocal('rxListDefine').'/'
execute 'syntax match VimwikiListTodo /'.vimwiki#vars#get_wikilocal('rxListItem').'/'

" Task List Done:
if vimwiki#vars#get_global('hl_cb_checked') == 1
  execute 'syntax match VimwikiCheckBoxDone /'.vimwiki#vars#get_wikilocal('rxListItemWithoutCB')
        \ . '\s*\[['.vimwiki#vars#get_wikilocal('listsyms_list')[-1]
        \ . vimwiki#vars#get_global('listsym_rejected')
        \ . ']\]\s\(.*\)$/ '
        \ . 'contains=' . syntax_dic.nested . ',VimwikiNoExistsLink,VimwikiLink,VimwikiWeblink1,VimwikiWikiLink1,@Spell'
elseif vimwiki#vars#get_global('hl_cb_checked') == 2
  execute 'syntax match VimwikiCheckBoxDone /'
        \ . vimwiki#vars#get_wikilocal('rxListItemAndChildren')
        \ .'/ contains=VimwikiNoExistsLink,VimwikiLink,VimwikiWeblink1,VimwikiWikiLink1,@Spell'
endif


" Header Level: 1..6
for s:i in range(1,6)
  " WebLink are for markdown but putting them here avoidcode duplication
  " -- and syntax folding Issue #1009
  execute 'syntax match VimwikiHeader'.s:i
      \ . ' /'.vimwiki#vars#get_syntaxlocal('rxH'.s:i, s:current_syntax)
      \ . '/ contains=VimwikiTodo,VimwikiHeaderChar,VimwikiNoExistsLink,VimwikiCode,'
      \ . 'VimwikiLink,VimwikiWeblink1,VimwikiWikiLink1,VimwikiList,VimwikiListTodo,@Spell'
  execute 'syntax region VimwikiH'.s:i.'Folding start=/'
      \ . vimwiki#vars#get_syntaxlocal('rxH'.s:i.'_Start', s:current_syntax).'/ end=/'
      \ . vimwiki#vars#get_syntaxlocal('rxH'.s:i.'_End', s:current_syntax)
      \ . '/me=s-1'
      \ . ' transparent fold'
endfor


" SetExt Header:
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


let s:options = ' contained transparent contains=NONE'
if exists('+conceallevel')
  let s:options .= b:vimwiki_syntax_conceal
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
      \ vimwiki#vars#get_syntaxlocal('header_symbol').'\+\)\|\%('.vimwiki#vars#get_syntaxlocal('header_symbol').
      \ '\+\s*$\)/'

execute 'syntax match VimwikiTodo /'. vimwiki#vars#get_wikilocal('rx_todo') .'/'


" Table:
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
                           \ VimwikiEmoji,
                           \ @Spell

syntax match VimwikiCellSeparator /\%(|\)\|\%(-\@<=+\-\@=\)\|\%([|+]\@<=-\+\)/ contained


" Horizontal Rule: <hr>
execute 'syntax match VimwikiHR /'.vimwiki#vars#get_syntaxlocal('rxHR').'/'

" Preformated Text: `like that`
let concealpre = vimwiki#vars#get_global('conceal_pre') ? ' concealends' : ''
execute 'syntax region VimwikiPre matchgroup=VimwikiPreDelim start=/'.vimwiki#vars#get_syntaxlocal('rxPreStart').
      \ '/ end=/'.vimwiki#vars#get_syntaxlocal('rxPreEnd').'/ contains=@NoSpell'.concealpre

" Equation Text: $like that$
execute 'syntax region VimwikiMath start=/'.vimwiki#vars#get_syntaxlocal('rxMathStart').
      \ '/ end=/'.vimwiki#vars#get_syntaxlocal('rxMathEnd').'/ contains=@NoSpell'


" Placeholder:
syntax match VimwikiPlaceholder /^\s*%nohtml\s*$/
syntax match VimwikiPlaceholder
      \ /^\s*%title\ze\%(\s.*\)\?$/ nextgroup=VimwikiPlaceholderParam skipwhite
syntax match VimwikiPlaceholder
      \ /^\s*%date\ze\%(\s.*\)\?$/ nextgroup=VimwikiPlaceholderParam skipwhite
syntax match VimwikiPlaceholder
      \ /^\s*%template\ze\%(\s.*\)\?$/ nextgroup=VimwikiPlaceholderParam skipwhite
syntax match VimwikiPlaceholderParam /.*/ contained


" Html Tag: <u>
if vimwiki#vars#get_global('valid_html_tags') !=? ''
  let s:html_tags = join(split(vimwiki#vars#get_global('valid_html_tags'), '\s*,\s*'), '\|')
  exe 'syntax match VimwikiHTMLtag #\c</\?\%('.s:html_tags.'\)\%(\s\{-1}\S\{-}\)\{-}\s*/\?>#'

  " Html Typeface: <b>bold text</b>
  let html_typeface = {
    \ 'bold': [['<b>', '</b\_s*>'], ['<strong>', '</strong\_s*>']],
    \ 'italic': [['<i>', '</i\_s*>'], ['<em>', '</em\_s*>']],
    \ 'underline': [['<u>', '</u\_s*>']],
    \ 'code': [['<code>', '</code\_s*>']],
    \ 'del': [['<del>', '</del\_s*>']],
    \ 'eq': [],
    \ 'sup': [['<sup>', '</sup\_s*>']],
    \ 'sub': [['<sub>', '</sub\_s*>']],
    \ }
  " Highlight now
  call vimwiki#u#hi_typeface(html_typeface)
endif

" Html Color: <span style="color:#FF0000";>Red paragraph</span>
" -- See: h color_dic
let color_dic = vimwiki#vars#get_wikilocal('color_dic')
let color_tag = vimwiki#vars#get_wikilocal('color_tag_template')
for [color_key, color_value] in items(color_dic)
  let [fg, bg] = color_value
  let delimiter = color_tag
  let delimiter = substitute(delimiter, '__COLORFG__', fg, 'g')
  let delimiter = substitute(delimiter, '__COLORBG__', bg, 'g')
  " The user input has been already checked
  let [pre_region, post_region] = split(delimiter, '__CONTENT__')
  let cmd = 'syntax region Vimwiki' . color_key . ' matchgroup=VimwikiDelimiterColor'
        \ . ' start=/' . pre_region . '/'
        \ . ' end=/' . post_region . '/'
        \ . ' ' . b:vimwiki_syntax_concealends
  execute cmd

  " Build highlight command
  let cmd = 'hi Vimwiki' . color_key
  if fg !=# ''
    let cmd .= ' guifg=' . fg
  endif
  if bg !=# ''
    let cmd .= ' guibg=' . bg
  endif
  execute cmd
endfor

" Html mark tag, feature request in issue #1261
let cmd = 'syntax region VimwikiMarkTag matchgroup=VimwikiDelimiterColor'
      \ . ' start=/<mark>/'
      \ . ' end=+</mark>+'
      \ . ' ' . b:vimwiki_syntax_concealends
execute cmd


" Comment: home made
execute 'syntax match VimwikiComment /'.vimwiki#vars#get_syntaxlocal('comment_regex').
    \ '/ contains=@Spell,VimwikiTodo'
" Only do syntax highlighting for multiline comments if they exist
let mc_format = vimwiki#vars#get_syntaxlocal('multiline_comment_format')
if !empty(mc_format.pre_mark) && !empty(mc_format.post_mark)
execute 'syntax region VimwikiMultilineComment start=/'.mc_format.pre_mark.
      \ '/ end=/'.mc_format.post_mark.'/ contains=@NoSpell,VimwikiTodo'
endif

" Tag:
let tag_cmd = 'syntax match VimwikiTag /'.vimwiki#vars#get_syntaxlocal('rxTags').'/'
let tf = vimwiki#vars#get_wikilocal('tag_format')
if exists('+conceallevel') && tf.conceal != 0
  let tag_cmd .= ' conceal'
  if tf.cchar !=# ''
    let tag_cmd .= ' cchar=' . tf.cchar
  endif
endif
execute tag_cmd


" Header Groups: highlighting
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


" Typeface: -> u.vim
let s:typeface_dic = vimwiki#vars#get_syntaxlocal('typeface')
call vimwiki#u#hi_typeface(s:typeface_dic)


" Link highlighting groups
""""""""""""""""""""""""""

hi def link VimwikiMarkers Normal
hi def link VimwikiError Normal

hi def link VimwikiEqIn Number
hi def link VimwikiEqInT VimwikiEqIn

" Typeface 1
hi def VimwikiBold term=bold cterm=bold gui=bold
hi def link VimwikiBoldT VimwikiBold

hi def VimwikiItalic term=italic cterm=italic gui=italic
hi def link VimwikiItalicT VimwikiItalic

hi def VimwikiUnderline term=underline cterm=underline gui=underline

" Typeface 2
" Bold > Italic > Underline
hi def VimwikiBoldItalic term=bold,italic cterm=bold,italic gui=bold,italic
hi def link VimwikiItalicBold VimwikiBoldItalic
hi def link VimwikiBoldItalicT VimwikiBoldItalic
hi def link VimwikiItalicBoldT VimwikiBoldItalic

hi def VimwikiBoldUnderline term=bold,underline cterm=bold,underline gui=bold,underline
hi def link VimwikiUnderlineBold VimwikiBoldUnderline

hi def VimwikiItalicUnderline term=italic,underline cterm=italic,underline gui=italic,underline
hi def link VimwikiUnderlineItalic VimwikiItalicUnderline

" Typeface 3
hi def VimwikiBoldItalicUnderline term=bold,italic,underline cterm=bold,italic,underline gui=bold,italic,underline
hi def link VimwikiBoldUnderlineItalic VimwikiBoldItalicUnderline
hi def link VimwikiItalicBoldUnderline VimwikiBoldItalicUnderline
hi def link VimwikiItalicUnderlineBold VimwikiBoldItalicUnderline
hi def link VimwikiUnderlineBoldItalic VimwikiBoldItalicUnderline
hi def link VimwikiUnderlineItalicBold VimwikiBoldItalicUnderline

" Code
hi def link VimwikiCode PreProc
hi def link VimwikiCodeT VimwikiCode

" Mark
hi def VimwikiMarkTag term=bold ctermbg=yellow ctermfg=black guibg=yellow guifg=black
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


" Deleted called strikethrough
" See $VIMRUTIME/syntax/html.vim
if v:version > 800 || (v:version == 800 && has('patch1038')) || has('nvim-0.4.3')
  hi def VimwikiDelText term=strikethrough cterm=strikethrough gui=strikethrough
else
  hi def link VimwikiDelText Constant
endif
hi def link VimwikiDelTextT VimwikiDelText

hi def link VimwikiSuperScript Number
hi def link VimwikiSuperScriptT VimwikiSuperScript

hi def link VimwikiSubScript Number
hi def link VimwikiSubScriptT VimwikiSubScript

hi def link VimwikiTodo Todo
hi def link VimwikiComment Comment
hi def link VimwikiMultilineComment Comment

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

" TODO remove unused due to region refactoring
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


" Include: Code: EMBEDDED syntax setup -> base.vim
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

" Include: Yaml metadata block for pandoc
let a_yaml_delimiter = vimwiki#vars#get_syntaxlocal('yaml_metadata_block')
for [rx_start, rx_end] in a_yaml_delimiter
  call vimwiki#base#nested_syntax(
        \ 'yaml',
        \ rx_start,
        \ rx_end,
        \ 'VimwikiPre')
endfor


" LaTex: Load
if !empty(globpath(&runtimepath, 'syntax/tex.vim'))
  execute 'syntax include @textGrouptex syntax/tex.vim'
endif
if !empty(globpath(&runtimepath, 'after/syntax/tex.vim'))
  execute 'syntax include @textGrouptex after/syntax/tex.vim'
endif

" LaTeX: Block
call vimwiki#base#nested_syntax('tex',
      \ vimwiki#vars#get_syntaxlocal('rxMathStart').'\%(.*[[:blank:][:punct:]]\)\?'.
      \ '\%([[:blank:][:punct:]].*\)\?',
      \ vimwiki#vars#get_syntaxlocal('rxMathEnd'), 'VimwikiMath')

" LaTeX: Inline
for u in syntax_dic.typeface.eq
  execute 'syntax region textSniptex  matchgroup=texSnip'
        \ . ' start="'.u[0].'" end="'.u[1].'"'
        \ . ' contains=@texMathZoneGroup'
        \ . ' keepend oneline '. b:vimwiki_syntax_concealends
endfor

" Emoji: :dog: (after tags to take precedence, after nested to not be reset)
if and(vimwiki#vars#get_global('emoji_enable'), 1) != 0 && has('conceal')
  call vimwiki#emoji#apply_conceal()
  exe 'syn iskeyword '.&iskeyword.',-,:'
endif


syntax spell toplevel
