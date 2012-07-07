" vim:tabstop=2:shiftwidth=2:expandtab:foldmethod=marker:textwidth=79
" Vimwiki autoload plugin file
" Desc: Handle diary notes
" Author: Maxim Kim <habamax@gmail.com>
" Home: http://code.google.com/p/vimwiki/

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

function! s:link_exists(lines, link) "{{{
  let link_exists = 0
  for line in a:lines
    if line =~ escape(a:link, '[]\')
      let link_exists = 1
      break
    endif
  endfor
  return link_exists
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
  if a:link =~ '^\d\{4}-\d\d-\d\d'
    let links = keys(s:get_diary_links())
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
    let fl_key = fnamemodify(fl, ':t:r')

    if filereadable(fl)
      for line in readfile(fl, '', s:vimwiki_max_scan_for_caption)
        if line =~ g:vimwiki_rxHeader && !has_key(result, fl_key)
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

fun! s:get_diary_links(...) "{{{
  let rx = '^\d\{4}-\d\d-\d\d'
  let s_files = glob(VimwikiGet('path').VimwikiGet('diary_rel_path').'*'.VimwikiGet('ext'))
  let files = split(s_files, '\n')
  call filter(files, 'fnamemodify(v:val, ":t") =~ "'.escape(rx, '\').'"')

  " remove backup files (.wiki~)
  call filter(files, 'v:val !~ ''.*\~$''')

  if a:0
    call add(files, a:1)
  endif
  let links_with_captions = s:read_captions(files)

  return links_with_captions
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

fun! s:sort(lst) "{{{
  if VimwikiGet("diary_sort") == 'desc'
    return reverse(sort(a:lst))
  else
    return sort(a:lst)
  endif
endfun "}}}

fun! s:format_diary(...) "{{{
  let result = []

  call add(result, substitute(g:vimwiki_rxH1_Template, '__Header__', VimwikiGet('diary_header'), ''))

  if a:0
    let g_files = s:group_links(s:get_diary_links(a:1))
  else
    let g_files = s:group_links(s:get_diary_links())
  endif

  " for year in s:rev(sort(keys(g_files)))
  for year in s:sort(keys(g_files))
    call add(result, '')
    call add(result, substitute(g:vimwiki_rxH2_Template, '__Header__', year , ''))

    " for month in s:rev(sort(keys(g_files[year])))
    for month in s:sort(keys(g_files[year]))
      call add(result, '')
      call add(result, substitute(g:vimwiki_rxH3_Template, '__Header__', s:get_month_name(month), ''))

      " for [fl, cap] in s:rev(sort(items(g_files[year][month])))
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
  call add(result, '')

  return result
endfun "}}}

function! s:delete_diary_section() "{{{
  " remove diary section
  let old_pos = getpos('.')
  let ln_start = -1
  let ln_end = -1
  call cursor(1, 1)
  if search(substitute(g:vimwiki_rxH1_Template, '__Header__', VimwikiGet('diary_header'), ''), 'Wc')
    let ln_start = line('.')
    if search(g:vimwiki_rxH1, 'W')
      let ln_end = line('.') - 1
    else
      let ln_end = line('$')
    endif
  endif

  if ln_start < 0 || ln_end < 0
    call setpos('.', old_pos)
    return
  endif

  if !&readonly
    exe ln_start.",".ln_end."delete _"
  endif

  call setpos('.', old_pos)
endfunction "}}}

function! s:insert_diary_section() "{{{
  if !&readonly
    let ln = line('.')
    call append(ln, s:format_diary())
    if ln == 1 && getline(ln) == ''
      1,1delete
    endif
  endif
endfunction "}}}

" Diary index stuff }}}

function! vimwiki#diary#make_note(wnum, ...) "{{{
  if a:wnum > len(g:vimwiki_list)
    echom "vimwiki: Wiki ".a:wnum." is not registered in g:vimwiki_list!"
    return
  endif

  " TODO: refactor it. base#goto_index uses the same
  if a:wnum > 0
    let idx = a:wnum - 1
  else
    let idx = 0
  endif

  call vimwiki#base#validate_wiki_options(idx)
  call vimwiki#base#mkdir(VimwikiGet('path', idx).VimwikiGet('diary_rel_path', idx))

  if a:0 && a:1 == 1
    let cmd = 'tabedit'
  else
    let cmd = 'edit'
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
    echom "vimwiki: Wiki ".a:wnum." is not registered in g:vimwiki_list!"
    return
  endif

  " TODO: refactor it. base#goto_index uses the same
  if a:wnum > 0
    let idx = a:wnum - 1
  else
    let idx = 0
  endif

  call vimwiki#base#validate_wiki_options(idx)
  call vimwiki#base#edit_file('e', s:diary_index(idx))
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
  let current_file = vimwiki#u#path_norm(expand("%:p"))
  let diary_file = vimwiki#u#path_norm(s:diary_index())
  if  current_file == diary_file
    call s:delete_diary_section()
    call s:insert_diary_section()
  else
    echom "vimwiki: You can generate diary links only in a diary index page!"
  endif
endfunction "}}}

" Calendar.vim {{{
" Callback function.
function! vimwiki#diary#calendar_action(day, month, year, week, dir) "{{{
  let day = s:prefix_zero(a:day)
  let month = s:prefix_zero(a:month)

  let link = a:year.'-'.month.'-'.day
  if winnr('#') == 0
    if a:dir == 'V'
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

  " Create diary note for a selected date in default wiki.
  call vimwiki#diary#make_note(1, 0, link)
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

