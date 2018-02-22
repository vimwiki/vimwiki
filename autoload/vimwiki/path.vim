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
  let result = resolve(expand(a:path, ':p'))
  if vimwiki#u#is_windows()
    let result = substitute(result, '\\', '/', 'g')
  endif
  let result = vimwiki#path#chomp_slash(result)
  return result
endfunction "}}}

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
function! vimwiki#path#mkdir(dir_obj, ...) "{{{

  if a:dir_obj.protocoll ==# 'scp'
    " we can not do much, so let's pretend everything is ok
    return 1
  endif

  if vimwiki#path#exists(a:dir_obj)
    return 1
  else
    if !exists("*mkdir")
      return 0
    endif

    let path = vimwiki#path#to_string(a:dir_obj)
    if vimwiki#u#is_windows() && !empty(vimwiki#vars#get_global('w32_dir_enc'))
      let path = iconv(path, &enc, vimwiki#vars#get_global('w32_dir_enc'))
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


"----------------------------------------------------------
" Path manipulation, i.e. functions which do stuff with the paths of (not necessarily existing) files
"----------------------------------------------------------


" The used data types are
"
" - directory object:
"    - used for an absolute path to a directory
"    - internally, it is a dictionary with the following entries:
"      - 'protocoll' -- how to access the file. Supported are 'scp' or 'file'
"      - 'is_unix' -- 1 if it's supposed to be a unix-like path
"      - 'path' -- a list containing the directory names starting at the root
" - file object:
"    - for an absolute path to a file
"    - internally a list [dir_obj, file name]
" - file segment:
"    - for a relative path to a file or a part of an absolute path
"    - internally a list where the first element is a list of directory names and the second the
"      file name
" - directory segment:
"    - for a relative path to a directory or a part of an absolute path
"    - internally a list of directory names


" create and return a file object from a string. It is assumed that the given
" path is absolute and points to a file (not a directory)
function! vimwiki#path#file_obj(filepath)
  let filename = fnamemodify(a:filepath, ':p:t')
  let path = fnamemodify(a:filepath, ':p:h')
  return [vimwiki#path#dir_obj(path), filename]
endfunction


" create and return a dir object from a string. The given path should be
" absolute and point to a directory.
function! vimwiki#path#dir_obj(dirpath)
  if a:dirpath =~# '^scp:'
    let dirpath = a:dirpath[4:]
    let protocoll = 'scp'
  else
    let dirpath = resolve(a:dirpath)
    let protocoll = 'file'
  endif
  let path = split(vimwiki#path#chomp_slash(dirpath), '\m[/\\]', 1)
  let is_unix = dirpath[0] ==# '/'
  let result = {
    \ 'is_unix' : is_unix,
    \ 'protocoll' : protocoll,
    \ 'path' : path,
    \}
  return result
endfunction


" Assume it is not an absolute path
function! vimwiki#path#file_segment(path_segment)
  let filename = fnamemodify(a:path_segment, ':t')
  let path = fnamemodify(a:path_segment, ':h')
  let path_list = (path ==# '.' ? [] : split(path, '\m[/\\]', 1))
  return [path_list, filename]
endfunction


" Assume it is not an absolute path
function! vimwiki#path#dir_segment(path_segment)
  return split(a:path_segment, '\m[/\\]', 1)
endfunction


function! vimwiki#path#extension(file_object)
  return fnamemodify(a:file_object[1], ':e')
endfunction


" Returns: the dir of the file object as dir object
function! vimwiki#path#directory_of_file(file_object)
  return copy(a:file_object[0])
endfunction


" Returns: the file_obj's file name as a string
function! vimwiki#path#filename(file_object)
  return a:file_object[1]
endfunction


" Returns: the dir_obj, file_obj, file segment or dir segment as string, ready
" to be used with the regular path handling functions in Vim
function! vimwiki#path#to_string(obj)
  if type(a:obj) == 4   " dir object
    let separator = a:obj.is_unix ? '/' : '\'
    let address = join(dir_obj.path, separator) . separator
    return address
  elseif type(a:obj[0]) == 4  " file object
    let dir_obj = type(a:obj) == 4 ? a:obj : a:obj[0]
    let separator = a:obj[0].is_unix ? '/' : '\'
    let address = join(a:obj[0].path, separator) . separator . a:obj[1]
    return address
  elseif type(a:obj[0]) == 3  " file segment
    " XXX: what about the separator?
    return join(a:obj[0], '/') . '/' . a:obj[1]
  elseif type(a:obj[0]) == 1  " directory segment
    return join(a:obj, '/') . '/'
  else
    call vimwiki#u#error('Invalid argument ' . string(a:obj))
  endif
endfunction


" Returns: the given a:dir_obj with a:str appended to the dir name
function! vimwiki#path#append_to_dirname(dir_obj, str)
  let a:dir_obj.path[-1] .= a:str
  return a:dir_obj
endfunction


" Returns a file object made from a dir object plus a file semgent
function! vimwiki#path#join(dir_obje, file_segment)
  let new_dir_object = copy(a:dir_obj)
  let new_dir_object.path += a:file_segment[0]
  return [new_dir_object, a:file_segment[1]]
endfunction


" Returns a dir object made from a dir object plus a dir semgent
function! vimwiki#path#join_dir(dir_path, dir_segment)
  let new_dir_object = copy(a:dir_path)
  let new_dir_object.path += a:dir_segment
  return new_dir_object
endfunction


" returns the file segment fs, so that join(dir, fs) == file
" we just assume the file is somewhere in dir
function! vimwiki#path#subtract(dir_object, file_object)
  let path_rest = a:file_object[0].path[len(a:dir_object.path):]
  return [path_rest, file_object[1]]
endfunction


" Returns: the relative path from a:dir to a:file
function! vimwiki#path#relpath(dir1_object, dir2_object)
  let dir1_path = copy(a:dir1_object.path)
  let dir2_path = copy(a:dir2_object.path)
  let result_path = []
  while (len(dir) > 0 && len(file) > 0) && vimwiki#path#is_equal(dir1_path[0], dir2_path[0])
    call remove(dir1_path, 0)
    call remove(dir2_path, 0)
  endwhile
  for segment in dir1_path
    let result += ['..']
  endfor
  for segment in dir2_path
    let result += [segment]
  endfor
  let result = {
    \ 'is_unix' : a:dir1_object.is_unix,
    \ 'protocoll' : a:dir1_object.protocoll,
    \ 'path' : result_path,
    \}
  return result
endfunction


"-----------------
" File manipulation, i.e. do stuff with actually existing files
"-----------------


function! vimwiki#path#current_file()
  return vimwiki#path#file_obj(expand('%:p'))
endfunction

function! vimwiki#path#exists(object)
  if type(a:object) == 4
    return isdirectory(vimwiki#path#to_string(a:object))
  else
    " glob() checks whether or not a file exists (readable or writable)
    return glob(vimwiki#path#to_string(a:object)) != ''
  endif
endfunction

" this must be outside a function, because only outside a function <sfile> expands
" to the directory where this file is in
let s:vimwiki_autoload_dir = expand('<sfile>:p:h')

function! vimwiki#path#find_autoload_file(filename)
  let autoload_dir = vimwiki#path#dir_obj(s:vimwiki_autoload_dir)
  let filename_obj = vimwiki#path#file_segment(a:filename)
  let file = vimwiki#path#join(autoload_dir, filename_obj)
  if !vimwiki#path#exists(file)
    echom 'Vimwiki Error: ' . vimwiki#path#to_string(file) . ' not found'
  endif
  return file
endfunction

function! vimwiki#path#copy_file(file_obj, dir_obj)
  call vimwiki#path#mkdir(a:dir_obj)
  let new_file = deepcopy(a:file_obj)
  let new_file[0] = copy(a:dir_obj)
  let lines = readfile(vimwiki#path#to_string(a:file_obj))
  let ok = writefile(lines, vimwiki#path#to_string(new_file))
  if ok < 0
    call vimwiki#u#error('Could not write ' . vimwiki#path#to_string(new_file))
  endif
endfunction

" Returns: a list of all files somewhere in a:dir_obj with extension a:ext
function! vimwiki#path#files_in_dir_recursive(dir_obj, ext)
  let htmlfiles = split(glob(a:path.'**/*.html'), '\n')
endfunction
