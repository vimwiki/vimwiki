" vim:tabstop=2:shiftwidth=2:expandtab:textwidth=99
" Vimwiki autoload plugin file
" Description: Handle diary notes
" Home: https://github.com/vimwiki/vimwiki/


if exists("g:loaded_vimwiki_diary_auto") || &cp
  finish
endif
let g:loaded_vimwiki_diary_auto = 1


let s:vimwiki_max_scan_for_caption = 5


function! s:prefix_zero(num)
  if a:num < 10
    return '0'.a:num
  endif
  return a:num
endfunction


function! s:diary_path(...)
  let idx = a:0 == 0 ? vimwiki#vars#get_bufferlocal('wiki_nr') : a:1
  return vimwiki#vars#get_wikilocal('path', idx).vimwiki#vars#get_wikilocal('diary_rel_path', idx)
endfunction


function! s:diary_index(...)
  let idx = a:0 == 0 ? vimwiki#vars#get_bufferlocal('wiki_nr') : a:1
  return s:diary_path(idx).vimwiki#vars#get_wikilocal('diary_index', idx).
        \ vimwiki#vars#get_wikilocal('ext', idx)
endfunction


function! vimwiki#diary#diary_date_link(...)
  if a:0
    return strftime('%Y-%m-%d', a:1)
  else
    return strftime('%Y-%m-%d')
  endif
endfunction


function! s:get_position_links(link)
  let idx = -1
  let links = []
  if a:link =~# '^\d\{4}-\d\d-\d\d'
    let links = map(s:get_diary_files(), 'fnamemodify(v:val, ":t:r")')
    " include 'today' into links
    if index(links, vimwiki#diary#diary_date_link()) == -1
      call add(links, vimwiki#diary#diary_date_link())
    endif
    call sort(links)
    let idx = index(links, a:link)
  endif
  return [idx, links]
endfunction


function! s:get_month_name(month)
  return vimwiki#vars#get_global('diary_months')[str2nr(a:month)]
endfunction


function! s:read_captions(files)
  let result = {}
  let rx_header = vimwiki#vars#get_syntaxlocal('rxHeader')
  for fl in a:files
    " remove paths and extensions
    let fl_key = substitute(fnamemodify(fl, ':t'), vimwiki#vars#get_wikilocal('ext').'$', '', '')

    if filereadable(fl)
      for line in readfile(fl, '', s:vimwiki_max_scan_for_caption)
        if line =~# rx_header && !has_key(result, fl_key)
          let result[fl_key] = vimwiki#u#trim(matchstr(line, rx_header))
        endif
      endfor
    endif

    if !has_key(result, fl_key)
      let result[fl_key] = ''
    endif

  endfor
  return result
endfunction


function! s:get_diary_files()
  let rx = '^\d\{4}-\d\d-\d\d'
  let s_files = glob(vimwiki#vars#get_wikilocal('path').
        \ vimwiki#vars#get_wikilocal('diary_rel_path').'*'.vimwiki#vars#get_wikilocal('ext'))
  let files = split(s_files, '\n')
  call filter(files, 'fnamemodify(v:val, ":t") =~# "'.escape(rx, '\').'"')

  " remove backup files (.wiki~)
  call filter(files, 'v:val !~# ''.*\~$''')

  return files
endfunction


function! s:group_links(links)
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
endfunction


function! s:sort(lst)
  if vimwiki#vars#get_wikilocal('diary_sort') ==? 'desc'
    return reverse(sort(a:lst))
  else
    return sort(a:lst)
  endif
endfunction


function! s:format_diary()
  let result = []

  let links_with_captions = s:read_captions(s:get_diary_files())
  let g_files = s:group_links(links_with_captions)

  for year in s:sort(keys(g_files))
    call add(result, '')
    call add(result,
          \ substitute(vimwiki#vars#get_syntaxlocal('rxH2_Template'), '__Header__', year , ''))

    for month in s:sort(keys(g_files[year]))
      call add(result, '')
      call add(result, substitute(vimwiki#vars#get_syntaxlocal('rxH3_Template'),
            \ '__Header__', s:get_month_name(month), ''))

      for [fl, cap] in s:sort(items(g_files[year][month]))
        let link_tpl = vimwiki#vars#get_global('WikiLinkTemplate2')

        if vimwiki#vars#get_wikilocal('syntax') == 'markdown'
          let link_tpl = vimwiki#vars#get_syntaxlocal('Weblink1Template')

          if empty(cap) " When using markdown syntax, we should ensure we always have a link description.
            let cap = fl
          endif
        elseif empty(cap)
          let link_tpl = vimwiki#vars#get_global('WikiLinkTemplate1')
        endif

        let entry = substitute(link_tpl, '__LinkUrl__', fl, '')
        let entry = substitute(entry, '__LinkDescription__', cap, '')
        call add(result, repeat(' ', vimwiki#lst#get_list_margin()).'* '.entry)
      endfor

    endfor
  endfor

  return result
endfunction


" The given wiki number a:wnum is 1 for the first wiki, 2 for the second and so on. This is in
" contrast to most other places, where counting starts with 0. When a:wnum is 0, the current wiki
" is used.
function! vimwiki#diary#make_note(wnum, ...)
  if a:wnum == 0
    let wiki_nr = vimwiki#vars#get_bufferlocal('wiki_nr')
    if wiki_nr < 0  " this happens when e.g. VimwikiMakeDiaryNote was called outside a wiki buffer
      let wiki_nr = 0
    endif
  else
    let wiki_nr = a:wnum - 1
  endif

  if wiki_nr >= vimwiki#vars#number_of_wikis()
    echomsg 'Vimwiki Error: Wiki '.wiki_nr.' is not registered in g:vimwiki_list!'
    return
  endif

  " TODO: refactor it. base#goto_index uses the same

  call vimwiki#path#mkdir(vimwiki#vars#get_wikilocal('path', wiki_nr).
        \ vimwiki#vars#get_wikilocal('diary_rel_path', wiki_nr))

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
    let link = 'diary:'.vimwiki#diary#diary_date_link()
  endif

  call vimwiki#base#open_link(cmd, link, s:diary_index(wiki_nr))
endfunction


function! vimwiki#diary#goto_diary_index(wnum)
  if a:wnum > vimwiki#vars#number_of_wikis()
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

  if vimwiki#vars#get_wikilocal('auto_diary_index')
    call vimwiki#diary#generate_diary_section()
    write! " save changes
  endif
endfunction


function! vimwiki#diary#goto_next_day()
  let link = ''
  let [idx, links] = s:get_position_links(expand('%:t:r'))

  if idx == (len(links) - 1)
    return
  endif

  if idx != -1 && idx < len(links) - 1
    let link = 'diary:'.links[idx+1]
  else
    " goto today
    let link = 'diary:'.vimwiki#diary#diary_date_link()
  endif

  if len(link)
    call vimwiki#base#open_link(':e ', link)
  endif
endfunction


function! vimwiki#diary#goto_prev_day()
  let link = ''
  let [idx, links] = s:get_position_links(expand('%:t:r'))

  if idx == 0
    return
  endif

  if idx > 0
    let link = 'diary:'.links[idx-1]
  else
    " goto today
    let link = 'diary:'.vimwiki#diary#diary_date_link()
  endif

  if len(link)
    call vimwiki#base#open_link(':e ', link)
  endif
endfunction


function! vimwiki#diary#generate_diary_section()
  let current_file = vimwiki#path#path_norm(expand("%:p"))
  let diary_file = vimwiki#path#path_norm(s:diary_index())
  if vimwiki#path#is_equal(current_file, diary_file)
    let content_rx = '^\%(\s*\* \)\|\%(^\s*$\)\|\%('.vimwiki#vars#get_syntaxlocal('rxHeader').'\)'
    call vimwiki#base#update_listing_in_buffer(s:format_diary(),
          \ vimwiki#vars#get_wikilocal('diary_header'), content_rx, line('$')+1, 1)
  else
    echomsg 'Vimwiki Error: You can generate diary links only in a diary index page!'
  endif
endfunction


" Callback function for Calendar.vim
function! vimwiki#diary#calendar_action(day, month, year, week, dir)
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

  call vimwiki#diary#make_note(0, 0, link)
endfunction


function vimwiki#diary#calendar_sign(day, month, year)
  let day = s:prefix_zero(a:day)
  let month = s:prefix_zero(a:month)
  let sfile = vimwiki#vars#get_wikilocal('path').vimwiki#vars#get_wikilocal('diary_rel_path').
        \ a:year.'-'.month.'-'.day.vimwiki#vars#get_wikilocal('ext')
  return filereadable(expand(sfile))
endfunction

