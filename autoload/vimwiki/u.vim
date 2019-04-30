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

" a:mode single character indicating the mode as defined by :h maparg
" a:key the key sequence to map
" a:plug the plug command the key sequence should be mapped to
" a:1 optional argument with the following functionality:
"   if a:1==1 then the hasmapto(<Plug>) check is skipped.
"     this can be used to map different keys to the same <Plug> definition
"   if a:1==2 then the mapping is not <buffer> specific
" This function maps a key sequence to a <Plug> command using the arguments
" described above. If there is already a mapping to the <Plug> command or
" the assigned keys are already mapped then nothing is done.
function vimwiki#u#map_key(mode, key, plug, ...)
  if a:0 && a:1 == 2
    let l:bo = ''
  else
    let l:bo = '<buffer> '
  endif

  if a:0 && a:1 == 1
    if maparg(a:key, a:mode) ==# ''
      exe a:mode . 'map ' . l:bo . a:key . ' ' . a:plug
    endif
  else
    if !hasmapto(a:plug) && maparg(a:key, a:mode) ==# ''
      exe a:mode . 'map ' . l:bo . a:key . ' ' . a:plug
    endif
  endif
endfunction
