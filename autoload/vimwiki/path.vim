" vim:tabstop=2:shiftwidth=2:expandtab:textwidth=99
" Vimwiki autoload plugin file
" Description: Path manipulation functions
" Home: https://github.com/vimwiki/vimwiki/


<<<<<<< HEAD

" Unixify path
function! s:unixify(path) abort
    return substitute(a:path, '\', '/', 'g')
endfunction


" Windowsify path
function! s:windowsify(path) abort
    return substitute(a:path, '/', '\', 'g')
endfunction


" Define os specific path convertion
if vimwiki#u#is_windows()
  function! s:osxify(path) abort
    return s:windowsify(a:path)
  endfunction
else
  function! s:osxify(path) abort
    return s:unixify(a:path)
  endfunction
endif


" Remove last path delimitator (slash or backslash)
=======
>>>>>>> Bump version number – release 2.5
function! vimwiki#path#chomp_slash(str) abort
  return substitute(a:str, '[/\\]\+$', '', '')
endfunction


<<<<<<< HEAD
" Define: path-compare function, either case-sensitive or not, depending on OS.
=======
" Define path-compare function, either case-sensitive or not, depending on OS.
>>>>>>> Bump version number – release 2.5
if vimwiki#u#is_windows()
  function! vimwiki#path#is_equal(p1, p2) abort
    return a:p1 ==? a:p2
  endfunction
else
  function! vimwiki#path#is_equal(p1, p2) abort
    return a:p1 ==# a:p2
  endfunction
endif

<<<<<<< HEAD

" Collapse sections like /a/b/../c to /a/c and /a/b/./c to /a/b/c
=======
" collapse sections like /a/b/../c to /a/c and /a/b/./c to /a/b/c
>>>>>>> Bump version number – release 2.5
function! vimwiki#path#normalize(path) abort
  let path = a:path
  while 1
    let intermediateResult = substitute(path, '/[^/]\+/\.\.', '', '')
    let result = substitute(intermediateResult, '/\./', '/', '')
    if result ==# path
      break
    endif
    let path = result
  endwhile
  return result
endfunction


<<<<<<< HEAD
" Normalize path: \ -> / &&  /// -> / && resolve(symlinks)
function! vimwiki#path#path_norm(path) abort
  " return if scp
  if a:path =~# '^scp:' | return a:path | endif
  " convert backslash to slash
  let path = substitute(a:path, '\', '/', 'g')
  " treat multiple consecutive slashes as one path separator
  let path = substitute(path, '/\+', '/', 'g')
  " ensure that we are not fooled by a symbolic link
  return resolve(path)
endfunction


" Check if link is to a directory
function! vimwiki#path#is_link_to_dir(link) abort
=======
function! vimwiki#path#path_norm(path) abort
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
endfunction


function! vimwiki#path#is_link_to_dir(link) abort
  " Check if link is to a directory.
>>>>>>> Bump version number – release 2.5
  " It should be ended with \ or /.
  return a:link =~# '\m[/\\]$'
endfunction


<<<<<<< HEAD
" Get absolute path <- path relative to current file
=======
>>>>>>> Bump version number – release 2.5
function! vimwiki#path#abs_path_of_link(link) abort
  return vimwiki#path#normalize(expand('%:p:h').'/'.a:link)
endfunction


<<<<<<< HEAD
" Returns: longest common path prefix of 2 given paths.
" Ex: '~/home/usrname/wiki', '~/home/usrname/wiki/shmiki' => '~/home/usrname/wiki'
=======
" return longest common path prefix of 2 given paths.
" '~/home/usrname/wiki', '~/home/usrname/wiki/shmiki' => '~/home/usrname/wiki'
>>>>>>> Bump version number – release 2.5
function! vimwiki#path#path_common_pfx(path1, path2) abort
  let p1 = split(a:path1, '[/\\]', 1)
  let p2 = split(a:path2, '[/\\]', 1)

  let idx = 0
  let minlen = min([len(p1), len(p2)])
  while (idx < minlen) && vimwiki#path#is_equal(p1[idx], p2[idx])
    let idx = idx + 1
  endwhile
  if idx == 0
    return ''
  else
    return join(p1[: idx-1], '/')
  endif
endfunction


<<<<<<< HEAD
" Convert path -> full resolved slashed path
=======
>>>>>>> Bump version number – release 2.5
function! vimwiki#path#wikify_path(path) abort
  let result = resolve(fnamemodify(a:path, ':p'))
  if vimwiki#u#is_windows()
    let result = substitute(result, '\\', '/', 'g')
  endif
  let result = vimwiki#path#chomp_slash(result)
  return result
endfunction


<<<<<<< HEAD
" Return: Current file path relative
=======
>>>>>>> Bump version number – release 2.5
function! vimwiki#path#current_wiki_file() abort
  return vimwiki#path#wikify_path(expand('%:p'))
endfunction


<<<<<<< HEAD
" Return: the relative path from a:dir to a:file
=======
" Returns: the relative path from a:dir to a:file
>>>>>>> Bump version number – release 2.5
function! vimwiki#path#relpath(dir, file) abort
  " Check if dir here ('.') -> return file
  if empty(a:dir) || a:dir =~# '^\.[/\\]\?$'
    return a:file
  endif
<<<<<<< HEAD
  " Unixify && Expand in
  let s_dir = expand(s:unixify(a:dir))
  let s_file = expand(s:unixify(a:file))

  " Split path
  let dir = split(s_dir, '/')
  let file = split(s_file, '/')

  " Shorten loop till equality
=======
  let result = []
  if vimwiki#u#is_windows()
    " TODO temporary fix see #478
    " not sure why paths get converted back to using forward slash
    " when passed to the function in the form C:\path\to\file
    let dir = substitute(a:dir, '/', '\', 'g')
    let file = substitute(a:file, '/', '\', 'g')
    let dir = split(dir, '\')
    let file = split(file, '\')
  else
    let dir = split(a:dir, '/')
    let file = split(a:file, '/')
  endif
>>>>>>> Bump version number – release 2.5
  while (len(dir) > 0 && len(file) > 0) && vimwiki#path#is_equal(dir[0], file[0])
    call remove(dir, 0)
    call remove(file, 0)
  endwhile
<<<<<<< HEAD

  " Return './' if nothing left
  if empty(dir) && empty(file)
    return s:osxify('./')
  endif

  " Build path segment
  let segments = []
  for segment in dir
    let segments += ['..']
  endfor
  for segment in file
    let segments += [segment]
  endfor

  " Join segments
  let result_path = join(segments, '/')
  if a:file =~# '\m/$'
    let result_path .= '/'
  endif

  return s:osxify(result_path)
endfunction


" Mkdir:
=======
  if empty(dir) && empty(file)
    if vimwiki#u#is_windows()
      " TODO temporary fix see #478
      return '.\'
    else
      return './'
    endif
  endif
  for segment in dir
    let result += ['..']
  endfor
  for segment in file
    let result += [segment]
  endfor
  if vimwiki#u#is_windows()
    " TODO temporary fix see #478
    let result_path = join(result, '\')
    if a:file =~? '\m\\$'
      let result_path .= '\'
    endif
  else
    let result_path = join(result, '/')
    if a:file =~? '\m/$'
      let result_path .= '/'
    endif
  endif
  return result_path
endfunction


>>>>>>> Bump version number – release 2.5
" If the optional argument provided and nonzero,
" it will ask before creating a directory
" Returns: 1 iff directory exists or successfully created
function! vimwiki#path#mkdir(path, ...) abort
  let path = expand(a:path)

  if path =~# '^scp:'
    " we can not do much, so let's pretend everything is ok
    return 1
  endif

  if isdirectory(path)
    return 1
  else
    if !exists('*mkdir')
      return 0
    endif

    let path = vimwiki#path#chomp_slash(path)
    if vimwiki#u#is_windows() && !empty(vimwiki#vars#get_global('w32_dir_enc'))
      let path = iconv(path, &encoding, vimwiki#vars#get_global('w32_dir_enc'))
    endif

    if a:0 && a:1 && input('Vimwiki: Make new directory: '.path."\n [y]es/[N]o? ") !~? '^y'
      return 0
    endif

    call mkdir(path, 'p')
    return 1
  endif
endfunction


<<<<<<< HEAD
" Check: if path is absolute
=======
>>>>>>> Bump version number – release 2.5
function! vimwiki#path#is_absolute(path) abort
  if vimwiki#u#is_windows()
    return a:path =~? '\m^\a:'
  else
    return a:path =~# '\m^/\|\~/'
  endif
endfunction


<<<<<<< HEAD
" Combine: a directory and a file into one path, doesn't generate duplicate
=======
" Combine a directory and a file into one path, doesn't generate duplicate
>>>>>>> Bump version number – release 2.5
" path separator in case the directory is also having an ending / or \. This
" is because on windows ~\vimwiki//.tags is invalid but ~\vimwiki/.tags is a
" valid path.
if vimwiki#u#is_windows()
  function! vimwiki#path#join_path(directory, file) abort
    let directory = vimwiki#path#chomp_slash(a:directory)
    let file = substitute(a:file, '\m^[\\/]\+', '', '')
    return directory . '/' . file
  endfunction
else
  function! vimwiki#path#join_path(directory, file) abort
    let directory = substitute(a:directory, '\m/\+$', '', '')
    let file = substitute(a:file, '\m^/\+', '', '')
    return directory . '/' . file
  endfunction
endif
<<<<<<< HEAD
=======

>>>>>>> Bump version number – release 2.5
