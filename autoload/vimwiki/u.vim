" vim:tabstop=2:shiftwidth=2:expandtab:foldmethod=marker:textwidth=79
" Vimwiki autoload plugin file
" Desc: Utility functions
" Home: https://github.com/vimwiki/vimwiki/

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

function! vimwiki#u#is_macos()
  if has("mac") || has("macunix") || has("gui_mac")
    return 1
  endif
  " that still doesn't mean we are not on Mac OS
  let os = substitute(system('uname'), '\n', '', '')
  return os == 'Darwin' || os == 'Mac'
endfunction

function! vimwiki#u#count_first_sym(line) "{{{
  let first_sym = matchstr(a:line, '\S')
  return len(matchstr(a:line, first_sym.'\+'))
endfunction "}}}

function! vimwiki#u#escape(string) "{{{
  return escape(a:string, '~.*[]\^$')
endfunction "}}}

" Load concrete Wiki syntax: sets regexes and templates for headers and links
function vimwiki#u#reload_regexes() "{{{
  execute 'runtime! syntax/vimwiki_'.VimwikiGet('syntax').'.vim'
endfunction "}}}

" Load omnipresent Wiki syntax
function vimwiki#u#reload_omni_regexes() "{{{
  execute 'runtime! syntax/omnipresent_syntax.vim'
endfunction "}}}

" Load syntax-specific functionality
function vimwiki#u#reload_regexes_custom() "{{{
  execute 'runtime! syntax/vimwiki_'.VimwikiGet('syntax').'_custom.vim'
endfunction "}}}

" Backward compatible version of the built-in function shiftwidth()
if exists('*shiftwidth') "{{{
  func vimwiki#u#sw()
    return shiftwidth()
  endfunc
else
  func vimwiki#u#sw()
    return &sw
  endfunc
endif "}}}
