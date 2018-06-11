" vim:tabstop=2:shiftwidth=2:expandtab:textwidth=99
" Vimwiki plugin file
" Home: https://github.com/vimwiki/vimwiki/
" GetLatestVimScripts: 2226 1 :AutoInstall: vimwiki


if exists("g:loaded_vimwiki") || &cp
  finish
endif
let g:loaded_vimwiki = 1

" Set to version number for release, otherwise -1 for dev-branch
let s:plugin_vers = -1

" Get the directory the script is installed in
let s:plugin_dir = expand('<sfile>:p:h:h')

let s:old_cpo = &cpo
set cpo&vim


if exists('g:vimwiki_autowriteall')
  let s:vimwiki_autowriteall_saved = g:vimwiki_autowriteall
else
  let s:vimwiki_autowriteall_saved = 1
endif


" this is called when the cursor leaves the buffer
function! s:setup_buffer_leave()
  " don't do anything if it's not managed by Vimwiki (that is, when it's not in
  " a registered wiki and not a temporary wiki)
  if vimwiki#vars#get_bufferlocal('wiki_nr') == -1
    return
  endif

  let &autowriteall = s:vimwiki_autowriteall_saved

  if vimwiki#vars#get_global('menu') != ""
    exe 'nmenu disable '.vimwiki#vars#get_global('menu').'.Table'
  endif
endfunction


" create a new temporary wiki for the current buffer
function! s:create_temporary_wiki()
  let path = expand('%:p:h')
  let ext = '.'.expand('%:e')

  let syntax_mapping = vimwiki#vars#get_global('ext2syntax')
  if has_key(syntax_mapping, ext)
    let syntax = syntax_mapping[ext]
  else
    let syntax = vimwiki#vars#get_wikilocal_default('syntax')
  endif

  let new_temp_wiki_settings = {'path': path,
        \ 'ext': ext,
        \ 'syntax': syntax,
        \ }

  call vimwiki#vars#add_temporary_wiki(new_temp_wiki_settings)

  " Update the wiki number of the current buffer, because it may have changed when adding this
  " temporary wiki.
  call vimwiki#vars#set_bufferlocal('wiki_nr', vimwiki#base#find_wiki(expand('%:p')))
endfunction


" This function is called when Vim opens a new buffer with a known wiki
" extension. Both when the buffer has never been opened in this session and
" when it has.
function! s:setup_new_wiki_buffer()
  let wiki_nr = vimwiki#vars#get_bufferlocal('wiki_nr')
  if wiki_nr == -1    " it's not in a known wiki directory
    if vimwiki#vars#get_global('global_ext')
      call s:create_temporary_wiki()
    else
      " the user does not want a temporary wiki, so do nothing
      return
    endif
  endif

  if vimwiki#vars#get_wikilocal('maxhi')
    call vimwiki#vars#set_bufferlocal('existing_wikifiles', vimwiki#base#get_wikilinks(wiki_nr, 1))
    call vimwiki#vars#set_bufferlocal('existing_wikidirs',
          \ vimwiki#base#get_wiki_directories(wiki_nr))
  endif

  " this makes that ftplugin/vimwiki.vim and afterwards syntax/vimwiki.vim are
  " sourced
  setfiletype vimwiki

endfunction


" this is called when the cursor enters the buffer
function! s:setup_buffer_enter()
  " don't do anything if it's not managed by Vimwiki (that is, when it's not in
  " a registered wiki and not a temporary wiki)
  if vimwiki#vars#get_bufferlocal('wiki_nr') == -1
    return
  endif

  if &filetype != 'vimwiki'
    setfiletype vimwiki
  endif

  call s:set_global_options()

  call s:set_windowlocal_options()
endfunction


function! s:setup_cleared_syntax()
  " highlight groups that get cleared
  " on colorscheme change because they are not linked to Vim-predefined groups
  hi def VimwikiBold term=bold cterm=bold gui=bold
  hi def VimwikiItalic term=italic cterm=italic gui=italic
  hi def VimwikiBoldItalic term=bold cterm=bold gui=bold,italic
  hi def VimwikiUnderline gui=underline
  if vimwiki#vars#get_global('hl_headers') == 1
    for i in range(1,6)
      execute 'hi def VimwikiHeader'.i.' guibg=bg guifg='
            \ . vimwiki#vars#get_global('hcolor_guifg_'.&bg)[i-1]
            \ .' gui=bold ctermfg='.vimwiki#vars#get_global('hcolor_ctermfg_'.&bg)[i-1]
            \ .' term=bold cterm=bold'
    endfor
  endif
endfunction


function! s:vimwiki_get_known_extensions()
  " Getting all extensions that different wikis could have
  let extensions = {}
  for idx in range(vimwiki#vars#number_of_wikis())
    let ext = vimwiki#vars#get_wikilocal('ext', idx)
    let extensions[ext] = 1
  endfor
  " append extensions from g:vimwiki_ext2syntax
  for ext in keys(vimwiki#vars#get_global('ext2syntax'))
    let extensions[ext] = 1
  endfor
  return keys(extensions)
endfunction


" Set settings which are global for Vim, but should only be executed for
" Vimwiki buffers. So they must be set when the cursor enters a Vimwiki buffer
" and reset when the cursor leaves the buffer.
function! s:set_global_options()
  let s:vimwiki_autowriteall_saved = &autowriteall
  let &autowriteall = vimwiki#vars#get_global('autowriteall')

  if vimwiki#vars#get_global('menu') !=# ''
    exe 'nmenu enable '.vimwiki#vars#get_global('menu').'.Table'
  endif
endfunction


" Set settings which are local to a window. In a new tab they would be reset to
" Vim defaults. So we enforce our settings here when the cursor enters a
" Vimwiki buffer.
function! s:set_windowlocal_options()
  let foldmethod = vimwiki#vars#get_global('folding')
  if foldmethod =~? '^expr.*'
    setlocal foldmethod=expr
    setlocal foldexpr=VimwikiFoldLevel(v:lnum)
    setlocal foldtext=VimwikiFoldText()
  elseif foldmethod =~? '^list.*' || foldmethod =~? '^lists.*'
    setlocal foldmethod=expr
    setlocal foldexpr=VimwikiFoldListLevel(v:lnum)
    setlocal foldtext=VimwikiFoldText()
  elseif foldmethod =~? '^syntax.*'
    setlocal foldmethod=syntax
    setlocal foldtext=VimwikiFoldText()
  elseif foldmethod =~? '^custom.*'
    " do nothing
  else
    setlocal foldmethod=manual
    normal! zE
  endif

  if vimwiki#vars#get_global('conceallevel') && exists("+conceallevel")
    let &conceallevel = vimwiki#vars#get_global('conceallevel')
  endif

  if vimwiki#vars#get_global('auto_chdir')
    exe 'lcd' vimwiki#vars#get_wikilocal('path')
  endif
endfunction


function! s:get_version()
  if s:plugin_vers != -1
    echo "Stable version: " . s:plugin_vers
  else
    let a:plugin_rev    = system("git --git-dir " . s:plugin_dir . "/.git rev-parse --short HEAD")
    let a:plugin_branch = system("git --git-dir " . s:plugin_dir . "/.git rev-parse --abbrev-ref HEAD")
    let a:plugin_date   = system("git --git-dir " . s:plugin_dir . "/.git show -s --format=%ci")
    if v:shell_error == 0
      echo "Branch: " . a:plugin_branch
      echo "Revision: " . a:plugin_rev
      echo "Date: " . a:plugin_date
    else
      echo "Unknown version"
    endif
  endif
endfunction



" Initialization of Vimwiki starts here. Make sure everything below does not
" cause autoload/vimwiki/base.vim to be loaded

call vimwiki#vars#init()


" Define callback functions which the user can redefine
if !exists("*VimwikiLinkHandler")
  function VimwikiLinkHandler(url)
    return 0
  endfunction
endif

if !exists("*VimwikiLinkConverter")
  function VimwikiLinkConverter(url, source, target)
    " Return the empty string when unable to process link
    return ''
  endfunction
endif

if !exists("*VimwikiWikiIncludeHandler")
  function! VimwikiWikiIncludeHandler(value)
    return ''
  endfunction
endif



" Define autocommands for all known wiki extensions

let s:known_extensions = s:vimwiki_get_known_extensions()

if index(s:known_extensions, '.wiki') > -1
  augroup filetypedetect
    " clear FlexWiki's stuff
    au! * *.wiki
  augroup end
endif

augroup vimwiki
  autocmd!
  for s:ext in s:known_extensions
    exe 'autocmd BufNewFile,BufRead *'.s:ext.' call s:setup_new_wiki_buffer()'
    exe 'autocmd BufEnter *'.s:ext.' call s:setup_buffer_enter()'
    exe 'autocmd BufLeave *'.s:ext.' call s:setup_buffer_leave()'
    exe 'autocmd ColorScheme *'.s:ext.' call s:setup_cleared_syntax()'
    " Format tables when exit from insert mode. Do not use textwidth to
    " autowrap tables.
    if vimwiki#vars#get_global('table_auto_fmt')
      exe 'autocmd InsertLeave *'.s:ext.' call vimwiki#tbl#format(line("."))'
      exe 'autocmd InsertEnter *'.s:ext.' call vimwiki#tbl#reset_tw(line("."))'
    endif
    if vimwiki#vars#get_global('folding') =~? ':quick$'
      " from http://vim.wikia.com/wiki/Keep_folds_closed_while_inserting_text
      " Don't screw up folds when inserting text that might affect them, until
      " leaving insert mode. Foldmethod is local to the window. Protect against
      " screwing up folding when switching between windows.
      exe 'autocmd InsertEnter *'.s:ext.' if !exists("w:last_fdm") | let w:last_fdm=&foldmethod'.
            \ ' | setlocal foldmethod=manual | endif'
      exe 'autocmd InsertLeave,WinLeave *'.s:ext.' if exists("w:last_fdm") |'.
            \ 'let &l:foldmethod=w:last_fdm | unlet w:last_fdm | endif'
    endif
  endfor
augroup END



command! VimwikiUISelect call vimwiki#base#ui_select()
" why not using <count> instead of v:count1?
" See https://github.com/vimwiki-backup/vimwiki/issues/324
command! -count=1 VimwikiIndex
      \ call vimwiki#base#goto_index(v:count1)
command! -count=1 VimwikiTabIndex
      \ call vimwiki#base#goto_index(v:count1, 1)

command! -count=1 VimwikiDiaryIndex
      \ call vimwiki#diary#goto_diary_index(v:count1)
command! -count=1 VimwikiMakeDiaryNote
      \ call vimwiki#diary#make_note(v:count)
command! -count=1 VimwikiTabMakeDiaryNote
      \ call vimwiki#diary#make_note(v:count, 1)
command! -count=1 VimwikiMakeYesterdayDiaryNote
      \ call vimwiki#diary#make_note(v:count, 0,
      \ vimwiki#diary#diary_date_link(localtime() - 60*60*24))
command! -count=1 VimwikiMakeTomorrowDiaryNote
      \ call vimwiki#diary#make_note(v:count, 0,
      \ vimwiki#diary#diary_date_link(localtime() + 60*60*24))

command! VimwikiDiaryGenerateLinks
      \ call vimwiki#diary#generate_diary_section()

command! VimwikiShowVersion call s:get_version()



let s:map_prefix = vimwiki#vars#get_global('map_prefix')

if !hasmapto('<Plug>VimwikiIndex')
  exe 'nmap <silent><unique> '.s:map_prefix.'w <Plug>VimwikiIndex'
endif
nnoremap <unique><script> <Plug>VimwikiIndex :VimwikiIndex<CR>

if !hasmapto('<Plug>VimwikiTabIndex')
  exe 'nmap <silent><unique> '.s:map_prefix.'t <Plug>VimwikiTabIndex'
endif
nnoremap <unique><script> <Plug>VimwikiTabIndex :VimwikiTabIndex<CR>

if !hasmapto('<Plug>VimwikiUISelect')
  exe 'nmap <silent><unique> '.s:map_prefix.'s <Plug>VimwikiUISelect'
endif
nnoremap <unique><script> <Plug>VimwikiUISelect :VimwikiUISelect<CR>

if !hasmapto('<Plug>VimwikiDiaryIndex')
  exe 'nmap <silent><unique> '.s:map_prefix.'i <Plug>VimwikiDiaryIndex'
endif
nnoremap <unique><script> <Plug>VimwikiDiaryIndex :VimwikiDiaryIndex<CR>

if !hasmapto('<Plug>VimwikiDiaryGenerateLinks')
  exe 'nmap <silent><unique> '.s:map_prefix.'<Leader>i <Plug>VimwikiDiaryGenerateLinks'
endif
nnoremap <unique><script> <Plug>VimwikiDiaryGenerateLinks :VimwikiDiaryGenerateLinks<CR>

if !hasmapto('<Plug>VimwikiMakeDiaryNote')
  exe 'nmap <silent><unique> '.s:map_prefix.'<Leader>w <Plug>VimwikiMakeDiaryNote'
endif
nnoremap <unique><script> <Plug>VimwikiMakeDiaryNote :VimwikiMakeDiaryNote<CR>

if !hasmapto('<Plug>VimwikiTabMakeDiaryNote')
  exe 'nmap <silent><unique> '.s:map_prefix.'<Leader>t <Plug>VimwikiTabMakeDiaryNote'
endif
nnoremap <unique><script> <Plug>VimwikiTabMakeDiaryNote
      \ :VimwikiTabMakeDiaryNote<CR>

if !hasmapto('<Plug>VimwikiMakeYesterdayDiaryNote')
  exe 'nmap <silent><unique> '.s:map_prefix.'<Leader>y <Plug>VimwikiMakeYesterdayDiaryNote'
endif
nnoremap <unique><script> <Plug>VimwikiMakeYesterdayDiaryNote
      \ :VimwikiMakeYesterdayDiaryNote<CR>

if !hasmapto('<Plug>VimwikiMakeTomorrowDiaryNote')
  exe 'nmap <silent><unique> '.s:map_prefix.'<Leader>m <Plug>VimwikiMakeTomorrowDiaryNote'
endif
nnoremap <unique><script> <Plug>VimwikiMakeTomorrowDiaryNote
      \ :VimwikiMakeTomorrowDiaryNote<CR>




function! s:build_menu(topmenu)
  for idx in range(vimwiki#vars#number_of_wikis())
    let norm_path = fnamemodify(vimwiki#vars#get_wikilocal('path', idx), ':h:t')
    let norm_path = escape(norm_path, '\ \.')
    execute 'menu '.a:topmenu.'.Open\ index.'.norm_path.
          \ ' :call vimwiki#base#goto_index('.(idx+1).')<CR>'
    execute 'menu '.a:topmenu.'.Open/Create\ diary\ note.'.norm_path.
          \ ' :call vimwiki#diary#make_note('.(idx+1).')<CR>'
  endfor
endfunction

function! s:build_table_menu(topmenu)
  exe 'menu '.a:topmenu.'.-Sep- :'
  exe 'menu '.a:topmenu.'.Table.Create\ (enter\ cols\ rows) :VimwikiTable '
  exe 'nmenu '.a:topmenu.'.Table.Format<tab>gqq gqq'
  exe 'nmenu '.a:topmenu.'.Table.Move\ column\ left<tab><A-Left> :VimwikiTableMoveColumnLeft<CR>'
  exe 'nmenu '.a:topmenu.
        \ '.Table.Move\ column\ right<tab><A-Right> :VimwikiTableMoveColumnRight<CR>'
  exe 'nmenu disable '.a:topmenu.'.Table'
endfunction


if !empty(vimwiki#vars#get_global('menu'))
  call s:build_menu(vimwiki#vars#get_global('menu'))
  call s:build_table_menu(vimwiki#vars#get_global('menu'))
endif


" Hook for calendar.vim
if vimwiki#vars#get_global('use_calendar')
  let g:calendar_action = 'vimwiki#diary#calendar_action'
  let g:calendar_sign = 'vimwiki#diary#calendar_sign'
endif


let &cpo = s:old_cpo
