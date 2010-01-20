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

" HELPER functions {{{
function! s:default(varname, value) "{{{
  if !exists('g:vimwiki_'.a:varname)
    let g:vimwiki_{a:varname} = a:value
  endif
endfunction "}}}

function! Str_common_part(str1, str2)"{{{
  let idx = 0
  let minlen = min([len(a:str1), len(a:str2)])
  while (idx < minlen) && (a:str1[idx] == a:str2[idx])
    let idx = idx + 1
  endwhile

  return strpart(a:str1, 0, idx)
endfunction"}}}

function! s:chomp_slash(str)"{{{
  return substitute(a:str, '[/\\]\+$', '', '')
endfunction"}}}

function! s:find_wiki(path) "{{{
  let idx = 0
  while idx < len(g:vimwiki_list)
    let path = s:chomp_slash(expand(VimwikiGet('path', idx)))
    if Str_common_part(path, a:path) == path
      return idx
    endif
    let idx += 1
  endwhile
  return -1
endfunction "}}}

function! s:setup_buffer_leave()"{{{
  if &filetype == 'vimwiki' && !exists("b:vimwiki_idx")
    let b:vimwiki_idx = g:vimwiki_current_idx
  endif
endfunction"}}}

function! s:setup_buffer_enter() "{{{
  if exists("b:vimwiki_idx")
    let g:vimwiki_current_idx = b:vimwiki_idx
  else
    " Find what wiki current buffer belongs to.
    " If wiki does not exist in g:vimwiki_list -- add new wiki there with
    " buffer's path and ext.
    " Else set g:vimwiki_current_idx to that wiki index.
    let path = expand('%:p:h')
    let ext = '.'.expand('%:e')
    let idx = s:find_wiki(path)

    " The buffer's file is not in the path and user do not want his wiki
    " extension to be global -- do not add new wiki.
    if idx == -1 && g:vimwiki_global_ext == 0
      return
    endif

    if idx == -1
      call add(g:vimwiki_list, {'path': path, 'ext': ext})
      let g:vimwiki_current_idx = len(g:vimwiki_list) - 1
    else
      let g:vimwiki_current_idx = idx
    endif

    let b:vimwiki_idx = g:vimwiki_current_idx
  endif

  call s:setup_colors()

  if &filetype != 'vimwiki'
    setlocal ft=vimwiki
  else
    setlocal syntax=vimwiki
  endif

  " Settings foldmethod, foldexpr and foldtext are local to window. Thus in a
  " new tab with the same buffer folding is reset to vim defaults. So we
  " insist vimwiki folding here.
  " TODO: remove the same from ftplugin.
  if g:vimwiki_folding == 1 && &fdm != 'expr'
    setlocal fdm=expr
    setlocal foldexpr=VimwikiFoldLevel(v:lnum)
    setlocal foldtext=VimwikiFoldText()
  endif
endfunction "}}}

function! s:setup_colors()"{{{
  if g:vimwiki_hl_headers == 0
    return
  endif

  if &background == 'light'
    hi def VimwikiHeader1 guibg=bg guifg=#aa5858 gui=bold ctermfg=DarkRed
    hi def VimwikiHeader2 guibg=bg guifg=#309010 gui=bold ctermfg=DarkGreen
    hi def VimwikiHeader3 guibg=bg guifg=#1030a0 gui=bold ctermfg=DarkBlue
    hi def VimwikiHeader4 guibg=bg guifg=#103040 gui=bold ctermfg=Black
    hi def VimwikiHeader5 guibg=bg guifg=#001020 gui=bold ctermfg=Black
    hi def VimwikiHeader6 guibg=bg guifg=#000000 gui=bold ctermfg=Black
  else
    hi def VimwikiHeader1 guibg=bg guifg=#e08090 gui=bold ctermfg=Red
    hi def VimwikiHeader2 guibg=bg guifg=#80e090 gui=bold ctermfg=Green
    hi def VimwikiHeader3 guibg=bg guifg=#6090e0 gui=bold ctermfg=Blue
    hi def VimwikiHeader4 guibg=bg guifg=#c0c0f0 gui=bold ctermfg=White
    hi def VimwikiHeader5 guibg=bg guifg=#e0e0f0 gui=bold ctermfg=White
    hi def VimwikiHeader6 guibg=bg guifg=#f0f0f0 gui=bold ctermfg=White
  endif
endfunction"}}}

" OPTION get/set functions {{{
" return value of option for current wiki or if second parameter exists for
" wiki with a given index.
function! VimwikiGet(option, ...) "{{{
  if a:0 == 0
    let idx = g:vimwiki_current_idx
  else
    let idx = a:1
  endif
  if !has_key(g:vimwiki_list[idx], a:option) &&
        \ has_key(s:vimwiki_defaults, a:option)
    if a:option == 'path_html'
      let g:vimwiki_list[idx][a:option] =
            \VimwikiGet('path', idx)[:-2].'_html/'
    else
      let g:vimwiki_list[idx][a:option] =
            \s:vimwiki_defaults[a:option]
    endif
  endif

  " if path's ending is not a / or \
  " then add it
  if a:option == 'path' || a:option == 'path_html'
    let p = g:vimwiki_list[idx][a:option]
    " resolve doesn't work quite right with symlinks ended with / or \
    let p = substitute(p, '[/\\]\+$', '', '')
    let p = resolve(expand(p))
    let g:vimwiki_list[idx][a:option] = p.'/'
  endif

  return g:vimwiki_list[idx][a:option]
endfunction "}}}

" set option for current wiki or if third parameter exists for
" wiki with a given index.
function! VimwikiSet(option, value, ...) "{{{
  if a:0 == 0
    let idx = g:vimwiki_current_idx
  else
    let idx = a:1
  endif
  let g:vimwiki_list[idx][a:option] = a:value
endfunction "}}}
" }}}

" }}}

" CALLBACK function "{{{
" User can redefine it.
if !exists("*VimwikiWeblinkHandler") "{{{
  function VimwikiWeblinkHandler(weblink)
    for browser in g:vimwiki_browsers
      if executable(browser)
        if has("win32")
          execute '!start "'.browser.'" ' . a:weblink
        else
          execute '!'.browser.' ' . a:weblink
        endif
        return
      endif
    endfor
  endfunction
endif "}}}
" CALLBACK }}}

" DEFAULT wiki {{{
let s:vimwiki_defaults = {}
let s:vimwiki_defaults.path = '~/vimwiki/'
let s:vimwiki_defaults.path_html = '~/vimwiki_html/'
let s:vimwiki_defaults.css_name = 'style.css'
let s:vimwiki_defaults.index = 'index'
let s:vimwiki_defaults.ext = '.wiki'
let s:vimwiki_defaults.maxhi = 1
let s:vimwiki_defaults.syntax = 'default'
let s:vimwiki_defaults.gohome = 'split'
let s:vimwiki_defaults.html_header = ''
let s:vimwiki_defaults.html_footer = ''
let s:vimwiki_defaults.nested_syntaxes = {}
"}}}

" DEFAULT options {{{
call s:default('list', [s:vimwiki_defaults])
if &encoding == 'utf-8'
  call s:default('upper', 'A-Z\u0410-\u042f')
  call s:default('lower', 'a-z\u0430-\u044f')
else
  call s:default('upper', 'A-Z')
  call s:default('lower', 'a-z')
endif
call s:default('other', '0-9')
call s:default('stripsym', '_')
call s:default('badsyms', '')
call s:default('auto_checkbox', 1)
call s:default('use_mouse', 0)
call s:default('folding', 0)
call s:default('fold_trailing_empty_lines', 0)
call s:default('fold_lists', 0)
call s:default('menu', 'Vimwiki')
call s:default('global_ext', 1)
call s:default('hl_headers', 0)
call s:default('hl_cb_checked', 0)
call s:default('camel_case', 1)
call s:default('list_ignore_newline', 1)
call s:default('listsyms', ' .oOX')
if has("win32")
  call s:default('browsers',
        \ [
        \  expand('~').'\Local Settings\Application Data\Google\Chrome\Application\chrome.exe',
        \  'C:\Program Files\Opera\opera.exe',
        \  'C:\Program Files\Mozilla Firefox\firefox.exe',
        \  'C:\Program Files\Internet Explorer\iexplore.exe',
        \ ])
else
  call s:default('browsers',
        \ [
        \  'opera',
        \  'firefox',
        \  'konqueror',
        \ ])
endif

call s:default('current_idx', 0)

let upp = g:vimwiki_upper
let low = g:vimwiki_lower
let oth = g:vimwiki_other
let nup = low.oth
let nlo = upp.oth
let any = upp.nup

let g:vimwiki_word1 = '\C\<['.upp.']['.nlo.']*['.
      \ low.']['.nup.']*['.upp.']['.any.']*\>'
let g:vimwiki_word2 = '\[\[[^\]]\+\]\]'
let g:vimwiki_word3 = '\[\[[^\]]\+\]\[[^\]]\+\]\]'
if g:vimwiki_camel_case
  let g:vimwiki_rxWikiWord = g:vimwiki_word1.'\|'.g:vimwiki_word2.'\|'.g:vimwiki_word3
else
  let g:vimwiki_rxWikiWord = g:vimwiki_word2.'\|'.g:vimwiki_word3
endif
let g:vimwiki_rxWeblink = '\%("[^"(]\+\((\([^)]\+\))\)\?":\)\?'.
      \'\%(https\?\|ftp\|gopher\|telnet\|file\|notes\|ms-help\):'.
      \'\%(\%(\%(//\)\|\%(\\\\\)\)\+[A-Za-z0-9:#@%/;,$~()_?+=.&\\\-]*\)'
"}}}

" FILETYPE setup for all known wiki extensions {{{
" Getting all extensions that different wikies could have
let extensions = {}
for wiki in g:vimwiki_list
  if has_key(wiki, 'ext')
    let extensions[wiki.ext] = 1
  else
    let extensions['.wiki'] = 1
  endif
endfor

augroup filetypedetect
  " clear FlexWiki's stuff
  au! * *.wiki
augroup end

augroup vimwiki
  autocmd!
  for ext in keys(extensions)
    execute 'autocmd BufEnter *'.ext.' call s:setup_buffer_enter()'
    execute 'autocmd BufLeave,BufHidden *'.ext.' call s:setup_buffer_leave()'

    " ColorScheme could have or could have not a VimwikiHeader1..VimwikiHeader6
    " highlight groups. We need to refresh syntax after colorscheme change.
    execute 'autocmd ColorScheme *'.ext.' call s:setup_colors() | set syntax=vimwiki'
  endfor
augroup END
"}}}

" COMMANDS {{{
command! VimwikiUISelect call vimwiki#WikiUISelect()
command! -count VimwikiGoHome
      \ call vimwiki#WikiGoHome(v:count1)
command! -count VimwikiTabGoHome tabedit <bar>
      \ call vimwiki#WikiGoHome(v:count1)
"}}}

" MAPPINGS {{{
if !hasmapto('<Plug>VimwikiGoHome')
  map <silent><unique> <Leader>ww <Plug>VimwikiGoHome
endif
noremap <unique><script> <Plug>VimwikiGoHome :VimwikiGoHome<CR>

if !hasmapto('<Plug>VimwikiTabGoHome')
  map <silent><unique> <Leader>wt <Plug>VimwikiTabGoHome
endif
noremap <unique><script> <Plug>VimwikiTabGoHome :VimwikiTabGoHome<CR>

if !hasmapto('<Plug>VimwikiUISelect')
  map <silent><unique> <Leader>ws <Plug>VimwikiUISelect
endif
noremap <unique><script> <Plug>VimwikiUISelect :VimwikiUISelect<CR>

"}}}

" MENU {{{
function! s:build_menu(path)
  let idx = 0
  while idx < len(g:vimwiki_list)
    execute 'menu '.a:path.'.'.VimwikiGet('path', idx).
          \ ' :call vimwiki#WikiGoHome('.(idx + 1).')<CR>'
    let idx += 1
  endwhile
endfunction

if !empty(g:vimwiki_menu)
  call s:build_menu(g:vimwiki_menu)
endif
" }}}

let &cpo = s:old_cpo
