" vim:tabstop=2:shiftwidth=2:expandtab:textwidth=99
" Vimwiki autoload plugin file
" Description: Handle diary notes
" Home: https://github.com/vimwiki/vimwiki/


" Clause: load only once
if exists('g:loaded_vimwiki_diary_auto') || &compatible
  finish
endif
let g:loaded_vimwiki_diary_auto = 1


function! s:prefix_zero(num) abort
  " Add zero prefix to a number
  if a:num < 10
    return '0'.a:num
  endif
  return a:num
endfunction


function! s:diary_path(...) abort
  " Return: diary directory path <String>
  let idx = a:0 == 0 ? vimwiki#vars#get_bufferlocal('wiki_nr') : a:1
  return vimwiki#vars#get_wikilocal('path', idx).vimwiki#vars#get_wikilocal('diary_rel_path', idx)
endfunction


function! s:diary_index(...) abort
  " Return: diary index file path <String>
  let idx = a:0 == 0 ? vimwiki#vars#get_bufferlocal('wiki_nr') : a:1
  return s:diary_path(idx).vimwiki#vars#get_wikilocal('diary_index', idx).
        \ vimwiki#vars#get_wikilocal('ext', idx)
endfunction


function! vimwiki#diary#diary_date_link(...) abort
  " Return: <String> date

  let wiki_nr = vimwiki#vars#get_bufferlocal('wiki_nr')
  if wiki_nr < 0  " this happens when called outside a wiki buffer
    let wiki_nr = 0
  endif

  if wiki_nr >= vimwiki#vars#number_of_wikis()
    call vimwiki#u#error('Wiki '.wiki_nr.' is not registered in g:vimwiki_list!')
    return
  endif

  if a:0
    let l:timestamp = a:1
  else
    let l:timestamp = localtime()
  endif

  let l:delta_periods = 0
  if a:0 > 1
    let l:delta_periods = a:2
  endif

  let l:day_s = 60*60*24

  let l:weekday_number = {
        \ 'monday': 1, 'tuesday': 2,
        \ 'wednesday': 3, 'thursday': 4,
        \ 'friday': 5, 'saturday': 6,
        \ 'sunday': 0}

  let l:frequency = vimwiki#vars#get_wikilocal('diary_frequency', wiki_nr)

  if l:frequency ==? 'weekly'
    let l:start_week_day = vimwiki#vars#get_wikilocal('diary_start_week_day', wiki_nr)
    let l:weekday_num = str2nr(strftime('%w', l:timestamp))
    let l:days_to_end_of_week = (7-l:weekday_number[l:start_week_day]+weekday_num) % 7
    let l:computed_timestamp = l:timestamp
          \ + 7*l:day_s*l:delta_periods
          \ - l:day_s*l:days_to_end_of_week

  elseif l:frequency ==? 'monthly'
    let l:day_of_month = str2nr(strftime('%d', l:timestamp))
    let l:beginning_of_month = l:timestamp - (l:day_of_month - 1)*l:day_s
    let l:middle_of_month = l:beginning_of_month + 15*l:day_s
    let l:middle_of_computed_month = l:middle_of_month + float2nr(30.5*l:day_s*l:delta_periods)
    let l:day_of_computed_month = str2nr(strftime('%d', l:middle_of_computed_month)) - 1
    let l:computed_timestamp = l:middle_of_computed_month - l:day_of_computed_month*l:day_s

  elseif l:frequency ==? 'yearly'
    let l:day_of_year = str2nr(strftime('%j', l:timestamp))
    let l:beginning_of_year = l:timestamp - (l:day_of_year - 1)*l:day_s
    let l:middle_of_year = l:beginning_of_year + float2nr(365.25/2*l:day_s)
    let l:middle_of_computed_year = l:middle_of_year + float2nr(365.25*l:day_s*l:delta_periods)
    let l:day_of_computed_year = str2nr(strftime('%j', l:middle_of_computed_year)) - 1
    let l:computed_timestamp = l:middle_of_computed_year - l:day_of_computed_year*l:day_s

  else "daily
    let l:computed_timestamp = localtime() + l:delta_periods*l:day_s
  endif

  return strftime('%Y-%m-%d', l:computed_timestamp)

endfunction


function! s:get_position_links(link) abort
  " Return: <int:index, list:links>
  let idx = -1
  let links = []
  if a:link =~# '^\d\{4}-\d\d-\d\d'
    let links = map(vimwiki#diary#get_diary_files(), 'fnamemodify(v:val, ":t:r")')
    " include 'today' into links
    if index(links, vimwiki#diary#diary_date_link()) == -1
      call add(links, vimwiki#diary#diary_date_link())
    endif
    call sort(links)
    let idx = index(links, a:link)
  endif
  return [idx, links]
endfunction


function! s:get_month_name(month) abort
  " Convert month: number -> name
  return vimwiki#vars#get_global('diary_months')[str2nr(a:month)]
endfunction


function! s:get_first_header(fl) abort
  " Get the first header in the file within the first s:vimwiki_max_scan_for_caption lines.
  let header_rx = vimwiki#vars#get_syntaxlocal('rxHeader')

  for line in readfile(a:fl, '', g:vimwiki_max_scan_for_caption)
    if line =~# header_rx
      return vimwiki#u#trim(matchstr(line, header_rx))
    endif
  endfor
  return ''
endfunction


function! s:get_all_headers(fl, maxlevel) abort
  " Get a list of all headers in a file up to a given level.
  " Return: list whose elements are pairs [level, title]
  let headers_rx = {}
  for i in range(1, a:maxlevel)
    let headers_rx[i] = vimwiki#vars#get_syntaxlocal('rxH'.i.'_Text')
  endfor

  let headers = []
  for line in readfile(a:fl, '')
    for [i, header_rx] in items(headers_rx)
      if line =~# header_rx
        call add(headers, [i, vimwiki#u#trim(matchstr(line, header_rx))])
        break
      endif
    endfor
  endfor
  return headers
endfunction

function! s:count_headers_level_less_equal(headers, maxlevel) abort
  " Count headers with level <=  maxlevel in a list of [level, title] pairs.
  let l:count = 0
  for [header_level, _] in a:headers
    if header_level <= a:maxlevel
      let l:count += 1
    endif
  endfor
  return l:count
endfunction


function! s:get_min_header_level(headers) abort
  " Get the minimum level of any header in a list of [level, title] pairs.
  if len(a:headers) == 0
    return 0
  endif
  let minlevel = a:headers[0][0]
  for [level, _] in a:headers
    let minlevel = min([minlevel, level])
  endfor
  return minlevel
endfunction


function! s:read_captions(files) abort
  " Read all caption in 1. <List>files
  " Return: <Dic>: key -> caption
  let result = {}
  let caption_level = vimwiki#vars#get_wikilocal('diary_caption_level')

  for fl in a:files
    " Remove paths and extensions
    let fl_captions = {}

    " Default; no captions from the file.
    let fl_captions['top'] = ''
    let fl_captions['rest'] = []

    if caption_level >= 0 && filereadable(fl)
      if caption_level == 0
        " Take first header of any level as the top caption.
        let fl_captions['top'] = s:get_first_header(fl)
      else
        let headers = s:get_all_headers(fl, caption_level)
        if len(headers) > 0
          " If first header is the only one at its level or less, then make it the top caption.
          let [first_level, first_header] = headers[0]
          if s:count_headers_level_less_equal(headers, first_level) == 1
            let fl_captions['top'] = first_header
            call remove(headers, 0)
          endif

          let min_header_level = s:get_min_header_level(headers)
          for [level, header] in headers
            call add(fl_captions['rest'], [level - min_header_level, header])
          endfor
        endif
      endif
    endif

    let fl_key = substitute(fnamemodify(fl, ':t'), vimwiki#vars#get_wikilocal('ext').'$', '', '')
    let result[fl_key] = fl_captions
  endfor
  return result
endfunction


function! vimwiki#diary#get_diary_files() abort
  " Return: <list> diary file names
  let rx = '^\d\{4}-\d\d-\d\d'
  let s_files = glob(vimwiki#vars#get_wikilocal('path').
        \ vimwiki#vars#get_wikilocal('diary_rel_path').'*'.vimwiki#vars#get_wikilocal('ext'))
  let files = split(s_files, '\n')
  call filter(files, 'fnamemodify(v:val, ":t") =~# "'.escape(rx, '\').'"')

  " remove backup files (.wiki~)
  call filter(files, 'v:val !~# ''.*\~$''')

  return files
endfunction


function! s:group_links(links) abort
  " Return: <dic> nested -> links
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


function! s:sort(lst) abort
  " Sort list
  if vimwiki#vars#get_wikilocal('diary_sort') ==? 'desc'
    return reverse(sort(a:lst))
  else
    return sort(a:lst)
  endif
endfunction

function! vimwiki#diary#diary_sort(lst) abort
  return s:sort(a:lst)
endfunction

function! vimwiki#diary#make_note(wnum, ...) abort
  " Create note
  " The given wiki number a:wnum is 1 for the first wiki, 2 for the second and so on. This is in
  " contrast to most other places, where counting starts with 0. When a:wnum is 0, the current wiki
  " is used.
  if a:wnum == 0
    let wiki_nr = vimwiki#vars#get_bufferlocal('wiki_nr')
    if wiki_nr < 0  " this happens when e.g. VimwikiMakeDiaryNote was called outside a wiki buffer
      let wiki_nr = 0
    endif
  else
    let wiki_nr = a:wnum - 1
  endif

  if wiki_nr >= vimwiki#vars#number_of_wikis()
    call vimwiki#u#error('Wiki '.wiki_nr.' is not registered in g:vimwiki_list!')
    return
  endif

  call vimwiki#path#mkdir(vimwiki#vars#get_wikilocal('path', wiki_nr).
        \ vimwiki#vars#get_wikilocal('diary_rel_path', wiki_nr))

  let cmd = ':edit'
  if a:0
    if a:1 == 1
      let cmd = ':tabedit'
    elseif a:1 == 2
      let cmd = ':split'
    elseif a:1 == 3
      let cmd = ':vsplit'
    elseif a:1 == 4
      let cmd = ':tab edit'
      if exists(':drop') == 2
        let cmd = ':tab drop'
      endif
    elseif a:1 == 5
      let cmd = ':edit'
      if exists(':drop') == 2
        let cmd = ':drop'
      endif
    endif
  endif
  if a:0>1
    let link = 'diary:'.a:2
  else
    let link = 'diary:'.vimwiki#diary#diary_date_link()
  endif

  call vimwiki#base#open_link(cmd, link, s:diary_index(wiki_nr))
endfunction


function! vimwiki#diary#goto_diary_index(wnum) abort
  " Jump to diary index of 1. <Int> wikinumber
  " if wnum = 0 the current wiki is used
  if a:wnum == 0
    let idx = vimwiki#vars#get_bufferlocal('wiki_nr')
    if idx < 0  " not in a wiki
      let idx = 0
    endif
  else
    let idx = a:wnum - 1 " convert to 0 based counting
  endif

  if a:wnum > vimwiki#vars#number_of_wikis()
    call vimwiki#u#error('Wiki '.a:wnum.' is not registered in g:vimwiki_list!')
    return
  endif

  call vimwiki#base#edit_file('e', s:diary_index(idx), '')

  if vimwiki#vars#get_wikilocal('auto_diary_index')
    call vimwiki#diary#generate_diary_section()
    write! " save changes
  endif
endfunction


function! vimwiki#diary#goto_next_day() abort
  " Jump to next day
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


function! vimwiki#diary#goto_prev_day() abort
  " Jump to previous day
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


function! vimwiki#diary#generate_diary_section() abort
  " Create diary index content
  let GeneratorDiary = copy(l:)
  function! GeneratorDiary.f() abort
    let lines = []

    let links_with_captions = s:read_captions(vimwiki#diary#get_diary_files())
    let g_files = s:group_links(links_with_captions)
    let g_keys = s:sort(keys(g_files))

    for year in g_keys
      if len(lines) > 0
        call add(lines, '')
      endif

      call add(lines, substitute(vimwiki#vars#get_syntaxlocal('rxH2_Template'), '__Header__', year , ''))

      for month in s:sort(keys(g_files[year]))
        call add(lines, '')
        call add(lines, substitute(vimwiki#vars#get_syntaxlocal('rxH3_Template'),
              \ '__Header__', s:get_month_name(month), ''))

        if vimwiki#vars#get_wikilocal('syntax') ==# 'markdown'
          for _ in range(vimwiki#vars#get_global('markdown_header_style'))
            call add(lines, '')
          endfor
        endif

        for [fl, captions] in s:sort(items(g_files[year][month]))
          let topcap = captions['top']
          let link_tpl = vimwiki#vars#get_global('WikiLinkTemplate2')

          if vimwiki#vars#get_wikilocal('syntax') ==# 'markdown'
            let link_tpl = vimwiki#vars#get_syntaxlocal('Weblink1Template')

            if empty(topcap) " When using markdown syntax, we should ensure we always have a link description.
              let topcap = fl
            endif
          endif

          if empty(topcap)
            let top_link_tpl = vimwiki#vars#get_global('WikiLinkTemplate1')
          else
            let top_link_tpl = link_tpl
          endif

          let bullet = vimwiki#lst#default_symbol().' '
          let entry = substitute(top_link_tpl, '__LinkUrl__', fl, '')
          let entry = substitute(entry, '__LinkDescription__', topcap, '')
          let wiki_nr = vimwiki#vars#get_bufferlocal('wiki_nr')
          let extension = vimwiki#vars#get_wikilocal('ext', wiki_nr)
          let entry = substitute(entry, '__FileExtension__', extension, 'g')
          " If single H1 then that will be used as the description for the link to the file
          " if multiple H1 then the filename will be used as the description for the link to the
          " file and multiple H1 headers will be indented by shiftwidth
          call add(lines, repeat(' ', vimwiki#lst#get_list_margin()).bullet.entry)

          let startindent = repeat(' ', vimwiki#lst#get_list_margin())
          let indentstring = repeat(' ', vimwiki#u#sw())

          for [depth, subcap] in captions['rest']
            if empty(subcap)
              continue
            endif
            let entry = substitute(link_tpl, '__LinkUrl__', fl.'#'.subcap, '')
            let entry = substitute(entry, '__LinkDescription__', subcap, '')
            " if single H1 then depth H2=0, H3=1, H4=2, H5=3, H6=4
            " if multiple H1 then depth H1= 0, H2=1, H3=2, H4=3, H5=4, H6=5
            " indent subsequent headers levels by shiftwidth
            call add(lines, startindent.repeat(indentstring, depth+1).bullet.entry)
          endfor
        endfor

      endfor
    endfor

    return lines
  endfunction

  let current_file = vimwiki#path#path_norm(expand('%:p'))
  let diary_file = vimwiki#path#path_norm(s:diary_index())
  if vimwiki#path#is_equal(current_file, diary_file)
    let content_rx = '^\%('.vimwiki#vars#get_syntaxlocal('rxHeader').'\)\|'.
          \ '\%(^\s*$\)\|\%('.vimwiki#vars#get_syntaxlocal('rxListBullet').'\)'

    call vimwiki#base#update_listing_in_buffer(
          \ GeneratorDiary,
          \ vimwiki#vars#get_wikilocal('diary_header'),
          \ content_rx,
          \ 1,
          \ 1,
          \ 1)
  else
    call vimwiki#u#error('You can generate diary links only in a diary index page!')
  endif
endfunction


function! vimwiki#diary#calendar_action(day, month, year, week, dir) abort
  " Callback function for Calendar.vim
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


function! vimwiki#diary#calendar_sign(day, month, year) abort
  " Callback function for Calendar.vim
  " Clause: no wiki no sign #290
  if exists('g:vimwiki_list') && len(g:vimwiki_list) <= 0
    return
  endif
  let day = s:prefix_zero(a:day)
  let month = s:prefix_zero(a:month)
  let sfile = vimwiki#vars#get_wikilocal('path') . vimwiki#vars#get_wikilocal('diary_rel_path')
        \ . a:year.'-'.month.'-'.day.vimwiki#vars#get_wikilocal('ext')
  return filereadable(expand(sfile))
endfunction

function! vimwiki#diary#diary_file_captions() abort
  return s:read_captions(vimwiki#diary#get_diary_files())
endfunction
