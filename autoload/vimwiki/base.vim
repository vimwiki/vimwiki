" vim:tabstop=2:shiftwidth=2:expandtab:foldmethod=marker:textwidth=79
" Vimwiki autoload plugin file
" Author: Maxim Kim <habamax@gmail.com>
" Home: http://code.google.com/p/vimwiki/

if exists("g:loaded_vimwiki_auto") || &cp
  finish
endif
let g:loaded_vimwiki_auto = 1

" MISC helper functions {{{

" s:normalize_path
function! s:normalize_path(path) "{{{
  let g:VimwikiLog.normalize_path += 1  "XXX
  " resolve doesn't work quite right with symlinks ended with / or \
  return resolve(expand(substitute(a:path, '[/\\]\+$', '', ''))).'/'
endfunction "}}}

" s:path_html
function! s:path_html(idx) "{{{
  let path_html = VimwikiGet('path_html', a:idx)
  if !empty(path_html)
    return path_html
  else
    let g:VimwikiLog.path_html += 1  "XXX
    let path = VimwikiGet('path', a:idx)
    return substitute(path, '[/\\]\+$', '', '').'_html/'
  endif
endfunction "}}}

function! vimwiki#base#get_known_extensions() " {{{
  " Getting all extensions that different wikis could have
  let extensions = {}
  for wiki in g:vimwiki_list
    if has_key(wiki, 'ext')
      let extensions[wiki.ext] = 1
    else
      let extensions['.wiki'] = 1
    endif
  endfor
  " append map g:vimwiki_ext2syntax
  for ext in keys(g:vimwiki_ext2syntax)
    let extensions[ext] = 1
  endfor
  return keys(extensions)
endfunction " }}}

function! vimwiki#base#get_known_syntaxes() " {{{
  " Getting all syntaxes that different wikis could have
  let syntaxes = {}
  let syntaxes['default'] = 1
  for wiki in g:vimwiki_list
    if has_key(wiki, 'syntax')
      let syntaxes[wiki.syntax] = 1
    endif
  endfor
  " append map g:vimwiki_ext2syntax
  for syn in values(g:vimwiki_ext2syntax)
    let syntaxes[syn] = 1
  endfor
  return keys(syntaxes)
endfunction " }}}
" }}}

" vimwiki#base#apply_wiki_options
function! vimwiki#base#apply_wiki_options(options) " {{{ Update the current
  " wiki using the options dictionary
  for kk in keys(a:options)
    let g:vimwiki_list[g:vimwiki_current_idx][kk] = a:options[kk]
  endfor
  call vimwiki#base#validate_wiki_options(g:vimwiki_current_idx)
  call vimwiki#base#setup_buffer_state(g:vimwiki_current_idx)
endfunction " }}}

" vimwiki#base#read_wiki_options
function! vimwiki#base#read_wiki_options(check) " {{{ Attempt to read wiki
  " options from the current page's directory, or its ancesters.  If a file
  "   named vimwiki.vimrc is found, which declares a wiki-options dictionary
  "   named g:local_wiki, a message alerts the user that an update has been
  "   found and may be applied.  If the argument check=1, the user is queried
  "   before applying the update to the current wiki's option.

  " Save global vimwiki options ... after all, the global list is often
  "   initialized for the first time in vimrc files, and we don't want to
  "   overwrite !!  (not to mention all the other globals ...)
  let l:vimwiki_list = deepcopy(g:vimwiki_list, 1)
  "
  if a:check > 1
    call vimwiki#base#print_wiki_state()
    echo " \n"
  endif
  "
  let g:local_wiki = {}
  let done = 0
  " ... start the wild-goose chase!
  for invsubdir in ['.', '..', '../..', '../../..']
    " other names are possible, but most vimrc files will cause grief!
    for nm in ['vimwiki.vimrc']
      " TODO: use an alternate strategy, instead of source, to read options
      if done
        continue
      endif
      "
      let local_wiki_options_filename = expand('%:p:h').'/'.invsubdir.'/'.nm
      if !filereadable(local_wiki_options_filename)
        continue
      endif
      "
      echo "\nFound file : ".local_wiki_options_filename
      let query = "Vimwiki: Check for options in this file [Y]es/[n]o? "
      if a:check > 0 && (tolower(input(query)) !~ "y")
        continue
      endif
      "
      try
        execute 'source '.local_wiki_options_filename
      catch
      endtry
      if empty(g:local_wiki)
        continue
      endif
      "
      if a:check > 0
        echo "\n\nFound wiki options\n  g:local_wiki = ".string(g:local_wiki)
        let query = "Vimwiki: Apply these options [Y]es/[n]o? "
        if tolower(input(query)) !~ "y"
          let g:local_wiki = {}
          continue
        endif
      endif
      "
      " restore global list
      " - this prevents corruption by g:vimwiki_list in options_file
      let g:vimwiki_list = deepcopy(l:vimwiki_list, 1)
      "
      call vimwiki#base#apply_wiki_options(g:local_wiki)
      let done = 1
    endfor
  endfor
  if !done
    "
    " restore global list, if no local options were found
    " - this prevents corruption by g:vimwiki_list in options_file
    let g:vimwiki_list = deepcopy(l:vimwiki_list, 1)
    "
  endif
  if a:check > 1
    echo " \n "
    if done
      call vimwiki#base#print_wiki_state()
    else
      echo "Vimwiki: No options were applied."
    endif
  endif
endfunction " }}}

" vimwiki#base#validate_wiki_options
function! vimwiki#base#validate_wiki_options(idx) " {{{ Validate wiki options
  " Only call this function *before* opening a wiki page.
  "
  " XXX: It's too early to update global / buffer variables, because they are
  "  still needed in their existing state for s:setup_buffer_leave()
  "" let g:vimwiki_current_idx = a:idx

  " update normalized path & path_html
  call VimwikiSet('path', s:normalize_path(VimwikiGet('path', a:idx)), a:idx)
  call VimwikiSet('path_html', s:normalize_path(s:path_html(a:idx)), a:idx)
  call VimwikiSet('template_path', 
        \ s:normalize_path(VimwikiGet('template_path', a:idx)), a:idx)
  call VimwikiSet('diary_rel_path', 
        \ s:normalize_path(VimwikiGet('diary_rel_path', a:idx)), a:idx)

  " XXX: It's too early to update global / buffer variables, because they are
  "  still needed in their existing state for s:setup_buffer_leave()
  "" call vimwiki#base#cache_buffer_state()
endfunction " }}}

" vimwiki#base#setup_buffer_state
function! vimwiki#base#setup_buffer_state(idx) " {{{ Init page-specific variables
  " Only call this function *after* opening a wiki page.
  if a:idx < 0
    return
  endif

  let g:vimwiki_current_idx = a:idx

  " The following state depends on the current active wiki page
  let subdir = vimwiki#base#current_subdir(a:idx)
  call VimwikiSet('subdir', subdir, a:idx)
  call VimwikiSet('invsubdir', vimwiki#base#invsubdir(subdir), a:idx)
  call VimwikiSet('url', vimwiki#html#get_wikifile_url(expand('%:p')), a:idx)

  " update cache
  call vimwiki#base#cache_buffer_state()
endfunction " }}}

" vimwiki#base#cache_buffer_state
function! vimwiki#base#cache_buffer_state() "{{{
  if !exists('g:vimwiki_current_idx') && g:vimwiki_debug
    echo "[Vimwiki Internal Error]: Missing global state variable: 'g:vimwiki_current_idx'"
  endif
  let b:vimwiki_idx = g:vimwiki_current_idx
endfunction "}}}

" vimwiki#base#recall_buffer_state
function! vimwiki#base#recall_buffer_state() "{{{
  if !exists('b:vimwiki_idx')
    if g:vimwiki_debug
      echo "[Vimwiki Internal Error]: Missing buffer state variable: 'b:vimwiki_idx'"
    endif
    return 0
  else
    let g:vimwiki_current_idx = b:vimwiki_idx
    return 1
  endif
endfunction " }}}

" vimwiki#base#print_wiki_state
function! vimwiki#base#print_wiki_state() "{{{ print wiki options
  "   and buffer state variables
  let g_width = 18
  let b_width = 18
  echo "- Wiki Options (idx=".g:vimwiki_current_idx.") -"
  for kk in VimwikiGetOptionNames()
      echo "  '".kk."': ".repeat(' ', g_width-len(kk)).string(VimwikiGet(kk))
  endfor
  if !exists('b:vimwiki_list')
    return
  endif
  echo "- Cached Variables -"
  for kk in keys(b:vimwiki_list)
    echo "  '".kk."': ".repeat(' ', b_width-len(kk)).string(b:vimwiki_list[kk])
  endfor
endfunction "}}}

" vimwiki#base#mkdir
" If the optional argument 'confirm' == 1 is provided,
" vimwiki#base#mkdir will ask before creating a directory 
function! vimwiki#base#mkdir(path, ...) "{{{
  let path = expand(a:path)
  if !isdirectory(path) && exists("*mkdir")
    let path = vimwiki#u#chomp_slash(path)
    if vimwiki#u#is_windows() && !empty(g:vimwiki_w32_dir_enc)
      let path = iconv(path, &enc, g:vimwiki_w32_dir_enc)
    endif
    if a:0 && a:1 && tolower(input("Vimwiki: Make new directory: ".path."\n [Y]es/[n]o? ")) !~ "y"
      return 0
    endif
    call mkdir(path, "p")
  endif
  return 1
endfunction " }}}

" vimwiki#base#file_pattern
function! vimwiki#base#file_pattern(files) "{{{ Get search regex from glob()
  " string. Aim to support *all* special characters, forcing the user to choose
  "   names that are compatible with any external restrictions that they
  "   encounter (e.g. filesystem, wiki conventions, other syntaxes, ...).
  "   See: http://code.google.com/p/vimwiki/issues/detail?id=316
  " Change / to [/\\] to allow "Windows paths" 
  " TODO: boundary cases ...
  "   e.g. "File$", "^File", "Fi]le", "Fi[le", "Fi\le", "Fi/le"
  " XXX: (remove my comment if agreed) Maxim: with \V (very nomagic) boundary
  " cases works for 1 and 2.
  " 3, 4, 5 is not highlighted as links thus wouldn't be highlighted.
  " 6 is a regular vimwiki link with subdirectory...
  "
  let pattern = vimwiki#base#branched_pattern(a:files,"\n")
  return '\V'.pattern.'\m'
endfunction "}}}

" vimwiki#base#branched_pattern
function! vimwiki#base#branched_pattern(string,separator) "{{{ get search regex
" from a string-list; separators assumed at start and end as well
  let pattern = substitute(a:string, a:separator, '\\|','g')
  let pattern = substitute(pattern, '\%^\\|', '\\%(','')
  let pattern = substitute(pattern,'\\|\%$', '\\)','')
  return pattern
endfunction "}}}

" vimwiki#base#subdir
"FIXME TODO slow and faulty
function! vimwiki#base#subdir(path, filename)"{{{
  let g:VimwikiLog.subdir += 1  "XXX
  let path = a:path
  " ensure that we are not fooled by a symbolic link
  "FIXME if we are not "fooled", we end up in a completely different wiki?
  let filename = resolve(a:filename)
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
endfunction "}}}

" vimwiki#base#current_subdir
function! vimwiki#base#current_subdir(idx)"{{{
  return vimwiki#base#subdir(VimwikiGet('path', a:idx), expand('%:p'))
endfunction"}}}

" vimwiki#base#invsubdir
function! vimwiki#base#invsubdir(subdir) " {{{
  return substitute(a:subdir, '[^/\.]\+/', '../', 'g')
endfunction " }}}

" vimwiki#base#resolve_scheme
function! vimwiki#base#resolve_scheme(lnk, as_html) " {{{ Resolve scheme
  " if link is schemeless add wikiN: scheme
  let lnk = a:lnk
  let is_schemeless = lnk !~ g:vimwiki_rxSchemeUrl
  let lnk = (is_schemeless  ? 'wiki'.g:vimwiki_current_idx.':'.lnk : lnk)
  
  " Get scheme
  let scheme = matchstr(lnk, g:vimwiki_rxSchemeUrlMatchScheme)
  " Get link (without scheme)
  let lnk = matchstr(lnk, g:vimwiki_rxSchemeUrlMatchUrl)
  let path = ''
  let subdir = ''
  let ext = ''
  let idx = -1

  " do nothing if scheme is unknown to vimwiki
  if !(scheme =~ 'wiki.*' || scheme =~ 'diary' || scheme =~ 'local' 
        \ || scheme =~ 'file')
    return [idx, scheme, path, subdir, lnk, ext, scheme.':'.lnk]
  endif

  " scheme behaviors
  if scheme =~ 'wiki\d\+'
    let idx = eval(matchstr(scheme, '\D\+\zs\d\+\ze'))
    if idx < 0 || idx >= len(g:vimwiki_list)
      echom 'Vimwiki Error: Numbered scheme refers to a non-existent wiki!'
      return [idx,'','','','','','']
    else
      if idx != g:vimwiki_current_idx
        call vimwiki#base#validate_wiki_options(idx)
      endif
    endif

    if a:as_html
      if idx == g:vimwiki_current_idx
        let path = VimwikiGet('path_html')
      else
        let path = VimwikiGet('path_html', idx)
      endif
    else
      if idx == g:vimwiki_current_idx
        let path = VimwikiGet('path')
      else
        let path = VimwikiGet('path', idx)
      endif
    endif

    " For Issue 310. Otherwise current subdir is used for another wiki.
    if idx == g:vimwiki_current_idx
      let subdir = VimwikiGet('subdir')
    else
      let subdir = ""
    endif

    if a:as_html
      let ext = '.html'
    else
      if idx == g:vimwiki_current_idx
        let ext = VimwikiGet('ext')
      else
        let ext = VimwikiGet('ext', idx)
      endif
    endif

    " default link for directories
    if vimwiki#u#is_link_to_dir(lnk)
      let ext = (g:vimwiki_dir_link != '' ? g:vimwiki_dir_link. ext : '')
    endif
  elseif scheme =~ 'diary'
    if a:as_html
      " use cached value (save time when converting diary index!)
      let path = VimwikiGet('invsubdir')
      let ext = '.html'
    else
      let path = VimwikiGet('path')
      let ext = VimwikiGet('ext')
    endif
    let subdir = VimwikiGet('diary_rel_path')
  elseif scheme =~ 'local'
    " revisiting the 'lcd'-bug ...
    let path = VimwikiGet('path')
    let subdir = VimwikiGet('subdir')
    if a:as_html
      " prepend browser-specific file: scheme
      let path = 'file://'.fnamemodify(path, ":p")
    endif
  elseif scheme =~ 'file'
    " RM repeated leading "/"'s within a link
    let lnk = substitute(lnk, '^/*', '/', '')
    " convert "/~..." into "~..." for fnamemodify
    let lnk = substitute(lnk, '^/\~', '\~', '')
    " convert /C: to C: (or fnamemodify(...":p:h") interpret it as C:\C:
    if vimwiki#u#is_windows()
      let lnk = substitute(lnk, '^/\ze[[:alpha:]]:', '', '')
    endif
    if a:as_html
      " prepend browser-specific file: scheme
      let path = 'file://'.fnamemodify(lnk, ":p:h").'/'
    else
      let path = fnamemodify(lnk, ":p:h").'/'
    endif
    let lnk = fnamemodify(lnk, ":p:t")
    let subdir = ''
  endif


  " construct url from parts
  if is_schemeless && a:as_html
    let scheme = ''
    let url = lnk.ext
  else
    let url = path.subdir.lnk.ext
  endif

  " result
  return [idx, scheme, path, subdir, lnk, ext, url]
endfunction "}}}

" vimwiki#base#system_open_link
function! vimwiki#base#system_open_link(url) "{{{
  " handlers
  function! s:win32_handler(url)
    "http://vim.wikia.com/wiki/Opening_current_Vim_file_in_your_Windows_browser
    execute 'silent ! start "Title" /B ' . shellescape(a:url, 1)
  endfunction
  function! s:macunix_handler(url)
    execute '!open ' . shellescape(a:url, 1)
  endfunction
  function! s:linux_handler(url)
    call system('xdg-open ' . shellescape(a:url, 1).' &')
  endfunction
  let success = 0
  try 
    if vimwiki#u#is_windows()
      call s:win32_handler(a:url)
      return
    elseif has("macunix")
      call s:macunix_handler(a:url)
      return
    else
      call s:linux_handler(a:url)
      return
    endif
  endtry
  echomsg 'Default Vimwiki link handler was unable to open the HTML file!'
endfunction "}}}

" vimwiki#base#open_link
function! vimwiki#base#open_link(cmd, link, ...) "{{{
  let [idx, scheme, path, subdir, lnk, ext, url] = 
        \ vimwiki#base#resolve_scheme(a:link, 0)

  if url == ''
    if g:vimwiki_debug
      echom 'open_link: idx='.idx.', scheme='.scheme.', path='.path.', subdir='.subdir.', lnk='.lnk.', ext='.ext.', url='.url
    endif
    echom 'Vimwiki Error: Unable to resolve link!'
    return
  endif

  let update_prev_link = (
        \ scheme == '' || 
        \ scheme =~ 'wiki' || 
        \ scheme =~ 'diary' ? 1 : 0)

  let use_system_open = (
        \ scheme == '' || 
        \ scheme =~ 'wiki' || 
        \ scheme =~ 'diary' ? 0 : 1)

  let vimwiki_prev_link = []
  " update previous link for wiki pages
  if update_prev_link
    if a:0
      let vimwiki_prev_link = [a:1, []]
    elseif &ft == 'vimwiki'
      let vimwiki_prev_link = [expand('%:p'), getpos('.')]
    endif
  endif

  " open/edit
  if g:vimwiki_debug
    echom 'open_link: idx='.idx.', scheme='.scheme.', path='.path.', subdir='.subdir.', lnk='.lnk.', ext='.ext.', url='.url
  endif

  if use_system_open
    call vimwiki#base#system_open_link(url)
  else
    call vimwiki#base#edit_file(a:cmd, url,
          \ vimwiki_prev_link, update_prev_link)
    if idx != g:vimwiki_current_idx
      " this call to setup_buffer_state may not be necessary
      call vimwiki#base#setup_buffer_state(idx)
    endif
  endif
endfunction " }}}

" vimwiki#base#generate_links
function! vimwiki#base#generate_links() "{{{only get links from the current dir
  " change to the directory of the current file
  let orig_pwd = getcwd()
  lcd! %:h
  " all path are relative to the current file's location 
  let globlinks = glob('*'.VimwikiGet('ext'),1)."\n"
  " remove extensions
  let globlinks = substitute(globlinks, '\'.VimwikiGet('ext').'\ze\n', '', 'g')
  " restore the original working directory
  exe 'lcd! '.orig_pwd

  " We don't want link to itself. XXX Why ???
  " let cur_link = expand('%:t:r')
  " call filter(links, 'v:val != cur_link')
  let links = split(globlinks,"\n")
  call append(line('$'), substitute(g:vimwiki_rxH1_Template, '__Header__', 'Generated Links', ''))

  call sort(links)

  let bullet = repeat(' ', vimwiki#lst#get_list_margin()).
        \ vimwiki#lst#default_symbol().' '
  for link in links
    call append(line('$'), bullet.
          \ substitute(g:vimwiki_WikiLinkTemplate1, '__LinkUrl__', '\='."'".link."'", ''))
  endfor
endfunction " }}}

" vimwiki#base#goto
function! vimwiki#base#goto(key) "{{{
    call vimwiki#base#edit_file(':e',
          \ VimwikiGet('path').
          \ a:key.
          \ VimwikiGet('ext'))
endfunction "}}}

" vimwiki#base#backlinks
function! vimwiki#base#backlinks() "{{{
    execute 'lvimgrep "\%(^\|[[:blank:][:punct:]]\)'.
          \ expand("%:t:r").
          \ '\([[:blank:][:punct:]]\|$\)\C" '. 
          \ escape(VimwikiGet('path').'**/*'.VimwikiGet('ext'), ' ')
endfunction "}}}

" vimwiki#base#get_links
function! vimwiki#base#get_links(pat) "{{{ return string-list for files
  " in the current wiki matching the pattern "pat"
  " search all wiki files (or directories) in wiki 'path' and its subdirs.

  let time1 = reltime()  " start the clock

  " XXX: 
  " if maxhi = 1 and <leader>w<leader>w before loading any vimwiki file
  " cached 'subdir' is not set up
  try
    let subdir = VimwikiGet('subdir')
    " FIXED: was previously converting './' to '../'
    let invsubdir = VimwikiGet('invsubdir')
  catch
    let subdir = ''
    let invsubdir = ''
  endtry

  " if current wiki is temporary -- was added by an arbitrary wiki file then do
  " not search wiki files in subdirectories. Or it would hang the system if
  " wiki file was created in $HOME or C:/ dirs.
  if VimwikiGet('temp') 
    let search_dirs = ''
  else
    let search_dirs = '**/'
  endif
  " let globlinks = "\n".glob(VimwikiGet('path').search_dirs.a:pat,1)."\n"
  
  "save pwd, do lcd %:h, restore old pwd; getcwd()
  " change to the directory of the current file
  let orig_pwd = getcwd()
  
  " calling from other than vimwiki file 
  let path_base = vimwiki#u#path_norm(vimwiki#u#chomp_slash(VimwikiGet('path')))
  let path_file = vimwiki#u#path_norm(vimwiki#u#chomp_slash(expand('%:p:h')))

  if vimwiki#u#path_common_pfx(path_file, path_base) != path_base
    exe 'lcd! '.path_base
  else
    lcd! %:p:h
  endif

  " all path are relative to the current file's location 
  let globlinks = "\n".glob(invsubdir.search_dirs.a:pat,1)."\n"
  " remove extensions
  let globlinks = substitute(globlinks,'\'.VimwikiGet('ext').'\ze\n', '', 'g')
  " standardize path separators on Windows
  let globlinks = substitute(globlinks,'\\', '/', 'g')

  " shortening those paths ../../dir1/dir2/ that can be shortened
  " first for the current directory, then for parent etc.
  let sp_rx = '\n\zs' . invsubdir . subdir . '\ze'
  for i in range(len(invsubdir)/3)   "XXX multibyte?
    let globlinks = substitute(globlinks, sp_rx, '', 'g')
    let sp_rx = substitute(sp_rx,'\\zs../','../\\zs','')
    let sp_rx = substitute(sp_rx,'[^/]\+/\\ze','\\ze','')
  endfor
  " for directories: add ./ (instead of now empty) and invsubdir (if distinct)
  if a:pat == '*/'
    let globlinks = substitute(globlinks, "\n\n", "\n./\n",'') 
    if invsubdir != ''
      let globlinks .= invsubdir."\n"
    else
      let globlinks .= "./\n"
    endif
  endif

  " restore the original working directory
  exe 'lcd! '.orig_pwd

  let time2 = vimwiki#u#time(time1)
  call VimwikiLog_extend('timing',['base:afterglob('.len(split(globlinks, '\n')).')',time2])
  return globlinks
endfunction "}}}

" vimwiki#base#edit_file
function! vimwiki#base#edit_file(command, filename, ...) "{{{
  " XXX: Should we allow * in filenames!?
  " Maxim: It is allowed, escaping here is for vim to be able to open files
  " which have that symbols.
  " Try to remove * from escaping and open&save :
  " [[testBLAfile]]...
  " then
  " [[test*file]]...
  " you'll have E77: Too many file names
  let fname = escape(a:filename, '% *|#')
  let dir = fnamemodify(a:filename, ":p:h")
  if vimwiki#base#mkdir(dir, 1)
    execute a:command.' '.fname
  else
    echom ' '
    echom 'Vimwiki: Unable to edit file in non-existent directory: '.dir
  endif

  " save previous link
  " a:1 -- previous vimwiki link to save
  " a:2 -- should we update previous link
  if a:0 && a:2 && len(a:1) > 0
    let b:vimwiki_prev_link = a:1
  endif
endfunction " }}}

" vimwiki#base#search_word
function! vimwiki#base#search_word(wikiRx, cmd) "{{{
  let match_line = search(a:wikiRx, 's'.a:cmd)
  if match_line == 0
    echomsg 'vimwiki: Wiki link not found.'
  endif
endfunction " }}}

" vimwiki#base#matchstr_at_cursor
" Returns part of the line that matches wikiRX at cursor
function! vimwiki#base#matchstr_at_cursor(wikiRX) "{{{
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
endf "}}}

" vimwiki#base#replacestr_at_cursor
function! vimwiki#base#replacestr_at_cursor(wikiRX, sub) "{{{
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
endf "}}}

" s:print_wiki_list
function! s:print_wiki_list() "{{{
  let idx = 0
  while idx < len(g:vimwiki_list)
    if idx == g:vimwiki_current_idx
      let sep = ' * '
      echohl PmenuSel
    else
      let sep = '   '
      echohl None
    endif
    echo (idx + 1).sep.VimwikiGet('path', idx)
    let idx += 1
  endwhile
  echohl None
endfunction " }}}

" s:update_wiki_link
function! s:update_wiki_link(fname, old, new) " {{{
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
endfunction " }}}

" s:update_wiki_links_dir
function! s:update_wiki_links_dir(dir, old_fname, new_fname) " {{{
  let old_fname = substitute(a:old_fname, '[/\\]', '[/\\\\]', 'g')
  let new_fname = a:new_fname
  let old_fname_r = old_fname
  let new_fname_r = new_fname

  let old_fname_r = vimwiki#base#apply_template(g:vimwiki_WikiLinkTemplate1, 
          \ '\zs'.old_fname.'\ze', '.*', '').
        \ '\|'. vimwiki#base#apply_template(g:vimwiki_WikiLinkTemplate2, 
          \ '\zs'.old_fname.'\ze', '.*', '')

  let files = split(glob(VimwikiGet('path').a:dir.'*'.VimwikiGet('ext')), '\n')
  for fname in files
    call s:update_wiki_link(fname, old_fname_r, new_fname_r)
  endfor
endfunction " }}}

" s:tail_name
function! s:tail_name(fname) "{{{
  let result = substitute(a:fname, ":", "__colon__", "g")
  let result = fnamemodify(result, ":t:r")
  let result = substitute(result, "__colon__", ":", "g")
  return result
endfunction "}}}

" s:update_wiki_links
function! s:update_wiki_links(old_fname, new_fname) " {{{
  let old_fname = s:tail_name(a:old_fname)
  let new_fname = s:tail_name(a:new_fname)

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
    call s:update_wiki_links_dir(dir, 
          \ new_dir.old_fname, new_dir.new_fname)
    let idx = idx + 1
  endwhile
endfunction " }}}

" s:get_wiki_buffers
function! s:get_wiki_buffers() "{{{
  let blist = []
  let bcount = 1
  while bcount<=bufnr("$")
    if bufexists(bcount)
      let bname = fnamemodify(bufname(bcount), ":p")
      if bname =~ VimwikiGet('ext')."$"
        let bitem = [bname, getbufvar(bname, "vimwiki_prev_link")]
        call add(blist, bitem)
      endif
    endif
    let bcount = bcount + 1
  endwhile
  return blist
endfunction " }}}

" s:open_wiki_buffer
function! s:open_wiki_buffer(item) "{{{
  call vimwiki#base#edit_file(':e', a:item[0])
  if !empty(a:item[1])
    call setbufvar(a:item[0], "vimwiki_prev_link", a:item[1])
  endif
endfunction " }}}

" vimwiki#base#nested_syntax
function! vimwiki#base#nested_syntax(filetype, start, end, textSnipHl) abort "{{{
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
  if ft =~ 'perl'
    syntax clear perlFunctionName 
  endif
endfunction "}}}

" }}}

" WIKI link following functions {{{
" vimwiki#base#find_next_link
function! vimwiki#base#find_next_link() "{{{
  call vimwiki#base#search_word(g:vimwiki_rxAnyLink, '')
endfunction " }}}

" vimwiki#base#find_prev_link
function! vimwiki#base#find_prev_link() "{{{
  call vimwiki#base#search_word(g:vimwiki_rxAnyLink, 'b')
endfunction " }}}

" vimwiki#base#follow_link
function! vimwiki#base#follow_link(split, ...) "{{{ Parse link at cursor and pass 
  " to VimwikiLinkHandler, or failing that, the default open_link handler
  if exists('*vimwiki#'.VimwikiGet('syntax').'_base#follow_link')
    " Syntax-specific links
    " XXX: @Stuart: do we still need it?
    " XXX: @Maxim: most likely!  I am still working on a seemless way to
    " integrate regexp's without complicating syntax/vimwiki.vim
    if a:0
      call vimwiki#{VimwikiGet('syntax')}_base#follow_link(a:split, a:1)
    else
      call vimwiki#{VimwikiGet('syntax')}_base#follow_link(a:split)
    endif
  else
    if a:split == "split"
      let cmd = ":split "
    elseif a:split == "vsplit"
      let cmd = ":vsplit "
    elseif a:split == "tabnew"
      let cmd = ":tabnew "
    else
      let cmd = ":e "
    endif

    " try WikiLink
    let lnk = matchstr(vimwiki#base#matchstr_at_cursor(g:vimwiki_rxWikiLink),
          \ g:vimwiki_rxWikiLinkMatchUrl)
    " try WikiIncl
    if lnk == ""
      let lnk = matchstr(vimwiki#base#matchstr_at_cursor(g:vimwiki_rxWikiIncl),
          \ g:vimwiki_rxWikiInclMatchUrl)
    endif
    " try Weblink
    if lnk == ""
      let lnk = matchstr(vimwiki#base#matchstr_at_cursor(g:vimwiki_rxWeblink),
            \ g:vimwiki_rxWeblinkMatchUrl)
    endif

    if lnk != ""
      if !VimwikiLinkHandler(lnk)
        call vimwiki#base#open_link(cmd, lnk)
      endif
      return
    endif

    if a:0 > 0
      execute "normal! ".a:1
    else		
      call vimwiki#base#normalize_link(0)
    endif
  endif

endfunction " }}}

" vimwiki#base#go_back_link
function! vimwiki#base#go_back_link() "{{{
  if exists("b:vimwiki_prev_link")
    " go back to saved wiki link
    let prev_word = b:vimwiki_prev_link
    execute ":e ".substitute(prev_word[0], '\s', '\\\0', 'g')
    call setpos('.', prev_word[1])
  endif
endfunction " }}}

" vimwiki#base#goto_index
function! vimwiki#base#goto_index(wnum, ...) "{{{
  if a:wnum > len(g:vimwiki_list)
    echom "vimwiki: Wiki ".a:wnum." is not registered in g:vimwiki_list!"
    return
  endif

  " usually a:wnum is greater then 0 but with the following command it is == 0:
  " vim -n -c "exe 'VimwikiIndex' | echo g:vimwiki_current_idx"
  if a:wnum > 0
    let idx = a:wnum - 1
  else
    let idx = 0
  endif

  if a:0
    let cmd = 'tabedit'
  else
    let cmd = 'edit'
  endif

  if g:vimwiki_debug == 3
    echom "--- Goto_index g:curr_idx=".g:vimwiki_current_idx." ww_idx=".idx.""
  endif

  call vimwiki#base#validate_wiki_options(idx)
  call vimwiki#base#edit_file(cmd,
        \ VimwikiGet('path', idx).VimwikiGet('index', idx).
        \ VimwikiGet('ext', idx))
  call vimwiki#base#setup_buffer_state(idx)
endfunction "}}}

" vimwiki#base#delete_link
function! vimwiki#base#delete_link() "{{{
  "" file system funcs
  "" Delete wiki link you are in from filesystem
  let val = input('Delete ['.expand('%').'] (y/n)? ', "")
  if val != 'y'
    return
  endif
  let fname = expand('%:p')
  try
    call delete(fname)
  catch /.*/
    echomsg 'vimwiki: Cannot delete "'.expand('%:t:r').'"!'
    return
  endtry

  call vimwiki#base#go_back_link()
  execute "bdelete! ".escape(fname, " ")

  " reread buffer => deleted wiki link should appear as non-existent
  if expand('%:p') != ""
    execute "e"
  endif
endfunction "}}}

" vimwiki#base#rename_link
function! vimwiki#base#rename_link() "{{{
  "" Rename wiki link, update all links to renamed WikiWord
  let subdir = VimwikiGet('subdir')
  let old_fname = subdir.expand('%:t')

  " there is no file (new one maybe)
  if glob(expand('%:p')) == ''
    echomsg 'vimwiki: Cannot rename "'.expand('%:p').
          \'". It does not exist! (New file? Save it before renaming.)'
    return
  endif

  let val = input('Rename "'.expand('%:t:r').'" (y/n)? ', "")
  if val!='y'
    return
  endif

  let new_link = input('Enter new name: ', "")

  if new_link =~ '[/\\]'
    " It is actually doable but I do not have free time to do it.
    echomsg 'vimwiki: Cannot rename to a filename with path!'
    return
  endif

  " check new_fname - it should be 'good', not empty
  if substitute(new_link, '\s', '', 'g') == ''
    echomsg 'vimwiki: Cannot rename to an empty filename!'
    return
  endif

  let url = matchstr(new_link, g:vimwiki_rxWikiLinkMatchUrl)
  if url != ''
    let new_link = url
  endif
  
  let new_link = subdir.new_link
  let new_fname = VimwikiGet('path').new_link.VimwikiGet('ext')

  " do not rename if file with such name exists
  let fname = glob(new_fname)
  if fname != ''
    echomsg 'vimwiki: Cannot rename to "'.new_fname.
          \ '". File with that name exist!'
    return
  endif
  " rename wiki link file
  try
    echomsg "Renaming ".VimwikiGet('path').old_fname." to ".new_fname
    let res = rename(expand('%:p'), expand(new_fname))
    if res != 0
      throw "Cannot rename!"
    end
  catch /.*/
    echomsg 'vimwiki: Cannot rename "'.expand('%:t:r').'" to "'.new_fname.'"'
    return
  endtry

  let &buftype="nofile"

  let cur_buffer = [expand('%:p'),
        \getbufvar(expand('%:p'), "vimwiki_prev_link")]

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
  call s:update_wiki_links(old_fname, new_link)

  " restore wiki buffers
  for bitem in blist
    if bitem[0] != cur_buffer[0]
      call s:open_wiki_buffer(bitem)
    endif
  endfor

  call s:open_wiki_buffer([new_fname,
        \ cur_buffer[1]])
  " execute 'bwipeout '.escape(cur_buffer[0], ' ')

  echomsg old_fname." is renamed to ".new_fname

  let &more = setting_more
endfunction " }}}

" vimwiki#base#ui_select
function! vimwiki#base#ui_select() "{{{
  call s:print_wiki_list()
  let idx = input("Select Wiki (specify number): ")
  if idx == ""
    return
  endif
  call vimwiki#base#goto_index(idx)
endfunction "}}}
" }}}

" TEXT OBJECTS functions {{{

" vimwiki#base#TO_header
function! vimwiki#base#TO_header(inner, visual) "{{{
  if !search('^\(=\+\).\+\1\s*$', 'bcW')
    return
  endif
  
  let sel_start = line("'<")
  let sel_end = line("'>")
  let block_start = line(".")
  let advance = 0

  let level = vimwiki#u#count_first_sym(getline('.'))

  let is_header_selected = sel_start == block_start 
        \ && sel_start != sel_end

  if a:visual && is_header_selected
    if level > 1
      let level -= 1
      call search('^\(=\{'.level.'\}\).\+\1\s*$', 'bcW')
    else
      let advance = 1
    endif
  endif

  normal! V

  if a:visual && is_header_selected
    call cursor(sel_end + advance, 0)
  endif

  if search('^\(=\{1,'.level.'}\).\+\1\s*$', 'W')
    call cursor(line('.') - 1, 0)
  else
    call cursor(line('$'), 0)
  endif

  if a:inner && getline(line('.')) =~ '^\s*$'
    let lnum = prevnonblank(line('.') - 1)
    call cursor(lnum, 0)
  endif
endfunction "}}}

" vimwiki#base#TO_table_cell
function! vimwiki#base#TO_table_cell(inner, visual) "{{{
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
    " selection furhter fails. But if we shake the cursor left and right then
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
endfunction "}}}

" vimwiki#base#TO_table_col
function! vimwiki#base#TO_table_col(inner, visual) "{{{
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
      if strpart(getline('.'), virtcol('.')-1) =~ '^-+'
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
    elseif a:inner && getline('.')[virtcol('.')+1] =~ '[|+]'
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
    if strpart(getline('.'), virtcol('.')-1) =~ '^-+'
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
endfunction "}}}
" }}}

" HEADER functions {{{
" vimwiki#base#AddHeaderLevel
function! vimwiki#base#AddHeaderLevel() "{{{
  let lnum = line('.')
  let line = getline(lnum)
  let rxHdr = g:vimwiki_rxH
  if line =~ '^\s*$'
    return
  endif

  if line =~ g:vimwiki_rxHeader
    let level = vimwiki#u#count_first_sym(line)
    if level < 6
      if g:vimwiki_symH
        let line = substitute(line, '\('.rxHdr.'\+\).\+\1', rxHdr.'&'.rxHdr, '')
      else
        let line = substitute(line, '\('.rxHdr.'\+\).\+', rxHdr.'&', '')
      endif
      call setline(lnum, line)
    endif
  else
    let line = substitute(line, '^\s*', '&'.rxHdr.' ', '') 
    if g:vimwiki_symH
      let line = substitute(line, '\s*$', ' '.rxHdr.'&', '')
    endif
    call setline(lnum, line)
  endif
endfunction "}}}

" vimwiki#base#RemoveHeaderLevel
function! vimwiki#base#RemoveHeaderLevel() "{{{
  let lnum = line('.')
  let line = getline(lnum)
  let rxHdr = g:vimwiki_rxH
  if line =~ '^\s*$'
    return
  endif

  if line =~ g:vimwiki_rxHeader
    let level = vimwiki#u#count_first_sym(line)
    let old = repeat(rxHdr, level)
    let new = repeat(rxHdr, level - 1)

    let chomp = line =~ rxHdr.'\s'

    if g:vimwiki_symH
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
endfunction " }}}
"}}}

" LINK functions {{{
" vimwiki#base#apply_template
"   Construct a regular expression matching from template (with special
"   characters properly escaped), by substituting rxUrl for __LinkUrl__, rxDesc
"   for __LinkDescription__, and rxStyle for __LinkStyle__.  The three
"   arguments rxUrl, rxDesc, and rxStyle are copied verbatim, without any
"   special character escapes or substitutions.
function! vimwiki#base#apply_template(template, rxUrl, rxDesc, rxStyle) "{{{
  let magic_chars = '.*[\^$'
  let lnk = escape(a:template, magic_chars)
  if a:rxUrl != ""
    let lnk = substitute(lnk, '__LinkUrl__', '\='."'".a:rxUrl."'", '') 
  endif
  if a:rxDesc != ""
    let lnk = substitute(lnk, '__LinkDescription__', '\='."'".a:rxDesc."'", '')
  endif
  if a:rxStyle != ""
    let lnk = substitute(lnk, '__LinkStyle__', '\='."'".a:rxStyle."'", '')
  endif
  return lnk
endfunction " }}}

" s:clean_url
function! s:clean_url(url) " {{{
  let url = split(a:url, '/\|=\|-\|&\|?\|\.')
  let url = filter(url, 'v:val != ""')
  let url = filter(url, 'v:val != "www"')
  let url = filter(url, 'v:val != "com"')
  let url = filter(url, 'v:val != "org"')
  let url = filter(url, 'v:val != "net"')
  let url = filter(url, 'v:val != "edu"')
  let url = filter(url, 'v:val != "http\:"')
  let url = filter(url, 'v:val != "https\:"')
  let url = filter(url, 'v:val != "file\:"')
  let url = filter(url, 'v:val != "xml\:"')
  return join(url, " ")
endfunction " }}}

" vimwiki#base#normalize_link_helper
function! vimwiki#base#normalize_link_helper(str, rxUrl, rxDesc, template) " {{{
  let str = a:str
  let url = matchstr(str, a:rxUrl)
  let descr = matchstr(str, a:rxDesc)
  let template = a:template
  if descr == ""
    let descr = s:clean_url(url)
  endif
  let lnk = substitute(template, '__LinkDescription__', '\="'.descr.'"', '')
  let lnk = substitute(lnk, '__LinkUrl__', '\="'.url.'"', '')
  return lnk
endfunction " }}}

" vimwiki#base#normalize_imagelink_helper
function! vimwiki#base#normalize_imagelink_helper(str, rxUrl, rxDesc, rxStyle, template) "{{{
  let lnk = vimwiki#base#normalize_link_helper(a:str, a:rxUrl, a:rxDesc, a:template)
  let style = matchstr(str, a:rxStyle)
  let lnk = substitute(lnk, '__LinkStyle__', '\="'.style.'"', '')
  return lnk
endfunction " }}}

" s:normalize_link_syntax_n
function! s:normalize_link_syntax_n() " {{{
  let lnum = line('.')

  " try WikiLink
  let lnk = vimwiki#base#matchstr_at_cursor(g:vimwiki_rxWikiLink)
  if !empty(lnk)
    let sub = vimwiki#base#normalize_link_helper(lnk,
          \ g:vimwiki_rxWikiLinkMatchUrl, g:vimwiki_rxWikiLinkMatchDescr,
          \ g:vimwiki_WikiLinkTemplate2)
    call vimwiki#base#replacestr_at_cursor(g:vimwiki_rxWikiLink, sub)
    if g:vimwiki_debug > 1
      echomsg "WikiLink: ".lnk." Sub: ".sub
    endif
    return
  endif
  
  " try WikiIncl
  let lnk = vimwiki#base#matchstr_at_cursor(g:vimwiki_rxWikiIncl)
  if !empty(lnk)
    " NO-OP !!
    if g:vimwiki_debug > 1
      echomsg "WikiIncl: ".lnk." Sub: ".lnk
    endif
    return
  endif

  " try Word (any characters except separators)
  " rxWord is less permissive than rxWikiLinkUrl which is used in
  " normalize_link_syntax_v
  let lnk = vimwiki#base#matchstr_at_cursor(g:vimwiki_rxWord)
  if !empty(lnk)
    let sub = vimwiki#base#normalize_link_helper(lnk,
          \ g:vimwiki_rxWord, '',
          \ g:vimwiki_WikiLinkTemplate1)
    call vimwiki#base#replacestr_at_cursor('\V'.lnk, sub)
    if g:vimwiki_debug > 1
      echomsg "Word: ".lnk." Sub: ".sub
    endif
    return
  endif

endfunction " }}}

" s:normalize_link_syntax_v
function! s:normalize_link_syntax_v() " {{{
  let lnum = line('.')
  let sel_save = &selection
  let &selection = "old"
  let rv = @"
  let rt = getregtype('"')
  let done = 0

  try
    norm! gvy
    let visual_selection = @"
    let visual_selection = substitute(g:vimwiki_WikiLinkTemplate1, '__LinkUrl__', '\='."'".visual_selection."'", '')

    call setreg('"', visual_selection, 'v')

    " paste result
    norm! `>pgvd

  finally
    call setreg('"', rv, rt)
    let &selection = sel_save
  endtry

endfunction " }}}

" vimwiki#base#normalize_link
function! vimwiki#base#normalize_link(is_visual_mode) "{{{
  if exists('*vimwiki#'.VimwikiGet('syntax').'_base#normalize_link')
    " Syntax-specific links
    call vimwiki#{VimwikiGet('syntax')}_base#normalize_link(a:is_visual_mode)
  else
    if !a:is_visual_mode
      call s:normalize_link_syntax_n()
    elseif visualmode() ==# 'v' && line("'<") == line("'>")
      " action undefined for 'line-wise' or 'multi-line' visual mode selections
      call s:normalize_link_syntax_v()
    endif
  endif
endfunction "}}}

" }}}

" -------------------------------------------------------------------------
" Load syntax-specific Wiki functionality
for syn in vimwiki#base#get_known_syntaxes()
  execute 'runtime! autoload/vimwiki/'.syn.'_base.vim'
endfor 
" -------------------------------------------------------------------------


