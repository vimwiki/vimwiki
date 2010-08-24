" vim:tabstop=2:shiftwidth=2:expandtab:foldmethod=marker:textwidth=79
" Vimwiki filetype plugin file
" Author: Maxim Kim <habamax@gmail.com>
" Home: http://code.google.com/p/vimwiki/

if exists("b:did_ftplugin")
  finish
endif
let b:did_ftplugin = 1  " Don't load another plugin for this buffer

" UNDO list {{{
" Reset the following options to undo this plugin.
let b:undo_ftplugin = "setlocal ".
      \ "suffixesadd< isfname< comments< ".
      \ "autowriteall< ".
      \ "formatoptions< foldtext< ".
      \ "foldmethod< foldexpr< commentstring< "
" UNDO }}}

" MISC STUFF {{{

setlocal autowriteall
setlocal commentstring=<!--%s-->

if g:vimwiki_conceallevel && exists("+conceallevel")
  let &conceallevel = g:vimwiki_conceallevel
endif

" MISC }}}

" GOTO FILE: gf {{{
execute 'setlocal suffixesadd='.VimwikiGet('ext')
setlocal isfname-=[,]
" gf}}}

" Autocreate list items {{{
" for list items, and list items with checkboxes
if VimwikiGet('syntax') == 'default'
  setl comments=b:*,b:#,b:-
  setl formatlistpat=^\\s*[*#-]\\s*
else
  setl comments=n:*,n:#
endif
setlocal formatoptions=tnro

if !empty(&langmap)
  " Valid only if langmap is a comma separated pairs of chars
  let l_o = matchstr(&langmap, '\C,\zs.\zeo,')
  if l_o
    exe 'nnoremap <buffer> '.l_o.' :call vimwiki_lst#kbd_oO("o")<CR>a'
  endif

  let l_O = matchstr(&langmap, '\C,\zs.\zeO,')
  if l_O
    exe 'nnoremap <buffer> '.l_O.' :call vimwiki_lst#kbd_oO("O")<CR>a'
  endif
endif

" COMMENTS }}}

" FOLDING for headers and list items using expr fold method. {{{
function! VimwikiFoldLevel(lnum) "{{{
  let line = getline(a:lnum)

  " Header folding...
  if line =~ g:vimwiki_rxHeader
    let n = vimwiki#count_first_sym(line)
    return '>'.n
  endif

  if g:vimwiki_fold_trailing_empty_lines == 0
    if line =~ '^\s*$'
      let nnline = getline(nextnonblank(a:lnum + 1))
      if nnline =~ g:vimwiki_rxHeader
        let n = vimwiki#count_first_sym(nnline)
        return '<'.n
      endif
    endif
  endif

  " List item folding...
  if g:vimwiki_fold_lists
    let base_level = s:get_base_level(a:lnum)

    let rx_list_item = '\('.
          \ g:vimwiki_rxListBullet.'\|'.g:vimwiki_rxListNumber.
          \ '\)'


    if line =~ rx_list_item
      let [nnum, nline] = s:find_forward(rx_list_item, a:lnum)
      let level = s:get_li_level(a:lnum)
      let leveln = s:get_li_level(nnum)
      let adj = s:get_li_level(s:get_start_list(rx_list_item, a:lnum))

      if leveln > level
        return ">".(base_level+leveln-adj)
      else
        return (base_level+level-adj)
      endif
    else
      " process multilined list items
      let [pnum, pline] = s:find_backward(rx_list_item, a:lnum)
      if pline =~ rx_list_item
        if indent(a:lnum) > indent(pnum)
          let level = s:get_li_level(pnum)
          let adj = s:get_li_level(s:get_start_list(rx_list_item, pnum))

          let [nnum, nline] = s:find_forward(rx_list_item, a:lnum)
          if nline =~ rx_list_item
            let leveln = s:get_li_level(nnum)
            if leveln > level
              return (base_level+leveln-adj)
            endif
          endif

          return (base_level+level-adj)
        endif
      endif
    endif

    return base_level
  endif

  return -1
endfunction "}}}

function! s:get_base_level(lnum) "{{{
  let lnum = a:lnum - 1
  while lnum > 0
    if getline(lnum) =~ g:vimwiki_rxHeader
      return vimwiki#count_first_sym(getline(lnum))
    endif
    let lnum -= 1
  endwhile
  return 0
endfunction "}}}

function! s:find_forward(rx_item, lnum) "{{{
  let lnum = a:lnum + 1

  while lnum <= line('$')
    let line = getline(lnum)
    if line =~ a:rx_item
          \ || line =~ '^\S'
          \ || line =~ g:vimwiki_rxHeader
      break
    endif
    let lnum += 1
  endwhile

  return [lnum, getline(lnum)]
endfunction "}}}

function! s:find_backward(rx_item, lnum) "{{{
  let lnum = a:lnum - 1

  while lnum > 1
    let line = getline(lnum)
    if line =~ a:rx_item
          \ || line =~ '^\S'
      break
    endif
    let lnum -= 1
  endwhile

  return [lnum, getline(lnum)]
endfunction "}}}

function! s:get_li_level(lnum) "{{{
  if VimwikiGet('syntax') == 'media'
    let level = vimwiki#count_first_sym(getline(a:lnum))
  else
    let level = (indent(a:lnum) / &sw)
  endif
  return level
endfunction "}}}

function! s:get_start_list(rx_item, lnum) "{{{
  let lnum = a:lnum
  while lnum >= 1
    let line = getline(lnum)
    if line !~ a:rx_item && line =~ '^\S'
      return nextnonblank(lnum + 1)
    endif
    let lnum -= 1
  endwhile
  return 0
endfunction "}}}

function! VimwikiFoldText() "{{{
  let line = substitute(getline(v:foldstart), '\t',
        \ repeat(' ', &tabstop), 'g')
  return line.' ['.(v:foldend - v:foldstart).']'
endfunction "}}}

" FOLDING }}}

" COMMANDS {{{
command! -buffer Vimwiki2HTML
      \ call vimwiki_html#Wiki2HTML(expand(VimwikiGet('path_html')),
      \                             expand('%'))
command! -buffer VimwikiAll2HTML
      \ call vimwiki_html#WikiAll2HTML(expand(VimwikiGet('path_html')))

command! -buffer VimwikiNextLink call vimwiki#find_next_link()
command! -buffer VimwikiPrevLink call vimwiki#find_prev_link()
command! -buffer VimwikiDeleteLink call vimwiki#delete_link()
command! -buffer VimwikiRenameLink call vimwiki#rename_link()
command! -buffer VimwikiFollowLink call vimwiki#follow_link('nosplit')
command! -buffer VimwikiGoBackLink call vimwiki#go_back_link()
command! -buffer VimwikiSplitLink call vimwiki#follow_link('split')
command! -buffer VimwikiVSplitLink call vimwiki#follow_link('vsplit')

command! -buffer -range VimwikiToggleListItem call vimwiki_lst#ToggleListItem(<line1>, <line2>)

command! -buffer VimwikiGenerateLinks call vimwiki#generate_links()

exe 'command! -buffer -nargs=* VimwikiSearch vimgrep <args> '.
      \ escape(VimwikiGet('path').'**/*'.VimwikiGet('ext'), ' ')

exe 'command! -buffer -nargs=* VWS vimgrep <args> '.
      \ escape(VimwikiGet('path').'**/*'.VimwikiGet('ext'), ' ')

command! -buffer -nargs=1 VimwikiGoto call vimwiki#goto("<args>")

" table commands
command! -buffer -nargs=* VimwikiTable call vimwiki_tbl#create(<f-args>)
command! -buffer VimwikiTableAlignQ call vimwiki_tbl#align_or_cmd('gqq')
command! -buffer VimwikiTableAlignW call vimwiki_tbl#align_or_cmd('gww')
command! -buffer VimwikiTableMoveColumnLeft call vimwiki_tbl#move_column_left()
command! -buffer VimwikiTableMoveColumnRight call vimwiki_tbl#move_column_right()

" diary commands
command! -buffer VimwikiDiaryNextDay call vimwiki_diary#goto_next_day()
command! -buffer VimwikiDiaryPrevDay call vimwiki_diary#goto_prev_day()

" COMMANDS }}}

" KEYBINDINGS {{{
if g:vimwiki_use_mouse
  nmap <buffer> <S-LeftMouse> <NOP>
  nmap <buffer> <C-LeftMouse> <NOP>
  noremap <silent><buffer> <2-LeftMouse> :VimwikiFollowLink<CR>
  noremap <silent><buffer> <S-2-LeftMouse> <LeftMouse>:VimwikiSplitLink<CR>
  noremap <silent><buffer> <C-2-LeftMouse> <LeftMouse>:VimwikiVSplitLink<CR>
  noremap <silent><buffer> <RightMouse><LeftMouse> :VimwikiGoBackLink<CR>
endif

if !hasmapto('<Plug>VimwikiFollowLink')
  nmap <silent><buffer> <CR> <Plug>VimwikiFollowLink
endif
noremap <silent><script><buffer>
      \ <Plug>VimwikiFollowLink :VimwikiFollowLink<CR>

if !hasmapto('<Plug>VimwikiSplitLink')
  nmap <silent><buffer> <S-CR> <Plug>VimwikiSplitLink
endif
noremap <silent><script><buffer>
      \ <Plug>VimwikiSplitLink :VimwikiSplitLink<CR>

if !hasmapto('<Plug>VimwikiVSplitLink')
  nmap <silent><buffer> <C-CR> <Plug>VimwikiVSplitLink
endif
noremap <silent><script><buffer>
      \ <Plug>VimwikiVSplitLink :VimwikiVSplitLink<CR>

if !hasmapto('<Plug>VimwikiGoBackLink')
  nmap <silent><buffer> <BS> <Plug>VimwikiGoBackLink
endif
noremap <silent><script><buffer>
      \ <Plug>VimwikiGoBackLink :VimwikiGoBackLink<CR>

if !hasmapto('<Plug>VimwikiNextLink')
  nmap <silent><buffer> <TAB> <Plug>VimwikiNextLink
endif
noremap <silent><script><buffer>
      \ <Plug>VimwikiNextLink :VimwikiNextLink<CR>

if !hasmapto('<Plug>VimwikiPrevLink')
  nmap <silent><buffer> <S-TAB> <Plug>VimwikiPrevLink
endif
noremap <silent><script><buffer>
      \ <Plug>VimwikiPrevLink :VimwikiPrevLink<CR>

if !hasmapto('<Plug>VimwikiDeleteLink')
  nmap <silent><buffer> <Leader>wd <Plug>VimwikiDeleteLink
endif
noremap <silent><script><buffer>
      \ <Plug>VimwikiDeleteLink :VimwikiDeleteLink<CR>

if !hasmapto('<Plug>VimwikiRenameLink')
  nmap <silent><buffer> <Leader>wr <Plug>VimwikiRenameLink
endif
noremap <silent><script><buffer>
      \ <Plug>VimwikiRenameLink :VimwikiRenameLink<CR>

if !hasmapto('<Plug>VimwikiToggleListItem')
  nmap <silent><buffer> <C-Space> <Plug>VimwikiToggleListItem
  vmap <silent><buffer> <C-Space> <Plug>VimwikiToggleListItem
  if has("unix")
    nmap <silent><buffer> <C-@> <Plug>VimwikiToggleListItem
  endif
endif
noremap <silent><script><buffer>
      \ <Plug>VimwikiToggleListItem :VimwikiToggleListItem<CR>

if !hasmapto('<Plug>VimwikiDiaryNextDay')
  nmap <silent><buffer> <C-Down> <Plug>VimwikiDiaryNextDay
endif
noremap <silent><script><buffer>
      \ <Plug>VimwikiDiaryNextDay :VimwikiDiaryNextDay<CR>

if !hasmapto('<Plug>VimwikiDiaryPrevDay')
  nmap <silent><buffer> <C-Up> <Plug>VimwikiDiaryPrevDay
endif
noremap <silent><script><buffer>
      \ <Plug>VimwikiDiaryPrevDay :VimwikiDiaryPrevDay<CR>

function! s:CR() "{{{
  let res = vimwiki_lst#kbd_cr()
  if res == "\<CR>" && g:vimwiki_table_auto_fmt
    let res = vimwiki_tbl#kbd_cr()
  endif
  return res
endfunction "}}}

" List and Table <CR> mapping
inoremap <buffer> <expr> <CR> <SID>CR()

" List mappings
nnoremap <buffer> o :call vimwiki_lst#kbd_oO('o')<CR>a
nnoremap <buffer> O :call vimwiki_lst#kbd_oO('O')<CR>a

" Table mappings
if g:vimwiki_table_auto_fmt
  inoremap <expr> <buffer> <Tab> vimwiki_tbl#kbd_tab()
  inoremap <expr> <buffer> <S-Tab> vimwiki_tbl#kbd_shift_tab()
endif

nnoremap <buffer> gqq :VimwikiTableAlignQ<CR>
nnoremap <buffer> gww :VimwikiTableAlignW<CR>
nnoremap <buffer> <A-Left> :VimwikiTableMoveColumnLeft<CR>
nnoremap <buffer> <A-Right> :VimwikiTableMoveColumnRight<CR>

" Misc mappings
inoremap <buffer> <S-CR> <br /><CR>


" Text objects {{{
onoremap <silent><buffer> ah :<C-U>call vimwiki#TO_header(0, 0)<CR>
vnoremap <silent><buffer> ah :<C-U>call vimwiki#TO_header(0, 1)<CR>

onoremap <silent><buffer> ih :<C-U>call vimwiki#TO_header(1, 0)<CR>
vnoremap <silent><buffer> ih :<C-U>call vimwiki#TO_header(1, 1)<CR>

onoremap <silent><buffer> a\ :<C-U>call vimwiki#TO_table_cell(0, 0)<CR>
vnoremap <silent><buffer> a\ :<C-U>call vimwiki#TO_table_cell(0, 1)<CR>

onoremap <silent><buffer> i\ :<C-U>call vimwiki#TO_table_cell(1, 0)<CR>
vnoremap <silent><buffer> i\ :<C-U>call vimwiki#TO_table_cell(1, 1)<CR>

onoremap <silent><buffer> ac :<C-U>call vimwiki#TO_table_col(0, 0)<CR>
vnoremap <silent><buffer> ac :<C-U>call vimwiki#TO_table_col(0, 1)<CR>

onoremap <silent><buffer> ic :<C-U>call vimwiki#TO_table_col(1, 0)<CR>
vnoremap <silent><buffer> ic :<C-U>call vimwiki#TO_table_col(1, 1)<CR>

noremap <silent><buffer> = :call vimwiki#AddHeaderLevel()<CR>
noremap <silent><buffer> - :call vimwiki#RemoveHeaderLevel()<CR>

" }}}

" KEYBINDINGS }}}

" AUTOCOMMANDS {{{
if VimwikiGet('auto_export')
  " Automatically generate HTML on page write.
  augroup vimwiki
    au BufWritePost <buffer> Vimwiki2HTML
  augroup END
endif

" AUTOCOMMANDS }}}
