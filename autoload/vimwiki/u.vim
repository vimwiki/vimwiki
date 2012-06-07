" vim:tabstop=2:shiftwidth=2:expandtab:foldmethod=marker:textwidth=79
" Vimwiki autoload plugin file
" Utility functions
" Author: Maxim Kim <habamax@gmail.com>
" Home: http://code.google.com/p/vimwiki/

function! vimwiki#u#trim(string, ...) "{{{
  let chars = ''
  if a:0 > 0
    let chars = a:1
  endif
  let res = substitute(a:string, '^[[:space:]'.chars.']\+', '', '')
  let res = substitute(res, '[[:space:]'.chars.']\+$', '', '')
  return res
endfunction "}}}


" Builtin cursor doesn't work right with unicode characters.
function! vimwiki#u#cursor(lnum, cnum) "{{{
  exe a:lnum
  exe 'normal! 0'.a:cnum.'|'
endfunction "}}}

function! vimwiki#u#is_windows() "{{{
  return has("win32") || has("win64") || has("win95") || has("win16")
endfunction "}}}

function! vimwiki#u#chomp_slash(str) "{{{
  return substitute(a:str, '[/\\]\+$', '', '')
endfunction "}}}

function! vimwiki#u#time(starttime) "{{{
  " measure the elapsed time and cut away miliseconds and smaller
  return matchstr(reltimestr(reltime(a:starttime)),'\d\+\(\.\d\d\)\=')
endfunction "}}}

function! vimwiki#u#path_norm(path) "{{{
  " /-slashes
  let path = substitute(a:path, '\', '/', 'g')
  " treat multiple consecutive slashes as one path separator
  let path = substitute(path, '/\+', '/', 'g')
  " ensure that we are not fooled by a symbolic link
  return resolve(path)
endfunction "}}}

function! vimwiki#u#is_link_to_dir(link) "{{{
  " Check if link is to a directory.
  " It should be ended with \ or /.
  if a:link =~ '.\+[/\\]$'
    return 1
  endif
  return 0
endfunction " }}}

function! vimwiki#u#count_first_sym(line) "{{{
  let first_sym = matchstr(a:line, '\S')
  return len(matchstr(a:line, first_sym.'\+'))
endfunction "}}}

" return longest common path prefix of 2 given paths.
" '~/home/usrname/wiki', '~/home/usrname/wiki/shmiki' => '~/home/usrname/wiki'
function! vimwiki#u#path_common_pfx(path1, path2) "{{{
  let p1 = split(a:path1, '[/\\]', 1)
  let p2 = split(a:path2, '[/\\]', 1)

  let idx = 0
  let minlen = min([len(p1), len(p2)])
  while (idx < minlen) && (p1[idx] ==? p2[idx])
    let idx = idx + 1
  endwhile
  if idx == 0
    return ''
  else
    return join(p1[: idx-1], '/')
  endif
endfunction "}}}

