" vim:tabstop=2:shiftwidth=2:expandtab:textwidth=99
" Vimwiki plugin file
" Home: https://github.com/vimwiki/vimwiki/
" GetLatestVimScripts: 2226 1 :AutoInstall: vimwiki


" Clause: load only once
if exists('g:loaded_vimwiki') || &compatible
  finish
endif
let g:loaded_vimwiki = 1

" Set to version number for release:
let g:vimwiki_version = '2023.05.12'

" Get the directory the script is installed in
let s:plugin_dir = expand('<sfile>:p:h:h')

" Save peace in the galaxy
let s:old_cpo = &cpoptions
set cpoptions&vim

" Save autowriteall variable state
if exists('g:vimwiki_autowriteall')
  let s:vimwiki_autowriteall_saved = g:vimwiki_autowriteall
else
  let s:vimwiki_autowriteall_saved = 1
endif


" Autocommand called when the cursor leaves the buffer
function! s:setup_buffer_leave() abort
  " don't do anything if it's not managed by Vimwiki (that is, when it's not in
  " a registered wiki and not a temporary wiki)
  if vimwiki#vars#get_bufferlocal('wiki_nr') == -1
    return
  endif

  let &autowriteall = s:vimwiki_autowriteall_saved

  if !empty(vimwiki#vars#get_global('menu'))
    exe 'nmenu disable '.vimwiki#vars#get_global('menu').'.Table'
  endif
endfunction


" Create a new temporary wiki for the current buffer
function! s:create_temporary_wiki() abort
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


" Autocommand called when Vim opens a new buffer with a known wiki
" extension. Both when the buffer has never been opened in this session and
" when it has.
function! s:setup_new_wiki_buffer() abort
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
    call vimwiki#vars#set_bufferlocal('existing_wikifiles', vimwiki#base#get_wikilinks(wiki_nr, 1, ''))
    call vimwiki#vars#set_bufferlocal('existing_wikidirs',
          \ vimwiki#base#get_wiki_directories(wiki_nr))
  endif

  " this makes that ftplugin/vimwiki.vim and afterwards syntax/vimwiki.vim are
  " sourced
  call vimwiki#u#ft_set()
endfunction


" Autocommand called when the cursor enters the buffer
function! s:setup_buffer_enter() abort
  " don't do anything if it's not managed by Vimwiki (that is, when it's not in
  " a registered wiki and not a temporary wiki)
  if vimwiki#vars#get_bufferlocal('wiki_nr') == -1
    return
  endif

  call s:set_global_options()
endfunction


" Autocommand called when the buffer enters a window or when running a  diff
function! s:setup_buffer_win_enter() abort
  " don't do anything if it's not managed by Vimwiki (that is, when it's not in
  " a registered wiki and not a temporary wiki)
  if vimwiki#vars#get_bufferlocal('wiki_nr') == -1
    return
  endif

  if !vimwiki#u#ft_is_vw()
    call vimwiki#u#ft_set()
  endif

  call s:set_windowlocal_options()
endfunction


" Help syntax reloading
function! s:setup_cleared_syntax() abort
  " highlight groups that get cleared
  " on colorscheme change because they are not linked to Vim-predefined groups
  hi def VimwikiBold term=bold cterm=bold gui=bold
  hi def VimwikiItalic term=italic cterm=italic gui=italic
  hi def VimwikiBoldItalic term=bold,italic cterm=bold,italic gui=bold,italic
  hi def VimwikiUnderline term=underline cterm=underline gui=underline
  if vimwiki#vars#get_global('hl_headers') == 1
    for i in range(1,6)
      execute 'hi def VimwikiHeader'.i.' guibg=bg guifg='
            \ . vimwiki#vars#get_global('hcolor_guifg_'.&background)[i-1]
            \ .' gui=bold ctermfg='.vimwiki#vars#get_global('hcolor_ctermfg_'.&background)[i-1]
            \ .' term=bold cterm=bold'
    endfor
  endif
endfunction


" Return: list of extension known vy vimwiki
function! s:vimwiki_get_known_extensions() abort
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
function! s:set_global_options() abort
  let s:vimwiki_autowriteall_saved = &autowriteall
  let &autowriteall = vimwiki#vars#get_global('autowriteall')

  if !empty(vimwiki#vars#get_global('menu'))
    exe 'nmenu enable '.vimwiki#vars#get_global('menu').'.Table'
  endif
endfunction


" Set settings which are local to a window. In a new tab they would be reset to
" Vim defaults. So we enforce our settings here when the cursor enters a
" Vimwiki buffer.
function! s:set_windowlocal_options() abort
  if !&diff   " if Vim is currently in diff mode, don't interfere with its folding
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
  endif

  if exists('+conceallevel')
    let &l:conceallevel = vimwiki#vars#get_global('conceallevel')
  endif

  if vimwiki#vars#get_global('auto_chdir')
    exe 'lcd' vimwiki#vars#get_wikilocal('path')
  endif
endfunction


" Echo vimwiki version
" Called by :VimwikiShowVersion
function! s:get_version() abort
  echo 'Version: ' . g:vimwiki_version
  let l:plugin_rev    = system('git --git-dir ' . s:plugin_dir . '/.git rev-parse --short HEAD')
  let l:plugin_branch = system('git --git-dir ' . s:plugin_dir . '/.git rev-parse --abbrev-ref HEAD')
  let l:plugin_date   = system('git --git-dir ' . s:plugin_dir . '/.git show -s --format=%ci')
  if v:shell_error == 0
    echo 'Os: ' . vimwiki#u#os_name()
    echo 'Vim: ' . v:version
    echo 'Branch: ' . l:plugin_branch
    echo 'Revision: ' . l:plugin_rev
    echo 'Date: ' . l:plugin_date
  else
    echo 'Unable to retrieve repository info'
  endif
endfunction


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Initialization of Vimwiki starts here.
" Make sure everything below does not cause autoload/vimwiki/base.vim
" to be loaded
call vimwiki#vars#init()


" Define callback functions which the user can redefine
if !exists('*VimwikiLinkHandler')
  function VimwikiLinkHandler(url)
    return 0
  endfunction
endif

if !exists('*VimwikiLinkConverter')
  function VimwikiLinkConverter(url, source, target)
    " Return the empty string when unable to process link
    return ''
  endfunction
endif

if !exists('*VimwikiWikiIncludeHandler')
  function! VimwikiWikiIncludeHandler(value)
    return ''
  endfunction
endif


" Write a level 1 header to new wiki files
" a:fname should be an absolute filepath
function! s:create_h1(fname) abort
  " Clause: Don't do anything for unregistered wikis
  let idx = vimwiki#vars#get_bufferlocal('wiki_nr')
  if idx == -1
    return
  endif

  " Clause: no auto_header
  if !vimwiki#vars#get_global('auto_header')
    return
  endif

  " Clause: don't create header for the diary index page
  if vimwiki#path#is_equal(a:fname,
        \ vimwiki#vars#get_wikilocal('path', idx).vimwiki#vars#get_wikilocal('diary_rel_path', idx).
        \ vimwiki#vars#get_wikilocal('diary_index', idx).vimwiki#vars#get_wikilocal('ext', idx))
    return
  endif

  " Get tail of filename without extension
  let title = expand('%:t:r')

  " Clause: don't insert header for index page
  if title ==# vimwiki#vars#get_wikilocal('index', idx)
    return
  endif

  " Don't substitute space char for diary pages
  if title !~# '^\d\{4}-\d\d-\d\d'
    " NOTE: it is possible this could remove desired characters if the 'links_space_char'
    " character matches characters that are intentionally used in the title.
    let title = substitute(title, vimwiki#vars#get_wikilocal('links_space_char'), ' ', 'g')
  endif

  " Insert the header
  if vimwiki#vars#get_wikilocal('syntax') ==? 'markdown'
    keepjumps call append(0, '# ' . title)
    for _ in range(vimwiki#vars#get_global('markdown_header_style'))
      keepjumps call append(1, '')
    endfor
  else
    keepjumps call append(0, '= ' . title . ' =')
  endif
endfunction

" Define autocommands for all known wiki extensions
let s:known_extensions = s:vimwiki_get_known_extensions()

if index(s:known_extensions, '.wiki') > -1
  augroup filetypedetect
    " Clear FlexWiki's stuff
    au! * *.wiki
  augroup end
endif

augroup vimwiki
  autocmd!
  autocmd ColorScheme * call s:setup_cleared_syntax()

  " ['.md', '.mdown'] => *.md,*.mdown
  let pat = join(map(s:known_extensions, '"*" . v:val'), ',')
  exe 'autocmd BufNewFile,BufRead '.pat.' call s:setup_new_wiki_buffer()'
  exe 'autocmd BufEnter '.pat.' call s:setup_buffer_enter()'
  exe 'autocmd BufLeave '.pat.' call s:setup_buffer_leave()'
  exe 'autocmd BufWinEnter '.pat.' call s:setup_buffer_win_enter()'
  if exists('##DiffUpdated')
    exe 'autocmd DiffUpdated '.pat.' call s:setup_buffer_win_enter()'
  endif
  " automatically generate a level 1 header for new files
  exe 'autocmd BufNewFile '.pat.' call s:create_h1(expand("%:p"))'
  " Format tables when exit from insert mode. Do not use textwidth to
  " autowrap tables.
  if vimwiki#vars#get_global('table_auto_fmt')
    exe 'autocmd InsertLeave '.pat.' call vimwiki#tbl#format(line("."), 2)'
  endif
  if vimwiki#vars#get_global('folding') =~? ':quick$'
    " from http://vim.wikia.com/wiki/Keep_folds_closed_while_inserting_text
    " Don't screw up folds when inserting text that might affect them, until
    " leaving insert mode. Foldmethod is local to the window. Protect against
    " screwing up folding when switching between windows.
    exe 'autocmd InsertEnter '.pat.' if !exists("w:last_fdm") | let w:last_fdm=&foldmethod'.
          \ ' | setlocal foldmethod=manual | endif'
    exe 'autocmd InsertLeave,WinLeave '.pat.' if exists("w:last_fdm") |'.
          \ 'let &l:foldmethod=w:last_fdm | unlet w:last_fdm | endif'
  endif
augroup END


" Declare global commands
command! VimwikiUISelect call vimwiki#base#ui_select()

" these commands take a count e.g. :VimwikiIndex 2
" the default behavior is to open the index, diary etc.
" for the CURRENT wiki if no count is given
command! -count=0 VimwikiIndex
      \ call vimwiki#base#goto_index(<count>)

command! -count=0 VimwikiTabIndex
      \ call vimwiki#base#goto_index(<count>, 1)

command! -count=0 VimwikiDiaryIndex
      \ call vimwiki#diary#goto_diary_index(<count>)

command! -count=0 VimwikiMakeDiaryNote
      \ call vimwiki#diary#make_note(<count>, 5)

command! -count=0 VimwikiTabMakeDiaryNote
      \ call vimwiki#diary#make_note(<count>, 1)

command! -count=0 VimwikiMakeYesterdayDiaryNote
      \ call vimwiki#diary#make_note(<count>, 0,
      \ vimwiki#diary#diary_date_link(localtime(), -1))

command! -count=0 VimwikiMakeTomorrowDiaryNote
      \ call vimwiki#diary#make_note(<count>, 0,
      \ vimwiki#diary#diary_date_link(localtime(), 1))

command! VimwikiDiaryGenerateLinks
      \ call vimwiki#diary#generate_diary_section()

command! VimwikiShowVersion call s:get_version()

command! -nargs=* -complete=customlist,vimwiki#vars#complete
      \ VimwikiVar call vimwiki#vars#cmd(<q-args>)


" Declare global maps
" <Plug> global definitions
nnoremap <silent><script> <Plug>VimwikiIndex
    \ :<C-U>call vimwiki#base#goto_index(v:count)<CR>
nnoremap <silent><script> <Plug>VimwikiTabIndex
    \ :<C-U>call vimwiki#base#goto_index(v:count, 1)<CR>
nnoremap <silent><script> <Plug>VimwikiUISelect
    \ :VimwikiUISelect<CR>
nnoremap <silent><script> <Plug>VimwikiDiaryIndex
    \ :<C-U>call vimwiki#diary#goto_diary_index(v:count)<CR>
nnoremap <silent><script> <Plug>VimwikiDiaryGenerateLinks
    \ :VimwikiDiaryGenerateLinks<CR>
nnoremap <silent><script> <Plug>VimwikiMakeDiaryNote
    \ :<C-U>call vimwiki#diary#make_note(v:count, 5)<CR>
nnoremap <silent><script> <Plug>VimwikiTabMakeDiaryNote
    \ :<C-U>call vimwiki#diary#make_note(v:count, 1)<CR>
nnoremap <silent><script> <Plug>VimwikiMakeYesterdayDiaryNote
    \ :<C-U>call vimwiki#diary#make_note(v:count, 0,
    \ vimwiki#diary#diary_date_link(localtime(), -1))<CR>
nnoremap <silent><script> <Plug>VimwikiMakeTomorrowDiaryNote
    \ :<C-U>call vimwiki#diary#make_note(v:count, 0,
    \ vimwiki#diary#diary_date_link(localtime(), 1))<CR>


" Set default global key mappings
if str2nr(vimwiki#vars#get_global('key_mappings').global)
  " Get the user defined prefix (default <leader>w)
  let s:map_prefix = vimwiki#vars#get_global('map_prefix')

  call vimwiki#u#map_key('n', s:map_prefix . 'w', '<Plug>VimwikiIndex', 2)
  call vimwiki#u#map_key('n', s:map_prefix . 't', '<Plug>VimwikiTabIndex', 2)
  call vimwiki#u#map_key('n', s:map_prefix . 's', '<Plug>VimwikiUISelect', 2)
  call vimwiki#u#map_key('n', s:map_prefix . 'i', '<Plug>VimwikiDiaryIndex', 2)
  call vimwiki#u#map_key('n', s:map_prefix . '<Leader>i', '<Plug>VimwikiDiaryGenerateLinks', 2)
  call vimwiki#u#map_key('n', s:map_prefix . '<Leader>w', '<Plug>VimwikiMakeDiaryNote', 2)
  call vimwiki#u#map_key('n', s:map_prefix . '<Leader>t', '<Plug>VimwikiTabMakeDiaryNote', 2)
  call vimwiki#u#map_key('n', s:map_prefix . '<Leader>y', '<Plug>VimwikiMakeYesterdayDiaryNote', 2)
  call vimwiki#u#map_key('n', s:map_prefix . '<Leader>m', '<Plug>VimwikiMakeTomorrowDiaryNote', 2)
endif


" Build global wiki menu (GUI)
function! s:build_menu(topmenu) abort
  let wnamelist = []
  for idx in range(vimwiki#vars#number_of_wikis())
    let wname = vimwiki#vars#get_wikilocal('name', idx)
    if wname ==? ''
      " fall back to the path if wiki isn't named
      let wname = fnamemodify(vimwiki#vars#get_wikilocal('path', idx), ':h:t')
    endif

    if index(wnamelist, wname) != -1
      " append wiki index number to duplicate entries
      let wname = wname . ' ' . string(idx + 1)
    endif

    " add entry to the list of names for duplicate checks
    call add(wnamelist, wname)

    " escape spaces and periods
    let wname = escape(wname, '\ \.')

    " build the menu
    execute 'menu '.a:topmenu.'.Open\ index.'.wname.
          \ ' :call vimwiki#base#goto_index('.(idx+1).')<CR>'
    execute 'menu '.a:topmenu.'.Open/Create\ diary\ note.'.wname.
          \ ' :call vimwiki#diary#make_note('.(idx+1).')<CR>'
  endfor
endfunction


" Build global table menu (GUI)
function! s:build_table_menu(topmenu) abort
  exe 'menu '.a:topmenu.'.-Sep- :'
  exe 'menu '.a:topmenu.'.Table.Create\ (enter\ cols\ rows) :VimwikiTable '
  exe 'nmenu '.a:topmenu.'.Table.Format<tab>gqq gqq'
  exe 'nmenu '.a:topmenu.'.Table.Move\ column\ left<tab><A-Left> :VimwikiTableMoveColumnLeft<CR>'
  exe 'nmenu '.a:topmenu.
        \ '.Table.Move\ column\ right<tab><A-Right> :VimwikiTableMoveColumnRight<CR>'
  exe 'nmenu disable '.a:topmenu.'.Table'
endfunction


" Build Menus now
if !empty(vimwiki#vars#get_global('menu'))
  call s:build_menu(vimwiki#vars#get_global('menu'))
  call s:build_table_menu(vimwiki#vars#get_global('menu'))
endif


" Hook for calendar.vim
if vimwiki#vars#get_global('use_calendar')
  let g:calendar_action = 'vimwiki#diary#calendar_action'
  let g:calendar_sign = 'vimwiki#diary#calendar_sign'
endif


" Restore peace in the galaxy
let &cpoptions = s:old_cpo
