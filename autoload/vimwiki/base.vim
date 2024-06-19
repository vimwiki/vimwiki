" vim:tabstop=2:shiftwidth=2:expandtab:textwidth=99
" Vimwiki autoload plugin file
" Desc: Basic functionality
" Called by plugin/vimwiki.vim and ftplugin/vimwiki.vim
" by global and vimwiki local map and commands
" Home: https://github.com/vimwiki/vimwiki/

" Clause: load only once
if exists('g:loaded_vimwiki_auto') || &compatible
  finish
endif
let g:loaded_vimwiki_auto = 1


let g:vimwiki_max_scan_for_caption = 5


function! s:safesubstitute(text, search, replace, mode) abort
  " Substitute regexp but do not interpret replace
  let escaped = escape(a:replace, '\&')
  return substitute(a:text, a:search, escaped, a:mode)
endfunction


function! s:vimwiki_get_known_syntaxes() abort
  " Get all vimwiki known syntaxes
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


function! vimwiki#base#file_pattern(files) abort
  " Get search regex from glob()
  " string. Aim to support *all* special characters, forcing the user to choose
  "   names that are compatible with any external restrictions that they
  "   encounter (e.g. filesystem, wiki conventions, other syntaxes, ...).
  "   See: https://github.com/vimwiki-backup/vimwiki/issues/316
  " Change / to [/\\] to allow "Windows paths"
  return '\V\%('.join(a:files, '\|').'\)\m'
endfunction


function! vimwiki#base#subdir(path, filename) abort
  " TODO move in path
  " FIXME TODO slow and faulty
  let path = a:path
  " ensure that we are not fooled by a symbolic link
  "FIXME if we are not "fooled", we end up in a completely different wiki?
  if a:filename !~# '^scp:'
    let filename = resolve(a:filename)
  else
    let filename = a:filename
  endif
  let idx = 0
  let pathelement = split(path, '[/\\]')
  let fileelement = split(filename, '[/\\]')
  let minlen = min([len(pathelement), len(fileelement)])
  let p = fileelement[:]
  while pathelement[idx] ==? fileelement[idx]
    let p = p[1:]
    let idx = idx + 1
    if idx == minlen
      break
    endif
  endwhile

  let res = join(p[:-2], '/')
  if len(res) > 0
    let res = res.'/'
  endif
  return res
endfunction


function! vimwiki#base#current_subdir() abort
  " TODO move in path
  return vimwiki#base#subdir(vimwiki#vars#get_wikilocal('path'), expand('%:p'))
endfunction


function! vimwiki#base#invsubdir(subdir) abort
  " TODO move in path
  return substitute(a:subdir, '[^/\.]\+/', '../', 'g')
endfunction


function! vimwiki#base#find_wiki(path) abort
  " Returns: the number of the wiki a file belongs to or -1 if it doesn't belong
  " to any registered wiki.
  " The path can be the full path or just the directory of the file
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


function! s:is_wiki_link(link_infos) abort
  " Check if a link is a well formed wiki link (Helper)
  return a:link_infos.scheme =~# '\mwiki\d\+' || a:link_infos.scheme ==# 'diary'
endfunction


function! vimwiki#base#resolve_link(link_text, ...) abort
  " Extract infos about the target from a link.
  " THE central function of Vimwiki.
  " If the second parameter is present, which should be an absolute file path, it
  " is assumed that the link appears in that file. Without it, the current file
  " is used.
  if a:0
    let source_wiki = vimwiki#base#find_wiki(a:1)
    let source_file = a:1
  else
    let source_wiki = vimwiki#vars#get_bufferlocal('wiki_nr')
    let source_file = vimwiki#path#current_wiki_file()
  endif

  " Get rid of '\' in escaped characters in []() style markdown links
  " other style links don't allow '\'
  let link_text = substitute(a:link_text, '\(\\\)\(\W\)\@=', '', 'g')

  let link_infos = {
        \ 'index': -1,
        \ 'scheme': '',
        \ 'filename': '',
        \ 'anchor': '',
        \ }

  if link_text ==? ''
    return link_infos
  endif

  let scheme = matchstr(link_text, '^\zs'.vimwiki#vars#get_global('rxSchemes').'\ze:')
  if scheme ==? ''
    " interwiki link scheme is default
    let link_infos.scheme = 'wiki'.source_wiki
  else
    let link_infos.scheme = scheme

    if link_infos.scheme !~# '\mwiki\d\+\|diary\|local\|file'
      let link_infos.filename = link_text  " unknown scheme, may be a weblink
      return link_infos
    endif

    let link_text = matchstr(link_text, '^'.vimwiki#vars#get_global('rxSchemes').':\zs.*\ze')
  endif

  let is_wiki_link = s:is_wiki_link(link_infos)

  " Extract anchor
  if is_wiki_link
    let split_lnk = split(link_text, '#', 1)
    let link_text = split_lnk[0]
    if len(split_lnk) > 1 && split_lnk[-1] !=? ''
      let link_infos.anchor = join(split_lnk[1:], '#')
    endif
    if link_text ==? ''  " because the link was of the form '#anchor'
      let expected_ext = vimwiki#u#escape(vimwiki#vars#get_wikilocal('ext')).'$'
      if source_file =~# expected_ext
          " Source file has expected extension. Remove it, it will be added later on
          let ext_len = strlen(vimwiki#vars#get_wikilocal('ext'))
          let link_text = fnamemodify(source_file, ':p:t')[:-ext_len-1]
      endif

    endif
  endif

  if vimwiki#path#is_absolute(link_text)
    let link_text = expand(link_text)
  endif

  " This gets set for leading // links, which point to an absolute path to a
  " wiki page (minus the .md or .wiki extension):
  let is_absolute_wiki_link = 0

  if is_wiki_link && link_text[0] ==# '/'
    if link_text !=# '/'
      if link_text !=# '//' && link_text[0:1] ==# '//'
        let link_text = resolve(expand(link_text))
        let link_text = link_text[2:]
        let is_absolute_wiki_link = 1
      else
        let link_text = link_text[1:]
      endif
    endif
    let is_relative = 0
  elseif !is_wiki_link && vimwiki#path#is_absolute(link_text)
    let is_relative = 0
  else
    let is_relative = 1
    let root_dir = fnamemodify(source_file, ':p:h') . '/'
  endif

  " Extract the other items depending on the scheme
  if link_infos.scheme =~# '\mwiki\d\+'

    " interwiki link named wiki 'wn.name:link' format
    let wnmatch = matchlist(link_text, '\m^wn\.\([a-zA-Z0-9\-_ ]\+\):\(.*\)')
    if len(wnmatch) >= 2 && wnmatch[1] !=? '' && wnmatch[2] !=? ''
      let wname = wnmatch[1]
      for idx in range(vimwiki#vars#number_of_wikis())
        if vimwiki#vars#get_wikilocal('name', idx) ==# wname
          " name matches!
          let link_infos.index = idx
          let link_text = wnmatch[2]
          break
        endif
      endfor
      if link_text !=# wnmatch[2]
        " error: invalid wiki name
        let link_infos.index = -2
        let link_infos.filename = ''
        " use scheme field to return invalid wiki name
        let link_infos.scheme = wname
        return link_infos
      endif
    else
      " interwiki link numbered wiki format
      let link_infos.index = eval(matchstr(link_infos.scheme, '\D\+\zs\d\+\ze'))
      if link_infos.index < 0 || link_infos.index >= vimwiki#vars#number_of_wikis()
        let link_infos.index = -1
        let link_infos.filename = ''
        return link_infos
      endif
    endif

    if is_absolute_wiki_link
      " Leading // link to the absolute path of a wiki page somewhere on the
      " filesystem.
      let root_dir = ''
    elseif !is_relative || link_infos.index != source_wiki
      let root_dir = vimwiki#vars#get_wikilocal('path', link_infos.index)
    endif

    let link_infos.filename = root_dir . link_text

    if vimwiki#path#is_link_to_dir(link_text)
      if vimwiki#vars#get_global('dir_link') !=? ''
        let link_infos.filename .= vimwiki#vars#get_global('dir_link') .
              \ vimwiki#vars#get_wikilocal('ext', link_infos.index)
      endif
    else
      " append extension if one not already present or it's not the targeted
      " wiki extension - https://github.com/vimwiki/vimwiki/issues/950
      let ext = fnamemodify(link_text, ':e')
      let ext_with_dot = '.' . ext

      " Check if a .md must be added
      " See #1271 to modify files with a "."
      let do_add_ext = ext ==? ''
      if vimwiki#vars#get_syntaxlocal('open_link_add_ext')
        let do_add_ext = do_add_ext || ext_with_dot !=? vimwiki#vars#get_wikilocal('ext', link_infos.index)
      endif

      " Add the dot
      if do_add_ext
        let link_infos.filename .= vimwiki#vars#get_wikilocal('ext', link_infos.index)
      endif
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


function! vimwiki#base#system_open_link(url) abort
  " Open Link with OS handler (like gx)
  " handlers
  function! s:win32_handler(url) abort
    "Disable shellslash for cmd and command.com, but enable for all other shells
    "See Issue #560
    if (&shell =~? 'cmd') || (&shell =~? 'command.com')

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
  function! s:macunix_handler(url) abort
    call system('open ' . shellescape(a:url).' &')
  endfunction
  function! s:linux_handler(url) abort
    call system('xdg-open ' . shellescape(a:url).' >/dev/null 2>&1 &')
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
  call vimwiki#u#error('Default Vimwiki link handler was unable to open the HTML file!')
endfunction


function! vimwiki#base#open_link(cmd, link, ...) abort
  " Open link with Vim (like :e)
  let link_infos = {}
  if a:0
    let link_infos = vimwiki#base#resolve_link(a:link, a:1)
  else
    let link_infos = vimwiki#base#resolve_link(a:link)
  endif

  if link_infos.filename ==? ''
    if link_infos.index == -1
      call vimwiki#u#error('No registered wiki ''' . link_infos.scheme . '''.')
    elseif link_infos.index == -2
      " scheme field stores wiki name for this error case
      call vimwiki#u#error('No wiki found with name "' . link_infos.scheme . '"')
    else
      call vimwiki#u#error('Unable to resolve link!')
    endif
    return
  endif

  let is_wiki_link = s:is_wiki_link(link_infos)

  let vimwiki_prev_link = []
  " update previous link for wiki pages
  if is_wiki_link
    if a:0
      let vimwiki_prev_link = [a:1, []]
    elseif vimwiki#u#ft_is_vw()
      let vimwiki_prev_link = [vimwiki#path#current_wiki_file(), getpos('.')]
    endif
  endif

  " open/edit
  if is_wiki_link
    call vimwiki#base#edit_file(a:cmd, link_infos.filename, link_infos.anchor,
          \ vimwiki_prev_link, is_wiki_link)
  else
    call vimwiki#base#system_open_link(link_infos.filename)
  endif
endfunction


function! vimwiki#base#nop1(stg) abort
  " Nop with one arg, used if callback is required
  return a:stg
endfunction


function! vimwiki#base#get_globlinks_escaped(...) abort
  " Proxy: Called by command completion
  let args = copy(a:000)
  call insert(args, 'fnameescape')
  return call('vimwiki#base#get_globlinks_callback', args)
endfunction


function! vimwiki#base#get_globlinks_raw(...) abort
  " Proxy: Called by command completion
  let args = copy(a:000)
  call insert(args, 'vimwiki#base#nop1')
  return call('vimwiki#base#get_globlinks_callback', args)
endfunction


function! vimwiki#base#get_globlinks_callback(callback, ...) abort
  " Escape global link
  " Called by command completion
  " [1] callback <string> of a function converting file <string> => escaped file <string>
  " -- ex: fnameescape
  let s_arg_lead = a:0 > 0 ? a:1 : ''
  " only get links from the current dir
  " change to the directory of the current file
  let orig_pwd = getcwd()
  lcd! %:h
  " all path are relative to the current file's location
  let globlinks = glob('**/*'.vimwiki#vars#get_wikilocal('ext'), 1)."\n"
  " remove extensions
  let globlinks = substitute(globlinks, '\'.vimwiki#vars#get_wikilocal('ext').'\ze\n', '', 'g')
  " restore the original working directory
  exe 'lcd! '.orig_pwd
  " convert to a List
  let lst = split(globlinks, '\n')
  " Filter files whose path matches the  user's argument leader
  " " use smart case matching
  let r_arg = substitute(s_arg_lead, '\u', '[\0\l\0]', 'g')
  call filter(lst, '-1 != match(v:val, r_arg)')
  " Apply callback to each item
  call map(lst, a:callback . '(v:val)')
  " Return list (for customlist completion)
  return lst
endfunction


function! vimwiki#base#generate_links(create, ...) abort
  " Generate: wikilinks in current file
  " Called: by command VimwikiGenerateLinks (Exported)
  " Param: create: <Bool> Create links or not
  " Param: Optional pattern <String>
  " Get pattern if present
  " Globlal to script to be passed to closure
  if a:0
    let s:pattern = a:1
  else
    let s:pattern = ''
  endif

  " Define link generator closure
  let GeneratorLinks = copy(l:)
  function! GeneratorLinks.f() abort
    let lines = []

    let wiki_nr = vimwiki#vars#get_bufferlocal('wiki_nr')
    let links = vimwiki#base#get_wikilinks(wiki_nr, 0, s:pattern)
    call sort(links)

    let bullet = repeat(' ', vimwiki#lst#get_list_margin()) . vimwiki#lst#default_symbol().' '
    let l:diary_file_paths = vimwiki#diary#get_diary_files()

    let use_caption = vimwiki#vars#get_wikilocal('generated_links_caption', wiki_nr)
    for link in links
      let link_infos = vimwiki#base#resolve_link(link)
      if !vimwiki#base#is_among_diary_files(link_infos.filename, copy(l:diary_file_paths))
        let link_tpl = vimwiki#vars#get_syntaxlocal('Link1')

        let link_caption = vimwiki#base#read_caption(link_infos.filename)
        if link_caption ==? '' " default to link if caption not found
          let link_caption = link
        else
          if use_caption
            " switch to [[URL|DESCRIPTION]] if caption is not empty
            " Link2 is the same for mardown syntax
            let link_tpl = vimwiki#vars#get_syntaxlocal('Link2')
          endif
        endif
        " Replace Url, Description
        let entry = s:safesubstitute(link_tpl, '__LinkUrl__', link, '')
        let entry = s:safesubstitute(entry, '__LinkDescription__', link_caption, '')

        " Replace Extension
        let extension = vimwiki#vars#get_wikilocal('ext', wiki_nr)
        let entry = substitute(entry, '__FileExtension__', extension, 'g')

        call add(lines, bullet. entry)
      endif
    endfor

    return lines
  endfunction

  " Update buffer with generator super power
  let links_rx = '\%(^\s*$\)\|^\s*\%('.vimwiki#vars#get_syntaxlocal('rxListBullet').'\)'
  call vimwiki#base#update_listing_in_buffer(
        \ GeneratorLinks,
        \ vimwiki#vars#get_global('links_header'),
        \ links_rx,
        \ line('$')+1,
        \ vimwiki#vars#get_global('links_header_level'),
        \ a:create)
endfunction


function! vimwiki#base#goto(...) abort
  " Jump: to other wikifile, specified on command mode
  " Called: by command VimwikiGoto (Exported)
  let key = a:0 > 0 && a:1 !=# '' ? a:1 : input('Enter name: ', '',
        \ 'customlist,vimwiki#base#complete_links_raw')

  if key ==# ''
    " Input cancelled
    return
  endif

  let anchor = a:0 > 1 ? a:2 : ''

  " Save current file pos
  let vimwiki_prev_link = [vimwiki#path#current_wiki_file(), getpos('.')]

  call vimwiki#base#edit_file('edit',
        \ vimwiki#vars#get_wikilocal('path') . key . vimwiki#vars#get_wikilocal('ext'),
        \ anchor,
        \ vimwiki_prev_link,
        \ vimwiki#u#ft_is_vw())
endfunction


function! vimwiki#base#backlinks() abort
  " Jump: to previous file (backspace key)
  " Called: by VimwikiBacklinks (Exported)
  let current_filename = expand('%:p')
  let locations = []
  for idx in range(vimwiki#vars#number_of_wikis())
    let syntax = vimwiki#vars#get_wikilocal('syntax', idx)
    let wikifiles = vimwiki#base#find_files(idx, 0)
    for source_file in wikifiles
      let links = s:get_links(source_file, idx)
      for [target_file, _, lnum, col] in links
        if vimwiki#u#is_windows()
          " TODO this is a temporary fix - see issue #478
          let target_file = substitute(target_file, '/', '\', 'g')
          let current_filename = substitute(current_filename, '/', '\', 'g')
        endif
        " don't include links from the current file to itself
        if vimwiki#path#is_equal(target_file, current_filename) &&
              \ !vimwiki#path#is_equal(target_file, source_file)
          call add(locations, {'filename':source_file, 'lnum':lnum, 'col':col})
        endif
      endfor
    endfor
  endfor

  if empty(locations)
    call vimwiki#u#echo('No other file links to this file')
  else
    call setloclist(0, locations, 'r')
    lopen
  endif
endfunction


function! vimwiki#base#find_files(wiki_nr, directories_only, ...) abort
  " Returns: a list containing all files of the given wiki as absolute file path.
  " If the given wiki number is negative, the diary of the current wiki is used
  " If the second argument is not zero, only directories are found
  " If third argument: pattern to search for
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
  " If pattern is given, use it
  " if current wiki is temporary -- was added by an arbitrary wiki file then do
  " not search wiki files in subdirectories. Or it would hang the system if
  " wiki file was created in $HOME or C:/ dirs.
  if a:0 && a:1 !=# ''
    let pattern = a:1
  elseif vimwiki#vars#get_wikilocal('is_temporary_wiki', wiki_nr)
    let pattern = '*'.ext
  else
    let pattern = '**/*'.ext
  endif
  let files = split(globpath(root_directory, pattern), '\n')

  " filter excluded files before returning
  for pattern in vimwiki#vars#get_wikilocal('exclude_files')
    let efiles = split(globpath(root_directory, pattern), '\n')
    let files = filter(files, 'index(efiles, v:val) == -1')
  endfor

  return files
endfunction


function! vimwiki#base#get_wikilinks(wiki_nr, also_absolute_links, pattern) abort
  " Returns: a list containing the links to get from the current file to all wiki
  " files in the given wiki.
  " If the given wiki number is negative, the diary of the current wiki is used.
  " If also_absolute_links is nonzero, also return links of the form /file
  " If pattern is not '', only filepaths matching pattern will be considered
  let files = vimwiki#base#find_files(a:wiki_nr, 0, a:pattern)
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


function! vimwiki#base#get_wiki_directories(wiki_nr) abort
  " Returns: a list containing the links to all directories from the current file
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


function! vimwiki#base#get_anchors(filename, syntax) abort
  " Parse file. Returns list of all anchors
  " Called: vimwiki#base#check_links() for all wiki files
  " Clause: if not readable
  if !filereadable(a:filename)
    return []
  endif

  " Get: syntax local variables
  let rxheader = vimwiki#vars#get_syntaxlocal('header_search', a:syntax)
  let rxbold = vimwiki#vars#get_syntaxlocal('bold_search', a:syntax)
  let rxtag = vimwiki#vars#get_syntaxlocal('tag_search', a:syntax)

  " Init:
  let anchor_level = ['', '', '', '', '', '', '']
  let anchors = []
  let current_complete_anchor = ''

  for line in readfile(a:filename)
    " Collect: headers
    let h_match = matchlist(line, rxheader)
    if !empty(h_match)
      let header = vimwiki#base#normalize_anchor(h_match[2])
      " Measure: header level
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
          if anchor_level[l] !=? ''
            let current_complete_anchor .= anchor_level[l].'#'
          endif
        endfor
        let current_complete_anchor .= header
        " TODO: should not that be out of the if branch ?
        call add(anchors, current_complete_anchor)
      endif
    endif

    " Collect: bold text (there can be several in one line)
    let bold_count = 1
    while 1
      let bold_text = matchstr(line, rxbold, 0, bold_count)
      if bold_text ==? ''
        break
      endif
      call add(anchors, bold_text)
      if current_complete_anchor !=? ''
        call add(anchors, current_complete_anchor.'#'.bold_text)
      endif
      let bold_count += 1
    endwhile

    " Collect: tags text (there can be several in one line)
    let tag_count = 1
    while 1
      let tag_group_text = matchstr(line, rxtag, 0, tag_count)
      if tag_group_text ==? ''
        break
      endif
      let sep = vimwiki#vars#get_syntaxlocal('tag_format', a:syntax).sep
      for tag_text in split(tag_group_text, sep)
        call add(anchors, tag_text)
        if current_complete_anchor !=? ''
          call add(anchors, current_complete_anchor.'#'.tag_text)
        endif
      endfor
      let tag_count += 1
    endwhile
  endfor

  return anchors
endfunction


function! vimwiki#base#normalize_anchor(anchor, ...) abort
  " Convert: anchor <string> => link in TOC
  " Called: vimwiki#base#table_of_contents
  " :param: anchor <string> <= Heading line
  " :param: (1) previous_anchors <dic[IN/OUT]> of previous normalized anchor
  " -- to know if must append -2, updated on the fly
  " A Trim space
  let anchor = vimwiki#u#trim(a:anchor)

  " Guard: work only for markdown
  if vimwiki#vars#get_wikilocal('syntax') !=# 'markdown'
    return anchor
  endif

  " Keep previous anchors cache: See unormalize
  if a:0
    let previous_anchors = a:1
  else
    let previous_anchors = {}
  endif

  " 1 Downcase the string
  let anchor = tolower(anchor)

  " 2 Remove anything that is not a letter, number, CJK character, hyphen or space
  let punctuation_rx = vimwiki#u#get_punctuation_regex()
  let anchor = substitute(anchor, punctuation_rx, '', 'g')

  " 3 Change any space to a hyphen
  let anchor = substitute(anchor, ' \+', '-', 'g')

  " 4 Append '-1', '-2', '-3',... to make it unique <= If that not unique
  if has_key(previous_anchors, anchor)
    " Inc anchor number (before modifying the anchor)
    let anchor_nb = previous_anchors[anchor] + 1
    let previous_anchors[anchor] = anchor_nb
    " Append suffix
    let anchor .= '-' . string(anchor_nb)
  else
    " Save anchor in dic
    let previous_anchors[anchor] = 1
  endif

  return anchor
endfunction


function! vimwiki#base#unnormalize_anchor(anchor) abort
  " Convert: s_anchor_toc [anchor_re <regex>, anchor_nb <number>, suffix_re <regex>] to look for
  " Called: jump_to_anchor
  " :param: anchor <string> <= link
  " -- with or without suffix
  " -- Ex: ['toto", 2] => search for the second occurrence of toto
  " Note:
  " -- Pandoc keep the '_' in anchor
  " -- Done after: Add spaces leading and trailing => Later with the template
  " Link: Inspired from https://gist.github.com/asabaylus/3071099
  " Issue: #664 => Points to all others

  " A Trim space
  let anchor = vimwiki#u#trim(a:anchor)

  " Guard: work only for markdown
  if vimwiki#vars#get_wikilocal('syntax') !=# 'markdown'
    return [anchor, 1, '']
  endif

  let punctuation_rx = vimwiki#u#get_punctuation_regex()
  " Permit url part of link: '](www.i.did.it.my.way.cl)'
  let link_rx = '\%(\]([^)]*)\)'
  let invisible_rx =  '\%( \|-\|' . punctuation_rx . '\|' . link_rx . '\)'


  " 4 Add '-1', '-2', '-3',... to make it unique if not unique
  " -- Save the trailing -12
  let anchor_nb = substitute(anchor, '^.*-\(\d\+\)$', '\1', '')
  if anchor_nb ==# '' || anchor_nb == 0
    " No Suffix: number = 1
    let suffix = ''
    let anchor_nb = 1
  else
    " Yes suffix: number <- read suffix
    let suffix = invisible_rx.'*'
    for char in split(anchor_nb, '\zs')
      let suffix .= char . invisible_rx.'*'
    endfor
    let anchor_nb = str2nr(anchor_nb)
  endif
  " -- Remove it
  let anchor = substitute(anchor, '\(-\d\+\)$', '', '')

  " For each char
  let anchor_loop = ''
  for char in split(anchor, '\zs')
    " Nest the char for easier debugging
    let anchor_loop .=  '\%('

    " 3 Change any space to a hyphen
    if char ==# '-'
      " Match Space or hyphen or punctuation or link
      let anchor_loop .=  invisible_rx.'\+'

    " 2 Remove anything that is not a letter, number, CJK character, hyphen or space
    " -- So add punctuation regex at each char
    else
      " Match My_char . punctuation . ( link . punctuaction )?
      " Note: Because there may be punctuation before ad after link
      let anchor_loop .= char . punctuation_rx.'*'
      let anchor_loop .= '\%(' . link_rx . punctuation_rx.'*' . '\)' . '\?'

    endif

    " Close nest
    let anchor_loop .=  '\)'
  endfor
  let anchor = punctuation_rx.'*' . anchor_loop

  " 1 Downcase the string
  let anchor = '\c' . anchor

  return [anchor, anchor_nb, suffix]
endfunction


function! s:jump_to_anchor(anchor) abort
  " Jump: to anchor, doing the opposite of normalize_anchor
  " Called: edit_file
  " Get segments <= anchor
  let anchor = vimwiki#u#escape(a:anchor)
  let segments = split(anchor, '#', 0)

  " Start at beginning => Independent of link position
  call cursor(1, 1)

  " For markdown: there is only one segment
  for segment in segments
    " Craft segment pattern so that it is case insensitive and also matches dashes
    " in anchor link with spaces in heading
    let [segment_norm_re, segment_nb, segment_suffix] = vimwiki#base#unnormalize_anchor(segment)

    " Try once with suffix (If header ends with number)
    let res =  s:jump_to_segment(segment, segment_norm_re . segment_suffix, 1)
    " Try segment_nb times otherwise
    if res != 0
      let res =  s:jump_to_segment(segment, segment_norm_re, segment_nb)
    endif
  endfor
endfunction


function! s:jump_to_segment(segment, segment_norm_re, segment_nb) abort
  " Called: jump_to_anchor with suffix and withtou suffix
  " Save cursor %% Initialize at top of line
  let oldpos = getpos('.')

  " Get anchor regex
  let anchor_header = s:safesubstitute(
        \ vimwiki#vars#get_syntaxlocal('header_match'),
        \ '__Header__', a:segment_norm_re, 'g')
  let anchor_bold = s:safesubstitute(
        \ vimwiki#vars#get_syntaxlocal('bold_match'),
        \ '__Text__', a:segment, 'g')
  let anchor_tag = s:safesubstitute(
        \ vimwiki#vars#get_syntaxlocal('tag_match'),
        \ '__Tag__', a:segment, 'g')

  " Go: Move cursor: maybe more than once (see markdown suffix)
  let success_nb = 0
  let is_last_segment = 0
  for i in range(a:segment_nb)
    " Search
    let pos = 0
    let pos = pos != 0 ? pos : search(anchor_tag, 'Wc')
    let pos = pos != 0 ? pos : search(anchor_header, 'Wc')
    let pos = pos != 0 ? pos : search(anchor_bold, 'Wc')

    " Succeed: Get the result and reloop or leave
    if pos != 0
      " Advance, one line more to not rematch the same pattern if not last segment_nb
      if success_nb < a:segment_nb-1
        let pos += 1
        let is_last_segment = -1
      endif
      call cursor(pos, 1)
      let success_nb += 1

      " Break  if last line (avoid infinite loop)
      " Anyway leave the loop: (Imagine heading # 7271212 at last line)
      if pos >= line('$')
        return 0
      endif
    " Fail:
    " Do not move
    " But maybe suffix -2 is not the segment number but the real header suffix
    else
      " If fail at first: do not move
      if i == 0
        call setpos('.', oldpos)
      endif
      " Anyway leave the loop: (Imagine heading # 7271212, you do not want to loop all that)
      " Go one line back: if I advanced too much
      if is_last_segment == -1 | call cursor(line('.')-1, 1) | endif
      return 1
    endif
  endfor

  " Check if happy
  if success_nb == a:segment_nb
    return 0
  endif

  " Said 'fail' to caller
  return 1
endfunction


function! s:get_links(wikifile, idx) abort
  " Get: a list of all links inside the wiki file
  " Params: full path to a wiki file and its wiki number
  " Every list item has the form
  " [target file, anchor, line number of the link in source file, column number]
  if !filereadable(a:wikifile)
    return []
  endif

  let syntax = vimwiki#vars#get_wikilocal('syntax', a:idx)
  let rx_link = vimwiki#vars#get_syntaxlocal('wikilink', syntax)

  if syntax ==# 'markdown'
    let md_rx_link = vimwiki#vars#get_syntaxlocal('rxWeblink1MatchUrl', syntax)
  endif

  let links = []
  let lnum = 0

  for line in readfile(a:wikifile)
    let lnum += 1

    let link_count = 1
    while 1
      let col = match(line, rx_link, 0, link_count)+1
      let link_text = matchstr(line, rx_link, 0, link_count)

      " if a link wasn't found, also try markdown syntax (if enabled)
      if link_text ==? '' && syntax ==# 'markdown'
        let link_text = matchstr(line, md_rx_link, 0, link_count)
      endif
      if link_text ==? ''
        break
      endif

      let link_count += 1
      let target = vimwiki#base#resolve_link(link_text, a:wikifile)
      if target.filename !=? '' && target.scheme =~# '\mwiki\d\+\|diary\|file\|local'
        call add(links, [target.filename, target.anchor, lnum, col])
      endif
    endwhile
  endfor

  return links
endfunction


function! vimwiki#base#check_links(range, line1, line2) abort
  " Check: if all wikilinks are reachable. Answer in quickfix
  if a:range == 0
    let wiki_list = [vimwiki#vars#get_bufferlocal('wiki_nr')]
  elseif a:range == 1
    let wiki_list = [a:line1]
  else
    let wiki_list = range(a:line1, a:line2)
  endif
  call vimwiki#u#echo('Checking links in wikis ' . string(wiki_list))

  let anchors_of_files = {}
  let links_of_files = {}
  let errors = []
  for idx in wiki_list
    let syntax = vimwiki#vars#get_wikilocal('syntax', idx)
    let wikifiles = vimwiki#base#find_files(idx, 0)
    for wikifile in wikifiles
      let links_of_files[wikifile] = s:get_links(wikifile, idx)
      let anchors_of_files[wikifile] = vimwiki#base#get_anchors(wikifile, syntax)
    endfor
  endfor

  " Clean: all links: keep only file links
  for wikifile in keys(links_of_files)
    for [target_file, target_anchor, lnum, col] in links_of_files[wikifile]
      if target_file ==? '' && target_anchor ==? ''
        call add(errors, {'filename':wikifile, 'lnum':lnum, 'col':col,
              \ 'text': 'numbered scheme refers to a non-existent wiki'})
      elseif has_key(anchors_of_files, target_file)
        if target_anchor !=? '' && index(anchors_of_files[target_file], target_anchor) < 0
          call add(errors, {'filename':wikifile, 'lnum':lnum, 'col':col,
                \'text': 'there is no such anchor: '.target_anchor})
        endif
      else
        if target_file =~? '\m/$'  " maybe it's a link to a directory
          if !isdirectory(target_file)
            call add(errors, {'filename':wikifile, 'lnum':lnum, 'col':col,
                  \'text': 'there is no such directory: '.target_file})
          endif
        else  " maybe it's a non-wiki file
          if filereadable(target_file)
            let anchors_of_files[target_file] = []
          else
            call add(errors, {'filename':wikifile, 'lnum':lnum, 'col':col,
                  \'text': 'there is no such file: '.target_file})
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

  " Mark: every index file as reachable
  for idx in wiki_list
    let index_file = vimwiki#vars#get_wikilocal('path', idx) .
          \ vimwiki#vars#get_wikilocal('index', idx) . vimwiki#vars#get_wikilocal('ext', idx)
    if filereadable(index_file)
      let reachable_wikifiles[index_file] = 1
    endif
  endfor

  " Check: if files are reachable (recursively)
  while 1
    let next_unvisited_wikifile = ''
    for wf in keys(reachable_wikifiles)
      if reachable_wikifiles[wf] == 1
        let next_unvisited_wikifile = wf
        let reachable_wikifiles[wf] = 2
        break
      endif
    endfor
    if next_unvisited_wikifile ==? ''
      break
    endif
    for [target_file, target_anchor, lnum, col] in links_of_files[next_unvisited_wikifile]
      if has_key(reachable_wikifiles, target_file) && reachable_wikifiles[target_file] == 0
        let reachable_wikifiles[target_file] = 1
      endif
    endfor
  endwhile

  " Fill: errors
  for wf in keys(reachable_wikifiles)
    if reachable_wikifiles[wf] == 0
      call add(errors, {'text':wf.' is not reachable from the index file'})
    endif
  endfor

  " Fill: QuickFix list
  if empty(errors)
    call vimwiki#u#echo('All links are OK')
  else
    call setqflist(errors, 'r')
    copen
  endif
endfunction


function! vimwiki#base#edit_file(command, filename, anchor, ...) abort
  " Edit File: (like :e)
  " :param: command <string>: ':e'
  " :param: filename <string> vimwiki#vars#get_wikilocal('path') . key . vimwiki#vars#get_wikilocal('ext')
  " :param: anchor
  " :param: (1) vimwiki_prev_link
  " :param: (2) vimwiki#u#ft_is_vw()
  let fname = fnameescape(a:filename)
  let dir = fnamemodify(a:filename, ':p:h')

  let ok = vimwiki#path#mkdir(dir, 1)

  if !ok
    call vimwiki#u#error('Unable to edit file in non-existent directory: '.dir)
    return
  endif

  " Check if the file we want to open is already the current file
  " which happens if we jump to an anchor in the current file.
  " This hack is necessary because apparently Vim messes up the result of
  " getpos() directly after this command. Strange.
  if !(a:command =~# ':\?[ed].*' && vimwiki#path#is_equal(a:filename, expand('%:p')))
    try
      execute a:command fname
    catch /E37:/
      call vimwiki#u#warn('Can''t leave the current buffer, because it is modified. Hint: Take a look at'
            \ . ''':h g:vimwiki_autowriteall'' to see how to save automatically.')
      return
    catch /E325:/
      call vimwiki#u#warn('Vim couldn''t open the file, probably because a swapfile already exists. See :h E325.')
      return
    catch /E319:/
      call vimwiki#u#warn('Vim couldn''t open the file, cannot launch the drop command. See :h E319.')
      execute 'edit' fname
      return
    endtry
    " If the opened file was not already loaded by Vim, an autocommand is
    " triggered at this point
  endif

  " Goto anchor
  if a:anchor !=? ''
    call s:jump_to_anchor(a:anchor)
  endif

  " save previous link
  " a:1 -- previous vimwiki link to save
  " a:2 -- should we update previous link
  if a:0 && a:2 && len(a:1) > 0
    let prev_links = vimwiki#vars#get_bufferlocal('prev_links')
    call insert(prev_links, a:1)
    call vimwiki#vars#set_bufferlocal('prev_links', prev_links)
  endif
endfunction


function! vimwiki#base#search_word(wikiRX, flags) abort
  " Search for a 1. Pattern (usually a link) with 2. flags
  " Called by find_prev_link
  let match_line = search(a:wikiRX, 's'.a:flags)
  if match_line == 0
    call vimwiki#u#echo('Wiki link not found')
  endif
endfunction


function! vimwiki#base#matchstr_at_cursor(wikiRX) abort
  " Return: part of the line that matches wikiRX at cursor
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
    return ''
  endif
endfunction


function! vimwiki#base#replacestr_at_cursor(wikiRX, sub) abort
  " Replace next 1. wikiRX by 2. sub
  " Gather: cursor info
  let col = col('.') - 1
  let line = getline('.')
  let ebeg = -1
  let cont = match(line, a:wikiRX, 0)

  " Find: link
  while (ebeg >= 0 || (0 <= cont) && (cont <= col))
    let contn = matchend(line, a:wikiRX, cont)
    if (cont <= col) && (col < contn)
      let ebeg = match(line, a:wikiRX, cont)
      let elen = contn - ebeg
      break
    else
      let cont = match(line, a:wikiRX, contn)
    endif
  endwhile

  " Replace: by sub
  if ebeg >= 0
    " TODO: There might be problems with Unicode chars...
    let newline = strpart(line, 0, ebeg).a:sub.strpart(line, ebeg+elen)
    call setline(line('.'), newline)
  endif
endfunction


function! s:print_wiki_list() abort
  " Print list of global wiki to user
  " Called: by ui_select
  " Find the max name length for prettier formatting
  let max_len = 0
  for idx in range(vimwiki#vars#number_of_wikis())
    let wname = vimwiki#vars#get_wikilocal('name', idx)
    if len(wname) > max_len
      let max_len = len(wname)
    endif
  endfor

  " Print each wiki, active wiki highlighted and marked with '*'
  for idx in range(vimwiki#vars#number_of_wikis())
    if idx == vimwiki#vars#get_bufferlocal('wiki_nr')
      let sep = '*'
      echohl PmenuSel
    else
      let sep = ' '
      echohl None
    endif
    let wname = vimwiki#vars#get_wikilocal('name', idx)
    let wpath = vimwiki#vars#get_wikilocal('path', idx)
    if wname ==? ''
      let wname = '----'
      if max_len < 4
        let max_len = 4
      endif
    endif
    let wname = '"' . wname . '"'
    echo printf('%2d %s %-*s %s', idx+1, sep, max_len+2, wname, wpath)
  endfor
  echohl None
endfunction


function! s:update_wiki_link(fname, old, new) abort
  " Update link in fname.ext
  " Param: fname: the source file where to change links
  " Param: old: url regex of old path relative to wiki root
  " Param: new: url string of new path
  call vimwiki#u#echo('Updating links in '.a:fname)
  let has_updates = 0
  let dest = []
  for line in readfile(a:fname)
    if !has_updates && match(line, a:old) != -1
      let has_updates = 1
    endif
    " XXX: any other characters to escape!?
    call add(dest, substitute(line, a:old, escape(a:new, '&'), 'g'))
  endfor
  " add exception handling...
  if has_updates
    call rename(a:fname, a:fname.'#vimwiki_upd#')
    call writefile(dest, a:fname)
    call delete(a:fname.'#vimwiki_upd#')
  endif
endfunction


function! s:update_wiki_links(wiki_nr, dir, old_url, new_url) abort
  " Update link for all files in dir
  " Param: old_url, new_url: path of the old, new url relative to ...
  " Param: dir: directory of the files, relative to wiki_root
  " Called: rename_file
  " Get list of wiki files
  let wiki_root = vimwiki#vars#get_wikilocal('path', a:wiki_nr)
  let fsources = vimwiki#base#find_files(a:wiki_nr, 0)

  " Shorten dirname
  let dir_rel_root = vimwiki#path#relpath(wiki_root, a:dir)

  " Cache relative url, because they are often the same, like `../dir1/vim-vimwiki.md`
  let cache_dict = {}

  " Regex from path
  " Param: wiki_nr <int> to get the syntax template
  " Param: old_location <string> relative to the current wiki fsource
  function! s:compute_old_url_r(wiki_nr, old_location) abort
    " TODO this may be helped by path_to_regex
    " Start, Read param
    let old_url_r = a:old_location
    " Replace / -> [\\/]
    let old_url_r = substitute(old_url_r, '/', '[\\\\/]', 'g')
    " Add potential  ./
    let old_url_r = '\%(\.[/\\]\)\?' . old_url_r
    " Compute old url regex with filename between \zs and \ze
    let old_url_r = vimwiki#base#apply_template(
          \ vimwiki#vars#get_syntaxlocal('WikiLinkMatchUrlTemplate', vimwiki#vars#get_wikilocal('syntax', a:wiki_nr))
            \, old_url_r, '', '', vimwiki#vars#get_wikilocal('ext', a:wiki_nr))

    return old_url_r
  endfunction

  " For each wikifile
  for fsource in fsources
    " Shorten fname directory
    let fsource_rel_root = vimwiki#path#relpath(wiki_root, fsource)
    let fsource_rel_root = fnamemodify(fsource_rel_root, ':h')

    " Compute old_url relative to fname
    let dir_rel_fsource = vimwiki#path#relpath(fsource_rel_root, dir_rel_root)
    " TODO get relpath coherent (and remove next 2 stuff)
    " Remove the trailing ./
    if dir_rel_fsource =~# '.[/\\]$'
      let dir_rel_fsource = dir_rel_fsource[:-3]
    endif
    " Append a / if needed
    if !empty(dir_rel_fsource) && dir_rel_fsource !~# '[/\\]$'
      let dir_rel_fsource .= '/'
    endif

    " New url
    let new_url = simplify(dir_rel_fsource . a:new_url)

    " Old url
    " Avoid E713
    let old_rel_fsource = dir_rel_fsource . a:old_url
    let key = empty(old_rel_fsource) ? 'NaF' : old_rel_fsource
    if index(keys(cache_dict), key) == -1
      let cache_dict[key] = s:compute_old_url_r(
            \ a:wiki_nr,  old_rel_fsource)
    endif
    let r_old_rel_fsource = cache_dict[key]

    " Update url in source file
    call s:update_wiki_link(fsource, r_old_rel_fsource, new_url)

    " Same job with absolute path (#617)
    let old_rel_root = '/' . dir_rel_root . '/' . a:old_url
    let key = empty(dir_rel_root) ? 'NaF' : dir_rel_root
    if index(keys(cache_dict), key) == -1
      let cache_dict[key] = s:compute_old_url_r(
            \ a:wiki_nr, old_rel_root)
    endif
    let r_old_rel_root = cache_dict[key]
    let new_rel_root = simplify('/' . dir_rel_root . '/' . a:new_url)

    call s:update_wiki_link(fsource, r_old_rel_root, new_rel_root)
  endfor
endfunction


function! s:tail_name(fname) abort
  " Get tail of filename
  " TODO move me in path.vim
  let result = substitute(a:fname, ':', '__colon__', 'g')
  let result = fnamemodify(result, ':t:r')
  let result = substitute(result, '__colon__', ':', 'g')
  return result
endfunction


function! s:get_wiki_buffers() abort
  " Get list of currently open buffer that are wiki files
  " Called: by rename_file
  let blist = []
  let bcount = 1
  while bcount<=bufnr('$')
    if bufexists(bcount)
      let bname = fnamemodify(bufname(bcount), ':p')
      " this may find buffers that are not part of the current wiki, but that
      " doesn't hurt
      if bname =~# vimwiki#vars#get_wikilocal('ext').'$'
        let bitem = [bname, vimwiki#vars#get_bufferlocal('prev_links', bcount)]
        call add(blist, bitem)
      endif
    endif
    let bcount = bcount + 1
  endwhile
  return blist
endfunction


function! s:open_wiki_buffer(item) abort
  " Edit wiki file.
  " Called: by rename_file: Usefull for buffer commands
  call vimwiki#base#edit_file('edit', a:item[0], '')
  if !empty(a:item[1])
    call vimwiki#vars#set_bufferlocal('prev_links', a:item[1], a:item[0])
  endif
endfunction


function! vimwiki#base#nested_syntax(filetype, start, end, textSnipHl) abort
  " Helper nested syntax
  " Called: by syntax/vimwiki (exported)
  " TODO move me out of base
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

  " Check for the existence of syntax files in the runtime path before
  " attempting to include them.
  " https://vi.stackexchange.com/a/10354
  " Previously, this used a try/catch block to intercept any errors thrown
  " when attempting to include files. The error(s) interfered with running
  " with Vader tests (specifically, testing VimwikiSearch).
  if !empty(globpath(&runtimepath, 'syntax/'.a:filetype.'.vim'))
    execute 'syntax include @'.group.' syntax/'.a:filetype.'.vim'
  endif
  if !empty(globpath(&runtimepath, 'after/syntax/'.a:filetype.'.vim'))
    execute 'syntax include @'.group.' after/syntax/'.a:filetype.'.vim'
  endif

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

  let concealpre = vimwiki#vars#get_global('conceal_pre') ? ' concealends' : ''
  execute 'syntax region textSnip'.ft.
        \ ' matchgroup='.a:textSnipHl.
        \ ' start="'.a:start.'" end="'.a:end.'"'.
        \ ' contains=@'.group.' keepend'.concealpre

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


function! vimwiki#base#update_listing_in_buffer(Generator, start_header,
      \ content_regex, default_lnum, header_level, create) abort
  " Create: or update auto-generated listings in a wiki file, like TOC, diary
  " links, tags list etc.
  " - the listing consists of a header and a list of strings provided by a funcref
  " - a:content_regex is used to determine how long a potentially existing list is
  " - a:default_lnum is the line number where the new listing should be placed if
  "   it's not already present
  " - if a:create is true, it will be created if it doesn't exist, otherwise it
  "   will only be updated if it already exists
  " Called: by functions adding listing to buffer (this is an util function)

  " Clause: Vim behaves strangely when files change while in diff mode
  if &diff || &readonly
    return
  endif

  " Clause: Check if the listing is already there
  let already_there = 0
  " -- Craft header regex to search for
  let header_level = 'rxH' . a:header_level . '_Template'
  let header_rx = '\m^\s*'.substitute(vimwiki#vars#get_syntaxlocal(header_level),
        \ '__Header__', a:start_header, '') .'\s*$'
  let start_lnum = 1
  " -- Search fr the header in all file
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

  " Save state
  let winview_save = winsaveview()
  " Work is supposing an initial visibility (Issue: #921)
  let foldlevel_save = &l:foldlevel
  let &l:foldlevel = 100
  let cursor_line = winview_save.lnum
  let is_cursor_after_listing = 0

  let is_fold_closed = 1
  let lines_diff = 0

  " Generate listing content
  let a_list = a:Generator.f()

  " Set working range according to listing presence
  if already_there
    " Delete the old listing
    let is_fold_closed = ( foldclosed(start_lnum) > -1 )
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
    setlocal nofoldenable

    " Clause: don't update file if there are no changes
    if (join(getline(start_lnum + 2, end_lnum - 1), '') == join(a_list, ''))
      return
    endif

    silent exe 'keepjumps ' . start_lnum.','.string(end_lnum - 1).'delete _'
    let &l:foldenable = foldenable_save
    let lines_diff = 0 - (end_lnum - start_lnum)
  else
    " Create new listing
    let start_lnum = a:default_lnum
    let is_cursor_after_listing = ( cursor_line > a:default_lnum )
    let whitespaces_in_first_line = ''
    " Append newline if not replacing first line
    if start_lnum > 1
      keepjumps call append(start_lnum -1, '')
      let start_lnum += 1
    endif
  endif

  let start_of_listing = start_lnum

  " Write new listing
  let new_header = whitespaces_in_first_line
        \ . s:safesubstitute(vimwiki#vars#get_syntaxlocal(header_level),
        \ '__Header__', a:start_header, '')
  keepjumps call append(start_lnum - 1, new_header)
  let start_lnum += 1
  let lines_diff += 1
  if vimwiki#vars#get_wikilocal('syntax') ==# 'markdown'
    for _ in range(vimwiki#vars#get_global('markdown_header_style'))
      keepjumps call append(start_lnum - 1, '')
      let start_lnum += 1
      let lines_diff += 1
    endfor
  endif
  for string in a_list
    keepjumps call append(start_lnum - 1, string)
    let start_lnum += 1
    let lines_diff += 1
  endfor

  " Remove empty line if end of file, otherwise append if needed
  let current_line = getline(start_lnum)
  if start_lnum == line('$') && current_line =~# '^\s*$'
    silent exe 'keepjumps ' . start_lnum.'delete _'
  elseif start_lnum <= line('$') && current_line !~# '\m^\s*$'
    keepjumps call append(start_lnum - 1, '')
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

  " Restore state
  let &l:foldlevel = foldlevel_save
  call winrestview(winview_save)
endfunction


function! vimwiki#base#find_next_task() abort
  " Find next task (Exported)
  let taskRegex = vimwiki#vars#get_wikilocal('rxListItemWithoutCB')
    \ . '\+\(\[ \]\s\+\)\zs'
  call vimwiki#base#search_word(taskRegex, '')
endfunction


function! vimwiki#base#find_next_link() abort
  " Find next link (Exported)
  call vimwiki#base#search_word(vimwiki#vars#get_syntaxlocal('rxAnyLink'), '')
endfunction


function! vimwiki#base#find_prev_link() abort
  " Find previous link (Exported)
  "Jump 2 times if the cursor is in the middle of a link
  if synIDattr(synID(line('.'), col('.'), 0), 'name') =~# 'VimwikiLink.*' &&
        \ synIDattr(synID(line('.'), col('.')-1, 0), 'name') =~# 'VimwikiLink.*'
    call vimwiki#base#search_word(vimwiki#vars#get_syntaxlocal('rxAnyLink'), 'b')
  endif
  call vimwiki#base#search_word(vimwiki#vars#get_syntaxlocal('rxAnyLink'), 'b')
endfunction


function! vimwiki#base#follow_link(split, ...) abort
  " Jump to link target (Enter press, Exported)
  let reuse_other_split_window = a:0 >= 1 ? a:1 : 0
  let move_cursor_to_new_window = a:0 >= 2 ? a:2 : 1

  " Parse link at cursor and pass to VimwikiLinkHandler, or failing that, the
  " default open_link handler

  " Try WikiLink
  let lnk = matchstr(vimwiki#base#matchstr_at_cursor(vimwiki#vars#get_syntaxlocal('rxWikiLink')),
        \ vimwiki#vars#get_syntaxlocal('rxWikiLinkMatchUrl'))
  " Try WikiIncl
  if lnk ==? ''
    let lnk = matchstr(vimwiki#base#matchstr_at_cursor(vimwiki#vars#get_global('rxWikiIncl')),
          \ vimwiki#vars#get_global('rxWikiInclMatchUrl'))
  endif
  " Try Weblink
  if lnk ==? ''
    let lnk = matchstr(vimwiki#base#matchstr_at_cursor(vimwiki#vars#get_syntaxlocal('rxWeblink')),
          \ vimwiki#vars#get_syntaxlocal('rxWeblinkMatchUrl'))
  endif
  " Try markdown image ![]()
  if vimwiki#vars#get_wikilocal('syntax') ==# 'markdown' && lnk ==# ''
    let lnk = matchstr(vimwiki#base#matchstr_at_cursor(vimwiki#vars#get_syntaxlocal('rxImage')),
          \ vimwiki#vars#get_syntaxlocal('rxWeblinkMatchUrl'))
    if lnk !=# ''
      if lnk !~# '\%(\%('.vimwiki#vars#get_global('schemes_web').'\):\%(\/\/\)\?\)\S\{-1,}'
        " prepend file: scheme so link is opened by system handler if it isn't a web url
        let lnk = 'file:'.lnk
      endif
    endif
  endif

  " If cursor is indeed on a link
  if lnk !=? ''
    let processed_by_user_defined_handler = VimwikiLinkHandler(lnk)
    if processed_by_user_defined_handler
      return
    endif

    if a:split ==# 'hsplit'
      let cmd = 'split'
    elseif a:split ==# 'vsplit'
      let cmd = 'vsplit'
    elseif a:split ==# 'badd'
      let cmd = 'badd'
    elseif a:split ==# 'tab'
      let cmd = 'tabnew'
    elseif a:split ==# 'tabdrop'
      " Use tab drop if we've already got the file open in an existing tab
      let cmd = 'tab edit'
      if exists(':drop') == 2
        let cmd = 'tab drop'
      endif
    else
      " Same as above - doing this by default reduces incidence of multiple
      " tabs with the same file.  We default to :e just in case :drop doesn't
      " exist in the current build.
      let cmd = 'edit'
      if exists(':drop') == 2 && has('windows')
        let cmd = 'drop'
      endif
    endif

    " if we want to and can reuse a split window, jump to that window and open
    " the new file there
    if (a:split ==# 'hsplit' || a:split ==# 'vsplit') && reuse_other_split_window
      let previous_window_nr = winnr('#')
      if previous_window_nr > 0 && previous_window_nr != winnr()
        execute previous_window_nr . 'wincmd w'
        let cmd = ':edit'
      endif
    endif

    if vimwiki#vars#get_wikilocal('syntax') ==# 'markdown'
      let processed_by_markdown_reflink = vimwiki#markdown_base#open_reflink(lnk)
      if processed_by_markdown_reflink
        return
      endif
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

  " Else cursor is not on a link
  else
    if a:0 >= 3
      execute 'normal! '.a:3
    elseif vimwiki#vars#get_global('create_link')
      call vimwiki#base#normalize_link(0)
    endif
  endif
endfunction


function! vimwiki#base#go_back_link() abort
  " Jump to previous link (Backspace press, Exported)
  " Try pop previous link from buffer list
  let prev_links = vimwiki#vars#get_bufferlocal('prev_links')
  if !empty(prev_links)
    let prev_link = remove(prev_links, 0)
    call vimwiki#vars#set_bufferlocal('prev_links', prev_links)
  else
    let prev_link = []
  endif

  " Jump to target with edit_file
  if !empty(prev_link)
    " go back to saved wiki link
    " Change file if required lazy
    let file = prev_link[0]
    let pos = prev_link[1]
    " Removed the filereadable check for Vader
    if !(vimwiki#path#is_equal(file, expand('%:p')))
      call vimwiki#base#edit_file('edit', file, '')
    endif
    call setpos('.', pos)
  else
    " maybe we came here by jumping to a tag -> pop from the tag stack
    silent! pop!
  endif
endfunction


function! vimwiki#base#goto_index(wnum, ...) abort
  " Goto index file of wiki specified by index
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
    call vimwiki#u#error('Wiki '.a:wnum.' is not registered in your Vimwiki settings!')
    return
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


function! vimwiki#base#delete_link() abort
  " Delete current wiki file
  " Delete wiki file you are in from filesystem
  let val = input('Delete "'.expand('%').'" [y]es/[N]o? ')
  if val !~? '^y'
    return
  endif
  let fname = expand('%:p')
  try
    call delete(fname)
  catch /.*/
    call vimwiki#u#error('Cannot delete "'.expand('%:t:r').'"!')
    return
  endtry

  call vimwiki#base#go_back_link()
  execute 'bdelete! '.escape(fname, ' ')

  " Reread buffer => deleted wiki link should appear as non-existent
  if expand('%:p') !=? ''
    execute 'e'
  endif
endfunction


function! s:input_rename_file() abort
  " Ask user for a new filepath
  " Returns: '' if fails
  " Called: rename_file
  " Ask confirmation
  let val = input('Rename "'.expand('%:t:r').'" [y]es/[N]o? ')
  if val !~? '^y'
    return
  endif

  " Ask new name
  let new_link = input('Enter new name: ')

  " Guard: Check link
  if new_link =~# '[/\\]'
    call vimwiki#u#error('Cannot rename to a filename with path!')
    return
  endif
  if substitute(new_link, '\s', '', 'g') ==? ''
    call vimwiki#u#error('Cannot rename to an empty filename!')
    return
  endif

  " Check if new file well formed
  let url = matchstr(new_link, vimwiki#vars#get_syntaxlocal('rxWikiLinkMatchUrl'))
  if url !=? ''
    return url
  endif

  return new_link
endfunction


function! vimwiki#base#rename_file(...) abort
  " Rename current file, update all links to it
  " Param: [new_filepath <string>]
  " Exported: VimwikiRenameFile
  " Get filename and dir relative to wiki root
  let subdir = vimwiki#vars#get_bufferlocal('subdir')
  " Get old file directory relative to current path
  let old_dir = expand('%:p:h')
  let old_fname = subdir.expand('%:t')
  let wikiroot_path = vimwiki#vars#get_wikilocal('path')

  " Clause: Check if there current buffer is a file (new buffer maybe)
  if glob(expand('%:p')) ==? ''
    call vimwiki#u#error('Cannot rename "'.expand('%:p')
          \ . '". Current file does not exist! (New file? Save it before renaming.)')
    return
  endif

  " Read new_link <- command line || input()
  let new_link = a:0 > 0 ? a:1 : s:input_rename_file()
  if new_link ==# '' | return | endif

  let new_link = subdir.new_link
  let wiki_nr = vimwiki#vars#get_bufferlocal('wiki_nr')
  let new_fname = simplify(wikiroot_path . new_link . vimwiki#vars#get_wikilocal('ext'))

  " Guard: Do not rename if file with such name exists
  let fname = glob(new_fname)
  if fname !=? ''
    call vimwiki#u#error('Cannot rename to "'.new_fname.'". File with that name exist!')
    return
  endif

  " TODO Check new_file is in a wiki dir and warn user if not
  " Create new directory if needed
  let new_dir = fnamemodify(new_fname, ':h')
  if exists('*mkdir')
    " Sometimes complaining E739 if directory exists
    try
      call mkdir(new_dir, 'p')
    catch | endtry
  endif

  " Rename wiki link file
  try
    call vimwiki#u#echo('Renaming '.wikiroot_path.old_fname.' to '.new_fname)
    let res = rename(expand('%:p'), expand(new_fname))
    if res != 0
      throw 'Cannot rename!'
    end
  catch /.*/
    call vimwiki#u#error('Cannot rename "'.expand('%:t:r').'" to "'.new_fname.'"')
    return
  endtry

  let &buftype='nofile'

  " Save current buffer: [file_name, previous_name, buffer_number]
  let buf_old_info = [expand('%:p'), vimwiki#vars#get_bufferlocal('prev_links'), bufnr('%')]
  if v:version > 800 || has('patch-8.0.0083')
    let win_old_id = win_getid()
  endif

  " Get all wiki buffer
  let blist = s:get_wiki_buffers()

  " Dump wiki buffers: they may change
  for bitem in blist
    execute ':b '.escape(bitem[0], ' ')
    execute ':update'
  endfor

  " Prevent prompt from scrolling alone
  let more_save = &more
  setlocal nomore

  " Update links
  let old_fname_abs = wikiroot_path . old_fname
  let old_fname_rel_dir = vimwiki#path#relpath(old_dir, old_fname_abs)
  let new_fname_rel_dir = vimwiki#path#relpath(old_dir, new_fname)
  call s:update_wiki_links(
        \ wiki_nr, old_dir,
        \ fnamemodify(old_fname_rel_dir, ':r'),
        \ fnamemodify(new_fname_rel_dir, ':r')
        \ )

  "" Restore wiki buffers
  let autoread_save = &autoread
  set autoread
  for bitem in blist
    execute ':b '.escape(bitem[0], ' ')
    execute ':e!'
  endfor
  let &autoread = autoread_save

  " Open the new buffer
  call s:open_wiki_buffer([new_fname, buf_old_info[1]])
  let buf_new_nb = bufnr('%')

  " Change old_buffer by new buffer in all window
  windo if bufnr('%') == buf_old_info[2] | exe 'b ' . buf_new_nb | endif
  " Goto the window I belong
  if v:version > 800 || has('patch-8.0.0083')
    call win_gotoid(win_old_id)
  endif

  " Wipeout the old buffer: avoid surprises <= If it is not the same
  if buf_old_info[2] != buf_new_nb
    exe 'bwipeout! ' . buf_old_info[2]
  else
    " Should not happen
    call vimwiki#u#error('New buffer is the same as old, so will not delete: '
          \ . buf_new_nb . '.Please open an issue if see this message')
  endif

  " Log success
  call vimwiki#u#echo(old_fname.' is renamed to '.new_fname)

  " Restore prompt
  let &more = more_save
endfunction


function! vimwiki#base#ui_select() abort
  " Spawn User Interface to select wiki project
  " Called by VimwikiUISelect (Globally Exported)
  call s:print_wiki_list()
  let idx = input('Select Wiki by number and press <Enter> (empty cancels): ')
  if idx ==# ''
    return
  elseif idx !~# '\m[0-9]\+'
    echo "\n"
    echom 'Invalid wiki selection.'
    return
  endif
  call vimwiki#base#goto_index(idx)
endfunction


function! vimwiki#base#TO_header(inner, including_subheaders, count) abort
  " Jump to next header (Exported for text object)
  let headers = vimwiki#base#collect_headers()
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


function! vimwiki#base#TO_table_cell(inner, visual) abort
  " Jump to next table cell (Exported for text object)
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
      if getline('.')[virtcol('.')] ==# '+'
        normal! l
      endif
      if a:inner
        normal! 2l
      endif
      let sel_start = getpos('.')
    endif

    normal! `>
    call search('|\|\(-+-\)', '', line('.'))
    if getline('.')[virtcol('.')] ==# '+'
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
    if !a:inner && getline('.')[virtcol('.')-1] ==# '|'
      normal! h
    elseif a:inner
      normal! 2h
    endif
  endif
endfunction


function! vimwiki#base#TO_table_col(inner, visual) abort
  " Jump to next table col (Exported for text object)
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
      if getline('.')[virtcol('.')] ==# '+'
        normal! l
      endif
      " inner selection --> reduce selection
      if a:inner
        normal! 2l
      endif
      let sel_start = getpos('.')
    endif

    normal! `>
    if !firsttime && getline('.')[virtcol('.')] ==# '|'
      normal! l
    elseif a:inner && getline('.')[virtcol('.')+1] =~# '[|+]'
      normal! 2l
    endif
    " search for the next column separator
    call search('|\|\(-+-\)', '', line('.'))
    " Outer selection selects a column without border on the right. So we move
    " our cursor left if the previous search finds | border, not -+-.
    if getline('.')[virtcol('.')] !=# '+'
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
    if getline('.')[virtcol('.')] ==# '+'
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
    if getline('.')[virtcol('.')] !=# '+'
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


function! vimwiki#base#AddHeaderLevel(...) abort
  " Increase header level (Exported)
  " Clause, argument must be <= 1
  " Actually argument is not used :-)
  if a:1 > 1
    call vimwiki#base#AddHeaderLevel(a:1 - 1)
  endif
  let lnum = line('.')
  let line = getline(lnum)
  let rxHdr = vimwiki#vars#get_syntaxlocal('header_symbol')
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


function! vimwiki#base#RemoveHeaderLevel(...) abort
  " Decrease header level (Exported)
  " Clause, argument must be <= 1
  " Actually argument is not used :-)
  if a:1 > 1
    call vimwiki#base#RemoveHeaderLevel(a:1 - 1)
  endif
  let lnum = line('.')
  let line = getline(lnum)
  let rxHdr = vimwiki#vars#get_syntaxlocal('header_symbol')
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


function! vimwiki#base#collect_headers() abort
  " Returns: all the headers in the current buffer as a list of the form
  " [[line_number, header_level, header_text], [...], [...], ...]
  " Init loop variables
  let is_inside_pre_or_math = 0  " 1: inside pre, 2: inside math, 0: outside
  let headers = []
  let rxHeader = vimwiki#vars#get_syntaxlocal('rxHeader')

  " For all lines in file
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

    " Check SetExt Header
    " TODO mutualise SetExt line (for consistency)
    " TODO replace regex with =\+ or -\+
    if line_content =~# '^\s\{0,3}[=-][=-]\+\s*$'
      let header_level = stridx(line_content, '=') != -1 ? 1 : 2
      let header_text = getline(lnum-1)
    " Maybe ATX header
    else
      " Clause: Must match rxHeader
      if line_content !~# rxHeader
        continue
      endif
      " Clause: markdown headers must start in the first column
      if vimwiki#vars#get_wikilocal('syntax') ==# 'markdown'
            \ && stridx(line_content, vimwiki#vars#get_syntaxlocal('header_symbol')) > 0
        continue
      endif
      " Get header level
      let header_level = vimwiki#u#count_first_sym(line_content)
      let header_text = matchstr(line_content, rxHeader)
    endif

    " Clean && Append to res
    let header_text = vimwiki#u#trim(header_text)
    call add(headers, [lnum, header_level, header_text])
  endfor

  return headers
endfunction


function! s:current_header(headers, line_number) abort
  " Returns: header index at cursor position
  " Called: by header cursor movements
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


function! s:clean_header_text(h_text) abort
  " Returns: heading with link urls
  " Called: table_of_content
  " Note: I hardcode, who cares ?
  let h_text = a:h_text

  " Convert: [[url]] -> url
  let h_text = substitute(h_text, '\[\[\([^]]*\)\]\]', '\1', 'g')

  " Convert: [desc](url) -> url
  let h_text = substitute(h_text, '\[\([^]]*\)\]([^)]*)', '\1', 'g')

  return h_text
endfunction


function! s:get_another_header(headers, current_index, direction, operation) abort
  " Returns: index of neighbor header
  " Called: by header cursor movements
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


function! vimwiki#base#goto_parent_header() abort
  " Jump to parent header
  let headers = vimwiki#base#collect_headers()
  let current_header_index = s:current_header(headers, line('.'))
  let parent_header = s:get_another_header(headers, current_header_index, -1, '<')
  if parent_header >= 0
    call cursor(headers[parent_header][0], 1)
  else
    call vimwiki#u#echo('no parent header found')
  endif
endfunction


function! vimwiki#base#goto_next_header() abort
  " Jump to next header
  let headers = vimwiki#base#collect_headers()
  let current_header_index = s:current_header(headers, line('.'))
  if current_header_index >= 0 && current_header_index < len(headers) - 1
    call cursor(headers[current_header_index + 1][0], 1)
  elseif current_header_index < 0 && !empty(headers)  " we're above the first header
    call cursor(headers[0][0], 1)
  else
    call vimwiki#u#echo('no next header found')
  endif
endfunction


function! vimwiki#base#goto_prev_header() abort
  " Jump to previous header
  let headers = vimwiki#base#collect_headers()
  let current_header_index = s:current_header(headers, line('.'))
  " if the cursor already was on a header, jump to the previous one
  if current_header_index >= 1 && headers[current_header_index][0] == line('.')
    let current_header_index -= 1
  endif
  if current_header_index >= 0
    call cursor(headers[current_header_index][0], 1)
  else
    call vimwiki#u#echo('no previous header found')
  endif
endfunction


function! vimwiki#base#goto_sibling(direction) abort
  " Jump to sibling header, next or previous (with same level)
  let headers = vimwiki#base#collect_headers()
  let current_header_index = s:current_header(headers, line('.'))
  let next_potential_sibling =
        \ s:get_another_header(headers, current_header_index, a:direction, '<=')
  if next_potential_sibling >= 0 && headers[next_potential_sibling][1] ==
        \ headers[current_header_index][1]
    call cursor(headers[next_potential_sibling][0], 1)
  else
    call vimwiki#u#echo('no sibling header found')
  endif
endfunction


function! vimwiki#base#table_of_contents(create) abort
  " Create buffer TOC (Exported)
  " a:create == 1: creates or updates TOC in current file
  " a:create == 0: update if TOC exists
  " Gather heading
  let headers = vimwiki#base#collect_headers()
  let toc_header_text = vimwiki#vars#get_wikilocal('toc_header')

  if !a:create
    " Do nothing if there is no TOC to update. (This is a small performance optimization -- if
    " auto_toc == 1, but the current buffer has no TOC but is long, saving the buffer could
    " otherwise take a few seconds for nothing.)
    let toc_already_present = 0
    for entry in headers
      if entry[2] ==# toc_header_text
        let toc_already_present = 1
        break
      endif
    endfor
    if !toc_already_present
      return
    endif
  endif

  " use a dictionary function for closure like capability
  " copy all local variables into dict (add a: if arguments are needed)
  let GeneratorTOC = copy(l:)
  function! GeneratorTOC.f() abort
    " Clean heading information
    let numbering = vimwiki#vars#get_global('html_header_numbering')
    " TODO numbering not used !
    let headers_levels = [['', 0], ['', 0], ['', 0], ['', 0], ['', 0], ['', 0]]
    let complete_header_infos = []
    for header in self.headers
      let h_text = header[2]
      let h_level = header[1]

      " Don't include the TOC's header itself
      if h_text ==# self.toc_header_text
        continue
      endif

       " Clean text
       let h_text = s:clean_header_text(h_text)

       " Treat levels
      let headers_levels[h_level-1] = [h_text, headers_levels[h_level-1][1]+1]
      for idx in range(h_level, 5) | let headers_levels[idx] = ['', 0] | endfor

      " Add parents header to format if toc_link_format == 0 => extended
      let h_complete_id = ''
      if vimwiki#vars#get_wikilocal('toc_link_format') == 1
        for l in range(h_level-1)
          if headers_levels[l][0] !=? ''
            let h_complete_id .= headers_levels[l][0].'#'
          endif
        endfor
      endif
      let h_complete_id .= headers_levels[h_level-1][0]

      " Store
      call add(complete_header_infos, [h_level, h_complete_id, h_text])
    endfor

    " Insert the information in the Link Template
    " -- and create line list
    let lines = []
    let startindent = repeat(' ', vimwiki#lst#get_list_margin())
    let indentstring = repeat(' ', vimwiki#u#sw())
    let bullet = vimwiki#lst#default_symbol().' '
    " Keep previous anchor => if redundant => add suffix -2
    let previous_anchors = {}
    for [lvl, anchor, desc] in complete_header_infos
      " [DESC](URL)
      if vimwiki#vars#get_wikilocal('syntax') ==# 'markdown'
        let link_tpl = vimwiki#vars#get_syntaxlocal('Weblink2Template')
      " [[URL]]
      elseif vimwiki#vars#get_wikilocal('toc_link_format') == 1
        let link_tpl = vimwiki#vars#get_global('WikiLinkTemplate2')
      " [[URL|DESC]]
      else
        let link_tpl = vimwiki#vars#get_global('WikiLinkTemplate1')
      endif

      " Normalize anchor
      let anchor = vimwiki#base#normalize_anchor(anchor, previous_anchors)

      " Insert link in template
      let link = s:safesubstitute(link_tpl, '__LinkUrl__',
            \ '#'.anchor, '')
      let link = s:safesubstitute(link, '__LinkDescription__', desc, '')
      call add(lines, startindent.repeat(indentstring, lvl-1).bullet.link)
    endfor

    return lines
  endfunction

  let links_rx = '\%(^\s*$\)\|^\s*\%(\%('.vimwiki#vars#get_syntaxlocal('rxListBullet').'\)\)'
  call vimwiki#base#update_listing_in_buffer(
        \ GeneratorTOC,
        \ toc_header_text,
        \ links_rx,
        \ 1,
        \ vimwiki#vars#get_wikilocal('toc_header_level'),
        \ a:create)
endfunction


function! vimwiki#base#apply_template(template, rxUrl, rxDesc, rxStyle, rxExtension) abort
  "   Construct a regular expression matching from template (with special
  "   characters properly escaped), by substituting rxUrl for __LinkUrl__, rxDesc
  "   for __LinkDescription__, rxStyle for __LinkStyle__ and rxExtension for
  "   __FileExtension__.  The four arguments rxUrl, rxDesc, rxStyle and
  "   rxExtension are copied verbatim, without any special character escapes or
  "   substitutions.
  let lnk = a:template
  if a:rxUrl !=? ''
    let lnk = s:safesubstitute(lnk, '__LinkUrl__', a:rxUrl, 'g')
  endif
  if a:rxDesc !=? ''
    let lnk = s:safesubstitute(lnk, '__LinkDescription__', a:rxDesc, 'g')
  endif
  if a:rxStyle !=? ''
    let lnk = s:safesubstitute(lnk, '__LinkStyle__', a:rxStyle, 'g')
  endif
  if a:rxExtension !=? ''
    let lnk = s:safesubstitute(lnk, '__FileExtension__', a:rxExtension, 'g')
  endif
  return lnk
endfunction


function! s:clean_url(url) abort
  " Helper: Clean url string
  " don't use an extension as part of the description
  let url = substitute(a:url, '\'.vimwiki#vars#get_wikilocal('ext').'$', '', '')
  " remove protocol and tld
  let url = substitute(url, '^\a\+\d*:', '', '')
  " remove absolute path prefix
  let url = substitute(url, '^//', '', '')
  let url = substitute(url, '^\([^/]\+\)\.\a\{2,4}/', '\1/', '')
  let url_l = split(url, '/\|=\|-\|&\|?\|\.')
  " case only a '-'
  if url_l == []
    return ''
  endif
  let url_l = filter(url_l, 'v:val !=# ""')
  if url_l[0] ==# 'www'
    let url_l = url_l[1:]
  endif
  if url_l[-1] =~# '^\(htm\|html\|php\)$'
    let url_l = url_l[0:-2]
  endif
  " remove words with black listed codepoints
  " TODO mutualize blacklist in a variable
  let url_l = filter(url_l, 'v:val !~?  "[!\"$%&''()*+,:;<=>?\[\]\\^`{}]"')
  " remove words consisting of only hexadecimal digits
  let url_l = filter(url_l, 'v:val !~?  "^\\x\\{4,}$" || v:val !~? "\\d"')
  return join(url_l, ' ')
endfunction


function! vimwiki#base#is_among_diary_files(filename, diary_file_paths) abort
  " Check if filename is in a list of diary files
  let l:normalised_file_paths =
        \ map(a:diary_file_paths, 'vimwiki#path#normalize(v:val)')
  " Escape single quote (Issue #886)
  let filename = substitute(a:filename, "'", "''", 'g')
  let l:matching_files =
        \ filter(l:normalised_file_paths, "v:val ==# '" . filename . "'" )
  return len(l:matching_files) > 0 " filename is a diary file if match is found
endfunction


function! vimwiki#base#is_diary_file(filename, ...) abort
  " Check if filename is a diary file.
  "
  " For our purposes, a diary file is any readable file with the current wiki
  " extension in diary_rel_path.
  "
  " An optional second argument allows you to pass in a list of diary files
  " rather than generating a list on each call to the function.  This is
  " handled by passing off to is_among_diary_files().  This behavior is
  " retained just in case anyone has scripted against is_diary_file(), but
  " shouldn't be used internally by VimWiki code.  Call is_among_diary_files()
  " directly instead.

  " Handle the case with diary file paths passed in:
  if a:0 > 0
    return vimwiki#base#is_among_diary_files(a:filename, a:1)
  endif

  let l:readable = filereadable(a:filename)
  let l:diary_path = vimwiki#vars#get_wikilocal('path') .
        \ vimwiki#vars#get_wikilocal('diary_rel_path')
  let l:in_diary_path = (0 == stridx(a:filename, l:diary_path))
  return l:readable && l:in_diary_path
endfunction


function! vimwiki#base#normalize_link_helper(str, rxUrl, rxDesc, template) abort
  " Treat link string towards normalization
  " [__LinkDescription__](__LinkUrl__.__FileExtension__)
  let url = matchstr(a:str, a:rxUrl)
  if vimwiki#vars#get_wikilocal('syntax') ==# 'markdown' && vimwiki#vars#get_wikilocal('markdown_link_ext')
    " Strip the extension if it exists so it doesn't get added multiple times
    let url = substitute(url, '\'.vimwiki#vars#get_wikilocal('ext').'$', '', '')
  endif
  let descr = matchstr(a:str, a:rxDesc)
  " Try to clean, do not work if bad link
  if descr ==# ''
    let descr = s:clean_url(url)
    if descr ==# '' | return url | endif
  endif
  " Substitute placeholders
  let lnk = s:safesubstitute(a:template, '__LinkDescription__', descr, '')
  let lnk = s:safesubstitute(lnk, '__LinkUrl__', url, '')
  let file_extension = vimwiki#vars#get_wikilocal('ext', vimwiki#vars#get_bufferlocal('wiki_nr'))
  let lnk = s:safesubstitute(lnk, '__FileExtension__', file_extension , '')
  return lnk
endfunction


function! vimwiki#base#normalize_imagelink_helper(str, rxUrl, rxDesc, rxStyle, template) abort
  " Treat imagelink string towards normalization
  let lnk = vimwiki#base#normalize_link_helper(a:str, a:rxUrl, a:rxDesc, a:template)
  let style = matchstr(a:str, a:rxStyle)
  let lnk = s:safesubstitute(lnk, '__LinkStyle__', style, '')
  return lnk
endfunction


function! vimwiki#base#normalize_link_in_diary(lnk) abort
  " Normalize link in a diary file
  " Refactor: in diary
  let sc = vimwiki#vars#get_wikilocal('links_space_char')
  let link = a:lnk . vimwiki#vars#get_wikilocal('ext')
  let link_wiki = substitute(vimwiki#vars#get_wikilocal('path') . '/' . link, '\s', sc, 'g')
  let link_diary = substitute(vimwiki#vars#get_wikilocal('path') . '/'
        \ . vimwiki#vars#get_wikilocal('diary_rel_path') . '/' . link, '\s', sc, 'g')
  let link_exists_in_diary = filereadable(link_diary)
  let link_exists_in_wiki = filereadable(link_wiki)
  let link_is_date = a:lnk =~# '\d\d\d\d-\d\d-\d\d'

  if link_is_date
    let str = a:lnk
    let rxUrl = vimwiki#vars#get_global('rxWord')
    let rxDesc = '\d\d\d\d-\d\d-\d\d'
    let template = vimwiki#vars#get_global('WikiLinkTemplate1')
  elseif link_exists_in_wiki
    let depth = len(split(vimwiki#vars#get_wikilocal('diary_rel_path'), '/'))
    let str = repeat('../', depth) . a:lnk
    let rxUrl = '.*'
    let rxDesc = '[^/]*$'
    let template = vimwiki#vars#get_global('WikiLinkTemplate2')
  else
    let str = a:lnk
    let rxUrl = '.*'
    let rxDesc = ''
    let template = vimwiki#vars#get_global('WikiLinkTemplate1')
  endif

  if vimwiki#vars#get_wikilocal('syntax') ==? 'markdown'
    let template = vimwiki#vars#get_syntaxlocal('Link1')
  endif

  return vimwiki#base#normalize_link_helper(str, rxUrl, rxDesc, template)
endfunction


function! s:normalize_link_syntax_n() abort
  " Normalize link in normal mode Enter keypress
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
    if vimwiki#base#is_diary_file(expand('%:p'))
      let sub = vimwiki#base#normalize_link_in_diary(lnk)
    else
      let sub = s:safesubstitute(
            \ vimwiki#vars#get_global('WikiLinkTemplate1'), '__LinkUrl__', lnk, '')
    endif
    " Replace file extension
    let file_extension = vimwiki#vars#get_wikilocal('ext', vimwiki#vars#get_bufferlocal('wiki_nr'))
    let sub = s:safesubstitute(sub, '__FileExtension__', file_extension , '')
    call vimwiki#base#replacestr_at_cursor('\V'.lnk, sub)
    return
  endif
endfunction


function! s:normalize_link_syntax_v() abort
  " TODO mutualize most code with syntax_n
  " Normalize link in visual mode Enter keypress
  " Get selection content
  let visual_selection = vimwiki#u#get_selection()

  " Embed link in template
  " In case of a diary link, wiki or markdown link
  if vimwiki#base#is_diary_file(expand('%:p'))
    let link = vimwiki#base#normalize_link_in_diary(visual_selection)
  else
    let link_tpl = vimwiki#vars#get_syntaxlocal('Link1')
    let link = s:safesubstitute(link_tpl, '__LinkUrl__', visual_selection, '')
  endif

  " Transform link:
  " Replace file extension
  let file_extension = vimwiki#vars#get_wikilocal('ext', vimwiki#vars#get_bufferlocal('wiki_nr'))
  let link = s:safesubstitute(link, '__FileExtension__', file_extension , '')

  " Replace space characters
  let sc = vimwiki#vars#get_wikilocal('links_space_char')
  let link = substitute(link, '\s', sc, 'g')

  " Replace description (used for markdown)
  let link = s:safesubstitute(link, '__LinkDescription__', visual_selection, '')

  " Remove newlines
  let link = substitute(link, '\n', '', '')

  " Paste result
  call vimwiki#u#get_selection(link)
endfunction


function! vimwiki#base#normalize_link(is_visual_mode) abort
  " Normalize link (Implemented as a switch function)
  " If visual mode
  if a:is_visual_mode
    return s:normalize_link_syntax_v()

  " If Syntax-specific normalizer exists: call it
  elseif exists('*vimwiki#'.vimwiki#vars#get_wikilocal('syntax').'_base#normalize_link')
    return vimwiki#{vimwiki#vars#get_wikilocal('syntax')}_base#normalize_link()

  " Normal mode default
  else
    return s:normalize_link_syntax_n()
  endif
endfunction


function! vimwiki#base#detect_nested_syntax() abort
  " Get nested syntax are present
  " Return: dictionary of syntaxes
  let last_word = '\v.*<(\w+)\s*$'
  let lines = map(filter(getline(1, '$'), 'v:val =~# "\\%({{{\\|`\\{3,\}\\|\\~\\{3,\}\\)" && v:val =~# last_word'),
        \ 'substitute(v:val, last_word, "\\=submatch(1)", "")')
  let dict = {}
  for elem in lines
    let dict[elem] = elem
  endfor
  return dict
endfunction


function! vimwiki#base#complete_links_escaped(ArgLead, CmdLine, CursorPos) abort
  " Complete globlinks escaping
  return vimwiki#base#get_globlinks_escaped(a:ArgLead)
endfunction


function! vimwiki#base#complete_links_raw(ArgLead, CmdLine, CursorPos) abort
  " Complete globlinks as raw string (unescaped)
  return vimwiki#base#get_globlinks_raw(a:ArgLead)
endfunction


function! vimwiki#base#complete_file(ArgLead, CmdLine, CursorPos) abort
  " Complete filename relative to current file
  " Called: rename_file
  " Start from current file
  let base_path = expand('%:h')

  " Get every file you can
  let completion_pattern = base_path . '/' . a:ArgLead . '*'
  let completion_list = split(glob(completion_pattern), '\n')

  " Remove base_path prefix from the result
  let base_len = len(base_path)
  let completion_list = map(completion_list, 'v:val[base_len+1:]')
  return completion_list
endfunction


function! vimwiki#base#read_caption(file) abort
  " Read caption
  " Called: by generate_links
  let rx_header = vimwiki#vars#get_syntaxlocal('rxHeader')

  if filereadable(a:file)
    for line in readfile(a:file, '', g:vimwiki_max_scan_for_caption)
      if line =~# rx_header
        return vimwiki#u#trim(matchstr(line, rx_header))
      endif
    endfor
  endif

  return ''
endfunction


function! vimwiki#base#search(search_pattern) abort
  " Search for 1.pattern
  " Called by commands VimwikiSearch and VWS
  if empty(a:search_pattern)
    call vimwiki#u#error('No search pattern given.')
    return
  endif

  let pattern = a:search_pattern

  " If the pattern does not start with a '/', then we'll assume that a
  " literal search is intended and enclose and escape it:
  if match(pattern, '^/') == -1
    let pattern = '/'.escape(pattern, '\').'/'
  endif

  let path = fnameescape(vimwiki#vars#get_wikilocal('path'))
  let ext  = vimwiki#vars#get_wikilocal('ext')
  let cmd  = 'lvimgrep '.pattern.' '.path.'**/*'.ext

  " Catch E480 error from lvimgrep if there's no match and present
  " a friendlier error message.
  try
    execute cmd
  catch
    call vimwiki#u#echo('Search: No match found.')
  endtry
endfunction

function! s:get_title(match) abort
  " used by function linkify to extract web page <title>
    " Do not overwrite if g:page_title is already set
    " when there are multiple <title> tags, only use the first one
    " this is a side effect of the substitute's 'n' flag (count number of
    " occurrences and evaluate \= for each one
    if (g:page_title !=# '')
        return
    endif
    let l:title = a:match

    " cleanup title so it's compatible with vimwiki links
    let l:title = substitute(l:title, '\\', '', 'g')
    let l:title = substitute(l:title, '\[', '(', 'g')
    let l:title = substitute(l:title, '\]', ')', 'g')

    " cosmetic cleanup (html entities), maybe more to add
    let l:title = substitute(l:title, '&lt;', '<', 'g')
    let l:title = substitute(l:title, '&gt;', '>', 'g')
    let l:title = substitute(l:title, '&nbsp;', ' ', 'g')

    " store title in global var
    let g:page_title = l:title
endfunction

function! vimwiki#base#linkify() abort
  " Transform: the url under the cursor to a wiki link
  let g:page_title = ''

  " Save existing value of @u and delete url under the cursor into @u
  let l:save_reg = @u
  exe 'normal! "udiW'

  " Create a scratch buffer and switch to it
  let current_buf = bufnr('')
  let scratch_buf = bufnr('scratch', 1)
  exe 'sil! ' . scratch_buf . 'buffer'

  " Load web page into scratch buffer using Nread with mode=2
  " FIXME: on Windows, with vim 7/8 (not with nvim), makes the cmd.exe window show up (annoying)
  exe 'sil! :2Nread ' . @u

  " Extract title from html
  " Note: if URL cannot be downloaded the buffer is empty or contains a single
  " line: 'Not found'
  let page_ok=0
  if (wordcount().chars !=0 && getline(1) !=? 'Not found')
    let page_ok=1
    " regex seems to work fine, but may not cover all cases
    exe 'sil! :keepp %s/\v\<title.{-}\>((.|\r)+)\<\/title\>/\=s:get_title(submatch(1))/n'
  endif

  " wipeout scratch buffer and switch to current
  exe scratch_buf . 'bwipeout'
  exe current_buf . 'buffer'

  if (page_ok)
    if vimwiki#vars#get_wikilocal('syntax') ==# 'markdown'
      " [DESC](URL)
      let link_tpl = vimwiki#vars#get_syntaxlocal('Weblink2Template')
    else
      " [[URL]]
      let link_tpl = g:vimwiki_global_vars.WikiLinkTemplate2
    endif
    let link = substitute(link_tpl, '__LinkUrl__', @u, '')
    let link = substitute(link, '__LinkDescription__', g:page_title==#'' ? @u : g:page_title, '')
    exe 'normal! i' . link
  else
    "if URL could not be downloaded, undo and display message
    "TODO: other behaviours may be possible (user options?)
    exe 'normal! u'
    echomsg 'Error downloading URL: ' . @u
  endif

  " restore initial value of @u
  let @u = l:save_reg
endfunction


function! vimwiki#base#complete_colorize(ArgLead, CmdLine, CursorPos) abort
  " We can safely ignore args if we use -custom=complete option, Vim engine
  " will do the job of filtering
  let colorlist = keys(vimwiki#vars#get_wikilocal('color_dic'))
  return join(colorlist, "\n")
endfunction

function! vimwiki#base#get_user_color(...) abort
  " Returns a color key <- user input, '' if fails
  let res = ''
  let display_list = []
  let color_dic = vimwiki#vars#get_wikilocal('color_dic')
  let key_list = sort(keys(color_dic))
  let i = 1
  for key in key_list
    call add(display_list, string(i) . '. ' . key)
    let i += 1
  endfor
  call insert(display_list, 'Select color:')
  " Ask user, fails if 0
  let i_selected = inputlist(display_list)
  if i_selected != 0
    let res = key_list[i_selected - 1]
  endif
  return res
endfunction

function! vimwiki#base#colorize(...) range abort
  " TODO Must be coherent with color_tag_template
  " Arg1: Key, list them with VimwikiColorize completion
  " Arg2: visualmode()
  " -- Just removing spaces, \/ -> /,  replacing COLORFG will do it
  let key = a:0 ? a:1 : 'default'
  let mode = a:0 > 1 ? a:2 : ''
  let color_dic = vimwiki#vars#get_wikilocal('color_dic')

  " Guard: if key = '', silently leave (user left inputlist)
  if key ==# ''
    return
  endif

  " Guard: color key nust exist
  if !has_key(color_dic, key)
    call vimwiki#u#error('color_dic variable has no key ''' . key . '''')
    return
  endif

  " Get content if called with a map with range
  if mode !=# ''
    " Visual mode
    let firstline = getpos("'<")[1]
    let lastline = getpos("'>")[1]
  else
    " Range command
    let firstline = a:firstline
    let lastline = a:lastline
  endif
  let lines = getline(firstline, lastline)

  " Prepare
  " -- pre
  let [fg, bg] = color_dic[key]
  let pre = '<span style="'
  if fg !=# ''
    let pre .= 'color:' . fg . ';'
  endif
  if bg !=# ''
    let pre .= 'background:' . bg . ';'
  endif
  let pre .= '">'
  " -- post
  let post = '</span>'

  " Concat
  if mode !=# ''
    " Visual mode (vim indexing ...)
    let pos = getpos("'>")[2] - 1
    let lines[len(lines)-1] = strpart(lines[len(lines)-1], 0, pos+1) . post . strpart(lines[len(lines)-1], pos+1)
    let pos = getpos("'<")[2]
    let lines[0] = strpart(lines[0],0, pos-1) . pre . strpart(lines[0], pos-1)
  else
    " Normal or Command
    let lines[len(lines)-1] = lines[len(lines)-1] . post
    let lines[0] = pre . lines[0]
  endif

  " Set buffer content
  for line in range(firstline, lastline)
    call setline(line, lines[line - firstline])
  endfor
endfunction

" -------------------------------------------------------------------------
" Load syntax-specific Wiki functionality
for s:syn in s:vimwiki_get_known_syntaxes()
  execute 'runtime! autoload/vimwiki/'.s:syn.'_base.vim'
endfor
" -------------------------------------------------------------------------
