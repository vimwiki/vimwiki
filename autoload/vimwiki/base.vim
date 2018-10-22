" vim:tabstop=2:shiftwidth=2:expandtab:textwidth=99
" Vimwiki autoload plugin file
" Desc: Basic functionality
" Home: https://github.com/vimwiki/vimwiki/

if exists("g:loaded_vimwiki_auto") || &cp
  finish
endif
let g:loaded_vimwiki_auto = 1


function! s:safesubstitute(text, search, replace, mode)
  " Substitute regexp but do not interpret replace
  let escaped = escape(a:replace, '\&')
  return substitute(a:text, a:search, escaped, a:mode)
endfunction


function! s:vimwiki_get_known_syntaxes()
  " Getting all syntaxes that different wikis could have
  let syntaxes = {}
  let syntaxes['default'] = 1
  for wiki_nr in range(vimwiki#vars#number_of_wikis())
    let wiki_syntax = vimwiki#vars#get_wikilocal('syntax', wiki_nr)
    let syntaxes[wiki_syntax] = 1
  endfor
  " also consider the syntaxes from g:vimwiki_ext2syntax
  for syn in values(vimwiki#vars#get_global('ext2syntax'))
    let syntaxes[syn] = 1
  endfor
  return keys(syntaxes)
endfunction


function! vimwiki#base#file_pattern(files)
  " Get search regex from glob()
  " string. Aim to support *all* special characters, forcing the user to choose
  "   names that are compatible with any external restrictions that they
  "   encounter (e.g. filesystem, wiki conventions, other syntaxes, ...).
  "   See: https://github.com/vimwiki-backup/vimwiki/issues/316
  " Change / to [/\\] to allow "Windows paths"
  return '\V\%('.join(a:files, '\|').'\)\m'
endfunction


"FIXME TODO slow and faulty
function! vimwiki#base#subdir(path, filename)
  let path = a:path
  " ensure that we are not fooled by a symbolic link
  "FIXME if we are not "fooled", we end up in a completely different wiki?
  if a:filename !~# '^scp:'
    let filename = resolve(a:filename)
  else
    let filename = a:filename
  endif
  let idx = 0
  "FIXME this can terminate in the middle of a path component!
  while path[idx] ==? filename[idx]
    let idx = idx + 1
  endwhile

  let p = split(strpart(filename, idx), '[/\\]')
  let res = join(p[:-2], '/')
  if len(res) > 0
    let res = res.'/'
  endif
  return res
endfunction


function! vimwiki#base#current_subdir()
  return vimwiki#base#subdir(vimwiki#vars#get_wikilocal('path'), expand('%:p'))
endfunction


function! vimwiki#base#invsubdir(subdir)
  return substitute(a:subdir, '[^/\.]\+/', '../', 'g')
endfunction


" Returns: the number of the wiki a file belongs to or -1 if it doesn't belong
" to any registered wiki.
" The path can be the full path or just the directory of the file
function! vimwiki#base#find_wiki(path)
  let bestmatch = -1
  let bestlen = 0
  let path = vimwiki#path#path_norm(vimwiki#path#chomp_slash(a:path))
  for idx in range(vimwiki#vars#number_of_wikis())
    let idx_path = expand(vimwiki#vars#get_wikilocal('path', idx))
    let idx_path = vimwiki#path#path_norm(vimwiki#path#chomp_slash(idx_path))
    let common_pfx = vimwiki#path#path_common_pfx(idx_path, path)
    if vimwiki#path#is_equal(common_pfx, idx_path)
      if len(common_pfx) > bestlen
        let bestlen = len(common_pfx)
        let bestmatch = idx
      endif
    endif
  endfor

  return bestmatch
endfunction


" THE central function of Vimwiki. Extract infos about the target from a link.
" If the second parameter is present, which should be an absolute file path, it
" is assumed that the link appears in that file. Without it, the current file
" is used.
function! vimwiki#base#resolve_link(link_text, ...)
  if a:0
    let source_wiki = vimwiki#base#find_wiki(a:1)
    let source_file = a:1
  else
    let source_wiki = vimwiki#vars#get_bufferlocal('wiki_nr')
    let source_file = vimwiki#path#current_wiki_file()
  endif

  let link_text = a:link_text


  let link_infos = {
        \ 'index': -1,
        \ 'scheme': '',
        \ 'filename': '',
        \ 'anchor': '',
        \ }

  if link_text == ''
    return link_infos
  endif

  let scheme = matchstr(link_text, '^\zs'.vimwiki#vars#get_global('rxSchemes').'\ze:')
  if scheme == ''
    let link_infos.scheme = 'wiki'.source_wiki
  else
    let link_infos.scheme = scheme

    if link_infos.scheme !~# '\mwiki\d\+\|diary\|local\|file'
      let link_infos.filename = link_text  " unknown scheme, may be a weblink
      return link_infos
    endif

    let link_text = matchstr(link_text, '^'.vimwiki#vars#get_global('rxSchemes').':\zs.*\ze')
  endif

  let is_wiki_link = link_infos.scheme =~# '\mwiki\d\+' || link_infos.scheme ==# 'diary'

  " extract anchor
  if is_wiki_link
    let split_lnk = split(link_text, '#', 1)
    let link_text = split_lnk[0]
    if len(split_lnk) > 1 && split_lnk[-1] != ''
      let link_infos.anchor = join(split_lnk[1:], '#')
    endif
    if link_text == ''  " because the link was of the form '#anchor'
      let link_text = fnamemodify(source_file, ':p:t:r')
    endif
  endif

  " check if absolute or relative path
  if is_wiki_link && link_text[0] == '/'
    if link_text != '/'
      let link_text = link_text[1:]
    endif
    let is_relative = 0
  elseif !is_wiki_link && vimwiki#path#is_absolute(link_text)
    let is_relative = 0
  else
    let is_relative = 1
    let root_dir = fnamemodify(source_file, ':p:h') . '/'
  endif


  " extract the other items depending on the scheme
  if link_infos.scheme =~# '\mwiki\d\+'
    let link_infos.index = eval(matchstr(link_infos.scheme, '\D\+\zs\d\+\ze'))
    if link_infos.index < 0 || link_infos.index >= vimwiki#vars#number_of_wikis()
      let link_infos.index = -1
      let link_infos.filename = ''
      return link_infos
    endif

    if !is_relative || link_infos.index != source_wiki
      let root_dir = vimwiki#vars#get_wikilocal('path', link_infos.index)
    endif

    let link_infos.filename = root_dir . link_text

    if vimwiki#path#is_link_to_dir(link_text)
      if vimwiki#vars#get_global('dir_link') != ''
        let link_infos.filename .= vimwiki#vars#get_global('dir_link') .
              \ vimwiki#vars#get_wikilocal('ext', link_infos.index)
      endif
    else
      let link_infos.filename .= vimwiki#vars#get_wikilocal('ext', link_infos.index)
    endif

  elseif link_infos.scheme ==# 'diary'
    let link_infos.index = source_wiki

    let link_infos.filename =
          \ vimwiki#vars#get_wikilocal('path', link_infos.index) .
          \ vimwiki#vars#get_wikilocal('diary_rel_path', link_infos.index) .
          \ link_text .
          \ vimwiki#vars#get_wikilocal('ext', link_infos.index)
  elseif (link_infos.scheme ==# 'file' || link_infos.scheme ==# 'local') && is_relative
    let link_infos.filename = simplify(root_dir . link_text)
  else " absolute file link
    " collapse repeated leading "/"'s within a link
    let link_text = substitute(link_text, '\m^/\+', '/', '')
    " expand ~/
    let link_text = fnamemodify(link_text, ':p')
    let link_infos.filename = simplify(link_text)
  endif

  let link_infos.filename = vimwiki#path#normalize(link_infos.filename)
  return link_infos
endfunction


function! vimwiki#base#system_open_link(url)
  " handlers
  function! s:win32_handler(url)
    "Disable shellslash for cmd and command.com, but enable for all other shells
    "See Issue #560
    if (&shell =~? "cmd") || (&shell =~? "command.com")

      if exists('+shellslash')
        let old_ssl = &shellslash
        set noshellslash
        let url = shellescape(a:url, 1)
        let &shellslash = old_ssl
      else
        let url = shellescape(a:url, 1)
      endif
      execute 'silent ! start "Title" /B ' . url

    else

      if exists('+shellslash')
        let old_ssl = &shellslash
        set shellslash
        let url = shellescape(a:url, 1)
        let &shellslash = old_ssl
      else
        let url = shellescape(a:url, 1)
      endif
      execute 'silent ! start ' . url

    endif
  endfunction
  function! s:macunix_handler(url)
    call system('open ' . shellescape(a:url).' &')
  endfunction
  function! s:linux_handler(url)
    call system('xdg-open ' . shellescape(a:url).' &')
  endfunction
  try
    if vimwiki#u#is_windows()
      call s:win32_handler(a:url)
      return
    elseif vimwiki#u#is_macos()
      call s:macunix_handler(a:url)
      return
    else
      call s:linux_handler(a:url)
      return
    endif
  endtry
  echomsg 'Vimwiki Error: Default Vimwiki link handler was unable to open the HTML file!'
endfunction


function! vimwiki#base#open_link(cmd, link, ...)
  let link_infos = {}
  if a:0
    let link_infos = vimwiki#base#resolve_link(a:link, a:1)
  else
    let link_infos = vimwiki#base#resolve_link(a:link)
  endif

  if link_infos.filename == ''
    if link_infos.index == -1
      echomsg 'Vimwiki Error: No registered wiki ''' . link_infos.scheme . '''.'
    else
      echomsg 'Vimwiki Error: Unable to resolve link!'
    endif
    return
  endif

  let is_wiki_link = link_infos.scheme =~# '\mwiki\d\+' || link_infos.scheme =~# 'diary'

  let update_prev_link = is_wiki_link &&
        \ !vimwiki#path#is_equal(link_infos.filename, vimwiki#path#current_wiki_file())

  let vimwiki_prev_link = []
  " update previous link for wiki pages
  if update_prev_link
    if a:0
      let vimwiki_prev_link = [a:1, []]
    elseif &ft ==# 'vimwiki'
      let vimwiki_prev_link = [vimwiki#path#current_wiki_file(), getpos('.')]
    endif
  endif

  " open/edit
  if is_wiki_link
    call vimwiki#base#edit_file(a:cmd, link_infos.filename, link_infos.anchor,
          \ vimwiki_prev_link, update_prev_link)
  else
    call vimwiki#base#system_open_link(link_infos.filename)
  endif
endfunction


function! vimwiki#base#get_globlinks_escaped() abort
  " only get links from the current dir
  " change to the directory of the current file
  let orig_pwd = getcwd()
  lcd! %:h
  " all path are relative to the current file's location
  let globlinks = glob('*'.vimwiki#vars#get_wikilocal('ext'), 1)."\n"
  " remove extensions
  let globlinks = substitute(globlinks, '\'.vimwiki#vars#get_wikilocal('ext').'\ze\n', '', 'g')
  " restore the original working directory
  exe 'lcd! '.orig_pwd
  " convert to a List
  let lst = split(globlinks, '\n')
  " Apply fnameescape() to each item
  call map(lst, 'fnameescape(v:val)')
  " Convert back to newline-separated list
  let globlinks = join(lst, "\n")
  " return all escaped links as a single newline-separated string
  return globlinks
endfunction


function! vimwiki#base#generate_links()
  let lines = []

  let links = vimwiki#base#get_wikilinks(vimwiki#vars#get_bufferlocal('wiki_nr'), 0)
  call sort(links)

  let bullet = repeat(' ', vimwiki#lst#get_list_margin()) . vimwiki#lst#default_symbol().' '
  for link in links
    let abs_filepath = vimwiki#path#abs_path_of_link(link)
    if !s:is_diary_file(abs_filepath)
      call add(lines, bullet.
            \ s:safesubstitute(vimwiki#vars#get_global('WikiLinkTemplate1'),
            \ '__LinkUrl__', link, ''))
    endif
  endfor

  let links_rx = '\m^\s*'.vimwiki#u#escape(vimwiki#lst#default_symbol()).' '

  call vimwiki#base#update_listing_in_buffer(lines, 'Generated Links', links_rx, line('$')+1, 1)
endfunction


function! vimwiki#base#goto(...)
  let key = a:1
  let anchor = a:0 > 1 ? a:2 : ''

  call vimwiki#base#edit_file(':e',
        \ vimwiki#vars#get_wikilocal('path') . key . vimwiki#vars#get_wikilocal('ext'),
        \ anchor)
endfunction


function! vimwiki#base#backlinks()
  let current_filename = expand("%:p")
  let locations = []
  for idx in range(vimwiki#vars#number_of_wikis())
    let syntax = vimwiki#vars#get_wikilocal('syntax', idx)
    let wikifiles = vimwiki#base#find_files(idx, 0)
    for source_file in wikifiles
      let links = s:get_links(source_file, idx)
      for [target_file, _, lnum, col] in links
        " don't include links from the current file to itself
        if vimwiki#path#is_equal(target_file, current_filename) &&
              \ !vimwiki#path#is_equal(target_file, source_file)
          call add(locations, {'filename':source_file, 'lnum':lnum, 'col':col})
        endif
      endfor
    endfor
  endfor

  if empty(locations)
    echomsg 'Vimwiki: No other file links to this file'
  else
    call setloclist(0, locations, 'r')
    lopen
  endif
endfunction


" Returns: a list containing all files of the given wiki as absolute file path.
" If the given wiki number is negative, the diary of the current wiki is used
" If the second argument is not zero, only directories are found
function! vimwiki#base#find_files(wiki_nr, directories_only)
  let wiki_nr = a:wiki_nr
  if wiki_nr >= 0
    let root_directory = vimwiki#vars#get_wikilocal('path', wiki_nr)
  else
    let root_directory = vimwiki#vars#get_wikilocal('path') .
          \ vimwiki#vars#get_wikilocal('diary_rel_path')
    let wiki_nr = vimwiki#vars#get_bufferlocal('wiki_nr')
  endif
  if a:directories_only
    let ext = '/'
  else
    let ext = vimwiki#vars#get_wikilocal('ext', wiki_nr)
  endif
  " if current wiki is temporary -- was added by an arbitrary wiki file then do
  " not search wiki files in subdirectories. Or it would hang the system if
  " wiki file was created in $HOME or C:/ dirs.
  if vimwiki#vars#get_wikilocal('is_temporary_wiki', wiki_nr)
    let pattern = '*'.ext
  else
    let pattern = '**/*'.ext
  endif
  return split(globpath(root_directory, pattern), '\n')
endfunction


" Returns: a list containing the links to get from the current file to all wiki
" files in the given wiki.
" If the given wiki number is negative, the diary of the current wiki is used.
" If also_absolute_links is nonzero, also return links of the form /file
function! vimwiki#base#get_wikilinks(wiki_nr, also_absolute_links)
  let files = vimwiki#base#find_files(a:wiki_nr, 0)
  if a:wiki_nr == vimwiki#vars#get_bufferlocal('wiki_nr')
    let cwd = vimwiki#path#wikify_path(expand('%:p:h'))
  elseif a:wiki_nr < 0
    let cwd = vimwiki#vars#get_wikilocal('path') . vimwiki#vars#get_wikilocal('diary_rel_path')
  else
    let cwd = vimwiki#vars#get_wikilocal('path', a:wiki_nr)
  endif
  let result = []
  for wikifile in files
    let wikifile = fnamemodify(wikifile, ':r') " strip extension
    let wikifile = vimwiki#path#relpath(cwd, wikifile)
    call add(result, wikifile)
  endfor
  if a:also_absolute_links
    for wikifile in files
      if a:wiki_nr == vimwiki#vars#get_bufferlocal('wiki_nr')
        let cwd = vimwiki#vars#get_wikilocal('path')
      elseif a:wiki_nr < 0
        let cwd = vimwiki#vars#get_wikilocal('path') . vimwiki#vars#get_wikilocal('diary_rel_path')
      endif
      let wikifile = fnamemodify(wikifile, ':r') " strip extension
      let wikifile = '/'.vimwiki#path#relpath(cwd, wikifile)
      call add(result, wikifile)
    endfor
  endif
  return result
endfunction


" Returns: a list containing the links to all directories from the current file
function! vimwiki#base#get_wiki_directories(wiki_nr)
  let dirs = vimwiki#base#find_files(a:wiki_nr, 1)
  if a:wiki_nr == vimwiki#vars#get_bufferlocal('wiki_nr')
    let cwd = vimwiki#path#wikify_path(expand('%:p:h'))
    let root_dir = vimwiki#vars#get_wikilocal('path')
  else
    let cwd = vimwiki#vars#get_wikilocal('path', a:wiki_nr)
  endif
  let result = ['./']
  for wikidir in dirs
    let wikidir_relative = vimwiki#path#relpath(cwd, wikidir)
    call add(result, wikidir_relative)
    if a:wiki_nr == vimwiki#vars#get_bufferlocal('wiki_nr')
      let wikidir_absolute = '/'.vimwiki#path#relpath(root_dir, wikidir)
      call add(result, wikidir_absolute)
    endif
  endfor
  return result
endfunction


function! vimwiki#base#get_anchors(filename, syntax)
  if !filereadable(a:filename)
    return []
  endif

  let rxheader = vimwiki#vars#get_syntaxlocal('header_search', a:syntax)
  let rxbold = vimwiki#vars#get_syntaxlocal('bold_search', a:syntax)
  let rxtag = vimwiki#vars#get_syntaxlocal('tag_search', a:syntax)

  let anchor_level = ['', '', '', '', '', '', '']
  let anchors = []
  let current_complete_anchor = ''
  for line in readfile(a:filename)

    " collect headers
    let h_match = matchlist(line, rxheader)
    if !empty(h_match)
      let header = vimwiki#u#trim(h_match[2])
      let level = len(h_match[1])
      call add(anchors, header)
      let anchor_level[level-1] = header
      for l in range(level, 6)
        let anchor_level[l] = ''
      endfor
      if level == 1
        let current_complete_anchor = header
      else
        let current_complete_anchor = ''
        for l in range(level-1)
          if anchor_level[l] != ''
            let current_complete_anchor .= anchor_level[l].'#'
          endif
        endfor
        let current_complete_anchor .= header
        call add(anchors, current_complete_anchor)
      endif
    endif

    " collect bold text (there can be several in one line)
    let bold_count = 1
    while 1
      let bold_text = matchstr(line, rxbold, 0, bold_count)
      if bold_text == ''
        break
      endif
      call add(anchors, bold_text)
      if current_complete_anchor != ''
        call add(anchors, current_complete_anchor.'#'.bold_text)
      endif
      let bold_count += 1
    endwhile

    " collect tags text (there can be several in one line)
    let tag_count = 1
    while 1
      let tag_group_text = matchstr(line, rxtag, 0, tag_count)
      if tag_group_text == ''
        break
      endif
      for tag_text in split(tag_group_text, ':')
        call add(anchors, tag_text)
        if current_complete_anchor != ''
          call add(anchors, current_complete_anchor.'#'.tag_text)
        endif
      endfor
      let tag_count += 1
    endwhile

  endfor

  return anchors
endfunction


function! s:jump_to_anchor(anchor)
  let oldpos = getpos('.')
  call cursor(1, 1)

  let anchor = vimwiki#u#escape(a:anchor)

  let segments = split(anchor, '#', 0)

  for segment in segments

    let anchor_header = s:safesubstitute(
          \ vimwiki#vars#get_syntaxlocal('header_match'),
          \ '__Header__', segment, '')
    let anchor_bold = s:safesubstitute(
          \ vimwiki#vars#get_syntaxlocal('bold_match'),
          \ '__Text__', segment, '')
    let anchor_tag = s:safesubstitute(
          \ vimwiki#vars#get_syntaxlocal('tag_match'),
          \ '__Tag__', segment, '')

    if !search(anchor_tag, 'Wc') && !search(anchor_header, 'Wc') && !search(anchor_bold, 'Wc')
      call setpos('.', oldpos)
      break
    endif
    let oldpos = getpos('.')
  endfor
endfunction


" Params: full path to a wiki file and its wiki number
" Returns: a list of all links inside the wiki file
" Every list item has the form
" [target file, anchor, line number of the link in source file, column number]
function! s:get_links(wikifile, idx)
  if !filereadable(a:wikifile)
    return []
  endif

  let syntax = vimwiki#vars#get_wikilocal('syntax', a:idx)
  let rx_link = vimwiki#vars#get_syntaxlocal('wikilink', syntax)
  let links = []
  let lnum = 0

  for line in readfile(a:wikifile)
    let lnum += 1

    let link_count = 1
    while 1
      let col = match(line, rx_link, 0, link_count)+1
      let link_text = matchstr(line, rx_link, 0, link_count)
      if link_text == ''
        break
      endif
      let link_count += 1
      let target = vimwiki#base#resolve_link(link_text, a:wikifile)
      if target.filename != '' && target.scheme =~# '\mwiki\d\+\|diary\|file\|local'
        call add(links, [target.filename, target.anchor, lnum, col])
      endif
    endwhile
  endfor

  return links
endfunction


function! vimwiki#base#check_links()
  let anchors_of_files = {}
  let links_of_files = {}
  let errors = []
  for idx in range(vimwiki#vars#number_of_wikis())
    let syntax = vimwiki#vars#get_wikilocal('syntax', idx)
    let wikifiles = vimwiki#base#find_files(idx, 0)
    for wikifile in wikifiles
      let links_of_files[wikifile] = s:get_links(wikifile, idx)
      let anchors_of_files[wikifile] = vimwiki#base#get_anchors(wikifile, syntax)
    endfor
  endfor

  for wikifile in keys(links_of_files)
    for [target_file, target_anchor, lnum, col] in links_of_files[wikifile]
      if target_file == '' && target_anchor == ''
        call add(errors, {'filename':wikifile, 'lnum':lnum, 'col':col,
              \ 'text': "numbered scheme refers to a non-existent wiki"})
      elseif has_key(anchors_of_files, target_file)
        if target_anchor != '' && index(anchors_of_files[target_file], target_anchor) < 0
          call add(errors, {'filename':wikifile, 'lnum':lnum, 'col':col,
                \'text': "there is no such anchor: ".target_anchor})
        endif
      else
        if target_file =~ '\m/$'  " maybe it's a link to a directory
          if !isdirectory(target_file)
            call add(errors, {'filename':wikifile, 'lnum':lnum, 'col':col,
                  \'text': "there is no such directory: ".target_file})
          endif
        else  " maybe it's a non-wiki file
          if filereadable(target_file)
            let anchors_of_files[target_file] = []
          else
            call add(errors, {'filename':wikifile, 'lnum':lnum, 'col':col,
                  \'text': "there is no such file: ".target_file})
          endif
        endif
      endif
    endfor
  endfor


  " Check which wiki files are reachable from at least one of the index files.
  " First, all index files are marked as reachable. Then, pick a reachable file
  " and mark all files to which it links as reachable, too. Repeat until the
  " links of all reachable files have been checked.

  " Map every wiki file to a number. 0 means not reachable from any index file,
  " 1 means reachable, but the outgoing links are not checked yet, 2 means
  " reachable and done.
  let reachable_wikifiles = {}

  " first, all files are considered not reachable
  for wikifile in keys(links_of_files)
    let reachable_wikifiles[wikifile] = 0
  endfor

  " mark every index file as reachable
  for idx in range(vimwiki#vars#number_of_wikis())
    let index_file = vimwiki#vars#get_wikilocal('path', idx) .
          \ vimwiki#vars#get_wikilocal('index', idx) . vimwiki#vars#get_wikilocal('ext', idx)
    if filereadable(index_file)
      let reachable_wikifiles[index_file] = 1
    endif
  endfor

  while 1
    let next_unvisited_wikifile = ''
    for wf in keys(reachable_wikifiles)
      if reachable_wikifiles[wf] == 1
        let next_unvisited_wikifile = wf
        let reachable_wikifiles[wf] = 2
        break
      endif
    endfor
    if next_unvisited_wikifile == ''
      break
    endif
    for [target_file, target_anchor, lnum, col] in links_of_files[next_unvisited_wikifile]
      if has_key(reachable_wikifiles, target_file) && reachable_wikifiles[target_file] == 0
        let reachable_wikifiles[target_file] = 1
      endif
    endfor
  endwhile

  for wf in keys(reachable_wikifiles)
    if reachable_wikifiles[wf] == 0
      call add(errors, {'text':wf." is not reachable from the index file"})
    endif
  endfor

  if empty(errors)
    echomsg 'Vimwiki: All links are OK'
  else
    call setqflist(errors, 'r')
    copen
  endif
endfunction


function! vimwiki#base#edit_file(command, filename, anchor, ...)
  let fname = escape(a:filename, '% *|#`')
  let dir = fnamemodify(a:filename, ":p:h")

  let ok = vimwiki#path#mkdir(dir, 1)

  if !ok
    echomsg ' '
    echomsg 'Vimwiki Error: Unable to edit file in non-existent directory: '.dir
    return
  endif

  " Check if the file we want to open is already the current file
  " which happens if we jump to an achor in the current file.
  " This hack is necessary because apparently Vim messes up the result of
  " getpos() directly after this command. Strange.
  if !(a:command ==# ':e ' && vimwiki#path#is_equal(a:filename, expand('%:p')))
    if &autowriteall && !&hidden  " in this case, the file is saved before switching to the
      " new buffer. This causes Vim to show two messages in the command line which triggers
      " the annoying hit-enter prompt. Solution: show no messages at all.
      silent execute a:command fname
    else
      try
        execute a:command fname
      catch /E37:/
        echomsg 'Vimwiki: The current file is modified. Hint: Take a look at'
              \ ''':h g:vimwiki_autowriteall'' to see how to save automatically.'
        return
      catch /E325:/
        echom 'Vimwiki: Vim couldn''t open the file, probably because a swapfile already exists. See :h E325.'
        return
      endtry
    endif

    " If the opened file was not already loaded by Vim, an autocommand is
    " triggered at this point

    " Make sure no other plugin takes ownership over the new file. Vimwiki
    " rules them all! Well, except for directories, which may be opened with
    " Netrw
    if &filetype != 'vimwiki' && fname !~ '\m/$'
      setfiletype vimwiki
    endif
  endif
  if a:anchor != ''
    call s:jump_to_anchor(a:anchor)
  endif

  " save previous link
  " a:1 -- previous vimwiki link to save
  " a:2 -- should we update previous link
  if a:0 && a:2 && len(a:1) > 0
    call vimwiki#vars#set_bufferlocal('prev_link', a:1)
  endif
endfunction


function! vimwiki#base#search_word(wikiRx, cmd)
  let match_line = search(a:wikiRx, 's'.a:cmd)
  if match_line == 0
    echomsg 'Vimwiki: Wiki link not found'
  endif
endfunction


" Returns part of the line that matches wikiRX at cursor
function! vimwiki#base#matchstr_at_cursor(wikiRX)
  let col = col('.') - 1
  let line = getline('.')
  let ebeg = -1
  let cont = match(line, a:wikiRX, 0)
  while (ebeg >= 0 || (0 <= cont) && (cont <= col))
    let contn = matchend(line, a:wikiRX, cont)
    if (cont <= col) && (col < contn)
      let ebeg = match(line, a:wikiRX, cont)
      let elen = contn - ebeg
      break
    else
      let cont = match(line, a:wikiRX, contn)
    endif
  endwh
  if ebeg >= 0
    return strpart(line, ebeg, elen)
  else
    return ""
  endif
endfunction


function! vimwiki#base#replacestr_at_cursor(wikiRX, sub)
  let col = col('.') - 1
  let line = getline('.')
  let ebeg = -1
  let cont = match(line, a:wikiRX, 0)
  while (ebeg >= 0 || (0 <= cont) && (cont <= col))
    let contn = matchend(line, a:wikiRX, cont)
    if (cont <= col) && (col < contn)
      let ebeg = match(line, a:wikiRX, cont)
      let elen = contn - ebeg
      break
    else
      let cont = match(line, a:wikiRX, contn)
    endif
  endwh
  if ebeg >= 0
    " TODO: There might be problems with Unicode chars...
    let newline = strpart(line, 0, ebeg).a:sub.strpart(line, ebeg+elen)
    call setline(line('.'), newline)
  endif
endfunction


function! s:print_wiki_list()
  let idx = 0
  while idx < vimwiki#vars#number_of_wikis()
    if idx == vimwiki#vars#get_bufferlocal('wiki_nr')
      let sep = ' * '
      echohl PmenuSel
    else
      let sep = '   '
      echohl None
    endif
    echo (idx + 1) . sep . vimwiki#vars#get_wikilocal('path', idx)
    let idx += 1
  endwhile
  echohl None
endfunction


function! s:update_wiki_link(fname, old, new)
  echo "Updating links in ".a:fname
  let has_updates = 0
  let dest = []
  for line in readfile(a:fname)
    if !has_updates && match(line, a:old) != -1
      let has_updates = 1
    endif
    " XXX: any other characters to escape!?
    call add(dest, substitute(line, a:old, escape(a:new, "&"), "g"))
  endfor
  " add exception handling...
  if has_updates
    call rename(a:fname, a:fname.'#vimwiki_upd#')
    call writefile(dest, a:fname)
    call delete(a:fname.'#vimwiki_upd#')
  endif
endfunction


function! s:update_wiki_links_dir(dir, old_fname, new_fname)
  let old_fname = substitute(a:old_fname, '[/\\]', '[/\\\\]', 'g')
  let new_fname = a:new_fname

  let old_fname_r = vimwiki#base#apply_template(
        \ vimwiki#vars#get_syntaxlocal('WikiLinkMatchUrlTemplate'), old_fname, '', '')

  let files = split(glob(vimwiki#vars#get_wikilocal('path').a:dir.'*'.
        \ vimwiki#vars#get_wikilocal('ext')), '\n')
  for fname in files
    call s:update_wiki_link(fname, old_fname_r, new_fname)
  endfor
endfunction


function! s:tail_name(fname)
  let result = substitute(a:fname, ":", "__colon__", "g")
  let result = fnamemodify(result, ":t:r")
  let result = substitute(result, "__colon__", ":", "g")
  return result
endfunction


function! s:update_wiki_links(old_fname, new_fname)
  let old_fname = a:old_fname
  let new_fname = a:new_fname

  let subdirs = split(a:old_fname, '[/\\]')[: -2]

  " TODO: Use Dictionary here...
  let dirs_keys = ['']
  let dirs_vals = ['']
  if len(subdirs) > 0
    let dirs_keys = ['']
    let dirs_vals = [join(subdirs, '/').'/']
    let idx = 0
    while idx < len(subdirs) - 1
      call add(dirs_keys, join(subdirs[: idx], '/').'/')
      call add(dirs_vals, join(subdirs[idx+1 :], '/').'/')
      let idx = idx + 1
    endwhile
    call add(dirs_keys,join(subdirs, '/').'/')
    call add(dirs_vals, '')
  endif

  let idx = 0
  while idx < len(dirs_keys)
    let dir = dirs_keys[idx]
    let new_dir = dirs_vals[idx]
    call s:update_wiki_links_dir(dir, new_dir.old_fname, new_dir.new_fname)
    let idx = idx + 1
  endwhile
endfunction


function! s:get_wiki_buffers()
  let blist = []
  let bcount = 1
  while bcount<=bufnr("$")
    if bufexists(bcount)
      let bname = fnamemodify(bufname(bcount), ":p")
      " this may find buffers that are not part of the current wiki, but that
      " doesn't hurt
      if bname =~# vimwiki#vars#get_wikilocal('ext')."$"
        let bitem = [bname, vimwiki#vars#get_bufferlocal('prev_link', bcount)]
        call add(blist, bitem)
      endif
    endif
    let bcount = bcount + 1
  endwhile
  return blist
endfunction


function! s:open_wiki_buffer(item)
  call vimwiki#base#edit_file(':e', a:item[0], '')
  if !empty(a:item[1])
    call vimwiki#vars#set_bufferlocal('prev_link', a:item[1], a:item[0])
  endif
endfunction


function! vimwiki#base#nested_syntax(filetype, start, end, textSnipHl) abort
" From http://vim.wikia.com/wiki/VimTip857
  let ft=toupper(a:filetype)
  let group='textGroup'.ft
  if exists('b:current_syntax')
    let s:current_syntax=b:current_syntax
    " Remove current syntax definition, as some syntax files (e.g. cpp.vim)
    " do nothing if b:current_syntax is defined.
    unlet b:current_syntax
  endif

  " Some syntax files set up iskeyword which might scratch vimwiki a bit.
  " Let us save and restore it later.
  " let b:skip_set_iskeyword = 1
  let is_keyword = &iskeyword

  try
    " keep going even if syntax file is not found
    execute 'syntax include @'.group.' syntax/'.a:filetype.'.vim'
    execute 'syntax include @'.group.' after/syntax/'.a:filetype.'.vim'
  catch
  endtry

  let &iskeyword = is_keyword

  if exists('s:current_syntax')
    let b:current_syntax=s:current_syntax
  else
    unlet b:current_syntax
  endif

  " Fix issue #236: tell Vimwiki to think in maths when encountering maths
  " blocks like {{$ }}$. Here, we don't want the tex highlight group, but the
  " group for tex math.
  if a:textSnipHl ==# 'VimwikiMath'
    let group='texMathZoneGroup'
  endif

  execute 'syntax region textSnip'.ft.
        \ ' matchgroup='.a:textSnipHl.
        \ ' start="'.a:start.'" end="'.a:end.'"'.
        \ ' contains=@'.group.' keepend'

  " A workaround to Issue 115: Nested Perl syntax highlighting differs from
  " regular one.
  " Perl syntax file has perlFunctionName which is usually has no effect due to
  " 'contained' flag. Now we have 'syntax include' that makes all the groups
  " included as 'contained' into specific group.
  " Here perlFunctionName (with quite an angry regexp "\h\w*[^:]") clashes with
  " the rest syntax rules as now it has effect being really 'contained'.
  " Clear it!
  if ft =~? 'perl'
    syntax clear perlFunctionName
  endif
endfunction


" creates or updates auto-generated listings in a wiki file, like TOC, diary
" links, tags list etc.
" - the listing consists of a level 1 header and a list of strings as content
" - a:content_regex is used to determine how long a potentially existing list is
" - a:default_lnum is the line number where the new listing should be placed if
"   it's not already present
" - if a:create is true, it will be created if it doesn't exist, otherwise it
"   will only be updated if it already exists
function! vimwiki#base#update_listing_in_buffer(strings, start_header,
      \ content_regex, default_lnum, create)
  " apparently, Vim behaves strange when files change while in diff mode
  if &diff || &readonly
    return
  endif

  " check if the listing is already there
  let already_there = 0

  let header_rx = '\m^\s*'.substitute(vimwiki#vars#get_syntaxlocal('rxH1_Template'),
        \ '__Header__', a:start_header, '') .'\s*$'

  let start_lnum = 1
  while start_lnum <= line('$')
    if getline(start_lnum) =~# header_rx
      let already_there = 1
      break
    endif
    let start_lnum += 1
  endwhile

  if !already_there && !a:create
    return
  endif

  let winview_save = winsaveview()
  let cursor_line = winview_save.lnum
  let is_cursor_after_listing = 0

  let is_fold_closed = 1

  let lines_diff = 0

  if already_there
    let is_fold_closed = ( foldclosed(start_lnum) > -1 )
    " delete the old listing
    let whitespaces_in_first_line = matchstr(getline(start_lnum), '\m^\s*')
    let end_lnum = start_lnum + 1
    while end_lnum <= line('$') && getline(end_lnum) =~# a:content_regex
      let end_lnum += 1
    endwhile
    let is_cursor_after_listing = ( cursor_line >= end_lnum )
    " We'll be removing a range.  But, apparently, if folds are enabled, Vim
    " won't let you remove a range that overlaps with closed fold -- the entire
    " fold gets deleted.  So we temporarily disable folds, and then reenable
    " them right back.
    let foldenable_save = &l:foldenable
    setlo nofoldenable
    silent exe start_lnum.','.string(end_lnum - 1).'delete _'
    let &l:foldenable = foldenable_save
    let lines_diff = 0 - (end_lnum - start_lnum)
  else
    let start_lnum = a:default_lnum
    let is_cursor_after_listing = ( cursor_line > a:default_lnum )
    let whitespaces_in_first_line = ''
  endif

  let start_of_listing = start_lnum

  " write new listing
  let new_header = whitespaces_in_first_line
        \ . s:safesubstitute(vimwiki#vars#get_syntaxlocal('rxH1_Template'),
        \ '__Header__', a:start_header, '')
  call append(start_lnum - 1, new_header)
  let start_lnum += 1
  let lines_diff += 1 + len(a:strings)
  for string in a:strings
    call append(start_lnum - 1, string)
    let start_lnum += 1
  endfor
  " append an empty line if there is not one
  if start_lnum <= line('$') && getline(start_lnum) !~# '\m^\s*$'
    call append(start_lnum - 1, '')
    let lines_diff += 1
  endif

  " Open fold, if needed
  if !is_fold_closed && ( foldclosed(start_of_listing) > -1 )
    exe start_of_listing
    norm! zo
  endif

  if is_cursor_after_listing
    let winview_save.lnum += lines_diff
  endif
  call winrestview(winview_save)
endfunction


function! vimwiki#base#find_next_link()
  call vimwiki#base#search_word(vimwiki#vars#get_syntaxlocal('rxAnyLink'), '')
endfunction


function! vimwiki#base#find_prev_link()
  "Jump 2 times if the cursor is in the middle of a link
  if synIDattr(synID(line('.'), col('.'), 0), "name") =~# "VimwikiLink.*" &&
        \ synIDattr(synID(line('.'), col('.')-1, 0), "name") =~# "VimwikiLink.*"
    call vimwiki#base#search_word(vimwiki#vars#get_syntaxlocal('rxAnyLink'), 'b')
  endif
  call vimwiki#base#search_word(vimwiki#vars#get_syntaxlocal('rxAnyLink'), 'b')
endfunction


function! vimwiki#base#follow_link(split, ...)
  let reuse_other_split_window = a:0 >= 1 ? a:1 : 0
  let move_cursor_to_new_window = a:0 >= 2 ? a:2 : 1

  " Parse link at cursor and pass to VimwikiLinkHandler, or failing that, the
  " default open_link handler

  " try WikiLink
  let lnk = matchstr(vimwiki#base#matchstr_at_cursor(vimwiki#vars#get_syntaxlocal('rxWikiLink')),
        \ vimwiki#vars#get_syntaxlocal('rxWikiLinkMatchUrl'))
  " try WikiIncl
  if lnk == ""
    let lnk = matchstr(vimwiki#base#matchstr_at_cursor(vimwiki#vars#get_global('rxWikiIncl')),
          \ vimwiki#vars#get_global('rxWikiInclMatchUrl'))
  endif
  " try Weblink
  if lnk == ""
    let lnk = matchstr(vimwiki#base#matchstr_at_cursor(vimwiki#vars#get_syntaxlocal('rxWeblink')),
          \ vimwiki#vars#get_syntaxlocal('rxWeblinkMatchUrl'))
  endif

  if lnk != ""    " cursor is indeed on a link
    let processed_by_user_defined_handler = VimwikiLinkHandler(lnk)
    if processed_by_user_defined_handler
      return
    endif

    if a:split ==# "hsplit"
      let cmd = ":split "
    elseif a:split ==# "vsplit"
      let cmd = ":vsplit "
    elseif a:split ==# "tab"
      let cmd = ":tabnew "
    else
      let cmd = ":e "
    endif

    " if we want to and can reuse a split window, jump to that window and open
    " the new file there
    if (a:split ==# 'hsplit' || a:split ==# 'vsplit') && reuse_other_split_window
      let previous_window_nr = winnr('#')
      if previous_window_nr > 0 && previous_window_nr != winnr()
        execute previous_window_nr . 'wincmd w'
        let cmd = ':e'
      endif
    endif


    if vimwiki#vars#get_wikilocal('syntax') == 'markdown'
      let processed_by_markdown_reflink = vimwiki#markdown_base#open_reflink(lnk)
      if processed_by_markdown_reflink
        return
      endif

      " remove the extension from the filename if exists, because non-vimwiki
      " markdown files usually include the extension in links
      let lnk = substitute(lnk, '\'.vimwiki#vars#get_wikilocal('ext').'$', '', '')
    endif

    let current_tab_page = tabpagenr()

    call vimwiki#base#open_link(cmd, lnk)

    if !move_cursor_to_new_window
      if (a:split ==# 'hsplit' || a:split ==# 'vsplit')
        execute 'wincmd p'
      elseif a:split ==# 'tab'
        execute 'tabnext ' . current_tab_page
      endif
    endif

  else
    if a:0 >= 3
      execute "normal! ".a:3
    else
      call vimwiki#base#normalize_link(0)
    endif
  endif
endfunction


function! vimwiki#base#go_back_link()
  let prev_link = vimwiki#vars#get_bufferlocal('prev_link')
  if !empty(prev_link)
    " go back to saved wiki link
    call vimwiki#base#edit_file(':e ', prev_link[0], '')
    call setpos('.', prev_link[1])
  else
    " maybe we came here by jumping to a tag -> pop from the tag stack
    silent! pop!
  endif
endfunction


function! vimwiki#base#goto_index(wnum, ...)
  if a:wnum > vimwiki#vars#number_of_wikis()
    echomsg 'Vimwiki Error: Wiki '.a:wnum.' is not registered in your Vimwiki settings!'
    return
  endif

  " usually a:wnum is greater then 0 but with the following command it is == 0:
  " vim -n -c ":VimwikiIndex"
  if a:wnum > 0
    let idx = a:wnum - 1
  else
    let idx = 0
  endif

  if a:0
    if a:1 == 1
      let cmd = 'tabedit'
    elseif a:1 == 2
      let cmd = 'split'
    elseif a:1 == 3
      let cmd = 'vsplit'
    endif
  else
    let cmd = 'edit'
  endif

  let index_file = vimwiki#vars#get_wikilocal('path', idx).
        \ vimwiki#vars#get_wikilocal('index', idx).
        \ vimwiki#vars#get_wikilocal('ext', idx)

  call vimwiki#base#edit_file(cmd, index_file, '')
endfunction


function! vimwiki#base#delete_link()
  " Delete wiki file you are in from filesystem
  let val = input('Delete "'.expand('%').'" [y]es/[N]o? ')
  if val !~? '^y'
    return
  endif
  let fname = expand('%:p')
  try
    call delete(fname)
  catch /.*/
    echomsg 'Vimwiki Error: Cannot delete "'.expand('%:t:r').'"!'
    return
  endtry

  call vimwiki#base#go_back_link()
  execute "bdelete! ".escape(fname, " ")

  " reread buffer => deleted wiki link should appear as non-existent
  if expand('%:p') != ""
    execute "e"
  endif
endfunction


" Rename current file, update all links to it
function! vimwiki#base#rename_link()
  let subdir = vimwiki#vars#get_bufferlocal('subdir')
  let old_fname = subdir.expand('%:t')

  " there is no file (new one maybe)
  if glob(expand('%:p')) == ''
    echomsg 'Vimwiki Error: Cannot rename "'.expand('%:p').
          \'". It does not exist! (New file? Save it before renaming.)'
    return
  endif

  let val = input('Rename "'.expand('%:t:r').'" [y]es/[N]o? ')
  if val !~? '^y'
    return
  endif

  let new_link = input('Enter new name: ')

  if new_link =~# '[/\\]'
    " It is actually doable but I do not have free time to do it.
    echomsg 'Vimwiki Error: Cannot rename to a filename with path!'
    return
  endif

  " check new_fname - it should be 'good', not empty
  if substitute(new_link, '\s', '', 'g') == ''
    echomsg 'Vimwiki Error: Cannot rename to an empty filename!'
    return
  endif

  let url = matchstr(new_link, vimwiki#vars#get_syntaxlocal('rxWikiLinkMatchUrl'))
  if url != ''
    let new_link = url
  endif

  let new_link = subdir.new_link
  let new_fname = vimwiki#vars#get_wikilocal('path') . new_link . vimwiki#vars#get_wikilocal('ext')

  " do not rename if file with such name exists
  let fname = glob(new_fname)
  if fname != ''
    echomsg 'Vimwiki Error: Cannot rename to "'.new_fname.'". File with that name exist!'
    return
  endif
  " rename wiki link file
  try
    echomsg 'Vimwiki: Renaming '.vimwiki#vars#get_wikilocal('path').old_fname.' to '.new_fname
    let res = rename(expand('%:p'), expand(new_fname))
    if res != 0
      throw "Cannot rename!"
    end
  catch /.*/
    echomsg 'Vimwiki Error: Cannot rename "'.expand('%:t:r').'" to "'.new_fname.'"'
    return
  endtry

  let &buftype="nofile"

  let cur_buffer = [expand('%:p'), vimwiki#vars#get_bufferlocal('prev_link')]

  let blist = s:get_wiki_buffers()

  " save wiki buffers
  for bitem in blist
    execute ':b '.escape(bitem[0], ' ')
    execute ':update'
  endfor

  execute ':b '.escape(cur_buffer[0], ' ')

  " remove wiki buffers
  for bitem in blist
    execute 'bwipeout '.escape(bitem[0], ' ')
  endfor

  let setting_more = &more
  setlocal nomore

  " update links
  call s:update_wiki_links(s:tail_name(old_fname), new_link)

  " restore wiki buffers
  for bitem in blist
    if !vimwiki#path#is_equal(bitem[0], cur_buffer[0])
      call s:open_wiki_buffer(bitem)
    endif
  endfor

  call s:open_wiki_buffer([new_fname, cur_buffer[1]])
  " execute 'bwipeout '.escape(cur_buffer[0], ' ')

  echomsg 'Vimwiki: '.old_fname.' is renamed to '.new_fname

  let &more = setting_more
endfunction


function! vimwiki#base#ui_select()
  call s:print_wiki_list()
  let idx = input("Select Wiki (specify number): ")
  if idx == ""
    return
  endif
  call vimwiki#base#goto_index(idx)
endfunction


function! vimwiki#base#TO_header(inner, including_subheaders, count)
  let headers = s:collect_headers()
  if empty(headers)
    return
  endif

  let current_line = line('.')

  let current_header_index = s:current_header(headers, current_line)

  if current_header_index < 0
    return
  endif

  " from which to which header
  if !a:including_subheaders && a:count <= 1
    let first_line = headers[current_header_index][0]
    let last_line = current_header_index == len(headers)-1 ? line('$') :
          \ headers[current_header_index + 1][0] - 1
  else
    let first_header_index = current_header_index
    for _ in range(a:count - 1)
      let parent = s:get_another_header(headers, first_header_index, -1, '<')
      if parent < 0
        break
      else
        let first_header_index = parent
      endif
    endfor

    let next_sibling_or_higher = s:get_another_header(headers, first_header_index, +1, '<=')

    let first_line = headers[first_header_index][0]
    let last_line =
          \ next_sibling_or_higher >= 0 ? headers[next_sibling_or_higher][0] - 1 : line('$')
  endif

  if a:inner
    let first_line += 1
    let last_line = prevnonblank(last_line)
  endif

  if first_line > last_line
    " this can happen e.g. when doing vih on a header with another header in the very next line
    return
  endif

  call cursor(first_line, 1)
  normal! V
  call cursor(last_line, 1)
endfunction


function! vimwiki#base#TO_table_cell(inner, visual)
  if col('.') == col('$')-1
    return
  endif

  if a:visual
    normal! `>
    let sel_end = getpos('.')
    normal! `<
    let sel_start = getpos('.')

    let firsttime = sel_start == sel_end

    if firsttime
      if !search('|\|\(-+-\)', 'cb', line('.'))
        return
      endif
      if getline('.')[virtcol('.')] == '+'
        normal! l
      endif
      if a:inner
        normal! 2l
      endif
      let sel_start = getpos('.')
    endif

    normal! `>
    call search('|\|\(-+-\)', '', line('.'))
    if getline('.')[virtcol('.')] == '+'
      normal! l
    endif
    if a:inner
      if firsttime || abs(sel_end[2] - getpos('.')[2]) != 2
        normal! 2h
      endif
    endif
    let sel_end = getpos('.')

    call setpos('.', sel_start)
    exe "normal! \<C-v>"
    call setpos('.', sel_end)

    " XXX: WORKAROUND.
    " if blockwise selection is ended at | character then pressing j to extend
    " selection further fails. But if we shake the cursor left and right then
    " it works.
    normal! hl
  else
    if !search('|\|\(-+-\)', 'cb', line('.'))
      return
    endif
    if a:inner
      normal! 2l
    endif
    normal! v
    call search('|\|\(-+-\)', '', line('.'))
    if !a:inner && getline('.')[virtcol('.')-1] == '|'
      normal! h
    elseif a:inner
      normal! 2h
    endif
  endif
endfunction


function! vimwiki#base#TO_table_col(inner, visual)
  let t_rows = vimwiki#tbl#get_rows(line('.'))
  if empty(t_rows)
    return
  endif

  " TODO: refactor it!
  if a:visual
    normal! `>
    let sel_end = getpos('.')
    normal! `<
    let sel_start = getpos('.')

    let firsttime = sel_start == sel_end

    if firsttime
      " place cursor to the top row of the table
      call vimwiki#u#cursor(t_rows[0][0], virtcol('.'))
      " do not accept the match at cursor position if cursor is next to column
      " separator of the table separator (^ is a cursor):
      " |-----^-+-------|
      " | bla   | bla   |
      " |-------+-------|
      " or it will select wrong column.
      if strpart(getline('.'), virtcol('.')-1) =~# '^-+'
        let s_flag = 'b'
      else
        let s_flag = 'cb'
      endif
      " search the column separator backwards
      if !search('|\|\(-+-\)', s_flag, line('.'))
        return
      endif
      " -+- column separator is matched --> move cursor to the + sign
      if getline('.')[virtcol('.')] == '+'
        normal! l
      endif
      " inner selection --> reduce selection
      if a:inner
        normal! 2l
      endif
      let sel_start = getpos('.')
    endif

    normal! `>
    if !firsttime && getline('.')[virtcol('.')] == '|'
      normal! l
    elseif a:inner && getline('.')[virtcol('.')+1] =~# '[|+]'
      normal! 2l
    endif
    " search for the next column separator
    call search('|\|\(-+-\)', '', line('.'))
    " Outer selection selects a column without border on the right. So we move
    " our cursor left if the previous search finds | border, not -+-.
    if getline('.')[virtcol('.')] != '+'
      normal! h
    endif
    if a:inner
      " reduce selection a bit more if inner.
      normal! h
    endif
    " expand selection to the bottom line of the table
    call vimwiki#u#cursor(t_rows[-1][0], virtcol('.'))
    let sel_end = getpos('.')

    call setpos('.', sel_start)
    exe "normal! \<C-v>"
    call setpos('.', sel_end)

  else
    " place cursor to the top row of the table
    call vimwiki#u#cursor(t_rows[0][0], virtcol('.'))
    " do not accept the match at cursor position if cursor is next to column
    " separator of the table separator (^ is a cursor):
    " |-----^-+-------|
    " | bla   | bla   |
    " |-------+-------|
    " or it will select wrong column.
    if strpart(getline('.'), virtcol('.')-1) =~# '^-+'
      let s_flag = 'b'
    else
      let s_flag = 'cb'
    endif
    " search the column separator backwards
    if !search('|\|\(-+-\)', s_flag, line('.'))
      return
    endif
    " -+- column separator is matched --> move cursor to the + sign
    if getline('.')[virtcol('.')] == '+'
      normal! l
    endif
    " inner selection --> reduce selection
    if a:inner
      normal! 2l
    endif

    exe "normal! \<C-V>"

    " search for the next column separator
    call search('|\|\(-+-\)', '', line('.'))
    " Outer selection selects a column without border on the right. So we move
    " our cursor left if the previous search finds | border, not -+-.
    if getline('.')[virtcol('.')] != '+'
      normal! h
    endif
    " reduce selection a bit more if inner.
    if a:inner
      normal! h
    endif
    " expand selection to the bottom line of the table
    call vimwiki#u#cursor(t_rows[-1][0], virtcol('.'))
  endif
endfunction


function! vimwiki#base#AddHeaderLevel()
  let lnum = line('.')
  let line = getline(lnum)
  let rxHdr = vimwiki#vars#get_syntaxlocal('rxH')
  if line =~# '^\s*$'
    return
  endif

  if line =~# vimwiki#vars#get_syntaxlocal('rxHeader')
    let level = vimwiki#u#count_first_sym(line)
    if level < 6
      if vimwiki#vars#get_syntaxlocal('symH')
        let line = substitute(line, '\('.rxHdr.'\+\).\+\1', rxHdr.'&'.rxHdr, '')
      else
        let line = substitute(line, '\('.rxHdr.'\+\).\+', rxHdr.'&', '')
      endif
      call setline(lnum, line)
    endif
  else
    let line = substitute(line, '^\s*', '&'.rxHdr.' ', '')
    if vimwiki#vars#get_syntaxlocal('symH')
      let line = substitute(line, '\s*$', ' '.rxHdr.'&', '')
    endif
    call setline(lnum, line)
  endif
endfunction


function! vimwiki#base#RemoveHeaderLevel()
  let lnum = line('.')
  let line = getline(lnum)
  let rxHdr = vimwiki#vars#get_syntaxlocal('rxH')
  if line =~# '^\s*$'
    return
  endif

  if line =~# vimwiki#vars#get_syntaxlocal('rxHeader')
    let level = vimwiki#u#count_first_sym(line)
    let old = repeat(rxHdr, level)
    let new = repeat(rxHdr, level - 1)

    let chomp = line =~# rxHdr.'\s'

    if vimwiki#vars#get_syntaxlocal('symH')
      let line = substitute(line, old, new, 'g')
    else
      let line = substitute(line, old, new, '')
    endif

    if level == 1 && chomp
      let line = substitute(line, '^\s', '', 'g')
      let line = substitute(line, '\s$', '', 'g')
    endif

    let line = substitute(line, '\s*$', '', '')

    call setline(lnum, line)
  endif
endfunction



" Returns all the headers in the current buffer as a list of the form
" [[line_number, header_level, header_text], [...], [...], ...]
function! s:collect_headers()
  let is_inside_pre_or_math = 0  " 1: inside pre, 2: inside math, 0: outside
  let headers = []
  for lnum in range(1, line('$'))
    let line_content = getline(lnum)
    if (is_inside_pre_or_math == 1 && line_content =~# vimwiki#vars#get_syntaxlocal('rxPreEnd')) ||
       \ (is_inside_pre_or_math == 2 && line_content =~# vimwiki#vars#get_syntaxlocal('rxMathEnd'))
      let is_inside_pre_or_math = 0
      continue
    endif
    if is_inside_pre_or_math > 0
      continue
    endif
    if line_content =~# vimwiki#vars#get_syntaxlocal('rxPreStart')
      let is_inside_pre_or_math = 1
      continue
    endif
    if line_content =~# vimwiki#vars#get_syntaxlocal('rxMathStart')
      let is_inside_pre_or_math = 2
      continue
    endif
    if line_content !~# vimwiki#vars#get_syntaxlocal('rxHeader')
      continue
    endif
    let header_level = vimwiki#u#count_first_sym(line_content)
    let header_text =
          \ vimwiki#u#trim(matchstr(line_content, vimwiki#vars#get_syntaxlocal('rxHeader')))
    call add(headers, [lnum, header_level, header_text])
  endfor

  return headers
endfunction


function! s:current_header(headers, line_number)
  if empty(a:headers)
    return -1
  endif

  if a:line_number >= a:headers[-1][0]
    return len(a:headers) - 1
  endif

  let current_header_index = -1
  while a:headers[current_header_index+1][0] <= a:line_number
    let current_header_index += 1
  endwhile
  return current_header_index
endfunction


function! s:get_another_header(headers, current_index, direction, operation)
  if empty(a:headers) || a:current_index < 0
    return -1
  endif
  let current_level = a:headers[a:current_index][1]
  let index = a:current_index + a:direction

  while 1
    if index < 0 || index >= len(a:headers)
      return -1
    endif
    if eval('a:headers[index][1] ' . a:operation . ' current_level')
      return index
    endif
    let index += a:direction
  endwhile
endfunction


function! vimwiki#base#goto_parent_header()
  let headers = s:collect_headers()
  let current_header_index = s:current_header(headers, line('.'))
  let parent_header = s:get_another_header(headers, current_header_index, -1, '<')
  if parent_header >= 0
    call cursor(headers[parent_header][0], 1)
  else
    echo 'Vimwiki: no parent header found'
  endif
endfunction


function! vimwiki#base#goto_next_header()
  let headers = s:collect_headers()
  let current_header_index = s:current_header(headers, line('.'))
  if current_header_index >= 0 && current_header_index < len(headers) - 1
    call cursor(headers[current_header_index + 1][0], 1)
  elseif current_header_index < 0 && !empty(headers)  " we're above the first header
    call cursor(headers[0][0], 1)
  else
    echo 'Vimwiki: no next header found'
  endif
endfunction


function! vimwiki#base#goto_prev_header()
  let headers = s:collect_headers()
  let current_header_index = s:current_header(headers, line('.'))
  " if the cursor already was on a header, jump to the previous one
  if current_header_index >= 1 && headers[current_header_index][0] == line('.')
    let current_header_index -= 1
  endif
  if current_header_index >= 0
    call cursor(headers[current_header_index][0], 1)
  else
    echo 'Vimwiki: no previous header found'
  endif
endfunction


function! vimwiki#base#goto_sibling(direction)
  let headers = s:collect_headers()
  let current_header_index = s:current_header(headers, line('.'))
  let next_potential_sibling =
        \ s:get_another_header(headers, current_header_index, a:direction, '<=')
  if next_potential_sibling >= 0 && headers[next_potential_sibling][1] ==
        \ headers[current_header_index][1]
    call cursor(headers[next_potential_sibling][0], 1)
  else
    echo 'Vimwiki: no sibling header found'
  endif
endfunction


" a:create == 1: creates or updates TOC in current file
" a:create == 0: update if TOC exists
function! vimwiki#base#table_of_contents(create)
  let headers = s:collect_headers()
  let numbering = vimwiki#vars#get_global('html_header_numbering')
  let headers_levels = [['', 0], ['', 0], ['', 0], ['', 0], ['', 0], ['', 0]]
  let complete_header_infos = []
  for header in headers
    let h_text = header[2]
    let h_level = header[1]
    if h_text ==# vimwiki#vars#get_global('toc_header')  " don't include the TOC's header itself
      continue
    endif
    let headers_levels[h_level-1] = [h_text, headers_levels[h_level-1][1]+1]
    for idx in range(h_level, 5) | let headers_levels[idx] = ['', 0] | endfor

    let h_complete_id = ''
    for l in range(h_level-1)
      if headers_levels[l][0] != ''
        let h_complete_id .= headers_levels[l][0].'#'
      endif
    endfor
    let h_complete_id .= headers_levels[h_level-1][0]

    if numbering > 0 && numbering <= h_level
      let h_number = join(map(copy(headers_levels[numbering-1 : h_level-1]), 'v:val[1]'), '.')
      let h_number .= vimwiki#vars#get_global('html_header_numbering_sym')
      let h_text = h_number.' '.h_text
    endif

    call add(complete_header_infos, [h_level, h_complete_id, h_text])
  endfor

  let lines = []
  let startindent = repeat(' ', vimwiki#lst#get_list_margin())
  let indentstring = repeat(' ', vimwiki#u#sw())
  let bullet = vimwiki#lst#default_symbol().' '
  for [lvl, link, desc] in complete_header_infos
    let esc_link = substitute(link, "'", "''", 'g')
    let esc_desc = substitute(desc, "'", "''", 'g')
    let link_tpl = vimwiki#vars#get_global('WikiLinkTemplate2')
    if vimwiki#vars#get_wikilocal('syntax') == 'markdown'
      let link_tpl = vimwiki#vars#get_syntaxlocal('Weblink1Template')
    endif
    let link = s:safesubstitute(link_tpl, '__LinkUrl__',
          \ '#'.esc_link, '')
    let link = s:safesubstitute(link, '__LinkDescription__', esc_desc, '')
    call add(lines, startindent.repeat(indentstring, lvl-1).bullet.link)
  endfor

  let links_rx = '\m^\s*'.vimwiki#u#escape(vimwiki#lst#default_symbol()).' '

  call vimwiki#base#update_listing_in_buffer(lines,
        \ vimwiki#vars#get_global('toc_header'), links_rx, 1, a:create)
endfunction


"   Construct a regular expression matching from template (with special
"   characters properly escaped), by substituting rxUrl for __LinkUrl__, rxDesc
"   for __LinkDescription__, and rxStyle for __LinkStyle__.  The three
"   arguments rxUrl, rxDesc, and rxStyle are copied verbatim, without any
"   special character escapes or substitutions.
function! vimwiki#base#apply_template(template, rxUrl, rxDesc, rxStyle)
  let lnk = a:template
  if a:rxUrl != ""
    let lnk = s:safesubstitute(lnk, '__LinkUrl__', a:rxUrl, 'g')
  endif
  if a:rxDesc != ""
    let lnk = s:safesubstitute(lnk, '__LinkDescription__', a:rxDesc, 'g')
  endif
  if a:rxStyle != ""
    let lnk = s:safesubstitute(lnk, '__LinkStyle__', a:rxStyle, 'g')
  endif
  return lnk
endfunction


function! s:clean_url(url)
  " remove protocol and tld
  let url = substitute(a:url, '^\a\+\d*:', '', '')
  let url = substitute(url, '^//', '', '')
  let url = substitute(url, '^\([^/]\+\).\a\{2,4}/', '\1/', '')
  let url = split(url, '/\|=\|-\|&\|?\|\.')
  let url = filter(url, 'v:val !=# ""')
  if url[0] == "www"
    let url = url[1:]
  endif
  if url[-1] =~ '^\(htm\|html\|php\)$'
    let url = url[0:-2]
  endif
  " remove words consisting of only hexadecimal digits or non-word characters
  let url = filter(url, 'v:val !~  "^\\A\\{4,}$"')
  let url = filter(url, 'v:val !~  "^\\x\\{4,}$" || v:val !~ "\\d"')
  return join(url, " ")
endfunction


function! s:is_diary_file(filename)
  let file_path = vimwiki#path#path_norm(a:filename)
  let rel_path = vimwiki#vars#get_wikilocal('diary_rel_path')
  let diary_path = vimwiki#path#path_norm(vimwiki#vars#get_wikilocal('path') . rel_path)
  return rel_path != '' && file_path =~# '^'.vimwiki#u#escape(diary_path)
endfunction


function! vimwiki#base#normalize_link_helper(str, rxUrl, rxDesc, template)
  let url = matchstr(a:str, a:rxUrl)
  let descr = matchstr(a:str, a:rxDesc)
  if descr == ""
    let descr = s:clean_url(url)
  endif
  let lnk = s:safesubstitute(a:template, '__LinkDescription__', descr, '')
  let lnk = s:safesubstitute(lnk, '__LinkUrl__', url, '')
  return lnk
endfunction


function! vimwiki#base#normalize_imagelink_helper(str, rxUrl, rxDesc, rxStyle, template)
  let lnk = vimwiki#base#normalize_link_helper(a:str, a:rxUrl, a:rxDesc, a:template)
  let style = matchstr(a:str, a:rxStyle)
  let lnk = s:safesubstitute(lnk, '__LinkStyle__', style, '')
  return lnk
endfunction


function! s:normalize_link_in_diary(lnk)
  let link = a:lnk . vimwiki#vars#get_wikilocal('ext')
  let link_wiki = vimwiki#vars#get_wikilocal('path') . '/' . link
  let link_diary = vimwiki#vars#get_wikilocal('path') . '/'
        \ . vimwiki#vars#get_wikilocal('diary_rel_path') . '/' . link
  let link_exists_in_diary = filereadable(link_diary)
  let link_exists_in_wiki = filereadable(link_wiki)
  let link_is_date = a:lnk =~# '\d\d\d\d-\d\d-\d\d'

  if ! link_exists_in_wiki || link_exists_in_diary || link_is_date
    let str = a:lnk
    let rxUrl = vimwiki#vars#get_global('rxWord')
    let rxDesc = ''
    let template = vimwiki#vars#get_global('WikiLinkTemplate1')
  else
    let depth = len(split(vimwiki#vars#get_wikilocal('diary_rel_path'), '/'))
    let str = repeat('../', depth) . a:lnk . '|' . a:lnk
    let rxUrl = '^.*\ze|'
    let rxDesc = '|\zs.*$'
    let template = vimwiki#vars#get_global('WikiLinkTemplate2')
  endif

  return vimwiki#base#normalize_link_helper(str, rxUrl, rxDesc, template)
endfunction


function! s:normalize_link_syntax_n()

  " try WikiLink
  let lnk = vimwiki#base#matchstr_at_cursor(vimwiki#vars#get_syntaxlocal('rxWikiLink'))
  if !empty(lnk)
    let sub = vimwiki#base#normalize_link_helper(lnk,
          \ vimwiki#vars#get_syntaxlocal('rxWikiLinkMatchUrl'),
          \ vimwiki#vars#get_syntaxlocal('rxWikiLinkMatchDescr'),
          \ vimwiki#vars#get_global('WikiLinkTemplate2'))
    call vimwiki#base#replacestr_at_cursor(vimwiki#vars#get_syntaxlocal('rxWikiLink'), sub)
    return
  endif

  " try WikiIncl
  let lnk = vimwiki#base#matchstr_at_cursor(vimwiki#vars#get_global('rxWikiIncl'))
  if !empty(lnk)
    " NO-OP !!
    return
  endif

  " try Weblink
  let lnk = vimwiki#base#matchstr_at_cursor(vimwiki#vars#get_syntaxlocal('rxWeblink'))
  if !empty(lnk)
    let sub = vimwiki#base#normalize_link_helper(lnk,
          \ lnk, '', vimwiki#vars#get_global('WikiLinkTemplate2'))
    call vimwiki#base#replacestr_at_cursor(vimwiki#vars#get_syntaxlocal('rxWeblink'), sub)
    return
  endif

  " try Word (any characters except separators)
  " rxWord is less permissive than rxWikiLinkUrl which is used in
  " normalize_link_syntax_v
  let lnk = vimwiki#base#matchstr_at_cursor(vimwiki#vars#get_global('rxWord'))
  if !empty(lnk)
    if s:is_diary_file(expand("%:p"))
      let sub = s:normalize_link_in_diary(lnk)
    else
      let sub = vimwiki#base#normalize_link_helper(lnk,
            \ vimwiki#vars#get_global('rxWord'), '',
            \ vimwiki#vars#get_global('WikiLinkTemplate1'))
    endif
    call vimwiki#base#replacestr_at_cursor('\V'.lnk, sub)
    return
  endif

endfunction


function! s:normalize_link_syntax_v()
  let sel_save = &selection
  let &selection = "old"
  let default_register_save = @"
  let registertype_save = getregtype('"')

  try
    " Save selected text to register "
    normal! gv""y

    " Set substitution
    if s:is_diary_file(expand("%:p"))
      let sub = s:normalize_link_in_diary(@")
    else
      let sub = s:safesubstitute(vimwiki#vars#get_global('WikiLinkTemplate1'),
            \ '__LinkUrl__', @", '')
    endif

    " Put substitution in register " and change text
    call setreg('"', substitute(sub, '\n', '', ''), visualmode())
    normal! `>""pgvd
  finally
    call setreg('"', default_register_save, registertype_save)
    let &selection = sel_save
  endtry
endfunction


function! vimwiki#base#normalize_link(is_visual_mode)
  if exists('*vimwiki#'.vimwiki#vars#get_wikilocal('syntax').'_base#normalize_link')
    " Syntax-specific links
    call vimwiki#{vimwiki#vars#get_wikilocal('syntax')}_base#normalize_link(a:is_visual_mode)
  else
    if !a:is_visual_mode
      call s:normalize_link_syntax_n()
    elseif line("'<") == line("'>")
      " action undefined for multi-line visual mode selections
      call s:normalize_link_syntax_v()
    endif
  endif
endfunction


function! vimwiki#base#detect_nested_syntax()
  let last_word = '\v.*<(\w+)\s*$'
  let lines = map(filter(getline(1, "$"), 'v:val =~ "\\%({{{\\|```\\)" && v:val =~ last_word'),
        \ 'substitute(v:val, last_word, "\\=submatch(1)", "")')
  let dict = {}
  for elem in lines
    let dict[elem] = elem
  endfor
  return dict
endfunction


function! vimwiki#base#complete_links_escaped(ArgLead, CmdLine, CursorPos) abort
  " We can safely ignore args if we use -custom=complete option, Vim engine
  " will do the job of filtering.
  return vimwiki#base#get_globlinks_escaped()
endfunction


" -------------------------------------------------------------------------
" Load syntax-specific Wiki functionality
for s:syn in s:vimwiki_get_known_syntaxes()
  execute 'runtime! autoload/vimwiki/'.s:syn.'_base.vim'
endfor
" -------------------------------------------------------------------------

