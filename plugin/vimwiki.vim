" vim:tabstop=2:shiftwidth=2:expandtab:foldmethod=marker:textwidth=79
" Vimwiki plugin file
" Author: Maxim Kim <habamax@gmail.com>
" Home: http://code.google.com/p/vimwiki/
" GetLatestVimScripts: 2226 1 :AutoInstall: vimwiki

if exists("loaded_vimwiki") || &cp
  finish
endif
let loaded_vimwiki = 1

let s:old_cpo = &cpo
set cpo&vim

" Logging and performance instrumentation "{{{
let g:VimwikiLog = {}
let g:VimwikiLog.path = 0           " # of calls to VimwikiGet with path or path_html
let g:VimwikiLog.path_html = 0      " # of calls to path_html()
let g:VimwikiLog.normalize_path = 0 " # of calls to normalize_path()
let g:VimwikiLog.subdir = 0         " # of calls to vimwiki#base#subdir()
let g:VimwikiLog.timing = []        " various timing measurements
let g:VimwikiLog.html = []          " html conversion timing
function! VimwikiLog_extend(what,...)  "{{{
  call extend(g:VimwikiLog[a:what],a:000)
endfunction "}}}
"}}}

" HELPER functions {{{
function! s:default(varname, value) "{{{
  if !exists('g:vimwiki_'.a:varname)
    let g:vimwiki_{a:varname} = a:value
  endif
endfunction "}}}

function! s:find_wiki(path) "{{{
  " XXX: find_wiki() does not (yet) take into consideration the ext
  let path = vimwiki#u#path_norm(vimwiki#u#chomp_slash(a:path))
  let idx = 0
  while idx < len(g:vimwiki_list)
    let idx_path = expand(VimwikiGet('path', idx))
    let idx_path = vimwiki#u#path_norm(vimwiki#u#chomp_slash(idx_path))
    if vimwiki#u#path_common_pfx(idx_path, path) == idx_path
      return idx
    endif
    let idx += 1
  endwhile
  return -1
  " an orphan page has been detected
endfunction "}}}


function! s:vimwiki_idx() " {{{
  if exists('b:vimwiki_idx')
    return b:vimwiki_idx
  else
    return -1
  endif
endfunction " }}}

function! s:setup_buffer_leave() "{{{
  if g:vimwiki_debug ==3
    echom "Setup_buffer_leave g:curr_idx=".g:vimwiki_current_idx." b:curr_idx=".s:vimwiki_idx().""
  endif
  if &filetype == 'vimwiki'
    " cache global vars of current state XXX: SLOW!?
    call vimwiki#base#cache_buffer_state()
  endif
  if g:vimwiki_debug ==3
    echom "  Setup_buffer_leave g:curr_idx=".g:vimwiki_current_idx." b:curr_idx=".s:vimwiki_idx().""
  endif

  " Set up menu
  if g:vimwiki_menu != ""
    exe 'nmenu disable '.g:vimwiki_menu.'.Table'
  endif
endfunction "}}}

function! s:setup_filetype() "{{{
  if g:vimwiki_debug ==3
    echom "Setup_filetype g:curr_idx=".g:vimwiki_current_idx." b:curr_idx=".s:vimwiki_idx().""
  endif
  let time0 = reltime()  " start the clock  "XXX
  " Find what wiki current buffer belongs to.
  let path = expand('%:p:h')
  " XXX: find_wiki() does not (yet) take into consideration the ext
  let idx = s:find_wiki(path)
  if g:vimwiki_debug ==3
    echom "  Setup_filetype g:curr_idx=".g:vimwiki_current_idx." find_idx=".idx." b:curr_idx=".s:vimwiki_idx().""
  endif

  if idx == -1 && g:vimwiki_global_ext == 0
    return
  endif
  "XXX when idx = -1? (an orphan page has been detected)

  "TODO: refactor (same code in setup_buffer_enter)
  " The buffer's file is not in the path and user *does* want his wiki
  " extension(s) to be global -- Add new wiki.
  if idx == -1
    let ext = '.'.expand('%:e')
    " lookup syntax using g:vimwiki_ext2syntax
    if has_key(g:vimwiki_ext2syntax, ext)
      let syn = g:vimwiki_ext2syntax[ext]
    else
      let syn = s:vimwiki_defaults.syntax
    endif
    call add(g:vimwiki_list, {'path': path, 'ext': ext, 'syntax': syn, 'temp': 1})
    let idx = len(g:vimwiki_list) - 1
  endif
  call vimwiki#base#validate_wiki_options(idx)
  " initialize and cache global vars of current state
  call vimwiki#base#setup_buffer_state(idx)
  if g:vimwiki_debug ==3
    echom "  Setup_filetype g:curr_idx=".g:vimwiki_current_idx." (reset_wiki_state) b:curr_idx=".s:vimwiki_idx().""
  endif

  unlet! b:vimwiki_fs_rescan
  set filetype=vimwiki
  if g:vimwiki_debug ==3
    echom "  Setup_filetype g:curr_idx=".g:vimwiki_current_idx." (set ft=vimwiki) b:curr_idx=".s:vimwiki_idx().""
  endif
  let time1 = vimwiki#u#time(time0)  "XXX
  call VimwikiLog_extend('timing',['plugin:setup_filetype:time1',time1])
endfunction "}}}

function! s:setup_buffer_enter() "{{{
  if g:vimwiki_debug ==3
    echom "Setup_buffer_enter g:curr_idx=".g:vimwiki_current_idx." b:curr_idx=".s:vimwiki_idx().""
  endif
  let time0 = reltime()  " start the clock  "XXX
  if !vimwiki#base#recall_buffer_state()
    " Find what wiki current buffer belongs to.
    " If wiki does not exist in g:vimwiki_list -- add new wiki there with
    " buffer's path and ext.
    " Else set g:vimwiki_current_idx to that wiki index.
    let path = expand('%:p:h')
    " XXX: find_wiki() does not (yet) take into consideration the ext
    let idx = s:find_wiki(path)

    if g:vimwiki_debug ==3
      echom "  Setup_buffer_enter g:curr_idx=".g:vimwiki_current_idx." find_idx=".idx." b:curr_idx=".s:vimwiki_idx().""
    endif
    " The buffer's file is not in the path and user *does NOT* want his wiki
    " extension to be global -- Do not add new wiki.
    if idx == -1 && g:vimwiki_global_ext == 0
      return
    endif

    "TODO: refactor (same code in setup_filetype)
    " The buffer's file is not in the path and user *does* want his wiki
    " extension(s) to be global -- Add new wiki.
    if idx == -1
      let ext = '.'.expand('%:e')
      " lookup syntax using g:vimwiki_ext2syntax
      if has_key(g:vimwiki_ext2syntax, ext)
        let syn = g:vimwiki_ext2syntax[ext]
      else
        let syn = s:vimwiki_defaults.syntax
      endif
      call add(g:vimwiki_list, {'path': path, 'ext': ext, 'syntax': syn, 'temp': 1})
      let idx = len(g:vimwiki_list) - 1
    endif
    call vimwiki#base#validate_wiki_options(idx)
    " initialize and cache global vars of current state
    call vimwiki#base#setup_buffer_state(idx)
    if g:vimwiki_debug ==3
      echom "  Setup_buffer_enter g:curr_idx=".g:vimwiki_current_idx." (reset_wiki_state) b:curr_idx=".s:vimwiki_idx().""
    endif

  endif

  " If you have
  "     au GUIEnter * VimwikiIndex
  " Then change it to
  "     au GUIEnter * nested VimwikiIndex
  if &filetype == ''
    set filetype=vimwiki
    if g:vimwiki_debug ==3
      echom "  Setup_buffer_enter g:curr_idx=".g:vimwiki_current_idx." (set ft vimwiki) b:curr_idx=".s:vimwiki_idx().""
    endif
  elseif &syntax == 'vimwiki'
    " to force a rescan of the filesystem which may have changed
    " and update VimwikiLinks syntax group that depends on it;
    " b:vimwiki_fs_rescan indicates that setup_filetype() has not been run
    if exists("b:vimwiki_fs_rescan") && VimwikiGet('maxhi')
      set syntax=vimwiki
      if g:vimwiki_debug ==3
        echom "  Setup_buffer_enter g:curr_idx=".g:vimwiki_current_idx." (set syntax=vimwiki) b:curr_idx=".s:vimwiki_idx().""
      endif
    endif
    let b:vimwiki_fs_rescan = 1
  endif
  let time1 = vimwiki#u#time(time0)  "XXX

  " Settings foldmethod, foldexpr and foldtext are local to window. Thus in a
  " new tab with the same buffer folding is reset to vim defaults. So we
  " insist vimwiki folding here.
  if g:vimwiki_folding == 2 && &fdm != 'expr'
    " User-defined fold-expression, and fold-text
  endif
  if g:vimwiki_folding == 1
    setlocal fdm=expr
    setlocal foldexpr=VimwikiFoldLevel(v:lnum)
    setlocal foldtext=VimwikiFoldText()
  endif

  " And conceal level too.
  if g:vimwiki_conceallevel && exists("+conceallevel")
    let &conceallevel = g:vimwiki_conceallevel
  endif

  " Set up menu
  if g:vimwiki_menu != ""
    exe 'nmenu enable '.g:vimwiki_menu.'.Table'
  endif
  "let time2 = vimwiki#u#time(time0)  "XXX
  call VimwikiLog_extend('timing',['plugin:setup_buffer_enter:time1',time1])
endfunction "}}}

function! s:setup_buffer_reenter() "{{{
  if g:vimwiki_debug ==3
    echom "Setup_buffer_reenter g:curr_idx=".g:vimwiki_current_idx." b:curr_idx=".s:vimwiki_idx().""
  endif
  if !vimwiki#base#recall_buffer_state()
    " Do not repeat work of s:setup_buffer_enter() and s:setup_filetype()
    " Once should be enough ...
  endif
  if g:vimwiki_debug ==3
    echom "  Setup_buffer_reenter g:curr_idx=".g:vimwiki_current_idx." b:curr_idx=".s:vimwiki_idx().""
  endif
endfunction "}}}

function! s:setup_cleared_syntax() "{{{ highlight groups that get cleared
  " on colorscheme change because they are not linked to Vim-predefined groups
  hi def VimwikiBold term=bold cterm=bold gui=bold
  hi def VimwikiItalic term=italic cterm=italic gui=italic
  hi def VimwikiBoldItalic term=bold cterm=bold gui=bold,italic
  hi def VimwikiUnderline gui=underline
  if g:vimwiki_hl_headers == 1
    for i in range(1,6)
      execute 'hi def VimwikiHeader'.i.' guibg=bg guifg='.g:vimwiki_hcolor_guifg_{&bg}[i-1].' gui=bold ctermfg='.g:vimwiki_hcolor_ctermfg_{&bg}[i-1].' term=bold cterm=bold'
    endfor
  endif
endfunction "}}}

" OPTION get/set functions {{{
" return complete list of options
function! VimwikiGetOptionNames() "{{{
  return keys(s:vimwiki_defaults)
endfunction "}}}

function! VimwikiGetOptions(...) "{{{
  let idx = a:0 == 0 ? g:vimwiki_current_idx : a:1
  let option_dict = {}
  for kk in keys(s:vimwiki_defaults)
    let option_dict[kk] = VimwikiGet(kk, idx)
  endfor
  return option_dict
endfunction "}}}

" Return value of option for current wiki or if second parameter exists for
"   wiki with a given index.
" If the option is not found, it is assumed to have been previously cached in a
"   buffer local dictionary, that acts as a cache.
" If the option is not found in the buffer local dictionary, an error is thrown
function! VimwikiGet(option, ...) "{{{
  let idx = a:0 == 0 ? g:vimwiki_current_idx : a:1

  if has_key(g:vimwiki_list[idx], a:option)
    let val = g:vimwiki_list[idx][a:option]
  elseif has_key(s:vimwiki_defaults, a:option)
    let val = s:vimwiki_defaults[a:option]
    let g:vimwiki_list[idx][a:option] = val
  else
    let val = b:vimwiki_list[a:option]
  endif

  " XXX no call to vimwiki#base here or else the whole autoload/base gets loaded!
  return val
endfunction "}}}

" Set option for current wiki or if third parameter exists for
"   wiki with a given index.
" If the option is not found or recognized (i.e. does not exist in
"   s:vimwiki_defaults), it is saved in a buffer local dictionary, that acts
"   as a cache.
" If the option is not found in the buffer local dictionary, an error is thrown
function! VimwikiSet(option, value, ...) "{{{
  let idx = a:0 == 0 ? g:vimwiki_current_idx : a:1

  if has_key(s:vimwiki_defaults, a:option) ||
        \ has_key(g:vimwiki_list[idx], a:option)
    let g:vimwiki_list[idx][a:option] = a:value
  elseif exists('b:vimwiki_list')
    let b:vimwiki_list[a:option] = a:value
  else
    let b:vimwiki_list = {}
    let b:vimwiki_list[a:option] = a:value
  endif

endfunction "}}}

" Clear option for current wiki or if third parameter exists for
"   wiki with a given index.
" Currently, only works if option was previously saved in the buffer local
"   dictionary, that acts as a cache.
function! VimwikiClear(option, ...) "{{{
  let idx = a:0 == 0 ? g:vimwiki_current_idx : a:1

  if exists('b:vimwiki_list') && has_key(b:vimwiki_list, a:option)
    call remove(b:vimwiki_list, a:option)
  endif

endfunction "}}}
" }}}

" }}}

" CALLBACK functions "{{{
" User can redefine it.
if !exists("*VimwikiLinkHandler") "{{{
  function VimwikiLinkHandler(url)
    return 0
  endfunction
endif "}}}

if !exists("*VimwikiWikiIncludeHandler") "{{{
  function! VimwikiWikiIncludeHandler(value) "{{{
    " Return the empty string when unable to process link
    return ''
  endfunction "}}}
endif "}}}
" CALLBACK }}}

" DEFAULT wiki {{{
let s:vimwiki_defaults = {}
let s:vimwiki_defaults.path = '~/vimwiki/'
let s:vimwiki_defaults.path_html = ''   " '' is replaced by derived path.'_html/'
let s:vimwiki_defaults.css_name = 'style.css'
let s:vimwiki_defaults.index = 'index'
let s:vimwiki_defaults.ext = '.wiki'
let s:vimwiki_defaults.maxhi = 0
let s:vimwiki_defaults.syntax = 'default'

let s:vimwiki_defaults.template_path = ''
let s:vimwiki_defaults.template_default = ''
let s:vimwiki_defaults.template_ext = ''

let s:vimwiki_defaults.nested_syntaxes = {}
let s:vimwiki_defaults.auto_export = 0
" is wiki temporary -- was added to g:vimwiki_list by opening arbitrary wiki
" file.
let s:vimwiki_defaults.temp = 0

" diary
let s:vimwiki_defaults.diary_rel_path = 'diary/'
let s:vimwiki_defaults.diary_index = 'diary'
let s:vimwiki_defaults.diary_header = 'Diary'
let s:vimwiki_defaults.diary_sort = 'desc'

" Do not change this! Will wait till vim become more datetime awareable.
let s:vimwiki_defaults.diary_link_fmt = '%Y-%m-%d'

" NEW! in v2.0
" custom_wiki2html
let s:vimwiki_defaults.custom_wiki2html = ''
"
let s:vimwiki_defaults.list_margin = -1
"}}}

" DEFAULT options {{{
call s:default('list', [s:vimwiki_defaults])
call s:default('auto_checkbox', 1)
call s:default('use_mouse', 0)
call s:default('folding', 0)
call s:default('fold_trailing_empty_lines', 0)
call s:default('fold_lists', 0)
call s:default('menu', 'Vimwiki')
call s:default('global_ext', 1)
call s:default('ext2syntax', {'.md': 'markdown'}) " syntax map keyed on extension
call s:default('hl_headers', 0)
call s:default('hl_cb_checked', 0)
call s:default('list_ignore_newline', 1)
call s:default('listsyms', ' .oOX')
call s:default('use_calendar', 1)
call s:default('table_mappings', 1)
call s:default('table_auto_fmt', 1)
call s:default('w32_dir_enc', '')
call s:default('CJK_length', 0)
call s:default('dir_link', '')
call s:default('valid_html_tags', 'b,i,s,u,sub,sup,kbd,br,hr,div,center,strong,em')
call s:default('user_htmls', '')

call s:default('html_header_numbering', 0)
call s:default('html_header_numbering_sym', '')
call s:default('conceallevel', 2)
call s:default('url_mingain', 12)
call s:default('url_maxsave', 15)
call s:default('debug', 0)

call s:default('diary_months',
      \ {
      \ 1: 'January', 2: 'February', 3: 'March',
      \ 4: 'April', 5: 'May', 6: 'June',
      \ 7: 'July', 8: 'August', 9: 'September',
      \ 10: 'October', 11: 'November', 12: 'December'
      \ })


call s:default('current_idx', 0)

" Scheme regexes should be defined even if syntax file is not loaded yet
" cause users should be able to <leader>w<leader>w without opening any
" vimwiki file first
" Scheme regexes {{{
call s:default('schemes', 'wiki\d\+,diary,local')
call s:default('web_schemes1', 'http,https,file,ftp,gopher,telnet,nntp,ldap,'.
        \ 'rsync,imap,pop,irc,ircs,cvs,svn,svn+ssh,git,ssh,fish,sftp')
call s:default('web_schemes2', 'mailto,news,xmpp,sip,sips,doi,urn,tel')

let rxSchemes = '\%('.
      \ join(split(g:vimwiki_schemes, '\s*,\s*'), '\|').'\|'.
      \ join(split(g:vimwiki_web_schemes1, '\s*,\s*'), '\|').'\|'.
      \ join(split(g:vimwiki_web_schemes2, '\s*,\s*'), '\|').
      \ '\)'

call s:default('rxSchemeUrl', rxSchemes.':.*')
call s:default('rxSchemeUrlMatchScheme', '\zs'.rxSchemes.'\ze:.*')
call s:default('rxSchemeUrlMatchUrl', rxSchemes.':\zs.*\ze')
" scheme regexes }}}
"}}}

" AUTOCOMMANDS for all known wiki extensions {{{
let extensions = vimwiki#base#get_known_extensions()

augroup filetypedetect
  " clear FlexWiki's stuff
  au! * *.wiki
augroup end

augroup vimwiki
  autocmd!
  for ext in extensions
    exe 'autocmd BufEnter *'.ext.' call s:setup_buffer_reenter()'
    exe 'autocmd BufWinEnter *'.ext.' call s:setup_buffer_enter()'
    exe 'autocmd BufLeave,BufHidden *'.ext.' call s:setup_buffer_leave()'
    exe 'autocmd BufNewFile,BufRead, *'.ext.' call s:setup_filetype()'
    exe 'autocmd ColorScheme *'.ext.' call s:setup_cleared_syntax()'
    " Format tables when exit from insert mode. Do not use textwidth to
    " autowrap tables.
    if g:vimwiki_table_auto_fmt
      exe 'autocmd InsertLeave *'.ext.' call vimwiki#tbl#format(line("."))'
      exe 'autocmd InsertEnter *'.ext.' call vimwiki#tbl#reset_tw(line("."))'
    endif
  endfor
augroup END
"}}}

" COMMANDS {{{
command! VimwikiUISelect call vimwiki#base#ui_select()
" XXX: why not using <count> instead of v:count1?
" See Issue 324.
command! -count=1 VimwikiIndex
      \ call vimwiki#base#goto_index(v:count1)
command! -count=1 VimwikiTabIndex
      \ call vimwiki#base#goto_index(v:count1, 1)

command! -count=1 VimwikiDiaryIndex
      \ call vimwiki#diary#goto_diary_index(v:count1)
command! -count=1 VimwikiMakeDiaryNote
      \ call vimwiki#diary#make_note(v:count1)
command! -count=1 VimwikiTabMakeDiaryNote
      \ call vimwiki#diary#make_note(v:count1, 1)

command! VimwikiDiaryGenerateLinks
      \ call vimwiki#diary#generate_diary_section()
"}}}

" MAPPINGS {{{
if !hasmapto('<Plug>VimwikiIndex')
  nmap <silent><unique> <Leader>ww <Plug>VimwikiIndex
endif
nnoremap <unique><script> <Plug>VimwikiIndex :VimwikiIndex<CR>

if !hasmapto('<Plug>VimwikiTabIndex')
  nmap <silent><unique> <Leader>wt <Plug>VimwikiTabIndex
endif
nnoremap <unique><script> <Plug>VimwikiTabIndex :VimwikiTabIndex<CR>

if !hasmapto('<Plug>VimwikiUISelect')
  nmap <silent><unique> <Leader>ws <Plug>VimwikiUISelect
endif
nnoremap <unique><script> <Plug>VimwikiUISelect :VimwikiUISelect<CR>

if !hasmapto('<Plug>VimwikiDiaryIndex')
  nmap <silent><unique> <Leader>wi <Plug>VimwikiDiaryIndex
endif
nnoremap <unique><script> <Plug>VimwikiDiaryIndex :VimwikiDiaryIndex<CR>

if !hasmapto('<Plug>VimwikiDiaryGenerateLinks')
  nmap <silent><unique> <Leader>w<Leader>i <Plug>VimwikiDiaryGenerateLinks
endif
nnoremap <unique><script> <Plug>VimwikiDiaryGenerateLinks :VimwikiDiaryGenerateLinks<CR>

if !hasmapto('<Plug>VimwikiMakeDiaryNote')
  nmap <silent><unique> <Leader>w<Leader>w <Plug>VimwikiMakeDiaryNote
endif
nnoremap <unique><script> <Plug>VimwikiMakeDiaryNote :VimwikiMakeDiaryNote<CR>

if !hasmapto('<Plug>VimwikiTabMakeDiaryNote')
  nmap <silent><unique> <Leader>w<Leader>t <Plug>VimwikiTabMakeDiaryNote
endif
nnoremap <unique><script> <Plug>VimwikiTabMakeDiaryNote
      \ :VimwikiTabMakeDiaryNote<CR>

"}}}

" MENU {{{
function! s:build_menu(topmenu)
  let idx = 0
  while idx < len(g:vimwiki_list)
    let norm_path = fnamemodify(VimwikiGet('path', idx), ':h:t')
    let norm_path = escape(norm_path, '\ \.')
    execute 'menu '.a:topmenu.'.Open\ index.'.norm_path.
          \ ' :call vimwiki#base#goto_index('.(idx + 1).')<CR>'
    execute 'menu '.a:topmenu.'.Open/Create\ diary\ note.'.norm_path.
          \ ' :call vimwiki#diary#make_note('.(idx + 1).')<CR>'
    let idx += 1
  endwhile
endfunction

function! s:build_table_menu(topmenu)
  exe 'menu '.a:topmenu.'.-Sep- :'
  exe 'menu '.a:topmenu.'.Table.Create\ (enter\ cols\ rows) :VimwikiTable '
  exe 'nmenu '.a:topmenu.'.Table.Format<tab>gqq gqq'
  exe 'nmenu '.a:topmenu.'.Table.Move\ column\ left<tab><A-Left> :VimwikiTableMoveColumnLeft<CR>'
  exe 'nmenu '.a:topmenu.'.Table.Move\ column\ right<tab><A-Right> :VimwikiTableMoveColumnRight<CR>'
  exe 'nmenu disable '.a:topmenu.'.Table'
endfunction

"XXX make sure anything below does not cause autoload/base to be loaded
if !empty(g:vimwiki_menu)
  call s:build_menu(g:vimwiki_menu)
  call s:build_table_menu(g:vimwiki_menu)
endif
" }}}

" CALENDAR Hook "{{{
if g:vimwiki_use_calendar
  let g:calendar_action = 'vimwiki#diary#calendar_action'
  let g:calendar_sign = 'vimwiki#diary#calendar_sign'
endif
"}}}


let &cpo = s:old_cpo
