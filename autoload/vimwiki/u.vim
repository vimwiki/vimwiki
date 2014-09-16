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
  if a:path !~# '^scp:'
    let path = substitute(a:path, '\', '/', 'g')
    " treat multiple consecutive slashes as one path separator
    let path = substitute(path, '/\+', '/', 'g')
    " ensure that we are not fooled by a symbolic link
    return resolve(path)
  else
    return a:path
  endif
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

function! vimwiki#u#escape(string) "{{{
  return escape(a:string, '.*[]\^$')
endfunction "}}}

function! vimwiki#u#wikify_path(path) "{{{
  let result = resolve(expand(a:path, ':p'))
  if vimwiki#u#is_windows()
    let result = substitute(result, '\\', '/', 'g')
  endif
  let result = vimwiki#u#chomp_slash(result)
  return result
endfunction "}}}

" Returns: the relative path from a:dir to a:file
function! vimwiki#u#relpath(dir, file) "{{{
  let result = []
  let dir = split(a:dir, '/')
  let file = split(a:file, '/')
  while (len(dir) > 0 && len(file) > 0) && dir[0] == file[0]
    call remove(dir, 0)
    call remove(file, 0)
  endwhile
  for segment in dir
    let result += ['..']
  endfor
  for segment in file
    let result += [segment]
  endfor
  return join(result, '/')
endfunction "}}}

" Load concrete Wiki syntax: sets regexes and templates for headers and links
function vimwiki#u#reload_regexes() "{{{
  execute 'runtime! syntax/vimwiki_'.VimwikiGet('syntax').'.vim'
endfunction "}}}

" Load syntax-specific functionality
function vimwiki#u#reload_regexes_custom() "{{{
  execute 'runtime! syntax/vimwiki_'.VimwikiGet('syntax').'_custom.vim'
endfunction "}}}
