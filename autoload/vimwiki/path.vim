" vim:tabstop=2:shiftwidth=2:expandtab:foldmethod=marker:textwidth=79
" Vimwiki autoload plugin file
" Desc: Path manipulation functions
" Home: https://github.com/vimwiki/vimwiki/


function! vimwiki#path#chomp_slash(str) "{{{
  return substitute(a:str, '[/\\]\+$', '', '')
endfunction "}}}

" Define path-compare function, either case-sensitive or not, depending on OS.
"{{{ " function! vimwiki#path#is_equal(p1, p2)
if vimwiki#u#is_windows()
  function! vimwiki#path#is_equal(p1, p2)
    return a:p1 ==? a:p2
  endfunction
else
  function! vimwiki#path#is_equal(p1, p2)
    return a:p1 ==# a:p2
  endfunction
endif "}}}

" collapse sections like /a/b/../c to /a/c
function! vimwiki#path#normalize(path) "{{{
  let path = a:path
  while 1
    let result = substitute(path, '/[^/]\+/\.\.', '', '')
    if result ==# path
      break
    endif
    let path = result
  endwhile
  return result
endfunction "}}}

function! vimwiki#path#path_norm(path) "{{{
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

function! vimwiki#path#is_link_to_dir(link) "{{{
  " Check if link is to a directory.
  " It should be ended with \ or /.
  return a:link =~# '\m[/\\]$'
endfunction "}}}

function! vimwiki#path#abs_path_of_link(link) "{{{
  return vimwiki#path#normalize(expand("%:p:h").'/'.a:link)
endfunction "}}}

" return longest common path prefix of 2 given paths.
" '~/home/usrname/wiki', '~/home/usrname/wiki/shmiki' => '~/home/usrname/wiki'
function! vimwiki#path#path_common_pfx(path1, path2) "{{{
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
endfunction "}}}

function! vimwiki#path#wikify_path(path) "{{{
  let result = resolve(fnamemodify(a:path, ':p'))
  if vimwiki#u#is_windows()
    let result = substitute(result, '\\', '/', 'g')
  endif
  let result = vimwiki#path#chomp_slash(result)
  return result
endfunction "}}}


function! vimwiki#path#current_wiki_file()
  return vimwiki#path#wikify_path(expand('%:p'))
endfunction


" Returns: the relative path from a:dir to a:file
function! vimwiki#path#relpath(dir, file) "{{{
  let result = []
  let dir = split(a:dir, '/')
  let file = split(a:file, '/')
  while (len(dir) > 0 && len(file) > 0) && vimwiki#path#is_equal(dir[0], file[0])
    call remove(dir, 0)
    call remove(file, 0)
  endwhile
  if empty(dir) && empty(file)
    return './'
  endif
  for segment in dir
    let result += ['..']
  endfor
  for segment in file
    let result += [segment]
  endfor
  let result_path = join(result, '/')
  if a:file =~ '\m/$'
    let result_path .= '/'
  endif
  return result_path
endfunction "}}}

" If the optional argument provided and nonzero,
" it will ask before creating a directory 
" Returns: 1 iff directory exists or successfully created
function! vimwiki#path#mkdir(path, ...) "{{{
  let path = expand(a:path)

  if path =~# '^scp:'
    " we can not do much, so let's pretend everything is ok
    return 1
  endif

  if isdirectory(path)
    return 1
  else
    if !exists("*mkdir")
      return 0
    endif

    let path = vimwiki#path#chomp_slash(path)
    if vimwiki#u#is_windows() && !empty(g:vimwiki_w32_dir_enc)
      let path = iconv(path, &enc, g:vimwiki_w32_dir_enc)
    endif

    if a:0 && a:1 && input("Vimwiki: Make new directory: "
          \ .path."\n [y]es/[N]o? ") !~? '^y'
      return 0
    endif

    call mkdir(path, "p")
    return 1
  endif
endfunction " }}}

function! vimwiki#path#is_absolute(path) "{{{
  if vimwiki#u#is_windows()
    return a:path =~? '\m^\a:'
  else
    return a:path =~# '\m^/\|\~/'
  endif
endfunction "}}}


" Combine a directory and a file into one path, doesn't generate duplicate
" path separator in case the directory is also having an ending / or \. This
" is because on windows ~\vimwiki//.tags is invalid but ~\vimwiki/.tags is a
" valid path.
if vimwiki#u#is_windows()
  function! vimwiki#path#join_path(directory, file)
    let directory = vimwiki#path#chomp_slash(a:directory)
    let file = substitute(a:file, '\m^[\\/]\+', '', '')
    return directory . '/' . file
  endfunction
else
  function! vimwiki#path#join_path(directory, file)
    let directory = substitute(a:directory, '\m/\+$', '', '')
    let file = substitute(a:file, '\m^/\+', '', '')
    return directory . '/' . file
  endfunction
endif
