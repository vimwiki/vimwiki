" vim:tabstop=2:shiftwidth=2:expandtab:textwidth=99
" Vimwiki autoload plugin file
" Description: Utility functions
" Home: https://github.com/vimwiki/vimwiki/

function! vimwiki#u#trim(string, ...)
  let chars = ''
  if a:0 > 0
    let chars = a:1
  endif
  let res = substitute(a:string, '^[[:space:]'.chars.']\+', '', '')
  let res = substitute(res, '[[:space:]'.chars.']\+$', '', '')
  return res
endfunction


" Builtin cursor doesn't work right with unicode characters.
function! vimwiki#u#cursor(lnum, cnum)
  exe a:lnum
  exe 'normal! 0'.a:cnum.'|'
endfunction


function! vimwiki#u#is_windows()
  return has("win32") || has("win64") || has("win95") || has("win16")
endfunction


function! vimwiki#u#is_macos()
  if has("mac") || has("macunix") || has("gui_mac")
    return 1
  endif
  " that still doesn't mean we are not on Mac OS
  let os = substitute(system('uname'), '\n', '', '')
  return os == 'Darwin' || os == 'Mac'
endfunction


function! vimwiki#u#count_first_sym(line)
  let first_sym = matchstr(a:line, '\S')
  return len(matchstr(a:line, first_sym.'\+'))
endfunction


function! vimwiki#u#escape(string)
  return escape(a:string, '~.*[]\^$')
endfunction


" Load concrete Wiki syntax: sets regexes and templates for headers and links
function vimwiki#u#reload_regexes()
  execute 'runtime! syntax/vimwiki_'.vimwiki#vars#get_wikilocal('syntax').'.vim'
endfunction


" Load syntax-specific functionality
function vimwiki#u#reload_regexes_custom()
  execute 'runtime! syntax/vimwiki_'.vimwiki#vars#get_wikilocal('syntax').'_custom.vim'
endfunction


" Backward compatible version of the built-in function shiftwidth()
if exists('*shiftwidth')
  func vimwiki#u#sw()
    return shiftwidth()
  endfunc
else
  func vimwiki#u#sw()
    return &sw
  endfunc
endif


" Sets the filetype to vimwiki
" If g:vimwiki_filetypes variable is set
" the filetype will be vimwiki.<ft1>.<ft2> etc.
function! vimwiki#u#ft_set()
  let ftypelist = vimwiki#vars#get_global('filetypes')
  let ftype = 'vimwiki'
  for ftypeadd in ftypelist
    let ftype = ftype . '.' . ftypeadd
  endfor
  let &filetype = ftype
endfunction


" Returns: 1 if filetype is vimwiki, 0 else
" If multiple fileytpes are in use 1 is returned only if the
" first ft is vimwiki which should always be the case unless
" the user manually changes it to something else
function! vimwiki#u#ft_is_vw()
  if split(&filetype, '\.')[0] ==? 'vimwiki'
    return 1
  else
    return 0
  endif
endfunction
