" vim:tabstop=2:shiftwidth=2:expandtab:textwidth=99
" Vimwiki autoload plugin file
" Description: Handle diary notes
" Home: https://github.com/vimwiki/vimwiki/


if exists('g:loaded_vimwiki_diary_auto') || &compatible
  finish
endif
let g:loaded_vimwiki_diary_auto = 1


function! s:prefix_zero(num) abort
  if a:num < 10
    return '0'.a:num
  endif
  return a:num
endfunction


function! s:diary_path(...) abort
  let idx = a:0 == 0 ? vimwiki#vars#get_bufferlocal('wiki_nr') : a:1
  return vimwiki#vars#get_wikilocal('path', idx).vimwiki#vars#get_wikilocal('diary_rel_path', idx)
endfunction


function! s:diary_index(...) abort
  let idx = a:0 == 0 ? vimwiki#vars#get_bufferlocal('wiki_nr') : a:1
  return s:diary_path(idx).vimwiki#vars#get_wikilocal('diary_index', idx).
        \ vimwiki#vars#get_wikilocal('ext', idx)
endfunction


function! vimwiki#diary#diary_date_link(...) abort
  if a:0
    return strftime('%Y-%m-%d', a:1)
  else
    return strftime('%Y-%m-%d')
  endif
endfunction


function! s:get_position_links(link) abort
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
  " Returns a list whose elements are pairs [level, title]
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
  " The minimum level of any header in a list of [level, title] pairs.
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
  let result = {}
  let caption_level = vimwiki#vars#get_wikilocal('diary_caption_level')

  for fl in a:files
    " remove paths and extensions
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
  if vimwiki#vars#get_wikilocal('diary_sort') ==? 'desc'
    return reverse(sort(a:lst))
  else
    return sort(a:lst)
  endif
endfunction

" The given wiki number a:wnum is 1 for the first wiki, 2 for the second and so on. This is in
" contrast to most other places, where counting starts with 0. When a:wnum is 0, the current wiki
" is used.
function! vimwiki#diary#make_note(wnum, ...) abort
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

function! vimwiki#diary#goto_diary_index(wnum) abort

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
    echomsg 'Vimwiki Error: Wiki '.a:wnum.' is not registered in g:vimwiki_list!'
    return
  endif

  call vimwiki#base#edit_file('e', s:diary_index(idx), '')

  if vimwiki#vars#get_wikilocal('auto_diary_index')
    call vimwiki#diary#generate_diary_section()
    write! " save changes
  endif
endfunction


function! vimwiki#diary#goto_next_day() abort
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
          " If single H1 then that will be used as the description for the link to the file
          " if multple H1 then the filename will be used as the description for the link to the
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
    echomsg 'Vimwiki Error: You can generate diary links only in a diary index page!'
  endif
endfunction


" Callback function for Calendar.vim
function! vimwiki#diary#calendar_action(day, month, year, week, dir) abort
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
  let day = s:prefix_zero(a:day)
  let month = s:prefix_zero(a:month)
  let sfile = vimwiki#vars#get_wikilocal('path').vimwiki#vars#get_wikilocal('diary_rel_path').
        \ a:year.'-'.month.'-'.day.vimwiki#vars#get_wikilocal('ext')
  return filereadable(expand(sfile))
endfunction
