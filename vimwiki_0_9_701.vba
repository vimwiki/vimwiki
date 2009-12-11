" Vimball Archiver by Charles E. Campbell, Jr., Ph.D.
UseVimball
finish
autoload\vimwiki.vim	[[[1
680
" Vimwiki autoload plugin file
" Author: Maxim Kim <habamax@gmail.com>
" Home: http://code.google.com/p/vimwiki/

if exists("g:loaded_vimwiki_auto") || &cp
  finish
endif
let g:loaded_vimwiki_auto = 1

if has("win32")
  let s:os_sep = '\'
else
  let s:os_sep = '/'
endif

let s:badsymbols = '['.g:vimwiki_badsyms.g:vimwiki_stripsym.'<>|?*:"]'

" MISC helper functions {{{

" This function is double defined.
" TODO: refactor common functions into new module.
function! s:chomp_slash(str)"{{{
  return substitute(a:str, '[/\\]\+$', '', '')
endfunction"}}}

function! vimwiki#mkdir(path) "{{{
  let path = expand(a:path)
  if !isdirectory(path) && exists("*mkdir")
    let path = s:chomp_slash(path)
    call mkdir(path, "p")
  endif
endfunction
" }}}

function! vimwiki#safe_link(string) "{{{
  return substitute(a:string, s:badsymbols, g:vimwiki_stripsym, 'g')
endfunction
"}}}

function! vimwiki#unsafe_link(string) "{{{
  return substitute(a:string, g:vimwiki_stripsym, s:badsymbols, 'g')
endfunction
"}}}

function! vimwiki#subdir(path, filename)"{{{
  let path = expand(a:path)
  let filename = expand(a:filename)
  let idx = 0
  while path[idx] == filename[idx]
    let idx = idx + 1
  endwhile

  let p = split(strpart(filename, idx), '[/\\]')
  let res = join(p[:-2], s:os_sep)
  if len(res) > 0
    let res = res.s:os_sep
  endif
  return res
endfunction"}}}

function! vimwiki#current_subdir()"{{{
  return vimwiki#subdir(VimwikiGet('path'), expand('%:p'))
endfunction"}}}

function! vimwiki#msg(message) "{{{
  echohl WarningMsg
  echomsg 'vimwiki: '.a:message
  echohl None
endfunction
" }}}

function! s:filename(link) "{{{
  let result = vimwiki#safe_link(a:link)
  if a:link =~ '|'
    let result = vimwiki#safe_link(split(a:link, '|')[0])
  elseif a:link =~ ']['
    let result = vimwiki#safe_link(split(a:link, '][')[0])
  endif
  return result
endfunction
" }}}

function! s:is_wiki_word(str) "{{{
  if a:str =~ g:vimwiki_word1 && a:str !~ '[[:space:]\\/]'
    return 1
  endif
  return 0
endfunction
" }}}

function! s:edit_file(command, filename) "{{{
  let fname = escape(a:filename, '% ')
  call vimwiki#mkdir(fnamemodify(a:filename, ":p:h"))
  execute a:command.' '.fname
endfunction
" }}}

function! s:search_word(wikiRx, cmd) "{{{
  let match_line = search(a:wikiRx, 's'.a:cmd)
  if match_line == 0
    call vimwiki#msg('WikiWord not found')
  endif
endfunction
" }}}

function! s:get_word_at_cursor(wikiRX) "{{{
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

function! s:strip_word(word) "{{{
  let result = a:word
  if strpart(a:word, 0, 2) == "[["
    " get rid of [[ and ]]
    let w = strpart(a:word, 2, strlen(a:word)-4)

    if w =~ '|'
      " we want "link" from [[link|link desc]]
      let w = split(w, "|")[0]
    elseif w =~ ']['
      " we want "link" from [[link][link desc]]
      let w = split(w, "][")[0]
    endif

    let result = vimwiki#safe_link(w)
  endif
  return result
endfunction
" }}}

function! s:is_link_to_non_wiki_file(word) "{{{
  " Check if word is link to a non-wiki file.
  " The easiest way is to check if it has extension like .txt or .html
  if a:word =~ '\.\w\{1,4}$'
    return 1
  endif
  return 0
endfunction
" }}}

function! s:print_wiki_list() "{{{
  let idx = 0
  while idx < len(g:vimwiki_list)
    if idx == g:vimwiki_current_idx
      let sep = ' * '
      echohl TablineSel
    else
      let sep = '   '
      echohl None
    endif
    echo (idx + 1).sep.VimwikiGet('path', idx)
    let idx += 1
  endwhile
  echohl None
endfunction
" }}}

function! s:wiki_select(wnum)"{{{
  if a:wnum < 1 || a:wnum > len(g:vimwiki_list)
    return
  endif
  let b:vimwiki_idx = g:vimwiki_current_idx
  let g:vimwiki_current_idx = a:wnum - 1
endfunction
" }}}

function! s:update_wiki_link(fname, old, new) " {{{
  echo "Updating links in ".a:fname
  let has_updates = 0
  let dest = []
  for line in readfile(a:fname)
    if !has_updates && match(line, a:old) != -1
      let has_updates = 1
    endif
    call add(dest, substitute(line, a:old, escape(a:new, "&"), "g"))
  endfor
  " add exception handling...
  if has_updates
    call rename(a:fname, a:fname.'#vimwiki_upd#')
    call writefile(dest, a:fname)
    call delete(a:fname.'#vimwiki_upd#')
  endif
endfunction
" }}}

function! s:update_wiki_links_dir(dir, old_fname, new_fname) " {{{
  let old_fname = substitute(a:old_fname, '[/\\]', '[/\\\\]', 'g')
  let new_fname = a:new_fname

  if !s:is_wiki_word(new_fname)
    let new_fname = '[['.new_fname.']]'
  endif
  if !s:is_wiki_word(old_fname)
    let old_fname = '\[\['.vimwiki#unsafe_link(old_fname).
          \ '\%(|.*\)\?\%(\]\[.*\)\?\]\]'
  else
    let old_fname = '\<'.old_fname.'\>'
  endif
  let files = split(glob(VimwikiGet('path').a:dir.'*'.VimwikiGet('ext')), '\n')
  for fname in files
    call s:update_wiki_link(fname, old_fname, new_fname)
  endfor
endfunction
" }}}

function! s:tail_name(fname) "{{{
  let result = substitute(a:fname, ":", "__colon__", "g")
  let result = fnamemodify(result, ":t:r")
  let result = substitute(result, "__colon__", ":", "g")
  return result
endfunction "}}}

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
endfunction
" }}}

function! s:get_wiki_buffers() "{{{
  let blist = []
  let bcount = 1
  while bcount<=bufnr("$")
    if bufexists(bcount)
      let bname = fnamemodify(bufname(bcount), ":p")
      if bname =~ VimwikiGet('ext')."$"
        let bitem = [bname, getbufvar(bname, "vimwiki_prev_word")]
        call add(blist, bitem)
      endif
    endif
    let bcount = bcount + 1
  endwhile
  return blist
endfunction
" }}}

function! s:open_wiki_buffer(item) "{{{
  call s:edit_file('e', a:item[0])
  if !empty(a:item[1])
    call setbufvar(a:item[0], "vimwiki_prev_word", a:item[1])
  endif
endfunction
" }}}

" }}}

" SYNTAX highlight {{{
function! vimwiki#WikiHighlightWords() "{{{
  " search all wiki files in 'path' and its subdirs.
  let subdir = vimwiki#current_subdir()
  let wikies = glob(VimwikiGet('path').subdir.'**/*'.VimwikiGet('ext'))

  " remove .wiki extensions
  let wikies = substitute(wikies, '\'.VimwikiGet('ext'), "", "g")
  let g:vimwiki_wikiwords = split(wikies, '\n')

  " remove backup files (.wiki~)
  call filter(g:vimwiki_wikiwords, 'v:val !~ ''.*\~$''')

  " remove paths
  let rem_path = escape(expand(VimwikiGet('path')).subdir, '\')
  call map(g:vimwiki_wikiwords, 'substitute(v:val, rem_path, "", "g")')

  " Links with subdirs should be highlighted for linux and windows separators
  " Change \ or / to [/\\]
  let os_p = '[/\\]'
  let os_p2 = escape(os_p, '\')
  call map(g:vimwiki_wikiwords, 'substitute(v:val, os_p, os_p2, "g")')

  for word in g:vimwiki_wikiwords
    if g:vimwiki_camel_case &&
          \ word =~ g:vimwiki_word1 && !s:is_link_to_non_wiki_file(word)
      execute 'syntax match VimwikiWord /\%(^\|[^!]\)\zs\<'.word.'\>/'
    endif
    execute 'syntax match VimwikiWord /\[\[\<'.
          \ vimwiki#unsafe_link(word).
          \ '\>\%(|\+.*\)*\]\]/'
    execute 'syntax match VimwikiWord /\[\[\<'.
          \ vimwiki#unsafe_link(word).
          \ '\>\]\[.\+\]\]/'
  endfor
  execute 'syntax match VimwikiWord /\[\[.\+\.\%(jpg\|png\|gif\)\%(|\+.*\)*\]\]/'
  execute 'syntax match VimwikiWord /\[\[.\+\.\%(jpg\|png\|gif\)\]\[.\+\]\]/'
endfunction
" }}}

function! vimwiki#hl_exists(hl)"{{{
  if !hlexists(a:hl)
    return 0
  endif
  redir => hlstatus
  exe "silent hi" a:hl
  redir END
  return (hlstatus !~ "cleared")
endfunction
"}}}

function! vimwiki#nested_syntax(filetype, start, end, textSnipHl) abort "{{{
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

  execute 'syntax include @'.group.' syntax/'.a:filetype.'.vim'
  try
    execute 'syntax include @'.group.' after/syntax/'.a:filetype.'.vim'
  catch
  endtry

  let &iskeyword = is_keyword

  if exists('s:current_syntax')
    let b:current_syntax=s:current_syntax
  else
    unlet b:current_syntax
  endif
  execute 'syntax region textSnip'.ft.'
        \ matchgroup='.a:textSnipHl.'
        \ start="'.a:start.'" end="'.a:end.'"
        \ contains=@'.group
endfunction "}}}

"}}}

" WIKI functions {{{
function! vimwiki#WikiNextWord() "{{{
  call s:search_word(g:vimwiki_rxWikiWord.'\|'.g:vimwiki_rxWeblink, '')
endfunction
" }}}

function! vimwiki#WikiPrevWord() "{{{
  call s:search_word(g:vimwiki_rxWikiWord.'\|'.g:vimwiki_rxWeblink, 'b')
endfunction
" }}}

function! vimwiki#WikiFollowWord(split) "{{{
  if a:split == "split"
    let cmd = ":split "
  elseif a:split == "vsplit"
    let cmd = ":vsplit "
  else
    let cmd = ":e "
  endif

  let word = s:strip_word(s:get_word_at_cursor(g:vimwiki_rxWikiWord))
  if word == ""
    let weblink = s:strip_word(s:get_word_at_cursor(g:vimwiki_rxWeblink))
    if weblink != ""
      call VimwikiWeblinkHandler(weblink)
    else
      execute "normal! \n"
    endif
    return
  endif

  if s:is_link_to_non_wiki_file(word)
    call s:edit_file(cmd, word)
  else
    let vimwiki_prev_word = [expand('%:p'), getpos('.')]
    let subdir = vimwiki#current_subdir()
    call s:edit_file(cmd, VimwikiGet('path').subdir.word.VimwikiGet('ext'))
    let b:vimwiki_prev_word = vimwiki_prev_word
  endif
endfunction
" }}}

function! vimwiki#WikiGoBackWord() "{{{
  if exists("b:vimwiki_prev_word")
    " go back to saved WikiWord
    let prev_word = b:vimwiki_prev_word
    execute ":e ".substitute(prev_word[0], '\s', '\\\0', 'g')
    call setpos('.', prev_word[1])
  endif
endfunction
" }}}

function! vimwiki#WikiGoHome(index) "{{{
  call s:wiki_select(a:index)
  call vimwiki#mkdir(VimwikiGet('path'))

  try
    execute ':e '.VimwikiGet('path').VimwikiGet('index').VimwikiGet('ext')
  catch /E37/ " catch 'No write since last change' error
    " this is really unsecure!!!
    execute ':'.VimwikiGet('gohome').' '.
          \ VimwikiGet('path').
          \ VimwikiGet('index').
          \ VimwikiGet('ext')
  catch /E325/ " catch 'ATTENTION' error
    " TODO: Hmmm, if open already opened index.wiki there is an error...
    " Find out what is the reason and how to avoid it. Is it dangerous?
    echomsg "Unknown error!"
  endtry
endfunction
"}}}

function! vimwiki#WikiDeleteWord() "{{{
  "" file system funcs
  "" Delete WikiWord you are in from filesystem
  let val = input('Delete ['.expand('%').'] (y/n)? ', "")
  if val != 'y'
    return
  endif
  let fname = expand('%:p')
  try
    call delete(fname)
  catch /.*/
    call vimwiki#msg('Cannot delete "'.expand('%:t:r').'"!')
    return
  endtry
  execute "bdelete! ".escape(fname, " ")

  " reread buffer => deleted WikiWord should appear as non-existent
  if expand('%:p') != ""
    execute "e"
  endif
endfunction
"}}}

function! vimwiki#WikiRenameWord() "{{{
  "" Rename WikiWord, update all links to renamed WikiWord
  let subdir = vimwiki#current_subdir()
  let old_fname = subdir.expand('%:t')

  " there is no file (new one maybe)
  if glob(expand('%:p')) == ''
    call vimwiki#msg('Cannot rename "'.expand('%:p').
          \ '". It does not exist! (New file? Save it before renaming.)')
    return
  endif

  let val = input('Rename "'.expand('%:t:r').'" (y/n)? ', "")
  if val!='y'
    return
  endif

  let new_link = input('Enter new name: ', "")

  if new_link =~ '[/\\]'
    " It is actually doable but I do not have free time to do it.
    call vimwiki#msg('Cannot rename to a filename with path!')
    return
  endif

  let new_link = subdir.new_link

  " check new_fname - it should be 'good', not empty
  if substitute(new_link, '\s', '', 'g') == ''
    call vimwiki#msg('Cannot rename to an empty filename!')
    return
  endif
  if s:is_link_to_non_wiki_file(new_link)
    call vimwiki#msg('Cannot rename to a filename with extension (ie .txt .html)!')
    return
  endif

  let new_link = s:strip_word(new_link)
  let new_fname = VimwikiGet('path').s:filename(new_link).VimwikiGet('ext')

  " do not rename if word with such name exists
  let fname = glob(new_fname)
  if fname != ''
    call vimwiki#msg('Cannot rename to "'.new_fname.
          \ '". File with that name exist!')
    return
  endif
  " rename WikiWord file
  try
    echomsg "Renaming ".VimwikiGet('path').old_fname." to ".new_fname
    let res = rename(expand('%:p'), expand(new_fname))
    if res != 0
      throw "Cannot rename!"
    end
  catch /.*/
    call vimwiki#msg('Cannot rename "'.expand('%:t:r').'" to "'.new_fname.'"')
    return
  endtry

  let &buftype="nofile"

  let cur_buffer = [expand('%:p'),
        \getbufvar(expand('%:p'), "vimwiki_prev_word")]

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
endfunction
" }}}

function! vimwiki#WikiUISelect()"{{{
  call s:print_wiki_list()
  let idx = input("Select Wiki (specify number): ")
  if idx == ""
    return
  endif
  call vimwiki#WikiGoHome(idx)
endfunction
"}}}

" }}}

" TEXT OBJECTS functions {{{

function! vimwiki#TO_header(inner, visual) "{{{
  if !search('^\(=\+\)[^=]\+\1\s*$', 'bcW')
    return
  endif

  let sel_start = line("'<")
  let sel_end = line("'>")
  let block_start = line(".")
  let advance = 0

  let level = vimwiki#count_first_sym(getline('.'))

  let is_header_selected = sel_start == block_start
        \ && sel_start != sel_end

  if a:visual && is_header_selected
    if level > 1
      let level -= 1
      call search('^\(=\{'.level.'\}\)[^=]\+\1\s*$', 'bcW')
    else
      let advance = 1
    endif
  endif

  normal! V

  if a:visual && is_header_selected
    call cursor(sel_end + advance, 0)
  endif

  if search('^\(=\{1,'.level.'}\)[^=]\+\1\s*$', 'W')
    call cursor(line('.') - 1, 0)
  else
    call cursor(line('$'), 0)
  endif

  if a:inner && getline(line('.')) =~ '^\s*$'
    let lnum = prevnonblank(line('.') - 1)
    call cursor(lnum, 0)
  endif
endfunction
"}}}

function! vimwiki#count_first_sym(line) "{{{
  let idx = 0
  while a:line[idx] == a:line[0] && idx < len(a:line)
    let idx += 1
  endwhile
  return idx
endfunction "}}}

function! vimwiki#AddHeaderLevel() "{{{
  let lnum = line('.')
  let line = getline(lnum)

  if line =~ '^\s*$'
    return
  endif

  if line !~ '^\(=\+\).\+\1\s*$'
    let line = substitute(line, '^\s*', ' ', '')
    let line = substitute(line, '\s*$', ' ', '')
  endif
  let level = vimwiki#count_first_sym(line)
  if level < 6
    call setline(lnum, '='.line.'=')
  endif
endfunction
"}}}

function! vimwiki#RemoveHeaderLevel() "{{{
  let lnum = line('.')
  let line = getline(lnum)

  if line =~ '^\s*$'
    return
  endif

  if line =~ '^\(=\+\).\+\1\s*$'
    let line = strpart(line, 1, len(line) - 2)
    if line =~ '^\s'
      let line = strpart(line, 1, len(line))
    endif
    if line =~ '\s$'
      let line = strpart(line, 0, len(line) - 1)
    endif
    call setline(lnum, line)
  endif
endfunction
" }}}

" }}}
autoload\vimwiki_html.vim	[[[1
1001
" Vimwiki autoload plugin file
" Export to HTML
" Author: Maxim Kim <habamax@gmail.com>
" Home: http://code.google.com/p/vimwiki/

" Load only once {{{
if exists("g:loaded_vimwiki_html_auto") || &cp
  finish
endif
let g:loaded_vimwiki_html_auto = 1
"}}}

" SCRIPT VARS "{{{
" Warn if html header or html footer do not exist only once.
let s:warn_html_header = 0
let s:warn_html_footer = 0
"}}}

" UTILITY "{{{
function! s:root_path(subdir) "{{{
  return repeat('../', len(split(a:subdir, '[/\\]')))
endfunction "}}}

function! s:syntax_supported() " {{{
  return VimwikiGet('syntax') == "default"
endfunction " }}}

function! s:remove_blank_lines(lines) " {{{
  while a:lines[-1] =~ '^\s*$'
    call remove(a:lines, -1)
  endwhile
endfunction "}}}

function! s:is_web_link(lnk) "{{{
  if a:lnk =~ '^\%(https://\|http://\|www.\|ftp://\)'
    return 1
  endif
  return 0
endfunction "}}}

function! s:is_img_link(lnk) "{{{
  if a:lnk =~ '\.\%(png\|jpg\|gif\|jpeg\)$'
    return 1
  endif
  return 0
endfunction "}}}

function! s:is_non_wiki_link(lnk) "{{{
  " TODO: Add more file extensions here
  if a:lnk =~ '.\+\.\%(pdf\|txt\|doc\|rtf\|xls\)$'
    return 1
  endif
  return 0
endfunction "}}}

function! s:has_abs_path(fname) "{{{
  if a:fname =~ '\(^.:\)\|\(^/\)'
    return 1
  endif
  return 0
endfunction "}}}

function! s:create_default_CSS(path) " {{{
  let path = expand(a:path)
  let css_full_name = path.VimwikiGet('css_name')
  if glob(css_full_name) == ""
    call vimwiki#mkdir(fnamemodify(css_full_name, ':p:h'))
    let lines = []

    call add(lines, 'body {font-family: Arial, sans-serif; margin: 1em 2em 1em 2em; font-size: 100%; line-height: 130%;}')
    call add(lines, 'h1, h2, h3, h4, h5, h6 {font-family: Trebuchet MS, serif; margin-top: 1.5em; margin-bottom: 0.5em;}')
    call add(lines, 'h1 {font-size: 2.0em; color: #3366aa;}')
    call add(lines, 'h2 {font-size: 1.6em; color: #335588;}')
    call add(lines, 'h3 {font-size: 1.2em; color: #224466;}')
    call add(lines, 'h4 {font-size: 1.1em; color: #113344;}')
    call add(lines, 'h5 {font-size: 1.0em; color: #112233;}')
    call add(lines, 'h6 {font-size: 1.0em; color: #111111;}')
    call add(lines, 'p, pre, blockquote, table, ul, ol, dl {margin-top: 1em; margin-bottom: 1em;}')
    call add(lines, 'ul ul, ul ol, ol ol, ol ul {margin-top: 0.5em; margin-bottom: 0.5em;}')
    call add(lines, 'li {margin: 0.3em auto;}')
    call add(lines, 'ul {margin-left: 2em; padding-left: 0.5em;}')
    call add(lines, 'dt {font-weight: bold;}')
    call add(lines, 'img {border: none;}')
    call add(lines, 'pre {border-left: 1px solid #ccc; margin-left: 2em; padding-left: 0.5em;}')
    call add(lines, 'blockquote {padding: 0.4em; background-color: #f6f5eb;}')
    call add(lines, 'td {border: 1px solid #ccc; padding: 0.3em;}')
    call add(lines, 'hr {border: none; border-top: 1px solid #ccc; width: 100%;}')
    call add(lines, '.todo {font-weight: bold; background-color: #f0ece8; color: #a03020;}')
    call add(lines, '.strike {text-decoration: line-through; color: #777777;}')
    call add(lines, '.justleft {text-align: left;}')
    call add(lines, '.justright {text-align: right;}')
    call add(lines, '.justcenter {text-align: center;}')

    call writefile(lines, css_full_name)
    echomsg "Default style.css is created."
  endif
endfunction "}}}

function! s:get_html_header(wikifile, subdir, charset) "{{{
  let lines=[]

  let title = fnamemodify(a:wikifile, ":t:r")

  if VimwikiGet('html_header') != "" && !s:warn_html_header
    try
      let lines = readfile(expand(VimwikiGet('html_header')))
      call map(lines, 'substitute(v:val, "%title%", "'. title .'", "g")')
      call map(lines, 'substitute(v:val, "%root_path%", "'.
            \ s:root_path(a:subdir) .'", "g")')
      return lines
    catch /E484/
      let s:warn_html_header = 1
      call vimwiki#msg("Header template ".VimwikiGet('html_header').
            \ " does not exist!")
    endtry
  endif

  let css_name = expand(VimwikiGet('css_name'))
  let css_name = substitute(css_name, '\', '/', 'g')
  if !s:has_abs_path(css_name)
    " Relative css file for deep links: [[dir1/dir2/dir3/filename]]
    let css_name = s:root_path(a:subdir).css_name
  endif

  " if no VimwikiGet('html_header') set up or error while reading template
  " file -- use default header.
  call add(lines, '<html>')
  call add(lines, '<head>')
  call add(lines, '<link rel="Stylesheet" type="text/css" href="'.
        \ css_name.'" />')
  call add(lines, '<title>'.title.'</title>')
  call add(lines, '<meta http-equiv="Content-Type" content="text/html;'.
        \ ' charset='.a:charset.'" />')
  call add(lines, '</head>')
  call add(lines, '<body>')

  return lines
endfunction "}}}

function! s:get_html_footer() "{{{
  let lines=[]

  if VimwikiGet('html_footer') != "" && !s:warn_html_footer
    try
      let lines = readfile(expand(VimwikiGet('html_footer')))
      return lines
    catch /E484/
      let s:warn_html_footer = 1
      call vimwiki#msg("Footer template ".VimwikiGet('html_footer').
            \ " does not exist!")
    endtry
  endif

  " if no VimwikiGet('html_footer') set up or error while reading template
  " file -- use default footer.
  call add(lines, "")
  call add(lines, '</body>')
  call add(lines, '</html>')

  return lines
endfunction "}}}

function! s:safe_html(line) "{{{
  "" change dangerous html symbols: < > &

  let line = substitute(a:line, '&', '\&amp;', 'g')
  let line = substitute(line, '<', '\&lt;', 'g')
  let line = substitute(line, '>', '\&gt;', 'g')
  return line
endfunction "}}}

function! s:delete_html_files(path) "{{{
  let htmlfiles = split(glob(a:path.'**/*.html'), '\n')
  for fname in htmlfiles
    try
      call delete(fname)
    catch
      vimwiki#msg('Can not delete '.fname)
    endtry
  endfor
endfunction "}}}

function! s:remove_comments(lines) "{{{
  let res = []
  let multiline_comment = 0

  let idx = 0
  while idx < len(a:lines)
    let line = a:lines[idx]
    let idx += 1

    if multiline_comment
      let col = matchend(line, '-->',)
      if col != -1
        let multiline_comment = 0
        let line = strpart(line, col)
      else
        continue
      endif
    endif

    if !multiline_comment && line =~ '<!--.*-->'
      let line = substitute(line, '<!--.*-->', '', 'g')
      if line =~ '^\s*$'
        continue
      endif
    endif

    if !multiline_comment
      let col = match(line, '<!--',)
      if col != -1
        let multiline_comment = 1
        let line = strpart(line, 1, col - 1)
      endif
    endif

    call add(res, line)
  endwhile
  return res
endfunction "}}}

function! s:mid(value, cnt) "{{{
  return strpart(a:value, a:cnt, len(a:value) - 2 * a:cnt)
endfunction "}}}

function! s:subst_func(line, regexp, func) " {{{
  " Substitute text found by regexp with result of
  " func(matched) function.

  let pos = 0
  let lines = split(a:line, a:regexp, 1)
  let res_line = ""
  for line in lines
    let res_line = res_line.line
    let matched = matchstr(a:line, a:regexp, pos)
    if matched != ""
      let res_line = res_line.{a:func}(matched)
    endif
    let pos = matchend(a:line, a:regexp, pos)
  endfor
  return res_line
endfunction " }}}

function! s:save_vimwiki_buffer() "{{{
  if &filetype == 'vimwiki'
    silent update
  endif
endfunction "}}}

"}}}

" INLINE TAGS "{{{
function! s:tag_em(value) "{{{
  return '<em>'.s:mid(a:value, 1).'</em>'
endfunction "}}}

function! s:tag_strong(value) "{{{
  return '<strong>'.s:mid(a:value, 1).'</strong>'
endfunction "}}}

function! s:tag_todo(value) "{{{
  return '<span class="todo">'.a:value.'</span>'
endfunction "}}}

function! s:tag_strike(value) "{{{
  return '<span class="strike">'.s:mid(a:value, 2).'</span>'
endfunction "}}}

function! s:tag_super(value) "{{{
  return '<sup><small>'.s:mid(a:value, 1).'</small></sup>'
endfunction "}}}

function! s:tag_sub(value) "{{{
  return '<sub><small>'.s:mid(a:value, 2).'</small></sub>'
endfunction "}}}

function! s:tag_code(value) "{{{
  return '<code>'.s:mid(a:value, 1).'</code>'
endfunction "}}}

function! s:tag_pre(value) "{{{
  return '<code>'.s:mid(a:value, 3).'</code>'
endfunction "}}}

function! s:tag_external_link(value) "{{{
  "" Make <a href="link">link desc</a>
  "" from [link link desc]

  let value = s:mid(a:value, 1)

  let line = ''
  if s:is_web_link(value)
    let lnkElements = split(value)
    let head = lnkElements[0]
    let rest = join(lnkElements[1:])
    if rest==""
      let rest=head
    endif
    if s:is_img_link(rest)
      if rest!=head
        let line = '<a href="'.head.'"><img src="'.rest.'" /></a>'
      else
        let line = '<img src="'.rest.'" />'
      endif
    else
      let line = '<a href="'.head.'">'.rest.'</a>'
    endif
  elseif s:is_img_link(value)
    let line = '<img src="'.value.'" />'
  else
    " [alskfj sfsf] shouldn't be a link. So return it as it was --
    " enclosed in [...]
    let line = '['.value.']'
  endif
  return line
endfunction "}}}

function! s:tag_internal_link(value) "{{{
  " Make <a href="This is a link">This is a link</a>
  " from [[This is a link]]
  " Make <a href="link">This is a link</a>
  " from [[link|This is a link]]
  " Make <a href="link">This is a link</a>
  " from [[link][This is a link]]
  " TODO: rename function -- it makes not only internal links.
  " TODO: refactor it.

  let value = s:mid(a:value, 2)

  let line = ''
  if value =~ '|'
    let link_parts = split(value, "|", 1)
  else
    let link_parts = split(value, "][", 1)
  endif

  if len(link_parts) > 1
    if len(link_parts) < 3
      let style = ""
    else
      let style = link_parts[2]
    endif

    if s:is_img_link(link_parts[1])
      let line = '<a href="'.link_parts[0].'"><img src="'.link_parts[1].
            \ '" style="'.style.'" /></a>'
    elseif len(link_parts) < 3
      if s:is_non_wiki_link(link_parts[0])
        let line = '<a href="'.link_parts[0].'">'.link_parts[1].'</a>'
      else
        let line = '<a href="'.vimwiki#safe_link(link_parts[0]).
              \ '.html">'.link_parts[1].'</a>'
      endif
    elseif s:is_img_link(link_parts[0])
      let line = '<img src="'.link_parts[0].'" alt="'.
            \ link_parts[1].'" style="'.style.'" />'
    endif
  else
    if s:is_img_link(value)
      let line = '<img src="'.value.'" />'
    elseif s:is_non_wiki_link(link_parts[0])
      let line = '<a href="'.value.'">'.value.'</a>'
    else
      let line = '<a href="'.vimwiki#safe_link(value).
            \ '.html">'.value.'</a>'
    endif
  endif
  return line
endfunction "}}}

function! s:tag_wikiword_link(value) "{{{
  " Make <a href="WikiWord">WikiWord</a> from WikiWord
  " if first symbol is ! then remove it and make no link.
  if a:value[0] == '!'
    return a:value[1:]
  else
    let line = '<a href="'.a:value.'.html">'.a:value.'</a>'
    return line
  endif
endfunction "}}}

function! s:tag_barebone_link(value) "{{{
  "" Make <a href="http://habamax.ru">http://habamax.ru</a>
  "" from http://habamax.ru

  if s:is_img_link(a:value)
    let line = '<img src="'.a:value.'" />'
  else
    let line = '<a href="'.a:value.'">'.a:value.'</a>'
  endif
  return line
endfunction "}}}

function! s:make_tag(line, regexp, func) "{{{
  " Make tags for a given matched regexp.
  " Exclude preformatted text and href links.

  let patt_splitter = '\(`[^`]\+`\)\|\({{{.\+}}}\)\|'.
        \ '\(<a href.\{-}</a>\)\|\(<img src.\{-}/>\)'
  if '`[^`]\+`' == a:regexp || '{{{.\+}}}' == a:regexp
    let res_line = s:subst_func(a:line, a:regexp, a:func)
  else
    let pos = 0
    " split line with patt_splitter to have parts of line before and after
    " href links, preformatted text
    " ie:
    " hello world `is just a` simple <a href="link.html">type of</a> prg.
    " result:
    " ['hello world ', ' simple ', 'type of', ' prg']
    let lines = split(a:line, patt_splitter, 1)
    let res_line = ""
    for line in lines
      let res_line = res_line.s:subst_func(line, a:regexp, a:func)
      let res_line = res_line.matchstr(a:line, patt_splitter, pos)
      let pos = matchend(a:line, patt_splitter, pos)
    endfor
  endif
  return res_line
endfunction "}}}

function! s:process_inline_tags(line) "{{{
  let line = a:line
  let line = s:make_tag(line, '\[\[.\{-}\]\]', 's:tag_internal_link')
  let line = s:make_tag(line, '\[.\{-}\]', 's:tag_external_link')
  let line = s:make_tag(line, g:vimwiki_rxWeblink, 's:tag_barebone_link')
  let line = s:make_tag(line, '!\?'.g:vimwiki_rxWikiWord,
        \ 's:tag_wikiword_link')
  let line = s:make_tag(line, g:vimwiki_rxItalic, 's:tag_em')
  let line = s:make_tag(line, g:vimwiki_rxBold, 's:tag_strong')
  let line = s:make_tag(line, g:vimwiki_rxTodo, 's:tag_todo')
  let line = s:make_tag(line, g:vimwiki_rxDelText, 's:tag_strike')
  let line = s:make_tag(line, g:vimwiki_rxSuperScript, 's:tag_super')
  let line = s:make_tag(line, g:vimwiki_rxSubScript, 's:tag_sub')
  let line = s:make_tag(line, g:vimwiki_rxCode, 's:tag_code')
  let line = s:make_tag(line, g:vimwiki_rxPreStart.'.\+'.g:vimwiki_rxPreEnd,
        \ 's:tag_pre')
  return line
endfunction " }}}
"}}}

" BLOCK TAGS {{{
function! s:close_tag_pre(pre, ldest) "{{{
  if a:pre
    call insert(a:ldest, "</pre></code>")
    return 0
  endif
  return a:pre
endfunction "}}}

function! s:close_tag_quote(quote, ldest) "{{{
  if a:quote
    call insert(a:ldest, "</blockquote>")
    return 0
  endif
  return a:quote
endfunction "}}}

function! s:close_tag_para(para, ldest) "{{{
  if a:para
    call insert(a:ldest, "</p>")
    return 0
  endif
  return a:para
endfunction "}}}

function! s:close_tag_table(table, ldest) "{{{
  if a:table
    call insert(a:ldest, "</table>")
    return 0
  endif
  return a:table
endfunction "}}}

function! s:close_tag_list(lists, ldest) "{{{
  while len(a:lists)
    let item = remove(a:lists, -1)
    call insert(a:ldest, item[0])
  endwhile
endfunction! "}}}

function! s:close_tag_def_list(deflist, ldest) "{{{
  if a:deflist
    call insert(a:ldest, "</dl>")
    return 0
  endif
  return a:deflist
endfunction! "}}}

function! s:process_tag_pre(line, pre) "{{{
  let lines = []
  let pre = a:pre
  let processed = 0
  if !pre && a:line =~ '{{{[^\(}}}\)]*\s*$'
    let class = matchstr(a:line, '{{{\zs.*$')
    let class = substitute(class, '\s\+$', '', 'g')
    if class != ""
      call add(lines, "<pre ".class.">")
    else
      call add(lines, "<pre>")
    endif
    let pre = 1
    let processed = 1
  elseif pre && a:line =~ '^}}}\s*$'
    let pre = 0
    call add(lines, "</pre>")
    let processed = 1
  elseif pre
    let processed = 1
    call add(lines, a:line)
  endif
  return [processed, lines, pre]
endfunction "}}}

function! s:process_tag_quote(line, quote) "{{{
  let lines = []
  let quote = a:quote
  let processed = 0
  if a:line =~ '^\s\{4,}[^[:blank:]*#]'
    if !quote
      call add(lines, "<blockquote>")
      let quote = 1
    endif
    let processed = 1
    call add(lines, substitute(a:line, '^\s*', '', ''))
  elseif quote && a:line =~ '^\s*$'
    let processed = 1
    call add(lines, a:line)
  elseif quote
    call add(lines, "</blockquote>")
    let quote = 0
  endif
  return [processed, lines, quote]
endfunction "}}}

function! s:process_tag_list(line, lists) "{{{

  function! s:add_strike(line, st_tag, en_tag) "{{{
    let st_tag = a:st_tag
    let en_tag = a:en_tag
    " apply strikethrough for checked list items
    if a:line =~ '^\s\+\%(\*\|#\)\s*\['.g:vimwiki_listsyms[4].']'
      let st_tag = a:st_tag.'<span class="strike">'
      let en_tag = '</span>'.a:en_tag
    endif
    return [st_tag, en_tag]
  endfunction "}}}

  function! s:add_checkbox(line, rx_list, st_tag, en_tag) "{{{
    let st_tag = a:st_tag
    let en_tag = a:en_tag

    let chk = matchlist(a:line, a:rx_list)
    if len(chk) > 0
      if chk[1] == g:vimwiki_listsyms[4]
        let st_tag .= '<input type="checkbox" checked />'
      else
        let st_tag .= '<input type="checkbox" />'
      endif
    endif
    return [st_tag, en_tag]
  endfunction "}}}

  let lines = []
  let processed = 0

  if a:line =~ '^\s\+\*'
    let lstSym = '*'
    let lstTagOpen = '<ul>'
    let lstTagClose = '</ul>'
    let lstRegExp = '^\s\+\*\s*'
  elseif a:line =~ '^\s\+#'
    let lstSym = '#'
    let lstTagOpen = '<ol>'
    let lstTagClose = '</ol>'
    let lstRegExp = '^\s\+#\s*'
  else
    let lstSym = ''
    let lstTagOpen = ''
    let lstTagClose = ''
    let lstRegExp = ''
  endif

  let in_list = (len(a:lists) > 0)
  if lstSym != ''
    " To get proper indent level 'retab' the line -- change all tabs
    " to spaces*tabstop
    let line = substitute(a:line, '\t', repeat(' ', &tabstop), 'g')
    let indent = stridx(line, lstSym)

    let checkbox = '\s*\[\(.\?\)]\s*'
    let [st_tag, en_tag] = s:add_strike(line, '<li>', '</li>')
    let [st_tag, en_tag] = s:add_checkbox(line,
          \ lstRegExp.checkbox, st_tag, en_tag)

    if !in_list
      call add(a:lists, [lstTagClose, indent])
      call add(lines, lstTagOpen)
    elseif (in_list && indent > a:lists[-1][1])
      let item = remove(a:lists, -1)
      call add(lines, item[0])

      call add(a:lists, [lstTagClose, indent])
      call add(lines, lstTagOpen)
    elseif (in_list && indent < a:lists[-1][1])
      while len(a:lists) && indent < a:lists[-1][1]
        let item = remove(a:lists, -1)
        call add(lines, item[0])
      endwhile
    elseif in_list
      let item = remove(a:lists, -1)
      call add(lines, item[0])
    endif

    call add(a:lists, [en_tag, indent])
    call add(lines, st_tag)
    call add(lines,
          \ substitute(a:line, lstRegExp.'\%('.checkbox.'\)\?', '', ''))
    let processed = 1
  elseif in_list > 0 && a:line =~ '^\s\+\S\+'
    if g:vimwiki_list_ignore_newline
      call add(lines, a:line)
    else
      call add(lines, '<br />'.a:line)
    endif
    let processed = 1
  else
    while len(a:lists)
      let item = remove(a:lists, -1)
      call add(lines, item[0])
    endwhile
  endif
  return [processed, lines]
endfunction "}}}

function! s:process_tag_def_list(line, deflist) "{{{
  let lines = []
  let deflist = a:deflist
  let processed = 0
  let matches = matchlist(a:line, '\(^.*\)::\%(\s\|$\)\(.*\)')
  if !deflist && len(matches) > 0
    call add(lines, "<dl>")
    let deflist = 1
  endif
  if deflist && len(matches) > 0
    if matches[1] != ''
      call add(lines, "<dt>".matches[1]."</dt>")
    endif
    if matches[2] != ''
      call add(lines, "<dd>".matches[2]."</dd>")
    endif
    let processed = 1
  elseif deflist
    let deflist = 0
    call add(lines, "</dl>")
  endif
  return [processed, lines, deflist]
endfunction "}}}

function! s:process_tag_para(line, para) "{{{
  let lines = []
  let para = a:para
  let processed = 0
  if a:line =~ '^\S'
    if !para
      call add(lines, "<p>")
      let para = 1
    endif
    let processed = 1
    call add(lines, a:line)
  elseif para && a:line =~ '^\s*$'
    call add(lines, "</p>")
    let para = 0
  endif
  return [processed, lines, para]
endfunction "}}}

function! s:process_tag_h(line) "{{{
  let line = a:line
  let processed = 0
  let h_level = 0
  if a:line =~ g:vimwiki_rxH6
    let h_level = 6
  elseif a:line =~ g:vimwiki_rxH5
    let h_level = 5
  elseif a:line =~ g:vimwiki_rxH4
    let h_level = 4
  elseif a:line =~ g:vimwiki_rxH3
    let h_level = 3
  elseif a:line =~ g:vimwiki_rxH2
    let h_level = 2
  elseif a:line =~ g:vimwiki_rxH1
    let h_level = 1
  endif
  if h_level > 0
    " rtrim
    let line = substitute(a:line, '\s\+$', '', 'g')
    let line = '<h'.h_level.'>'.
          \ strpart(line, h_level, len(line) - h_level * 2).
          \'</h'.h_level.'>'
    let processed = 1
  endif
  return [processed, line]
endfunction "}}}

function! s:process_tag_hr(line) "{{{
  let line = a:line
  let processed = 0
  if a:line =~ '^-----*$'
    let line = '<hr />'
    let processed = 1
  endif
  return [processed, line]
endfunction "}}}

function! s:process_tag_table(line, table) "{{{
  let table = a:table
  let lines = []
  let processed = 0
  if a:line =~ '^||.\+||.*'
    if !table
      call add(lines, "<table>")
      let table = 1
    endif
    let processed = 1

    call add(lines, "<tr>")
    let pos1 = 0
    let pos2 = 0
    let done = 0
    while !done
      let pos1 = stridx(a:line, '||', pos2)
      let pos2 = stridx(a:line, '||', pos1+2)
      if pos1==-1 || pos2==-1
        let done = 1
        let pos2 = len(a:line)
      endif
      let line = strpart(a:line, pos1+2, pos2-pos1-2)
      if line == ''
        continue
      endif
      if strpart(line, 0, 1) == ' ' &&
            \ strpart(line, len(line) - 1, 1) == ' '
        call add(lines, '<td class="justcenter">'.line.'</td>')
      elseif strpart(line, 0, 1) == ' '
        call add(lines, '<td class="justright">'.line.'</td>')
      else
        call add(lines, '<td class="justleft">'.line.'</td>')
      endif
    endwhile
    call add(lines, "</tr>")

  elseif table
    call add(lines, "</table>")
    let table = 0
  endif
  return [processed, lines, table]
endfunction "}}}

"}}}

" WIKI2HTML "{{{
function! s:wiki2html(line, state) " {{{
  let state = {}
  let state.para = a:state.para
  let state.quote = a:state.quote
  let state.pre = a:state.pre
  let state.table = a:state.table
  let state.lists = a:state.lists[:]
  let state.deflist = a:state.deflist

  let res_lines = []

  let line = s:safe_html(a:line)

  let processed = 0
  "" pre
  if !processed
    let [processed, lines, state.pre] = s:process_tag_pre(line, state.pre)
    if processed && len(state.lists)
      call s:close_tag_list(state.lists, lines)
    endif
    if processed && state.table
      let state.table = s:close_tag_table(state.table, lines)
    endif
    if processed && state.deflist
      let state.deflist = s:close_tag_def_list(state.deflist, lines)
    endif
    if processed && state.quote
      let state.quote = s:close_tag_quote(state.quote, lines)
    endif
    if processed && state.para
      let state.para = s:close_tag_para(state.para, lines)
    endif
    call extend(res_lines, lines)
  endif

  "" list
  if !processed
    let [processed, lines] = s:process_tag_list(line, state.lists)
    if processed && state.quote
      let state.quote = s:close_tag_quote(state.quote, lines)
    endif
    if processed && state.pre
      let state.pre = s:close_tag_pre(state.pre, lines)
    endif
    if processed && state.table
      let state.table = s:close_tag_table(state.table, lines)
    endif
    if processed && state.deflist
      let state.deflist = s:close_tag_def_list(state.deflist, lines)
    endif
    if processed && state.para
      let state.para = s:close_tag_para(state.para, lines)
    endif

    call map(lines, 's:process_inline_tags(v:val)')

    call extend(res_lines, lines)
  endif

  "" quote
  if !processed
    let [processed, lines, state.quote] = s:process_tag_quote(line, state.quote)
    if processed && len(state.lists)
      call s:close_tag_list(state.lists, lines)
    endif
    if processed && state.deflist
      let state.deflist = s:close_tag_def_list(state.deflist, lines)
    endif
    if processed && state.table
      let state.table = s:close_tag_table(state.table, lines)
    endif
    if processed && state.pre
      let state.pre = s:close_tag_pre(state.pre, lines)
    endif
    if processed && state.para
      let state.para = s:close_tag_para(state.para, lines)
    endif

    call extend(res_lines, lines)
  endif

  "" definition lists
  if !processed
    let [processed, lines, state.deflist] = s:process_tag_def_list(line, state.deflist)

    call map(lines, 's:process_inline_tags(v:val)')

    call extend(res_lines, lines)
  endif

  "" table
  if !processed
    let [processed, lines, state.table] = s:process_tag_table(line, state.table)

    call map(lines, 's:process_inline_tags(v:val)')

    call extend(res_lines, lines)
  endif

  if !processed
    let [processed, line] = s:process_tag_h(line)
    if processed
      call s:close_tag_list(state.lists, res_lines)
      let state.table = s:close_tag_table(state.table, res_lines)
      let state.pre = s:close_tag_pre(state.pre, res_lines)
      call add(res_lines, line)
    endif
  endif

  if !processed
    let [processed, line] = s:process_tag_hr(line)
    if processed
      call s:close_tag_list(state.lists, res_lines)
      let state.table = s:close_tag_table(state.table, res_lines)
      let state.pre = s:close_tag_pre(state.pre, res_lines)
      call add(res_lines, line)
    endif
  endif

  "" P
  if !processed
    let [processed, lines, state.para] = s:process_tag_para(line, state.para)
    if processed && len(state.lists)
      call s:close_tag_list(state.lists, lines)
    endif
    if processed && state.quote
      let state.quote = s:close_tag_quote(state.quote, res_lines)
    endif
    if processed && state.pre
      let state.pre = s:close_tag_pre(state.pre, res_lines)
    endif
    if processed && state.table
      let state.table = s:close_tag_table(state.table, res_lines)
    endif

    call map(lines, 's:process_inline_tags(v:val)')

    call extend(res_lines, lines)
  endif

  "" add the rest
  if !processed
    call add(res_lines, line)
  endif

  return [res_lines, state]

endfunction " }}}

function! vimwiki_html#Wiki2HTML(path, wikifile) "{{{

  if !s:syntax_supported()
    call vimwiki#msg('Only vimwiki_default syntax supported!!!')
    return
  endif

  let wikifile = fnamemodify(a:wikifile, ":p")
  let subdir = vimwiki#subdir(VimwikiGet('path'), wikifile)

  let path = expand(a:path).subdir
  call vimwiki#mkdir(path)

  let lsource = s:remove_comments(readfile(wikifile))
  let ldest = s:get_html_header(wikifile, subdir, &fileencoding)


  let state = {}
  let state.para = 0
  let state.quote = 0
  let state.pre = 0
  let state.table = 0
  let state.deflist = 0
  let state.lists = []

  for line in lsource
    let oldquote = state.quote
    let [lines, state] = s:wiki2html(line, state)

    " Hack: There could be a lot of empty strings before s:process_tag_quote
    " find out `quote` is over. So we should delete them all. Think of the way
    " to refactor it out.
    if (oldquote != state.quote) && ldest[-1] =~ '^\s*$'
      call s:remove_blank_lines(ldest)
    endif

    call extend(ldest, lines)
  endfor

  call s:remove_blank_lines(ldest)

  "" process end of file
  "" close opened tags if any
  let lines = []
  call s:close_tag_quote(state.quote, lines)
  call s:close_tag_para(state.para, lines)
  call s:close_tag_pre(state.pre, lines)
  call s:close_tag_list(state.lists, lines)
  call s:close_tag_def_list(state.deflist, lines)
  call s:close_tag_table(state.table, lines)
  call extend(ldest, lines)

  call extend(ldest, s:get_html_footer())

  "" make html file.
  let wwFileNameOnly = fnamemodify(wikifile, ":t:r")
  call writefile(ldest, path.wwFileNameOnly.'.html')
endfunction "}}}

function! vimwiki_html#WikiAll2HTML(path) "{{{
  if !s:syntax_supported()
    call vimwiki#msg('Only vimwiki_default syntax supported!!!')
    return
  endif

  echomsg 'Saving vimwiki files...'
  let cur_buf = bufname('%')
  bufdo call s:save_vimwiki_buffer()
  exe 'buffer '.cur_buf

  let path = expand(a:path)
  call vimwiki#mkdir(path)

  echomsg 'Deleting old html files...'
  call s:delete_html_files(path)

  echomsg 'Converting wiki to html files...'
  let setting_more = &more
  setlocal nomore

  let wikifiles = split(glob(VimwikiGet('path').'**/*'.VimwikiGet('ext')), '\n')
  for wikifile in wikifiles
    echomsg 'Processing '.wikifile
    call vimwiki_html#Wiki2HTML(path, wikifile)
  endfor
  call s:create_default_CSS(path)
  echomsg 'Done!'

  let &more = setting_more
endfunction "}}}
"}}}
autoload\vimwiki_lst.vim	[[[1
320
" Vimwiki autoload plugin file
" Todo lists related stuff here.
" Author: Maxim Kim <habamax@gmail.com>
" Home: http://code.google.com/p/vimwiki/

if exists("g:loaded_vimwiki_list_auto") || &cp
  finish
endif
let g:loaded_vimwiki_lst_auto = 1

" Script variables {{{
let s:rx_li_box = '\[.\?\]'
" }}}

" Script functions {{{

" Get checkbox regexp
function! s:rx_li_symbol(rate) "{{{
  let result = ''
  if a:rate == 100
    let result = g:vimwiki_listsyms[4]
  elseif a:rate == 0
    let result = g:vimwiki_listsyms[0]
  elseif a:rate >= 67
    let result = g:vimwiki_listsyms[3]
  elseif a:rate >= 34
    let result = g:vimwiki_listsyms[2]
  else
    let result = g:vimwiki_listsyms[1]
  endif

  return '\['.result.'\]'
endfunction "}}}

" Get regexp of the list item.
function! s:rx_list_item() "{{{
  return '\('.g:vimwiki_rxListBullet.'\|'.g:vimwiki_rxListNumber.'\)'
endfunction "}}}

" Get regexp of the list item with checkbox.
function! s:rx_cb_list_item() "{{{
  return s:rx_list_item().'\s*\zs\[.\?\]'
endfunction "}}}

" Get level of the list item.
function! s:get_level(lnum) "{{{
  if VimwikiGet('syntax') == 'media'
    let level = vimwiki#count_first_sym(getline(a:lnum))
  else
    let level = indent(a:lnum)
  endif
  return level
endfunction "}}}

" Get previous list item.
" Returns: line number or 0.
function! s:prev_list_item(lnum) "{{{
  let c_lnum = a:lnum - 1
  while c_lnum >= 1
    let line = getline(c_lnum)
    if line =~ s:rx_list_item()
      return c_lnum
    endif
    if line =~ '^\s*$'
      return 0
    endif
    let c_lnum -= 1
  endwhile
  return 0
endfunction "}}}

" Get next list item in the list.
" Returns: line number or 0.
function! s:next_list_item(lnum) "{{{
  let c_lnum = a:lnum + 1
  while c_lnum <= line('$')
    let line = getline(c_lnum)
    if line =~ s:rx_list_item()
      return c_lnum
    endif
    if line =~ '^\s*$'
      return 0
    endif
    let c_lnum += 1
  endwhile
  return 0
endfunction "}}}

" Find next list item in the buffer.
" Returns: line number or 0.
function! s:find_next_list_item(lnum) "{{{
  let c_lnum = a:lnum + 1
  while c_lnum <= line('$')
    let line = getline(c_lnum)
    if line =~ s:rx_list_item()
      return c_lnum
    endif
    let c_lnum += 1
  endwhile
  return 0
endfunction "}}}

" Set state of the list item on line number "lnum" to [ ] or [x]
function! s:set_state(lnum, rate) "{{{
  let line = getline(a:lnum)
  let state = s:rx_li_symbol(a:rate)
  let line = substitute(line, s:rx_li_box, state, '')
  call setline(a:lnum, line)
endfunction "}}}

" Get state of the list item on line number "lnum"
function! s:get_state(lnum) "{{{
  let state = 0
  let line = getline(a:lnum)
  let opt = matchstr(line, s:rx_cb_list_item())
  if opt =~ s:rx_li_symbol(100)
    let state = 100
  elseif opt =~ s:rx_li_symbol(0)
    let state = 0
  elseif opt =~ s:rx_li_symbol(25)
    let state = 25
  elseif opt =~ s:rx_li_symbol(50)
    let state = 50
  elseif opt =~ s:rx_li_symbol(75)
    let state = 75
  endif
  return state
endfunction "}}}

" Returns 1 if there is checkbox on a list item, 0 otherwise.
function! s:is_cb_list_item(lnum) "{{{
  return getline(a:lnum) =~ s:rx_cb_list_item()
endfunction "}}}

" Returns start line number of list item, 0 if it is not a list.
function! s:is_list_item(lnum) "{{{
  let c_lnum = a:lnum
  while c_lnum >= 1
    let line = getline(c_lnum)
    if line =~ s:rx_list_item()
      return c_lnum
    endif
    if line =~ '^\s*$'
      return 0
    endif
    if indent(c_lnum) > indent(a:lnum)
      return 0
    endif
    let c_lnum -= 1
  endwhile
  return 0
endfunction "}}}

" Returns char column of checkbox. Used in parent/child checks.
function! s:get_li_pos(lnum) "{{{
  return stridx(getline(a:lnum), '[')
endfunction "}}}

" Returns list of line numbers of parent and all its child items.
function! s:get_child_items(lnum) "{{{
  let result = []
  let lnum = a:lnum
  let p_pos = s:get_level(lnum)

  " add parent
  call add(result, lnum)

  let lnum = s:next_list_item(lnum)
  while lnum != 0 && s:is_list_item(lnum) && s:get_level(lnum) > p_pos
    call add(result, lnum)
    let lnum = s:next_list_item(lnum)
  endwhile

  return result
endfunction "}}}

" Returns list of line numbers of all items of the same level.
function! s:get_sibling_items(lnum) "{{{
  let result = []
  let lnum = a:lnum
  let ind = s:get_level(lnum)

  while s:get_level(lnum) >= ind &&
        \ lnum != 0

    if s:get_level(lnum) == ind && s:is_cb_list_item(lnum)
      call add(result, lnum)
    endif
    let lnum = s:next_list_item(lnum)
  endwhile

  let lnum = s:prev_list_item(a:lnum)
  while s:get_level(lnum) >= ind &&
        \ lnum != 0

    if s:get_level(lnum) == ind && s:is_cb_list_item(lnum)
      call add(result, lnum)
    endif
    let lnum = s:prev_list_item(lnum)
  endwhile

  return result
endfunction "}}}

" Returns line number of the parent of lnum item
function! s:get_parent_item(lnum) "{{{
  let lnum = a:lnum
  let ind = s:get_level(lnum)

  let lnum = s:prev_list_item(lnum)
  while lnum != 0 && s:is_list_item(lnum) && s:get_level(lnum) >= ind
    let lnum = s:prev_list_item(lnum)
  endwhile

  if s:is_cb_list_item(lnum)
    return lnum
  else
    return a:lnum
  endif
endfunction "}}}

" Creates checkbox in a list item.
function! s:create_cb_list_item(lnum) "{{{
  let line = getline(a:lnum)
  let m = matchstr(line, s:rx_list_item())
  if m != ''
    let line = m.' [ ]'.strpart(line, len(m))
    call setline(a:lnum, line)
  endif
endfunction "}}}

" Tells if all of the sibling list items are checked or not.
function! s:all_siblings_checked(lnum) "{{{
  let result = 0
  let cnt = 0
  let siblings = s:get_sibling_items(a:lnum)
  for lnum in siblings
    let cnt += s:get_state(lnum)/100.0
  endfor
  let result = (cnt*100.0)/len(siblings)
  return result
endfunction "}}}

" Creates checkbox on a list item if there is no one.
function! s:TLI_create_checkbox(lnum) "{{{
  if a:lnum && !s:is_cb_list_item(a:lnum)
    if g:vimwiki_auto_checkbox
      call s:create_cb_list_item(a:lnum)
    endif
    return 1
  endif
  return 0
endfunction "}}}

" Switch state of the child list items.
function! s:TLI_switch_child_state(lnum) "{{{
  let current_state = s:get_state(a:lnum)
  if current_state == 100
    let new_state = 0
  else
    let new_state = 100
  endif
  for lnum in s:get_child_items(a:lnum)
    call s:set_state(lnum, new_state)
  endfor
endfunction "}}}

" Switch state of the parent list items.
function! s:TLI_switch_parent_state(lnum) "{{{
  let c_lnum = a:lnum
  while s:is_cb_list_item(c_lnum)
    let parent_lnum = s:get_parent_item(c_lnum)
    if parent_lnum == c_lnum
      break
    endif
    call s:set_state(parent_lnum, s:all_siblings_checked(c_lnum))

    let c_lnum = parent_lnum
  endwhile
endfunction "}}}

function! s:TLI_toggle(lnum) "{{{
  if !s:TLI_create_checkbox(a:lnum)
    call s:TLI_switch_child_state(a:lnum)
  endif
  call s:TLI_switch_parent_state(a:lnum)
endfunction "}}}

" Script functions }}}

" Toggle list item between [ ] and [x]
function! vimwiki_lst#ToggleListItem(line1, line2) "{{{
  let line1 = a:line1
  let line2 = a:line2

  if line1 != line2 && !s:is_list_item(line1)
    let line1 = s:find_next_list_item(line1)
  endif

  let c_lnum = line1
  while c_lnum != 0 && c_lnum <= line2
    let li_lnum = s:is_list_item(c_lnum)

    if li_lnum
      let li_level = s:get_level(li_lnum)
      if c_lnum == line1
        let start_li_level = li_level
      endif

      if li_level <= start_li_level
        call s:TLI_toggle(li_lnum)
        let start_li_level = li_level
      endif
    endif

    let c_lnum = s:find_next_list_item(c_lnum)
  endwhile

endfunction "}}}

doc\vimwiki.txt	[[[1
1443
*vimwiki.txt*  A Personal Wiki for Vim

     __  __  ______            __      __  ______   __  __   ______     ~
    /\ \/\ \/\__  _\   /'\_/`\/\ \  __/\ \/\__  _\ /\ \/\ \ /\__  _\    ~
    \ \ \ \ \/_/\ \/  /\      \ \ \/\ \ \ \/_/\ \/ \ \ \/'/'\/_/\ \/    ~
     \ \ \ \ \ \ \ \  \ \ \__\ \ \ \ \ \ \ \ \ \ \  \ \ , <    \ \ \    ~
      \ \ \_/ \ \_\ \__\ \ \_/\ \ \ \_/ \_\ \ \_\ \__\ \ \\`\   \_\ \__ ~
       \ `\___/ /\_____\\ \_\\ \_\ `\___x___/ /\_____\\ \_\ \_\ /\_____\~
        `\/__/  \/_____/ \/_/ \/_/'\/__//__/  \/_____/ \/_/\/_/ \/_____/~

                               Version: 0.9.701 ~

==============================================================================
CONTENTS                                                    *vimwiki-contents*

  1. Intro ...................................|vimwiki|
  2. Prerequisites ...........................|vimwiki-prerequisites|
  3. Mappings ................................|vimwiki-mappings|
    3.1. Global mappings .....................|vimwiki-global-mappings|
    3.2. Local mappings ......................|vimwiki-local-mappings|
    3.3. Text objects ........................|vimwiki-text-objects|
  4. Commands ................................|vimwiki-commands|
    4.1. Global commands .....................|vimwiki-global-commands|
    4.2. Local commands ......................|vimwiki-local-commands|
  5. Wiki syntax .............................|vimwiki-syntax|
    5.1. Typefaces ...........................|vimwiki-syntax-typefaces|
    5.2. Links ...............................|vimwiki-syntax-links|
    5.3. Headers .............................|vimwiki-syntax-headers|
    5.4. Paragraphs...........................|vimwiki-syntax-paragraphs|
    5.5. Lists ...............................|vimwiki-syntax-lists|
    5.6. Tables ..............................|vimwiki-syntax-tables|
    5.7. Preformatted text ...................|vimwiki-syntax-preformatted|
    5.8. Blockquotes .........................|vimwiki-syntax-blockquotes|
    5.9. Comments ............................|vimwiki-syntax-comments|
  6. Folding/Outline .........................|vimwiki-folding|
  7. Todo lists...............................|vimwiki-todo-lists|
  8. Options .................................|vimwiki-options|
  9. Help ....................................|vimwiki-help|
  10. Author .................................|vimwiki-author|
  11. Changelog ..............................|vimwiki-changelog|
  12. License ................................|vimwiki-license|


==============================================================================
1. Intro                                                             *vimwiki*

Vimwiki is a personal wiki for Vim. Using it you can organize text files with
hyperlinks. To do a quick start press <Leader>ww (this is usually \ww) to go
to your index wiki file. By default it is located in: >
  ~/vimwiki/index.wiki
You do not have to create it manually -- vimwiki can make it for you.

Feed it with the following example:
= My knowledge base =
  * MyUrgentTasks -- things to be done _yesterday_!!!
  * ProjectGutenberg -- good books are power.
  * MusicILike, MusicIHate.

Notice that ProjectGutenberg, MyUrgentTasks, MusicILike and MusicIHate
highlighted as errors. These WikiWords (WikiWord or WikiPage -- capitalized
word connected with other capitalized words) do not exist yet.

Place cursor on ProjectGutenberg and press Enter. Now you are in
ProjectGutenberg. Edit and save it, then press Backspace to return to previous
WikiPage. You should see the difference in highlighting now.

Now it is your turn...

==============================================================================
2. Prerequisites                                       *vimwiki-prerequisites*

Make sure you have these settings in your vimrc file: >
    set nocompatible
    filetype plugin on
    syntax on

Without them Vimwiki will not work properly.


==============================================================================
3. Mappings                                                 *vimwiki-mappings*

There are global and local mappings in vimwiki.

------------------------------------------------------------------------------
3.1. Global mappings                                 *vimwiki-global-mappings*

<Leader>ww or <Plug>VimwikiGoHome
        Open index file of the [count]'s wiki.
        <Leader>ww opens first wiki from |g:vimwiki_list|.
        1<Leader>ww as above opens first wiki from |g:vimwiki_list|.
        2<Leader>ww opens second wiki from |g:vimwiki_list|.
        3<Leader>ww opens third wiki from |g:vimwiki_list|.
        etc.
        To remap: >
        :map <Leader>w <Plug>VimwikiGoHome
<
See also|:VimwikiGoHome|

<Leader>wt or <Plug>VimwikiTabGoHome
        Open index file of the [count]'s wiki in a new tab.
        <Leader>ww tabopens first wiki from |g:vimwiki_list|.
        1<Leader>ww as above tabopens first wiki from |g:vimwiki_list|.
        2<Leader>ww tabopens second wiki from |g:vimwiki_list|.
        3<Leader>ww tabopens third wiki from |g:vimwiki_list|.
        etc.
        To remap: >
        :map <Leader>t <Plug>VimwikiTabGoHome
<
See also|:VimwikiTabGoHome|

<Leader>ws or <Plug>VimwikiUISelect
        List and select available wikies.
        To remap: >
        :map <Leader>wq <Plug>VimwikiUISelect
<
See also|:VimwikiUISelect|


------------------------------------------------------------------------------
3.2. Local mappings                                   *vimwiki-local-mappings*

Normal mode (Keyboard):~
                        *vimwiki_<CR>*
<CR>                    Follow/Create WikiWord.
                        Maps to|:VimwikiFollowWord|.
                        To remap: >
                        :map <Leader>wf <Plug>VimwikiFollowWord
<
                        *vimwiki_<S-CR>*
<S-CR>                  Split and follow/create WikiWord
                        Maps to|:VimwikiSplitWord|.
                        To remap: >
                        :map <Leader>we <Plug>VimwikiSplitWord
<
                        *vimwiki_<C-CR>*
<C-CR>                  Vertical split and follow/create WikiWord
                        Maps to|:VimwikiVSplitWord|.
                        To remap: >
                        :map <Leader>wq <Plug>VimwikiVSplitWord
<
                        *vimwiki_<Backspace>*
<Backspace>             Go back to previous WikiWord
                        Maps to|:VimwikiGoBackWord|.
                        To remap: >
                        :map <Leader>wb <Plug>VimwikiGoBackWord
<
                        *vimwiki_<Tab>*
<Tab>                   Find next WikiWord
                        Maps to|:VimwikiNextWord|.
                        To remap: >
                        :map <Leader>wn <Plug>VimwikiNextWord
<
                        *vimwiki_<S-Tab>*
<S-Tab>                 Find previous WikiWord
                        Maps to|:VimwikiPrevWord|.
                        To remap: >
                        :map <Leader>wp <Plug>VimwikiPrevWord
<
                        *vimwiki_<Leader>wd*
<Leader>wd              Delete WikiWord you are in.
                        Maps to|:VimwikiDeleteWord|.
                        To remap: >
                        :map <Leader>dd <Plug>VimwikiDeleteWord
<
                        *vimwiki_<Leader>wr*
<Leader>wr              Rename WikiWord you are in.
                        Maps to|:VimwikiRenameWord|.
                        To remap: >
                        :map <Leader>rr <Plug>VimwikiRenameWord
<
                        *vimwiki_<C-Space>*
<C-Space>               Toggle list item on/off (checked/unchecked)
                        Maps to|:VimwikiToggleListItem|.
                        To remap: >
                        :map <leader>tt <Plug>VimwikiToggleListItem
<                       See |vimwiki-todo-lists|.

                        *vimwiki_=*
=                       Add header level. Create if needed.
                        There is nothing to indent with '==' command in
                        vimwiki, so it should be ok to use '=' here.

                        *vimwiki_-*
-                       Remove header level.

Normal mode (Mouse): ~
Works only if |g:vimwiki_use_mouse| is set to 1.
<2-LeftMouse>           Follow/Create WikiWord
<S-2-LeftMouse>         Split and follow/create WikiWord
<C-2-LeftMouse>         Vertical split and follow/create WikiWord
<RightMouse><LeftMouse> Go back to previous WikiWord

Note: <2-LeftMouse> is just left double click.

------------------------------------------------------------------------------
3.3. Text objects                                       *vimwiki-text-objects*

ah                      A Header with leading empty lines.
ih                      Inner Header without leading empty lines.

You can 'vah' to select a header with its contents or 'dah' to delete it or
'yah' to yank it or 'cah' to change it. ;)


==============================================================================
4. Commands                                                 *vimwiki-commands*

------------------------------------------------------------------------------
4.1. Global Commands                                 *vimwiki-global-commands*

*:VimwikiGoHome*
    Open index file of the current wiki.

*:VimwikiTabGoHome*
    Open index file of the current wiki in a new tab.

*:VimwikiUISelect*
    Open index file of the selected wiki.

------------------------------------------------------------------------------
4.2. Local commands                                   *vimwiki-local-commands*

*:VimwikiFollowWord*
    Follow/create WikiWord.

*:VimwikiGoBackWord*
    Go back to previous WikiWord you come from.

*:VimwikiSplitWord*
    Split and follow/create WikiWord.

*:VimwikiVSplitWord*
    Vertical split and follow/create WikiWord.

*:VimwikiNextWord*
    Find next WikiWord.

*:VimwikiPrevWord*
    Find previous WikiWord.

*:VimwikiDeleteWord*
    Delete WikiWord you are in.

*:VimwikiRenameWord*
    Rename WikiWord you are in.

*:Vimwiki2HTML*
    Convert current WikiPage to HTML.

*:VimwikiAll2HTML*
    Convert all WikiPages to HTML.

*:VimwikiToggleListItem*
    Toggle list item on/off (checked/unchecked)
    See |vimwiki-todo-lists|.

*:Search* /pattern/
    Search for /pattern/ in current wiki.


==============================================================================
5. Wiki syntax                                                *vimwiki-syntax*

There are a lot of different wikies out there. Most of them have their own
syntax and vimwiki is not an exception here. Default vimwiki's syntax is a
subset of google's wiki syntax markup.

As for MediaWiki's syntax -- it is not that convenient for non English
(Russian in my case :)) keyboard layouts to emphasize text as it uses a lot
of '''''' to do it. You have to switch layouts every time you want some bold
non English text. This is the answer to "Why not MediaWiki?"

Nevertheless, there is MediaWiki syntax file included in the distribution (it
doesn't have all the fancy stuff original MediaWiki syntax has though).
See |vimwiki-option-syntax|.


------------------------------------------------------------------------------
5.1. Typefaces                                      *vimwiki-syntax-typefaces*

There are a few typefaces that gives you a bit of control on how your
text should be decorated: >
  *bold text*
  _italic text_
  ~~strikeout text~~
  `code (no syntax) text`
  super^script^
  sub,,script,,

------------------------------------------------------------------------------
5.2. Links                                              *vimwiki-syntax-links*

Internal links~
WikiWords: >
  CapitalizedWordsConnected

You can limit linking of WikiWords by adding an exclamation mark in front of
it: >
  !CapitalizedWordsConnected

Or disable it completely with |g:vimwiki_camel_case|.

Link with spaces in it: >
  [[This is a link]]
or: >
  [[This is a link source|Description of the link]]
or: >
  [[This is a link source][Description of the link]]


External links~
Plain link: >
 http://code.google.com/p/vimwiki

Link with description: >
 [http://habamax.ru/blog habamax home page]


Images and image links~
Image link is the link with one of jpg, png or gif endings.
Plain image link: >
 http://someaddr.com/picture.jpg
in html: >
 <img src="http://someaddr.com/picture.jpg" />

Link to a local image: >
 [[images/pabloymoira.jpg]]
in html: >
 <img src="images/pabloymoira.jpg" />
Path to image (ie. images/pabloymoira.jpg) is relative to
|vimwiki-option-path_html|.

Double bracketed link to an image: >
 [[http://habamax.ru/blog/wp-content/uploads/2009/01/2740254sm.jpg]]
in html: >
 <img src="http://habamax.ru/ ... /.jpg" />

Double bracketed link to an image with description text: >
 [[http://habamax.ru/blog/wp-content/uploads/2009/01/2740254sm.jpg|dance]]
in html: >
 <a href="http://habamax.ru/ ... /.jpg">dance</a>

Double bracketed link to an image with alternate text: >
 [[http://habamax.ru/blog/wp-content/uploads/2009/01/2740254sm.jpg|dance|]]
in html: >
 <img src="http://habamax.ru/ ... /.jpg" alt="dance"/>

Double bracketed link to an image with alternate text and some style: >
 [[http://helloworld.com/blabla.jpg|cool stuff|width:150px; height: 120px;]]
in html: >
 <img src="http://helloworld.com/ ... /.jpg" alt="cool stuff"
 style="width:150px; height:120px"/>

Double bracketed link to an image without alternate text and some style: >
 [[http://helloworld.com/blabla.jpg||width:150px; height: 120px;]]
in html: >
 <img src="http://helloworld.com/ ... /.jpg" alt=""
 style="width:150px; height:120px"/>

Thumbnail link: >
 [http://someaddr.com/bigpicture.jpg http://someaddr.com/thumbnail.jpg]
or >
 [[http://someaddr.com/bigpicture.jpg|http://someaddr.com/thumbnail.jpg]]
in html: >
 <a href="http://someaddr.com/ ... /.jpg">
  <img src="http://../thumbnail.jpg /></a>


------------------------------------------------------------------------------
5.3. Headers                                          *vimwiki-syntax-headers*

= Header level 1 =~
By default all headers are highlighted using |hl-Title| highlight group.

== Header level 2 ==~
You can set up different colors for each header level: >
  :hi VimwikiHeader1 guifg=#FF0000
  :hi VimwikiHeader2 guifg=#00FF00
  :hi VimwikiHeader3 guifg=#0000FF
  :hi VimwikiHeader4 guifg=#FF00FF
  :hi VimwikiHeader5 guifg=#00FFFF
  :hi VimwikiHeader6 guifg=#FFFF00
Set up colors for all 6 header levels or none at all.

=== Header level 3 ===~
Check |g:vimwiki_hl_headers|.

==== Header level 4 ====~
===== Header level 5 =====~
====== Header level 6 ======~

Note: before vimwiki 0.8.2, header's markup syntax used exclamation marks:
! Header level 1
!! Header level 2
etc...

If you upgrade from pre 0.8.2 you might find the next commands useful.
To change headers from !Header to =Header= in your wiki files do: >
 :args .wiki
 :argdo %s/^\(!\+\)\([^!].*$\)/\=substitute(submatch(1),'!','=','g').submatch(2).substitute(submatch(1),'!','=','g')

Note: BACKUP FIRST!

------------------------------------------------------------------------------
5.4. Paragraphs                                    *vimwiki-syntax-paragraphs*

Paragraph is group of lines started from column 1 (no indentation). Paragraphs
divided by a blank line:

This is first paragraph
with two lines.

This is a second paragraph with
two lines.

------------------------------------------------------------------------------
5.5. Lists                                              *vimwiki-syntax-lists*

Indent list items with at least one space.
Unordered lists: >
  * Bulleted list item 1
  * Bulleted list item 2
    * Bulleted list sub item 1
    * Bulleted list sub item 2
    * more ...
      * and more ...
      * ...
    * Bulleted list sub item 3
    * etc.

Ordered lists: >
  # Numbered list item 1
  # Numbered list item 2
    # Numbered list sub item 1
    # Numbered list sub item 2
    # more ...
      # and more ...
      # ...
    # Numbered list sub item 3
    # etc.

It is possible to mix bulleted and numbered lists: >
  * Bulleted list item 1
  * Bulleted list item 2
    # Numbered list sub item 1
    # Numbered list sub item 2

Multiline list items: >
  * Bulleted list item 1
    List item 1 continued line.
    List item 1 next continued line.
  * Bulleted list item 2
    * Bulleted list sub item 1
      List sub item 1 continued line.
      List sub item 1 next continued line.
    * Bulleted list sub item 2
    * etc.

Definition lists: >
Term 1:: Definition 1
Term 2::
::Definition 2
::Definition 3


------------------------------------------------------------------------------
5.6. Tables                                            *vimwiki-syntax-tables*

Tables are created by entering the content of each cell separated by ||
delimiters. You can insert other inline wiki syntax in table cells, including
typeface formatting and links.
For example:

||*Year*s||*Temperature (low)*||*Temperature (high)*||
||1900   ||-10                ||25                  ||
||1910   ||-15                ||30                  ||
||1920   ||-10                ||32                  ||
||1930   ||_N/A_              ||_N/A_               ||
||1940   ||-2                 ||40                  ||


For HTML, contents of table cell could be aligned to the right, left and
center:

|| Center || Center || Center ||
||Left    || Center ||   Right||
||   Right||Left    || Center ||
|| Center ||   Right||Left    ||

No spaces on the left side -- left alignment.
No spaces on the right side -- right alignment.
Spaces on the left and on the right -- center alignment.


------------------------------------------------------------------------------
5.7. Preformatted text                           *vimwiki-syntax-preformatted*

Use {{{ and }}} to define block of preformatted text:
{{{ >
  Tyger! Tyger! burning bright
   In the forests of the night,
    What immortal hand or eye
     Could frame thy fearful symmetry?
  In what distant deeps or skies
   Burnt the fire of thine eyes?
    On what wings dare he aspire?
     What the hand dare sieze the fire?
}}}


You can add optional information to {{{ tag: >
{{{class="brush: python" >
 def hello(world):
     for x in range(10):
         print("Hello {0} number {1}".format(world, x))
}}}

Result of HTML export: >
 <pre class="brush: python">
 def hello(world):
     for x in range(10):
         print("Hello {0} number {1}".format(world, x))
 </pre>

This might be useful for coloring some programming code with external js tools
like google syntax highlighter.

You can setup vimwiki to highlight code snippets in preformatted text.
See |vimwiki-option-nested_syntaxes|

------------------------------------------------------------------------------
5.8. Blockquotes                                  *vimwiki-syntax-blockquotes*

Text started with 4 or more spaces is a blockquote.

    This would be a blockquote in vimwiki. It is not highlighted in vim but
    could be styled by css in html. Blockquotes are usually used to quote a
    long piece of text from another source.

------------------------------------------------------------------------------
5.9. Comments                                        *vimwiki-syntax-comments*

Text between <!-- and --> is a comment.
Ex: >
 <!-- this text would not be in HTML -->
<

==============================================================================
6. Folding/Outline                                           *vimwiki-folding*

Vimwiki can fold or outline headers and list items.

Example:
= My current task =
  * [ ] Do stuff 1
    * [ ] Do substuff 1.1
    * [ ] Do substuff 1.2
      * [ ] Do substuff 1.2.1
      * [ ] Do substuff 1.2.2
    * [ ] Do substuff 1.3
  * [ ] Do stuff 2
  * [ ] Do stuff 3

Hit |zM| :
= My current task = [8] --------------------------------------~

Hit |zr| :
= My current task =~
  * [ ] Do stuff 1 [5] --------------------------------------~
  * [ ] Do stuff 2~
  * [ ] Do stuff 3~

Hit |zr| one more time:
= My current task =~
  * [ ] Do stuff 1~
    * [ ] Do substuff 1.1~
    * [ ] Do substuff 1.2 [2] -------------------------------~
    * [ ] Do substuff 1.3~
  * [ ] Do stuff 2~
  * [ ] Do stuff 3~

NOTE: Whether you use default syntax, folding on list items should work
properly only if all of them are indented using current |shiftwidth|.
For MediaWiki * or # should be in the first column.

To turn folding on/off check |g:vimwiki_folding|.

==============================================================================
7. Todo lists                                             *vimwiki-todo-lists*

You can have todo lists -- lists of items you can check/uncheck.

Consider the following example:
= Toggleable list of todo items =
  * [X] Toggle list item on/off.
    * [X] Simple toggling between [ ] and [X].
    * [X] All list's subitems should be toggled on/off appropriately.
    * [X] Toggle child subitems only if current line is list item
    * [X] Parent list item should be toggled depending on it's child items.
  * [X] Make numbered list items toggleable too
  * [X] Add highlighting to list item boxes
  * [X] Add [ ] to the next created with o, O and <CR> list item.


Pressing <C-Space> on the first list item will toggle it and all of it's child
items:
= Toggleable list of todo items =
  * [ ] Toggle list item on/off.
    * [ ] Simple toggling between [ ] and [X].
    * [ ] All list's subitems should be toggled on/off appropriately.
    * [ ] Toggle child subitems only if current line is list item
    * [ ] Parent list item should be toggled depending on it's child items.
  * [X] Make numbered list items toggleable too
  * [X] Add highlighting to list item boxes
  * [X] Add [ ] to the next created with o, O and <CR> list item.

Pressing <C-Space> on the third list item will toggle it and all of it's
parent items:
= Toggleable list of todo items =
  * [.] Toggle list item on/off.
    * [ ] Simple toggling between [ ] and [X].
    * [X] All list's subitems should be toggled on/off appropriately.
    * [ ] Toggle child subitems only if current line is list item
    * [ ] Parent list item should be toggled depending on it's child items.
  * [ ] Make numbered list items toggleable too
  * [ ] Add highlighting to list item boxes
  * [ ] Add [ ] to the next created with o, O and <CR> list item.

Parent items could be toggled by its child items. Symbol inside [ ] depends on
percentage of toggled child items(see also |g:vimwiki_listsyms|): >
    [ ] -- 0%
    [.] -- 1-33%
    [o] -- 34-66%
    [O] -- 67-99%
    [X] -- 100%

It is possible to toggle several list items using visual mode.

==============================================================================
8. Options                                                   *vimwiki-options*

------------------------------------------------------------------------------
*g:vimwiki_list* *vimwiki-multiple-wikies*

Each item in g:vimwiki_list is a |Dictionary| that holds all customization
available for a wiki represented by that item. It is in form of >
  {'option1': 'value1', 'option2: 'value2', ...}

Consider the following example: >
  let g:vimwiki_list = [{'path': '~/my_site/', 'path_html': '~/public_html/'}]

It gives us one wiki located at ~/my_site/ that could be htmlized to
~/public_html/

The next example: >
  let g:vimwiki_list = [{'path': '~/my_site/', 'path_html': '~/public_html/'},
            \ {'path': '~/my_docs/', 'ext': '.mdox'}]
gives us 2 wikies, first wiki as in previous example, second one is located in
~/my_docs/ and its files have .mdox extension.

Empty |Dictionary| in the g:vimwiki_list is the wiki with default options: >
  let g:vimwiki_list = [{},
            \ {'path': '~/my_docs/', 'ext': '.mdox'}]

<
Per wiki options

*vimwiki-option-path*
---------------------
Key             Default value~
path            ~/vimwiki/

Description~
Wiki files location: >
  let g:vimwiki_list = [{'path': '~/my_site/'}]
<

*vimwiki-option-path_html*
--------------------------
Key             Default value~
path_html       ~/vimwiki_html/

Description~
HTML files converted from wiki files location: >
  let g:vimwiki_list = [{'path': '~/my_site/',
                       \ 'path_html': '~/my_site_html/'}]

If you omit this option path_html would be path - '/' + '_html/': >
  let g:vimwiki_list = [{'path': '~/okidoki/'}]

ie, path_html = '~/okidoki_html/'


*vimwiki-option-index*
----------------------
Key             Default value~
index           index

Description~
Name of wiki index file: >
  let g:vimwiki_list = [{'path': '~/my_site/', 'index': 'main'}]

NOTE: Do not add extension.


*vimwiki-option-ext*
--------------------
Key             Default value~
ext             .wiki

Description~
Extension of wiki files: >
  let g:vimwiki_list = [{'path': '~/my_site/',
                       \ 'index': 'main', 'ext': '.document'}]

<
*vimwiki-option-syntax*
-----------------------
Key             Default value     Values~
syntax          default           default, media

Description~
Wiki syntax.
You can use different markup languages (currently default vimwiki and
MediaWiki) but only vimwiki's default markup could be converted to HTML at the
moment.
To use MediaWiki's wiki markup: >
  let g:vimwiki_list = [{'path': '~/my_site/', 'syntax': 'media'}]
<

*vimwiki-option-html_header*
----------------------------
Key             Default value~
html_header

Description~
Set up file name for html header template: >
  let g:vimwiki_list = [{'path': '~/my_site/',
          \ 'html_header': '~/public_html/header.tpl'}]

This header.tpl could look like: >
    <html>
    <head>
        <link rel="Stylesheet" type="text/css" href="%root_path%style.css" />
        <title>%title%</title>
        <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    </head>
    <body>
        <div class="contents">

where
  %title% is replaced by a wiki page name
  %root_path% is replaced by a count of ../ for pages buried in subdirs:
    if you have wikilink [[dir1/dir2/dir3/my page in a subdir]] then
    %root_path% is replaced by '../../../'.


*vimwiki-option-html_footer*
----------------------------
Key             Default value~
html_footer

Description~
Set up file name for html footer template: >
  let g:vimwiki_list = [{'path': '~/my_site/',
          \ 'html_footer': '~/public_html/footer.tpl'}]

This footer.tpl could look like: >
        </div>
    </body>
    </html>
<

*vimwiki-option-css_name*
-------------------------
Key             Default value~
css_name        style.css

Description~
Set up css file name: >
  let g:vimwiki_list = [{'path': '~/my_pages/',
          \ 'css_name': 'main.css'}]
<
or even >
  let g:vimwiki_list = [{'path': '~/my_pages/',
          \ 'css_name': 'css/main.css'}]
<

*vimwiki-option-gohome*
-----------------------
Key             Default value     Values~
gohome          split             split, vsplit, tabe

Description~
This option controls the way |:VimwikiGoHome| command works.
For instance you have 'No write since last change' buffer. After <Leader>ww
(or :VimwikiGoHome) vimwiki index file will be splitted with it. Or vertically
splitted. Or opened in a new tab.
Ex: >
  let g:vimwiki_list = [{'path': '~/my_site/', 'gohome': 'vsplit'}]
<

*vimwiki-option-maxhi*
----------------------
Key             Default value     Values~
maxhi           1                 0, 1

Description~
Non-existent WikiWord highlighting could be quite slow and if you don't want
it set maxhi to 0: >
  let g:vimwiki_list = [{'path': '~/my_site/', 'maxhi': 0}]

This disables filesystem checks for WikiWords.


*vimwiki-option-nested_syntaxes*
--------------------------------
Key             Default value     Values~
nested_syntaxes {}                pairs of highlight keyword and vim filetype

Description~
You can make preformatted text to be highlighted with a different syntaxes
available for vim.
For example the following setup: >
  let wiki = {}
  let wiki.path = '~/my_site/'
  let wiki.nested_syntaxes = {'python': 'python', 'c++': 'cpp'}
  let vimwiki_list = [wiki]

would give you python and c++ highlighting in: >
 {{{class="brush: python"
 for i in range(1, 5):
     print(i)
 }}}

 {{{class="brush: c++"
 #include "helloworld.h"
 int helloworld()
 {
    printf("hello world");
 }
 }}}

or in: >
 {{{c++
 #include "helloworld.h"
 int helloworld()
 {
    printf("hello world");
 }
 }}}

 {{{python
 for i in range(1, 5):
     print(i)
 }}}



Global options
------------------------------------------------------------------------------
*g:vimwiki_hl_headers*

Highlight headers with =Reddish=, ==Greenish==, ===Blueish=== colors.

Value           Description~
1               Use predefined colors to highlight different header levels.
0               Use |hl-Title| or  VimwikiHeader1-VimwikiHeader6 (if defined
                in a colorscheme)

Default: 0


------------------------------------------------------------------------------
*g:vimwiki_hl_cb_checked*

Checked list items could be highlighted with a color:

  * [X] the whole line could be highlighted with the option set to 1.
  * [ ] I wish vim could use strikethru.

Value           Description~
1               Highlight checked [X] check box with |group-name| "Comment".
0               Don't.

Default: 0


------------------------------------------------------------------------------
*g:vimwiki_global_ext* *vimwiki-temporary-wiki*

If a file with a registered wiki extension is opened in a dir that is not
listed in |g:vimwiki_list| then:

Value           Description~
1               make a temporary wiki in that dir.
0               don't make temporary wiki it that dir.

Default: 1


------------------------------------------------------------------------------
*g:vimwiki_upper* *g:vimwiki_lower*

This affects WikiWord detection.
By default WikiWord detection uses English and Russian letters.
You can set up your own: >
  let g:vimwiki_upper = "A-Z\u0410-\u042f"
  let g:vimwiki_lower = "a-z\u0430-\u044f"


------------------------------------------------------------------------------
*g:vimwiki_auto_checkbox*

if on, creates checkbox while toggling list item.

Value           Description~
0               Do not create checkbox.
1               Create checkbox.

Default: 1

Ex:
Press <C-Space> (|:VimwikiToggleListItem|) on a list item without checkbox to
create it: >
  * List item
result: >
  * [ ] List item


------------------------------------------------------------------------------
*g:vimwiki_menu*

GUI menu of available wikies to select.

Value              Description~
''                 No menu
'Vimwiki'          Top level menu "Vimwiki"
'Plugin.Vimwiki'   "Vimwiki" submenu of top level menu "Plugin"
etc.

Default: 'Vimwiki'

------------------------------------------------------------------------------
*g:vimwiki_stripsym*

Change strip symbol -- in Windows you cannot use /*?<>:" in file names so
vimwiki replaces them with neutral symbol (_ is default): >
    let g:vimwiki_stripsym = '_'

You can change it to a <space> for example: >
    let g:vimwiki_stripsym = ' '

------------------------------------------------------------------------------
*g:vimwiki_badsyms*

Consider you do not like spaces in filenames (as some vimwiki users do).
In that case you can set up bad symbols that would be converted to
|g:vimwiki_stripsym|: >
    let g:vimwiki_badsyms = ' '

Now files for all [[links with spaces]] would be created like
'links_with_spaces'.

This option is a complement one to |g:vimwiki_stripsym|.

------------------------------------------------------------------------------
*g:vimwiki_listsyms*

String of 5 symbols for list items with checkboxes.
Default value is ' .oOX'.

g:vimwiki_listsyms[0] is for 0% done items.
g:vimwiki_listsyms[4] is for 100% done items.

------------------------------------------------------------------------------
*g:vimwiki_use_mouse*

Use local mouse mappings from |vimwiki-local-mappings|.

Value           Description~
0               Do not use mouse mappings.
1               Use mouse mappings.

Default: 0

------------------------------------------------------------------------------
*g:vimwiki_folding*

Enable/disable vimwiki's folding/outline. Folding in vimwiki is using 'expr'
foldmethod which is very flexible but really slow.

Value           Description~
0               Disable folding.
1               Enable folding.

Default: 1

------------------------------------------------------------------------------
*g:vimwiki_fold_lists*

Enable/disable folding of list subitems.

Value           Description~
0               Disable list subitem's folding.
1               Enable list subitem's folding.

Default: 0

------------------------------------------------------------------------------
*g:vimwiki_fold_empty_lines*

Fold or do not fold empty lines between folded headers.

Value           Description~
0               Do not fold in empty lines.
1               Fold in empty lines.

Default: 0

------------------------------------------------------------------------------
*g:vimwiki_camel_case*

If you do not want WikiWord to be a link this setting is just for you.

Value           Description~
0               Do not make links from CamelCased words.
1               Make links from CamelCased words.

Default: 1

------------------------------------------------------------------------------
*g:vimwiki_list_ignore_newline*

This is HTML related.
Convert newlines to <BR />s in multiline list items.

Value           Description~
0               Newlines in a list item are converted to <BR />s.
1               Ignore newlines.

Default: 1

------------------------------------------------------------------------------
*g:vimwiki_browsers* *VimwikiWeblinkHandler*

You can open external weblinks in a webbrowser. Webbrowsers are listed in
|g:vimwiki_browsers|.

For win32 it is: chrome, opera, firefox and explorer.
For other OSes it is: opera, firefox and konqueror.

The first available browser from the list is used to open weblink.
If you have opera and firefox and want weblinks to be opened in the latter
just: >
 let g:vimwiki_browsers=['C:\Program Files\Firefox\firefox.exe']

or redefine VimwikiWeblinkHandler function: >
  function! VimwikiWeblinkHandler(weblink)
    let browser = 'C:\Program Files\Firefox\firefox.exe'
    execute '!start "'.browser.'" ' . a:weblink
  endfunction


==============================================================================
9. Help                                                         *vimwiki-help*

As you could see I am not native English speaker (not a writer as well).
Please send me correct phrases instead of that incorrect stuff I have used
here.

Any help is really appreciated!

==============================================================================
10. Author                                                    *vimwiki-author*

I live in Moscow and you may believe me -- there are no polar bears (no brown
too) here in the streets.

I do not do programming for a living. So don't blame me for an ugly
ineffective code. Improvements are welcome.

Many thanks to all of you for voting vimwiki up on www.vim.org. I do vimwiki
in my spare time I could use to dance argentine tango with beautiful women.
Your votes are kind of a good replacement. ;)

Sincerely yours,
Maxim Kim <habamax@gmail.com>.

Vimwiki's website: http://code.google.com/p/vimwiki/
Vim plugins website: http://www.vim.org/scripts/script.php?script_id=2226

==============================================================================
11. Changelog                                              *vimwiki-changelog*

0.9.701
    * FIX: Issue 30: Highlighting doesn't work for checked list item.

0.9.7
    * NEW: Default checkbox symbols are changed to [ ], [.], [o], [O], [X].
      You can change them using |g:vimwiki_listsyms| variable.
    * NEW: Color group names are renamed from wikiBold, wikiItalic, etc to
      VimwikiBold, VimwikiItalic, etc.
    * NEW: Open external links in a browser. There are default browsers
      defined in |g:vimwiki_browsers| list. You can also redefine
      |VimwikiWeblinkHandler| function to open weblinks in other programs.
    * NEW: Issue 25: Toggle the states of multiple TODO list items at a time
      (in VISUAL and in VISUAL LINE modes)
    * NEW: Issue 26: Highlight code snippets in vimwiki's pre. See
      |vimwiki-option-nested_syntaxes|. Thanks kriomant.
    * NEW: Issue 27: Automatic garbage deletion from html directory.
    * NEW: Save all open vimwiki buffers before export to html.
    * NEW: Issue 29: Custom :Search command.
    * NEW: Header text objects are now expandable in VISUAL mode. Tap 'vah' to
      select a header. Tap again 'ah' to expand selection further. Thanks
      Andy Wokula.
    * FIX: Folding settings are reset to vim defaults in a new tab (think of
      \wt) so you cannot hide things in folds.
    * FIX: https links in form of [https://hello.world.com] are not exported
      into html. Thanks Saurabh Sarpal for the patch.

0.9.6
    * NEW: You can have multiline list items. See |vimwiki-syntax-lists|.
    * NEW: You can ignore newlines in multiline list items when do export to
      html. See |g:vimwiki_list_ignore_newline| option.
    * NEW: Different checkbox symbols [.], [:], [o] are added. See
      |vimwiki-todo-lists|.
    * NEW: Now there is no longer syntax of preformatted text that is started
      by a whitespace.
    * NEW: Blockquotes. See |vimwiki-syntax-blockquote|.
    * NEW: Per wiki folding option (vimwiki-option-folding) is removed. Global
      |g:vimwiki_folding| and |g:vimwiki_fold_lists| are added.
    * NEW: Due to being quite slow folding of list items is off by default.
      Use |g:vimwiki_fold_lists| to turn it on.
    * NEW: If you want replace some symbols in a wikifilename use
      |g:vimwiki_badsyms| option (Andreas Baldeau).
    * FIX: Command |:VimwikiToggleListItem| doesn't work for one of the two
      wikies opened at the same time with different syntaxes.
    * FIX: Command |:VimwikiToggleListItem| do not switch parent checkboxes if
      there are non-checkbox list items available.
    * FIX: Issue 24: Link error in html when write [[one.two.three]].
    * FIX: Rename WikiWord to something with a colon (:) does nasty things.
    * FIX: Command |:VimwikiToggleListItem| do not switch right if there are
      list items without checkboxes in the list.

0.9.5
    * NEW: Added |g:vimwiki_global_ext| to control creation of temporary
      wikies in dirs that are not listed in |g:vimwiki_list|.
    * NEW: Added |g:vimwiki_hl_headers| to highlight headers with different
      predefined colors.
    * NEW: Checked [X] items are not highlighted with Comment syntax group by
      default. Use |g:vimwiki_hl_cb_checked| to turn it on.
    * NEW: Added new syntax for links: [[link address][link description]].
    * NEW: Added <C-@> allias of <C-Space> mapping for *nix systems.
    * NEW: Added |g:vimwiki_camel_case|. Set it to 0 if you do not want
      CamelCased WikiWords to be linkified.
    * FIX: Links with g:vimwiki_stripsym (default '_') [[My_Link|Text]] are
      not highlighted when created.
    * FIX: indent/vimwiki.vim is obsolete. If you upgrade from previous
      versions remove it. It causes wrong list indentation if noexpandtab is
      set.
    * FIX: If tabs and spaces are used to indent list items html export gives
      error. Thanks Klaus Ethgen for report.
    * FIX: Some html export fixes.

0.9.4
    * NEW: Links with directories: [[dir1/dir2/Link|Text]]. Thanks Jie Wu.
    * NEW: Added %root_path% template variable to get relative root dir of
      path_html. See |vimwiki-option-html_header|.
    * FIX: Indent is incorrect for vim without "float" compile option. Thanks
      Julian Kooij.
    * FIX: Convert to html doesn't work right with links like [[foo::bar]].
    * FIX: Rename wikiword doesn't work right when rename WikiWord to
      [[WikiWord blablabla]].
    * FIX: Renaming of links with description doesn't work.
    * FIX: Weblinks with commas are not highlighted.
    * MISC: Some changes in default css file.

0.9.3
    * NEW: g:vimwiki_menu option is a string which is menu path. So one can
      use let g:vimwiki_menu = 'Plugin.Vimwiki' to set the menu to the right
      place.
    * NEW: g:vimwiki_fold_empty_lines -- don't or do fold in empty lines
      between headers. See |g:vimwiki_fold_empty_lines|
    * FIX: Encoding error when running vimwiki in Windows XP Japanese.
      Thanks KarasAya.

0.9.2c
    * FIX: Regression: Export HTML link error with [[Link|Text]].

0.9.2b
    * FIX: Installation on Linux doesn't work. (Dos line endings in Vimball
      archive file).
    * FIX: Clear out FlexWiki ftplugin's setup. Now you don't have to hack
      filetype.vim to get rid of unexpected ':setlocal bomb' from FlexWiki's
      ftplugin.
    * FIX: When write done: it will show another done: in html file.

0.9.2a
    * FIX: Installation on Linux doesn't work. (Dos line endings in
      autoload/vimwiki_lst.vim and indent/vimwiki.vim).

0.9.2
    * NEW: Option 'folding' added to turn folding on/off.
    * NEW: Header text object. See |vimwiki-text-objects|.
    * NEW: Add/remove Header levels with '=' and '-'. See |vimwiki_=|.
    * NEW: Vimwiki GUI menu to select available wikies. See |g:vimwiki_menu|.
    * NEW: You can specify the name of your css file now. See
      |vimwiki-option-css_name|
    * NEW: You can add styles to image links, see |vimwiki-syntax-links|.
    * FIX: History doesn't work after |VimwikiRenameWord|.
    * FIX: Some of wikipedia links are not correctly highlighted. Links with
      parentheses.
    * MISC: Renamed vimwiki_gtd to vimwiki_lst.

0.9.1
    * NEW: HTML Table cell text alignment, see |vimwiki-syntax-tables|
    * NEW: Wikipage history simplified. Each vimwiki buffer now holds
      b:vimwiki_prev_word which is list of [PrevWord, getpos()].
    * NEW: If highlight for groups wikiHeader1..wikiHeader6 exist (defined in
      a colorscheme) -- use it. Otherwise use Title highlight for all Headers.
    * FIX: Warn only once if 'html_header' or 'html_footer' does not exist.
    * FIX: Wrong folding for the text after the last nested list item.
    * FIX: Bold and Italic aren't highlighted in tables without spaces
      between || and * or _. ||*bold*||_asdf_ || (Thanks Brett Stahlman)

0.9.0
    * NEW: You can add classes to 'pre' tag -- |vimwiki-syntax-preformatted|.
      This might be useful for coloring some programming code with external js
      tools like google syntax highlighter.
    * NEW: !WikiPage is not highlighted. It is just a plain word WikiPage in
      HTML, without exclamation mark
    * NEW: Definition lists, see |vimwiki-syntax-lists|.
    * NEW: New implementation of |:VimwikiRenameWord|. CAUTION: It was tested
      on 2 computers only, backup your wiki before use it. Email me if it
      doesn't work for you.
    * FIX: Less than 3 symbols are not highlighted in Bold and Italic.
    * FIX: Added vimwiki autocmd group to avoid clashes with user defined
      autocmds.
    * FIX: Pressing ESC while |:VimwikiUISelect| opens current wiki index
      file.  Should cancel wiki selection.

0.8.3
    * NEW: <C-Space> on a list item creates checkbox.
    * FIX: With * in the first column, <CR> shouldn't insert more * (default
      syntax).
    * FIX: With MediaWiki's ** [ ], <CR> should insert it on the next line.
    * FIX: HTML export should use 'fileencoding' instead of 'encoding'.
    * FIX: Code cleanup.

0.8.2
    * DEL: Removed google syntax file.
    * NEW: Default vimwiki syntax is a subset of google's one. Header's has
      been changed from !Header to =Header=. It is easier to maintain only 2
      syntaxes. See |vimwiki-syntax-headers|.
    * NEW: Multiline paragraphs -- less longlines.
    * NEW: Comments. See |vimwiki-syntax-comments|.
    * DEL: Removed setlocal textwidth = 0 from ftplugin.
    * FIX: New regexps for bold, italic, bolditalic.
    * FIX: The last item in List sometimes fold-in incorrectly.
    * FIX: Minor tweaks on default css.

0.8.1
    * NEW: Vimwiki's foldmethod changed from syntax to expr. Foldtext is
      changed to be nicer with folded list items.
    * NEW: Fold/outline list items.
    * NEW: It is possible now to edit wiki files in arbitrary directories
      which is not in g:vimwiki_list's paths. New WikiWords are created in the
      path of the current WikiWord.
    * NEW: User can remap Vimwiki's built in mappings.
    * NEW: Added |g:vimwiki_use_mouse|. It is off by default.
    * FIX: Removed <C-h> mapping.

0.8.0
    * NEW: Multiple wikies support. A lot of options have been changed, see
      |vimwiki-options|
    * NEW: Auto create directories.
    * NEW: Checked list item highlighted as comment.
    * FIX: Multiple 'set ft=vimwiki' for each buffer disabled. Vimwiki should
      load its buffers a bit faster now.

0.7.1
    * NEW: <Plug>VimwikiToggleListItem added to be able to remap <C-Space> to
      anything user prefers more.
    * FIX: Toggleable list items do not work with MediaWiki markup.
    * FIX: Changing g:vimwiki_home_html to path with ~ while vimwiki is
      loaded gives errors for HTML export.
    * DEL: Command :VimwikiExploreHome.

0.7.0
    * NEW: GTD stuff -- toggleable list items. See |vimwiki-todo-lists|.
    * FIX: Headers do not fold inner headers. (Thanks Brett Stahlman)
    * FIX: Remove last blank lines from preformatted text at the end of file.
    * DEL: Removed g:vimwiki_smartCR option.

0.6.2
    * NEW: [[link|description]] is available now.
    * FIX: Barebone links (ie: http://bla-bla-bla.org/h.pl?id=98) get extra
      escaping of ? and friends so they become invalid in HTML.
    * FIX: In linux going to [[wiki with whitespaces]] and then pressing BS
      to go back to prev wikipage produce error. (Thanks Brendon Bensel for
      the fix)
    * FIX: Remove setlocal encoding and fileformat from vimwiki ftplugin.
    * FIX: Some tweaks on default style.css

0.6.1
    * FIX: [blablabla bla] shouldn't be converted to a link.
    * FIX: Remove extra annoing empty strings from PRE tag made from
      whitespaces in HTML export.
    * FIX: Moved functions related to HTML converting to new autoload module
      to increase a bit vimwiki startup time.

0.6
    * NEW: Header and footer templates. See|g:vimwiki_html_header| and
      |g:vimwiki_html_footer|.
    * FIX: |:Vimwiki2HTML| does not recognize ~ as part of a valid path.

0.5.3
    * FIX: Fixed |:VimwikiRenameWord|. Error when g:vimwiki_home had
      whitespaces in path.
    * FIX: |:VimwikiSplitWord| and |:VimwikiVSplitWord| didn't work.

0.5.2
    * NEW: Added |:VimwikiGoHome|, |:VimwikiTabGoHome| and
      |:VimwikiExploreHome| commands.
    * NEW: Added <Leader>wt mapping to open vimwiki index file in a new tab.
    * NEW: Added g:vimwiki_gohome option that controls how|:VimwikiGoHome|
      works when current buffer is changed. (Thanks Timur Zaripov)
    * FIX: Fixed |:VimwikiRenameWord|. Very bad behaviour when autochdir
      isn't set up.
    * FIX: Fixed commands :Wiki2HTML and :WikiAll2HTML to be available only
      for vimwiki buffers.
    * FIX: Renamed :Wiki2HTML and :WikiAll2HTML to |:Vimwiki2HTML| and
      |:VimwikiAll2HTML| commands.
    * FIX: Help file corrections.

0.5.1
    * NEW: This help is created.
    * NEW: Now you can fold headers.
    * NEW: <Plug>VimwikiGoHome and <Plug>VimwikiExploreHome were added.
    * FIX: Bug with {{{HelloWikiWord}}} export to HTML is fixed.
    * DEL: Sync option removed from: Syntax highlighting for preformatted
      text {{{ }}}.

0.5
    * NEW: vimwiki default markup to HTML conversion improved.
    * NEW: Added basic GoogleWiki and MediaWiki markup languages.
    * NEW: Chinese [[complex wiki words]].

0.4
    * NEW: vimwiki=>HTML converter in plain Vim language.
    * NEW: Plugin autoload.

0.3.4
    * FIX: Backup files (.wiki~) caused a bunch of errors while opening wiki
      files.

0.3.3
    * FIX: [[wiki word with dots at the end...]] didn't work.
    * NEW: Added error handling for delete wiki word function.
    * NEW: Added keybindings o and O for list items when g:vimwiki_smartCR=1.
    * NEW: Added keybinding <Leader>wh to visit wiki home directory.

0.3.2
    * FIX: Renaming -- error if complex wiki word contains %.
    * FIX: Syntax highlighting for preformatted text {{{ }}}. Sync option
      added.
    * FIX: smartCR bug fix.

0.3.1
    * FIX: Renaming -- [[hello world?]] to [[hello? world]] links are not
      updated.
    * FIX: Buffers menu is a bit awkward after renaming.
    * NEW: Use mouse to follow links. Left double-click to follow WikiWord,
      Rightclick then Leftclick to go back.

0.3
    * NEW: Highlight non-existent WikiWords.
    * NEW: Delete current WikiWord (<Leader>wd).
    * NEW: g:vimwiki_smartCR=2 => use Vim comments (see :h comments :h
      formatoptions) feature to deal with list items. (thx -- Dmitry
      Alexandrov)
    * NEW: Highlight TODO:, DONE:, FIXED:, FIXME:.
    * NEW: Rename current WikiWord -- be careful on Windows you cannot rename
      wikiword to WikiWord. After renaming update all links to that renamed
      WikiWord.
    * FIX: Bug -- do not duplicate WikiWords in wiki history.
    * FIX: After renaming [[wiki word]] twice buffers are not deleted.
    * FIX: Renaming from [[wiki word]] to WikiWord result is [[WikiWord]]
    * FIX: More than one complex words on one line is bugging each other when
      try go to one of them. [[bla bla bla]] [[dodo dodo dodo]] becomes bla
      bla bla]] [[dodo dodo dodo.


0.2.2
    * NEW: Added keybinding <S-CR> -- split WikiWord
    * NEW: Added keybinding <C-CR> -- vertical split WikiWord

0.2.1
    * NEW: Install on Linux now works.

0.2
    * NEW: Added part of Google's Wiki syntax.
    * NEW: Added auto insert # with ENTER.
    * NEW: On/Off auto insert bullet with ENTER.
    * NEW: Strip [[complex wiki name]] from symbols that cannot be used in
      file names.
    * NEW: Links to non-wiki files. Non wiki files are files with extensions
      ie [[hello world.txt]] or [[my homesite.html]]

0.1
    * First public version.

==============================================================================
12. License                                                   *vimwiki-license*

The MIT Licence
http://www.opensource.org/licenses/mit-license.php

Copyright (c) 2009 Maxim Kim

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.



 vim:tw=78:ts=8:ft=help
ftplugin\vimwiki.vim	[[[1
286
" Vimwiki filetype plugin file
" Author: Maxim Kim <habamax@gmail.com>
" Home: http://code.google.com/p/vimwiki/

if exists("b:did_ftplugin")
  finish
endif
let b:did_ftplugin = 1  " Don't load another plugin for this buffer

" UNDO list {{{
" Reset the following options to undo this plugin.
let b:undo_ftplugin = "setlocal wrap< linebreak< ".
      \ "suffixesadd< isfname< comments< ".
      \ "autowriteall< ".
      \ "formatoptions< foldtext< ".
      \ "foldmethod< foldexpr< commentstring< "
" UNDO }}}

" MISC STUFF {{{

setlocal wrap
setlocal linebreak
setlocal autowriteall
setlocal commentstring=<!--%s-->
" MISC }}}

" GOTO FILE: gf {{{
execute 'setlocal suffixesadd='.VimwikiGet('ext')
setlocal isfname-=[,]
" gf}}}

" COMMENTS: autocreate list items {{{
" for list items, and list items with checkboxes
if VimwikiGet('syntax') == 'default'
  exe 'setl comments=b:\ *\ ['.escape(g:vimwiki_listsyms[0], ' ').
        \ '],b:\ *\ ['.g:vimwiki_listsyms[4].']'
  exe 'setl comments+=b:\ #\ ['.escape(g:vimwiki_listsyms[0], ' ').
        \ '],b:\ #\ ['.g:vimwiki_listsyms[4].']'
  setl comments+=b:\ *,b:\ #
  setl formatlistpat=^\\s\\+[*#]\\s*
else
  exe 'setl comments=n:*\ ['.escape(g:vimwiki_listsyms[0], ' ').
        \ '],n:*\ ['.g:vimwiki_listsyms[4].']'
  exe 'setl comments+=n:#\ ['.escape(g:vimwiki_listsyms[0], ' ').
        \ '],n:#\ ['.g:vimwiki_listsyms[4].']'
  setl comments+=n:*,n:#
endif
setlocal formatoptions=tnro
" COMMENTS }}}

" FOLDING for headers and list items using expr fold method. {{{
if g:vimwiki_folding == 1
  setlocal fdm=expr
  setlocal foldexpr=VimwikiFoldLevel(v:lnum)
  setlocal foldtext=VimwikiFoldText()
endif

function! VimwikiFoldLevel(lnum) "{{{
  let line = getline(a:lnum)

  " Header folding...
  if line =~ g:vimwiki_rxHeader
    let n = vimwiki#count_first_sym(line)
    return '>' . n
  endif

  if g:vimwiki_fold_empty_lines == 0
    let nnline = getline(nextnonblank(a:lnum + 1))
    if nnline =~ g:vimwiki_rxHeader
      let n = vimwiki#count_first_sym(nnline)
      return '<' . n
    endif
  endif

  " List item folding...
  if g:vimwiki_fold_lists
    let rx_list_item = '\('.
          \ g:vimwiki_rxListBullet.'\|'.g:vimwiki_rxListNumber.
          \ '\)'

    if line =~ rx_list_item
      let [nnum, nline] = s:find_next_item(rx_list_item, a:lnum)
      if nline =~ rx_list_item
        let level = s:get_li_level(a:lnum, nnum)
        if !(level < 0 && (nnum - a:lnum) > 1)
          return s:fold_marker(level)
        endif
      elseif nnum - a:lnum == 1
        " last single-lined list item in a list
        let level = s:get_li_level_last(a:lnum)
        return s:fold_marker(level)
      endif
    else
      let [pnum, pline] = s:find_prev_item(rx_list_item, a:lnum)
      if pline =~ rx_list_item
        if getline(a:lnum + 1) =~ rx_list_item
          let level = s:get_li_level(pnum, a:lnum + 1)
          if level < 0
            return s:fold_marker(level)
          endif
        endif

        let [nnum, nline] = s:find_next_item(rx_list_item, pnum)
        if nline !~ rx_list_item && nnum-a:lnum == 1
          " last multi-lined list item in a list
          let level = s:get_li_level_last(pnum)
          return s:fold_marker(level)
        endif

      endif
    endif

  endif

  return '='
endfunction "}}}

function! s:fold_marker(level) "{{{
  if a:level > 0
    return "a".a:level
  elseif a:level < 0
    return "s".abs(a:level)
  else
    return "="
  endif
endfunction "}}}

function! s:find_next_item(rx_item, lnum) "{{{
  let lnum = a:lnum + 1

  while lnum <= line('$')
    if getline(lnum) =~ a:rx_item
          \ || getline(lnum) =~ '^\S'
          \ || indent(lnum) <= indent(a:lnum)
      break
    endif
    let lnum += 1
  endwhile

  return [lnum, getline(lnum)]
endfunction "}}}

function! s:find_prev_item(rx_item, lnum) "{{{
  let lnum = a:lnum - 1

  while lnum > 1
    if getline(lnum) =~ a:rx_item
          \ || getline(lnum) =~ '^\S'
      break
    endif
    let lnum -= 1
  endwhile

  return [lnum, getline(lnum)]
endfunction "}}}

function! s:get_li_level(lnum, nnum) "{{{
  if VimwikiGet('syntax') == 'media'
    let level = vimwiki#count_first_sym(getline(a:nnum)) -
          \ vimwiki#count_first_sym(getline(a:lnum))
  else
    let level = ((indent(a:nnum) - indent(a:lnum)) / &sw)
  endif
  return level
endfunction "}}}

function! s:get_li_level_last(lnum) "{{{
  if VimwikiGet('syntax') == 'media'
    return -(vimwiki#count_first_sym(getline(a:lnum)) - 1)
  else
    return -(indent(a:lnum) / &sw - 1)
  endif
endfunction "}}}

function! VimwikiFoldText() "{{{
  let line = getline(v:foldstart)
  return line.' ['.(v:foldend - v:foldstart).'] '
endfunction "}}}

" FOLDING }}}

" COMMANDS {{{
command! -buffer Vimwiki2HTML
      \ call vimwiki_html#Wiki2HTML(expand(VimwikiGet('path_html')),
      \                             expand('%'))
command! -buffer VimwikiAll2HTML
      \ call vimwiki_html#WikiAll2HTML(expand(VimwikiGet('path_html')))

command! -buffer VimwikiNextWord call vimwiki#WikiNextWord()
command! -buffer VimwikiPrevWord call vimwiki#WikiPrevWord()
command! -buffer VimwikiDeleteWord call vimwiki#WikiDeleteWord()
command! -buffer VimwikiRenameWord call vimwiki#WikiRenameWord()
command! -buffer VimwikiFollowWord call vimwiki#WikiFollowWord('nosplit')
command! -buffer VimwikiGoBackWord call vimwiki#WikiGoBackWord()
command! -buffer VimwikiSplitWord call vimwiki#WikiFollowWord('split')
command! -buffer VimwikiVSplitWord call vimwiki#WikiFollowWord('vsplit')

command! -buffer -range VimwikiToggleListItem call vimwiki_lst#ToggleListItem(<line1>, <line2>)

exe 'command! -buffer -nargs=* Search vimgrep <args> '.
      \ VimwikiGet('path').'**/*'.VimwikiGet('ext')

" COMMANDS }}}

" KEYBINDINGS {{{
if g:vimwiki_use_mouse
  nmap <buffer> <S-LeftMouse> <NOP>
  nmap <buffer> <C-LeftMouse> <NOP>
  noremap <silent><buffer> <2-LeftMouse> :VimwikiFollowWord<CR>
  noremap <silent><buffer> <S-2-LeftMouse> <LeftMouse>:VimwikiSplitWord<CR>
  noremap <silent><buffer> <C-2-LeftMouse> <LeftMouse>:VimwikiVSplitWord<CR>
  noremap <silent><buffer> <RightMouse><LeftMouse> :VimwikiGoBackWord<CR>
endif

if !hasmapto('<Plug>VimwikiFollowWord')
  nmap <silent><buffer> <CR> <Plug>VimwikiFollowWord
endif
noremap <silent><script><buffer>
      \ <Plug>VimwikiFollowWord :VimwikiFollowWord<CR>

if !hasmapto('<Plug>VimwikiSplitWord')
  nmap <silent><buffer> <S-CR> <Plug>VimwikiSplitWord
endif
noremap <silent><script><buffer>
      \ <Plug>VimwikiSplitWord :VimwikiSplitWord<CR>

if !hasmapto('<Plug>VimwikiVSplitWord')
  nmap <silent><buffer> <C-CR> <Plug>VimwikiVSplitWord
endif
noremap <silent><script><buffer>
      \ <Plug>VimwikiVSplitWord :VimwikiVSplitWord<CR>

if !hasmapto('<Plug>VimwikiGoBackWord')
  nmap <silent><buffer> <BS> <Plug>VimwikiGoBackWord
endif
noremap <silent><script><buffer>
      \ <Plug>VimwikiGoBackWord :VimwikiGoBackWord<CR>

if !hasmapto('<Plug>VimwikiNextWord')
  nmap <silent><buffer> <TAB> <Plug>VimwikiNextWord
endif
noremap <silent><script><buffer>
      \ <Plug>VimwikiNextWord :VimwikiNextWord<CR>

if !hasmapto('<Plug>VimwikiPrevWord')
  nmap <silent><buffer> <S-TAB> <Plug>VimwikiPrevWord
endif
noremap <silent><script><buffer>
      \ <Plug>VimwikiPrevWord :VimwikiPrevWord<CR>

if !hasmapto('<Plug>VimwikiDeleteWord')
  nmap <silent><buffer> <Leader>wd <Plug>VimwikiDeleteWord
endif
noremap <silent><script><buffer>
      \ <Plug>VimwikiDeleteWord :VimwikiDeleteWord<CR>

if !hasmapto('<Plug>VimwikiRenameWord')
  nmap <silent><buffer> <Leader>wr <Plug>VimwikiRenameWord
endif
noremap <silent><script><buffer>
      \ <Plug>VimwikiRenameWord :VimwikiRenameWord<CR>

if !hasmapto('<Plug>VimwikiToggleListItem')
  nmap <silent><buffer> <C-Space> <Plug>VimwikiToggleListItem
  vmap <silent><buffer> <C-Space> <Plug>VimwikiToggleListItem
  if has("unix")
    nmap <silent><buffer> <C-@> <Plug>VimwikiToggleListItem
  endif
endif
noremap <silent><script><buffer>
      \ <Plug>VimwikiToggleListItem :VimwikiToggleListItem<CR>


" Text objects {{{
omap <silent><buffer> ah :<C-U>call vimwiki#TO_header(0, 0)<CR>
vmap <silent><buffer> ah :<C-U>call vimwiki#TO_header(0, 1)<CR>

omap <silent><buffer> ih :<C-U>call vimwiki#TO_header(1, 0)<CR>
vmap <silent><buffer> ih :<C-U>call vimwiki#TO_header(1, 1)<CR>

nmap <silent><buffer> = :call vimwiki#AddHeaderLevel()<CR>
nmap <silent><buffer> - :call vimwiki#RemoveHeaderLevel()<CR>

" }}}

" KEYBINDINGS }}}
plugin\vimwiki.vim	[[[1
334
" Vimwiki plugin file
" Author: Maxim Kim <habamax@gmail.com>
" Home: http://code.google.com/p/vimwiki/

if exists("loaded_vimwiki") || &cp
  finish
endif
let loaded_vimwiki = 1

let s:old_cpo = &cpo
set cpo&vim

" HELPER functions {{{
function! s:default(varname, value) "{{{
  if !exists('g:vimwiki_'.a:varname)
    let g:vimwiki_{a:varname} = a:value
  endif
endfunction "}}}

function! Str_common_part(str1, str2)"{{{
  let idx = 0
  let minlen = min([len(a:str1), len(a:str2)])
  while (idx < minlen) && (a:str1[idx] == a:str2[idx])
    let idx = idx + 1
  endwhile

  return strpart(a:str1, 0, idx)
endfunction"}}}

function! s:chomp_slash(str)"{{{
  return substitute(a:str, '[/\\]\+$', '', '')
endfunction"}}}

function! s:find_wiki(path) "{{{
  let idx = 0
  while idx < len(g:vimwiki_list)
    let path = s:chomp_slash(expand(VimwikiGet('path', idx)))
    if Str_common_part(path, a:path) == path
      return idx
    endif
    let idx += 1
  endwhile
  return -1
endfunction "}}}

function! s:setup_buffer_leave()"{{{
  if &filetype == 'vimwiki' && !exists("b:vimwiki_idx")
    let b:vimwiki_idx = g:vimwiki_current_idx
  endif
endfunction"}}}

function! s:setup_buffer_enter() "{{{
  if exists("b:vimwiki_idx")
    let g:vimwiki_current_idx = b:vimwiki_idx
  else
    " Find what wiki current buffer belongs to.
    " If wiki does not exist in g:vimwiki_list -- add new wiki there with
    " buffer's path and ext.
    " Else set g:vimwiki_current_idx to that wiki index.
    let path = expand('%:p:h')
    let ext = '.'.expand('%:e')
    let idx = s:find_wiki(path)

    " The buffer's file is not in the path and user do not want his wiki
    " extension to be global -- do not add new wiki.
    if idx == -1 && g:vimwiki_global_ext == 0
      return
    endif

    if idx == -1
      call add(g:vimwiki_list, {'path': path, 'ext': ext})
      let g:vimwiki_current_idx = len(g:vimwiki_list) - 1
    else
      let g:vimwiki_current_idx = idx
    endif

    let b:vimwiki_idx = g:vimwiki_current_idx
  endif

  call s:setup_colors()

  if &filetype != 'vimwiki'
    setlocal ft=vimwiki
  else
    setlocal syntax=vimwiki
  endif

  " Settings foldmethod, foldexpr and foldtext are local to window. Thus in a
  " new tab with the same buffer folding is reset to vim defaults. So we
  " insist vimwiki folding here.
  " TODO: remove the same from ftplugin.
  if g:vimwiki_folding == 1 && &fdm != 'expr'
    setlocal fdm=expr
    setlocal foldexpr=VimwikiFoldLevel(v:lnum)
    setlocal foldtext=VimwikiFoldText()
  endif
endfunction "}}}

function! s:setup_colors()"{{{
  if g:vimwiki_hl_headers == 0
    return
  endif

  if &background == 'light'
    hi def VimwikiHeader1 guibg=bg guifg=#c05050 gui=bold ctermfg=DarkRed
    hi def VimwikiHeader2 guibg=bg guifg=#309010 gui=bold ctermfg=DarkGreen
    hi def VimwikiHeader3 guibg=bg guifg=#1030a0 gui=bold ctermfg=DarkBlue
    hi def VimwikiHeader4 guibg=bg guifg=#103040 gui=bold ctermfg=Black
    hi def VimwikiHeader5 guibg=bg guifg=#001020 gui=bold ctermfg=Black
    hi def VimwikiHeader6 guibg=bg guifg=#000000 gui=bold ctermfg=Black
  else
    hi def VimwikiHeader1 guibg=bg guifg=#e08090 gui=bold ctermfg=Red
    hi def VimwikiHeader2 guibg=bg guifg=#80e090 gui=bold ctermfg=Green
    hi def VimwikiHeader3 guibg=bg guifg=#6090e0 gui=bold ctermfg=Blue
    hi def VimwikiHeader4 guibg=bg guifg=#c0c0f0 gui=bold ctermfg=White
    hi def VimwikiHeader5 guibg=bg guifg=#e0e0f0 gui=bold ctermfg=White
    hi def VimwikiHeader6 guibg=bg guifg=#f0f0f0 gui=bold ctermfg=White
  endif
endfunction"}}}

" OPTION get/set functions {{{
" return value of option for current wiki or if second parameter exists for
" wiki with a given index.
function! VimwikiGet(option, ...) "{{{
  if a:0 == 0
    let idx = g:vimwiki_current_idx
  else
    let idx = a:1
  endif
  if !has_key(g:vimwiki_list[idx], a:option) &&
        \ has_key(s:vimwiki_defaults, a:option)
    if a:option == 'path_html'
      let g:vimwiki_list[idx][a:option] =
            \VimwikiGet('path', idx)[:-2].'_html/'
    else
      let g:vimwiki_list[idx][a:option] =
            \s:vimwiki_defaults[a:option]
    endif
  endif

  " if path's ending is not a / or \
  " then add it
  if a:option == 'path' || a:option == 'path_html'
    let p = g:vimwiki_list[idx][a:option]
    if p !~ '[\/]$'
      let g:vimwiki_list[idx][a:option] = p.'/'
    endif
  endif

  return g:vimwiki_list[idx][a:option]
endfunction "}}}

" set option for current wiki or if third parameter exists for
" wiki with a given index.
function! VimwikiSet(option, value, ...) "{{{
  if a:0 == 0
    let idx = g:vimwiki_current_idx
  else
    let idx = a:1
  endif
  let g:vimwiki_list[idx][a:option] = a:value
endfunction "}}}
" }}}

" }}}

" CALLBACK function "{{{
" User can redefine it.
if !exists("*VimwikiWeblinkHandler") "{{{
  function VimwikiWeblinkHandler(weblink)
    for browser in g:vimwiki_browsers
      if executable(browser)
        if has("win32")
          execute '!start "'.browser.'" ' . a:weblink
        else
          execute '!'.browser.' ' . a:weblink
        endif
        return
      endif
    endfor
  endfunction
endif "}}}
" CALLBACK }}}

" DEFAULT wiki {{{
let s:vimwiki_defaults = {}
let s:vimwiki_defaults.path = '~/vimwiki/'
let s:vimwiki_defaults.path_html = '~/vimwiki_html/'
let s:vimwiki_defaults.css_name = 'style.css'
let s:vimwiki_defaults.index = 'index'
let s:vimwiki_defaults.ext = '.wiki'
let s:vimwiki_defaults.maxhi = 1
let s:vimwiki_defaults.syntax = 'default'
let s:vimwiki_defaults.gohome = 'split'
let s:vimwiki_defaults.html_header = ''
let s:vimwiki_defaults.html_footer = ''
let s:vimwiki_defaults.nested_syntaxes = {}
"}}}

" DEFAULT options {{{
call s:default('list', [s:vimwiki_defaults])
if &encoding == 'utf-8'
  call s:default('upper', 'A-Z\u0410-\u042f')
  call s:default('lower', 'a-z\u0430-\u044f')
else
  call s:default('upper', 'A-Z')
  call s:default('lower', 'a-z')
endif
call s:default('other', '0-9')
call s:default('stripsym', '_')
call s:default('badsyms', '')
call s:default('auto_checkbox', 1)
call s:default('use_mouse', 0)
call s:default('folding', 1)
call s:default('fold_empty_lines', 0)
call s:default('fold_lists', 1)
call s:default('menu', 'Vimwiki')
call s:default('global_ext', 1)
call s:default('hl_headers', 0)
call s:default('hl_cb_checked', 0)
call s:default('camel_case', 1)
call s:default('list_ignore_newline', 1)
call s:default('listsyms', ' .oOX')
if has("win32")
  call s:default('browsers',
        \ [
        \  expand('~').'\Local Settings\Application Data\Google\Chrome\Application\chrome.exe',
        \  'C:\Program Files\Opera\opera.exe',
        \  'C:\Program Files\Mozilla Firefox\firefox.exe',
        \  'C:\Program Files\Internet Explorer\iexplore.exe',
        \ ])
else
  call s:default('browsers',
        \ [
        \  'opera',
        \  'firefox',
        \  'konqueror',
        \ ])
endif

call s:default('current_idx', 0)

let upp = g:vimwiki_upper
let low = g:vimwiki_lower
let oth = g:vimwiki_other
let nup = low.oth
let nlo = upp.oth
let any = upp.nup

let g:vimwiki_word1 = '\C\<['.upp.']['.nlo.']*['.
      \ low.']['.nup.']*['.upp.']['.any.']*\>'
let g:vimwiki_word2 = '\[\[[^\]]\+\]\]'
let g:vimwiki_word3 = '\[\[[^\]]\+\]\[[^\]]\+\]\]'
if g:vimwiki_camel_case
  let g:vimwiki_rxWikiWord = g:vimwiki_word1.'\|'.g:vimwiki_word2.'\|'.g:vimwiki_word3
else
  let g:vimwiki_rxWikiWord = g:vimwiki_word2.'\|'.g:vimwiki_word3
endif
let g:vimwiki_rxWeblink = '\%("[^"(]\+\((\([^)]\+\))\)\?":\)\?'.
      \'\%(https\?\|ftp\|gopher\|telnet\|file\|notes\|ms-help\):'.
      \'\%(\%(\%(//\)\|\%(\\\\\)\)\+[A-Za-z0-9:#@%/;,$~()_?+=.&\\\-]*\)'
"}}}

" FILETYPE setup for all known wiki extensions {{{
" Getting all extensions that different wikies could have
let extensions = {}
for wiki in g:vimwiki_list
  if has_key(wiki, 'ext')
    let extensions[wiki.ext] = 1
  else
    let extensions['.wiki'] = 1
  endif
endfor

augroup filetypedetect
  " clear FlexWiki's stuff
  au! * *.wiki
augroup end

augroup vimwiki
  autocmd!
  for ext in keys(extensions)
    execute 'autocmd BufEnter *'.ext.' call s:setup_buffer_enter()'
    execute 'autocmd BufLeave,BufHidden *'.ext.' call s:setup_buffer_leave()'

    " ColorScheme could have or could have not a VimwikiHeader1..VimwikiHeader6
    " highlight groups. We need to refresh syntax after colorscheme change.
    execute 'autocmd ColorScheme *'.ext.' call s:setup_colors() | set syntax=vimwiki'
  endfor
augroup END
"}}}

" COMMANDS {{{
command! VimwikiUISelect call vimwiki#WikiUISelect()
command! -count VimwikiGoHome
      \ call vimwiki#WikiGoHome(v:count1)
command! -count VimwikiTabGoHome tabedit <bar>
      \ call vimwiki#WikiGoHome(v:count1)
"}}}

" MAPPINGS {{{
if !hasmapto('<Plug>VimwikiGoHome')
  map <silent><unique> <Leader>ww <Plug>VimwikiGoHome
endif
noremap <unique><script> <Plug>VimwikiGoHome :VimwikiGoHome<CR>

if !hasmapto('<Plug>VimwikiTabGoHome')
  map <silent><unique> <Leader>wt <Plug>VimwikiTabGoHome
endif
noremap <unique><script> <Plug>VimwikiTabGoHome :VimwikiTabGoHome<CR>

if !hasmapto('<Plug>VimwikiUISelect')
  map <silent><unique> <Leader>ws <Plug>VimwikiUISelect
endif
noremap <unique><script> <Plug>VimwikiUISelect :VimwikiUISelect<CR>

"}}}

" MENU {{{
function! s:build_menu(path)
  let idx = 0
  while idx < len(g:vimwiki_list)
    execute 'menu '.a:path.'.'.VimwikiGet('path', idx).
          \ ' :call vimwiki#WikiGoHome('.(idx + 1).')<CR>'
    let idx += 1
  endwhile
endfunction

if !empty(g:vimwiki_menu)
  call s:build_menu(g:vimwiki_menu)
endif
" }}}

let &cpo = s:old_cpo
syntax\vimwiki.vim	[[[1
142
" Vimwiki syntax file
" Author: Maxim Kim <habamax@gmail.com>
" Home: http://code.google.com/p/vimwiki/
" vim:tw=79:

" Quit if syntax file is already loaded
if version < 600
  syntax clear
elseif exists("b:current_syntax")
  finish
endif

"" use max highlighting - could be quite slow if there are too many wikifiles
if VimwikiGet('maxhi')
  " Every WikiWord is nonexistent
  if g:vimwiki_camel_case
    execute 'syntax match VimwikiNoExistsWord /\%(^\|[^!]\)\zs'.g:vimwiki_word1.'/'
  endif
  execute 'syntax match VimwikiNoExistsWord /'.g:vimwiki_word2.'/'
  execute 'syntax match VimwikiNoExistsWord /'.g:vimwiki_word3.'/'
  " till we find them in vimwiki's path
  call vimwiki#WikiHighlightWords()
else
  " A WikiWord (unqualifiedWikiName)
  execute 'syntax match VimwikiWord /\%(^\|[^!]\)\zs\<'.g:vimwiki_word1.'\>/'
  " A [[bracketed wiki word]]
  execute 'syntax match VimwikiWord /'.g:vimwiki_word2.'/'
endif

execute 'syntax match VimwikiLink `'.g:vimwiki_rxWeblink.'`'

" Emoticons: must come after the Textilisms, as later rules take precedence
" over earlier ones. This match is an approximation for the ~70 distinct
syntax match VimwikiEmoticons /\%((.)\|:[()|$@]\|:-[DOPS()\]|$@]\|;)\|:'(\)/

let g:vimwiki_rxTodo = '\C\%(TODO:\|DONE:\|FIXME:\|FIXED:\|XXX:\)'
execute 'syntax match VimwikiTodo /'. g:vimwiki_rxTodo .'/'

" Load concrete Wiki syntax
execute 'runtime! syntax/vimwiki_'.VimwikiGet('syntax').'.vim'

" Tables
execute 'syntax match VimwikiTable /'.g:vimwiki_rxTable.'/'

execute 'syntax match VimwikiBold /'.g:vimwiki_rxBold.'/'

execute 'syntax match VimwikiItalic /'.g:vimwiki_rxItalic.'/'

execute 'syntax match VimwikiBoldItalic /'.g:vimwiki_rxBoldItalic.'/'

execute 'syntax match VimwikiItalicBold /'.g:vimwiki_rxItalicBold.'/'

execute 'syntax match VimwikiDelText /'.g:vimwiki_rxDelText.'/'

execute 'syntax match VimwikiSuperScript /'.g:vimwiki_rxSuperScript.'/'

execute 'syntax match VimwikiSubScript /'.g:vimwiki_rxSubScript.'/'

execute 'syntax match VimwikiCode /'.g:vimwiki_rxCode.'/'

" <hr> horizontal rule
execute 'syntax match VimwikiHR /'.g:vimwiki_rxHR.'/'

" List items
execute 'syntax match VimwikiList /'.g:vimwiki_rxListBullet.'/'
execute 'syntax match VimwikiList /'.g:vimwiki_rxListNumber.'/'
execute 'syntax match VimwikiList /'.g:vimwiki_rxListDefine.'/'

execute 'syntax region VimwikiPre start=/'.g:vimwiki_rxPreStart.
      \ '/ end=/'.g:vimwiki_rxPreEnd.'/ contains=VimwikiComment'

" List item checkbox
syntax match VimwikiCheckBox /\[.\?\]/
if g:vimwiki_hl_cb_checked
  execute 'syntax match VimwikiCheckBoxDone /'.
        \ g:vimwiki_rxListBullet.'\s*\['.g:vimwiki_listsyms[4].'\].*$/'
  execute 'syntax match VimwikiCheckBoxDone /'.
        \ g:vimwiki_rxListNumber.'\s*\['.g:vimwiki_listsyms[4].'\].*$/'
endif

syntax region VimwikiComment start='<!--' end='-->'

if !vimwiki#hl_exists("VimwikiHeader1")
  execute 'syntax match VimwikiHeader /'.g:vimwiki_rxHeader.'/'
else
  " Header levels, 1-6
  execute 'syntax match VimwikiHeader1 /'.g:vimwiki_rxH1.'/'
  execute 'syntax match VimwikiHeader2 /'.g:vimwiki_rxH2.'/'
  execute 'syntax match VimwikiHeader3 /'.g:vimwiki_rxH3.'/'
  execute 'syntax match VimwikiHeader4 /'.g:vimwiki_rxH4.'/'
  execute 'syntax match VimwikiHeader5 /'.g:vimwiki_rxH5.'/'
  execute 'syntax match VimwikiHeader6 /'.g:vimwiki_rxH6.'/'
endif

" group names "{{{
if !vimwiki#hl_exists("VimwikiHeader1")
  hi def link VimwikiHeader Title
else
  hi def link VimwikiHeader1 Title
  hi def link VimwikiHeader2 Title
  hi def link VimwikiHeader3 Title
  hi def link VimwikiHeader4 Title
  hi def link VimwikiHeader5 Title
  hi def link VimwikiHeader6 Title
endif

hi def VimwikiBold term=bold cterm=bold gui=bold
hi def VimwikiItalic term=italic cterm=italic gui=italic
hi def VimwikiBoldItalic term=bold cterm=bold gui=bold,italic
hi def link VimwikiItalicBold VimwikiBoldItalic

hi def link VimwikiCode PreProc
hi def link VimwikiWord Underlined
hi def link VimwikiNoExistsWord Error

hi def link VimwikiPre SpecialComment
hi def link VimwikiLink Underlined
hi def link VimwikiList Function
hi def link VimwikiCheckBox VimwikiList
hi def link VimwikiCheckBoxDone Comment
hi def link VimwikiTable PreProc
hi def link VimwikiEmoticons Character
hi def link VimwikiDelText Constant
hi def link VimwikiSuperScript Number
hi def link VimwikiSubScript Number
hi def link VimwikiTodo Todo
hi def link VimwikiComment Comment
"}}}

let b:current_syntax="vimwiki"

" EMBEDDED syntax setup "{{{
let nested = VimwikiGet('nested_syntaxes')
if !empty(nested)
  for [hl_syntax, vim_syntax] in items(nested)
    call vimwiki#nested_syntax(vim_syntax,
          \ '^{{{\%(.*[[:blank:][:punct:]]\)\?'.
          \ hl_syntax.'\%([[:blank:][:punct:]].*\)\?',
          \ '^}}}', 'VimwikiPre')
  endfor
endif
"}}}
syntax\vimwiki_default.vim	[[[1
76
" Vimwiki syntax file
" Default syntax
" Author: Maxim Kim <habamax@gmail.com>
" Home: http://code.google.com/p/vimwiki/
" vim:tw=78:

" text: *strong*
" let g:vimwiki_rxBold = '\*[^*]\+\*'
let g:vimwiki_rxBold = '\%(^\|\s\|[[:punct:]]\)\@<='.
      \'\*'.
      \'\([^*`[:space:]][^*`]*[^*`[:space:]]\|[^*`]\)'.
      \'\*'.
      \'\%([[:punct:]]\|\s\|$\)\@='

" text: _emphasis_
" let g:vimwiki_rxItalic = '_[^_]\+_'
let g:vimwiki_rxItalic = '\%(^\|\s\|[[:punct:]]\)\@<='.
      \'_'.
      \'\([^_`[:space:]][^_`]*[^_`[:space:]]\|[^_`]\)'.
      \'_'.
      \'\%([[:punct:]]\|\s\|$\)\@='

" text: *_bold italic_* or _*italic bold*_
let g:vimwiki_rxBoldItalic = '\%(^\|\s\|[[:punct:]]\)\@<='.
      \'\*_'.
      \'\([^*_`[:space:]][^*_`]*[^*_`[:space:]]\|[^*_`]\)'.
      \'_\*'.
      \'\%([[:punct:]]\|\s\|$\)\@='

let g:vimwiki_rxItalicBold = '\%(^\|\s\|[[:punct:]]\)\@<='.
      \'_\*'.
      \'\([^*_`[:space:]][^*_`]*[^*_`[:space:]]\|[^*_`]\)'.
      \'\*_'.
      \'\%([[:punct:]]\|\s\|$\)\@='

" text: `code`
let g:vimwiki_rxCode = '`[^`]\+`'

" text: ~~deleted text~~
let g:vimwiki_rxDelText = '\~\~[^~`]\+\~\~'

" text: ^superscript^
let g:vimwiki_rxSuperScript = '\^[^^`]\+\^'

" text: ,,subscript,,
let g:vimwiki_rxSubScript = ',,[^,`]\+,,'

" Header levels, 1-6
let g:vimwiki_rxH1 = '^\s*=\{1}[^=]\+.*[^=]\+=\{1}\s*$'
let g:vimwiki_rxH2 = '^\s*=\{2}[^=]\+.*[^=]\+=\{2}\s*$'
let g:vimwiki_rxH3 = '^\s*=\{3}[^=]\+.*[^=]\+=\{3}\s*$'
let g:vimwiki_rxH4 = '^\s*=\{4}[^=]\+.*[^=]\+=\{4}\s*$'
let g:vimwiki_rxH5 = '^\s*=\{5}[^=]\+.*[^=]\+=\{5}\s*$'
let g:vimwiki_rxH6 = '^\s*=\{6}[^=]\+.*[^=]\+=\{6}\s*$'
let g:vimwiki_rxHeader = '\%('.g:vimwiki_rxH1.'\)\|'.
      \ '\%('.g:vimwiki_rxH2.'\)\|'.
      \ '\%('.g:vimwiki_rxH3.'\)\|'.
      \ '\%('.g:vimwiki_rxH4.'\)\|'.
      \ '\%('.g:vimwiki_rxH5.'\)\|'.
      \ '\%('.g:vimwiki_rxH6.'\)'

" <hr>, horizontal rule
let g:vimwiki_rxHR = '^----.*$'

" Tables. Each line starts and ends with '||'; each cell is separated by '||'
let g:vimwiki_rxTable = '||'

" List items start with whitespace(s) then '*' or '#'
let g:vimwiki_rxListBullet = '^\s\+\*'
let g:vimwiki_rxListNumber = '^\s\+#'

let g:vimwiki_rxListDefine = '::\(\s\|$\)'

" Preformatted text
let g:vimwiki_rxPreStart = '{{{'
let g:vimwiki_rxPreEnd = '}}}'
syntax\vimwiki_media.vim	[[[1
58
" Vimwiki syntax file
" MediaWiki syntax
" Author: Maxim Kim <habamax@gmail.com>
" Home: http://code.google.com/p/vimwiki/
" vim:tw=78:

" text: '''strong'''
let g:vimwiki_rxBold = "'''[^']\\+'''"

" text: ''emphasis''
let g:vimwiki_rxItalic = "''[^']\\+''"

" text: '''''strong italic'''''
let g:vimwiki_rxBoldItalic = "'''''[^']\\+'''''"
let g:vimwiki_rxItalicBold = g:vimwiki_rxBoldItalic

" text: `code`
let g:vimwiki_rxCode = '`[^`]\+`'

" text: ~~deleted text~~
let g:vimwiki_rxDelText = '\~\~[^~]\+\~\~'

" text: ^superscript^
let g:vimwiki_rxSuperScript = '\^[^^]\+\^'

" text: ,,subscript,,
let g:vimwiki_rxSubScript = ',,[^,]\+,,'

" Header levels, 1-6
let g:vimwiki_rxH1 = '^\s*=\{1}[^=]\+.*[^=]\+=\{1}\s*$'
let g:vimwiki_rxH2 = '^\s*=\{2}[^=]\+.*[^=]\+=\{2}\s*$'
let g:vimwiki_rxH3 = '^\s*=\{3}[^=]\+.*[^=]\+=\{3}\s*$'
let g:vimwiki_rxH4 = '^\s*=\{4}[^=]\+.*[^=]\+=\{4}\s*$'
let g:vimwiki_rxH5 = '^\s*=\{5}[^=]\+.*[^=]\+=\{5}\s*$'
let g:vimwiki_rxH6 = '^\s*=\{6}[^=]\+.*[^=]\+=\{6}\s*$'
let g:vimwiki_rxHeader = '\%('.g:vimwiki_rxH1.'\)\|'.
      \ '\%('.g:vimwiki_rxH2.'\)\|'.
      \ '\%('.g:vimwiki_rxH3.'\)\|'.
      \ '\%('.g:vimwiki_rxH4.'\)\|'.
      \ '\%('.g:vimwiki_rxH5.'\)\|'.
      \ '\%('.g:vimwiki_rxH6.'\)'

" <hr>, horizontal rule
let g:vimwiki_rxHR = '^----.*$'

" Tables. Each line starts and ends with '||'; each cell is separated by '||'
let g:vimwiki_rxTable = '||'

" Bulleted list items start with whitespace(s), then '*'
" highlight only bullets and digits.
let g:vimwiki_rxListBullet = '^\s*\*\+\([^*]*$\)\@='
let g:vimwiki_rxListNumber = '^\s*#\+'

let g:vimwiki_rxListDefine = '^\%(;\|:\)\s'

" Preformatted text
let g:vimwiki_rxPreStart = '<pre>'
let g:vimwiki_rxPreEnd = '<\/pre>'
