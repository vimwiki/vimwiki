" vim:tabstop=2:shiftwidth=2:expandtab:foldmethod=marker:textwidth=79
" Vimwiki autoload plugin file
" Desc: Handle diary notes
" Home: https://github.com/vimwiki/vimwiki/

" Load only once {{{
if exists("g:loaded_vimwiki_diary_auto") || &cp
  finish
endif
let g:loaded_vimwiki_diary_auto = 1
"}}}

let s:vimwiki_max_scan_for_caption = 5

" Helpers {{{
function! s:prefix_zero(num) "{{{
  if a:num < 10
    return '0'.a:num
  endif
  return a:num
endfunction "}}}

function! s:get_date_link(fmt) "{{{
  return strftime(a:fmt)
endfunction "}}}

function! s:diary_path(...) "{{{
  let idx = a:0 == 0 ? g:vimwiki_current_idx : a:1
  return VimwikiGet('path', idx).VimwikiGet('diary_rel_path', idx)
endfunction "}}}

function! s:diary_index(...) "{{{
  let idx = a:0 == 0 ? g:vimwiki_current_idx : a:1
  return s:diary_path(idx).VimwikiGet('diary_index', idx).VimwikiGet('ext', idx)
endfunction "}}}

function! s:diary_date_link(...) "{{{
  let idx = a:0 == 0 ? g:vimwiki_current_idx : a:1
  return s:get_date_link(VimwikiGet('diary_link_fmt', idx))
endfunction "}}}

function! s:get_position_links(link) "{{{
  let idx = -1
  let links = []
  if a:link =~# '^\d\{4}-\d\d-\d\d'
    let links = map(s:get_diary_files(), 'fnamemodify(v:val, ":t:r")')
    " include 'today' into links
    if index(links, s:diary_date_link()) == -1
      call add(links, s:diary_date_link())
    endif
    call sort(links)
    let idx = index(links, a:link)
  endif
  return [idx, links]
endfunction "}}}

fun! s:get_month_name(month) "{{{
  return g:vimwiki_diary_months[str2nr(a:month)]
endfun "}}}

" Helpers }}}

" Diary index stuff {{{
fun! s:read_captions(files) "{{{
  let result = {}
  for fl in a:files
    " remove paths and extensions
    let fl_key = substitute(fnamemodify(fl, ':t'), VimwikiGet('ext').'$', '', '')

    if filereadable(fl)
      for line in readfile(fl, '', s:vimwiki_max_scan_for_caption)
        if line =~# g:vimwiki_rxHeader && !has_key(result, fl_key)
          let result[fl_key] = vimwiki#u#trim(matchstr(line, g:vimwiki_rxHeader))
        endif
      endfor
    endif

    if !has_key(result, fl_key)
      let result[fl_key] = ''
    endif

  endfor
  return result
endfun "}}}

fun! s:get_diary_files() "{{{
  let rx = '^\d\{4}-\d\d-\d\d'
  let s_files = glob(VimwikiGet('path').VimwikiGet('diary_rel_path').'*'.VimwikiGet('ext'))
  let files = split(s_files, '\n')
  call filter(files, 'fnamemodify(v:val, ":t") =~# "'.escape(rx, '\').'"')

  " remove backup files (.wiki~)
  call filter(files, 'v:val !~# ''.*\~$''')

  return files
endfun "}}}

fun! s:group_links(links) "{{{
  let result = {}
  let p_year = 0
  let p_month = 0
  for fl in sort(keys(a:links))
    let year = strpart(fl, 0, 4)
    let month = strpart(fl, 5, 2)
    if p_year != year
      let result[year] = {}
      let p_month = 0
    endif
    if p_month != month
      let result[year][month] = {}
    endif
    let result[year][month][fl] = a:links[fl]
    let p_year = year
    let p_month = month
  endfor
  return result
endfun "}}}

function! s:sort(lst) "{{{
  if VimwikiGet("diary_sort") ==? 'desc'
    return reverse(sort(a:lst))
  else
    return sort(a:lst)
  endif
endfunction "}}}

function! s:format_diary() "{{{
  let result = []


  let links_with_captions = s:read_captions(s:get_diary_files())
  let g_files = s:group_links(links_with_captions)

  for year in s:sort(keys(g_files))
    call add(result, '')
    call add(result, substitute(g:vimwiki_rxH2_Template, '__Header__', year , ''))

    for month in s:sort(keys(g_files[year]))
      call add(result, '')
      call add(result, substitute(g:vimwiki_rxH3_Template, '__Header__', s:get_month_name(month), ''))

      for [fl, cap] in s:sort(items(g_files[year][month]))
        if empty(cap)
          let entry = substitute(g:vimwiki_WikiLinkTemplate1, '__LinkUrl__', fl, '')
          let entry = substitute(entry, '__LinkDescription__', cap, '')
          call add(result, repeat(' ', &sw).'* '.entry)
        else
          let entry = substitute(g:vimwiki_WikiLinkTemplate2, '__LinkUrl__', fl, '')
          let entry = substitute(entry, '__LinkDescription__', cap, '')
          call add(result, repeat(' ', &sw).'* '.entry)
        endif
      endfor

    endfor
  endfor

  return result
endfunction "}}}

" Diary index stuff }}}

function! vimwiki#diary#make_note(wnum, ...) "{{{
  if a:wnum > len(g:vimwiki_list)
    echomsg 'Vimwiki Error: Wiki '.a:wnum.' is not registered in g:vimwiki_list!'
    return
  endif

  " TODO: refactor it. base#goto_index uses the same
  if a:wnum > 0
    let idx = a:wnum - 1
  else
    let idx = 0
  endif

  call vimwiki#path#mkdir(VimwikiGet('path', idx).VimwikiGet('diary_rel_path', idx))

  let cmd = 'edit'
  if a:0
    if a:1 == 1
      let cmd = 'tabedit'
    elseif a:1 == 2
      let cmd = 'split'
    elseif a:1 == 3
      let cmd = 'vsplit'
    endif
  endif
  if a:0>1
    let link = 'diary:'.a:2
  else
    let link = 'diary:'.s:diary_date_link(idx)
  endif

  call vimwiki#base#open_link(cmd, link, s:diary_index(idx))
  call vimwiki#base#setup_buffer_state(idx)
endfunction "}}}

function! vimwiki#diary#goto_diary_index(wnum) "{{{
  if a:wnum > len(g:vimwiki_list)
    echomsg 'Vimwiki Error: Wiki '.a:wnum.' is not registered in g:vimwiki_list!'
    return
  endif

  " TODO: refactor it. base#goto_index uses the same
  if a:wnum > 0
    let idx = a:wnum - 1
  else
    let idx = 0
  endif

  call vimwiki#base#edit_file('e', s:diary_index(idx), '')
  call vimwiki#base#setup_buffer_state(idx)
endfunction "}}}

function! vimwiki#diary#goto_next_day() "{{{
  let link = ''
  let [idx, links] = s:get_position_links(expand('%:t:r'))

  if idx == (len(links) - 1)
    return
  endif

  if idx != -1 && idx < len(links) - 1
    let link = 'diary:'.links[idx+1]
  else
    " goto today
    let link = 'diary:'.s:diary_date_link()
  endif

  if len(link)
    call vimwiki#base#open_link(':e ', link)
  endif
endfunction "}}}

function! vimwiki#diary#goto_prev_day() "{{{
  let link = ''
  let [idx, links] = s:get_position_links(expand('%:t:r'))

  if idx == 0
    return
  endif

  if idx > 0
    let link = 'diary:'.links[idx-1]
  else
    " goto today
    let link = 'diary:'.s:diary_date_link()
  endif

  if len(link)
    call vimwiki#base#open_link(':e ', link)
  endif
endfunction "}}}

function! vimwiki#diary#generate_diary_section() "{{{
  let current_file = vimwiki#path#path_norm(expand("%:p"))
  let diary_file = vimwiki#path#path_norm(s:diary_index())
  if vimwiki#path#is_equal(current_file, diary_file)
    let content_rx = '^\%(\s*\* \)\|\%(^\s*$\)\|\%('.g:vimwiki_rxHeader.'\)'
    call vimwiki#base#update_listing_in_buffer(s:format_diary(),
          \ VimwikiGet('diary_header'), content_rx, line('$')+1, 1)
  else
    echomsg 'Vimwiki Error: You can generate diary links only in a diary index page!'
  endif
endfunction "}}}

" Calendar.vim {{{
" Callback function.
function! vimwiki#diary#calendar_action(day, month, year, week, dir) "{{{
  let day = s:prefix_zero(a:day)
  let month = s:prefix_zero(a:month)

  let link = a:year.'-'.month.'-'.day
  if winnr('#') == 0
    if a:dir ==? 'V'
      vsplit
    else
      split
    endif
  else
    wincmd p
    if !&hidden && &modified
      new
    endif
  endif

  " XXX: Well, +1 is for inconsistent index basing...
  call vimwiki#diary#make_note(g:vimwiki_current_idx+1, 0, link)
endfunction "}}}

" Sign function.
function vimwiki#diary#calendar_sign(day, month, year) "{{{
  let day = s:prefix_zero(a:day)
  let month = s:prefix_zero(a:month)
  let sfile = VimwikiGet('path').VimwikiGet('diary_rel_path').
        \ a:year.'-'.month.'-'.day.VimwikiGet('ext')
  return filereadable(expand(sfile))
endfunction "}}}

" Calendar.vim }}}

