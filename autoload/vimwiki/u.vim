" vim:tabstop=2:shiftwidth=2:expandtab:textwidth=99
" Vimwiki autoload plugin file
" Description: Utility functions
" Home: https://github.com/vimwiki/vimwiki/

" Echo: msg
" :param: (1) <string> highlighting group
" :param: (2) <string> echo suffix (ex: 'n', 'm')
" :param: (3) <string> message prefix, default Vimwiki
function! vimwiki#u#echo(msg, ...) abort
  let hl_group = a:0 > 0 ? a:1 : ''
  let echo_suffix = a:0 > 1 ? a:2 : ''
  let msg_prefix = a:0 > 2 ? a:3 : 'Vimwiki: '
  " Start highlighting
  if hl_group !=# ''
    exe 'echohl ' . hl_group
  endif

  " Escape
  let msg = substitute(a:msg, "'", "''", 'g')
  " Print
  exe 'echo'.echo_suffix . " '" . msg_prefix . msg . "'"

  " Stop highlighting
  if hl_group !=# ''
    echohl None
  endif
endfunction

" Debug: msg
" let b:vimwiki_debug to trigger
function! vimwiki#u#debug(msg) abort
  if !exists('b:vimwiki_debug') || b:vimwiki_debug == 0
    return
  endif
  echomsg 'DEBUG: ' . a:msg
endfunction

" Warn: msg
function! vimwiki#u#warn(msg) abort
  call vimwiki#u#echo('Warning: ' . a:msg, 'WarningMsg', '')
endfunction

" Error: msg
function! vimwiki#u#error(msg) abort
  call vimwiki#u#echo('Error: ' . a:msg, 'Error', 'msg')
endfunction

" Warn: deprecated feature: old -> new
function! vimwiki#u#deprecate(old, new) abort
  call vimwiki#u#warn('Deprecated: ' . a:old . ' is deprecated and '
        \ . 'will be removed in future versions. Use ' . a:new . ' instead.')
endfunction

" Get visual selection text content, optionaly replace its content
" :param: Text to replace selection
function! vimwiki#u#get_selection(...) abort
  " Copyed from DarkWiiPlayer at stackoverflow
  " https://stackoverflow.com/a/47051271/2544873
  " Get selection extremity position,
  " Discriminate selection mode
  if mode() ==? 'v'
    let [line_start, column_start] = getpos('v')[1:2]
    let [line_end, column_end] = getpos('.')[1:2]
  else
    let [line_start, column_start] = getpos("'<")[1:2]
    let [line_end, column_end] = getpos("'>")[1:2]
  end

  " Guard
  if (line2byte(line_start)+column_start) > (line2byte(line_end)+column_end)
    let [line_start, column_start, line_end, column_end] =
    \   [line_end, column_end, line_start, column_start]
  end
  let lines = getline(line_start, line_end)
  if len(lines) == 0
    return ''
  endif

  " If want to modify selection
  if a:0 > 0
    " Grab new content
    let line_link = a:1

    " Grab the content of line around the link: pre and post
    let start_link = max([column_start - 2, 0])
    let line_pre = ''
    if start_link > 0
      let line_pre .= lines[0][ : start_link]
    endif
    let line_post = lines[0][column_end - (&selection ==# 'inclusive' ? 0 : 1) : ]

    " Set the only single selected line
    call setline(line_start, line_pre . line_link . line_post)
  endif

  " Get selection extremity position, take into account selection option
  let lines[-1] = lines[-1][: column_end - (&selection ==# 'inclusive' ? 1 : 2)]
  let lines[0] = lines[0][column_start - 1:]
  return join(lines, "\n")
endfunction


" Execute: string v:count times
function! vimwiki#u#count_exe(cmd) abort
    for i in range( max([1, v:count]) )
        exe a:cmd
    endfor
endfunction


function! vimwiki#u#sort_len(list) abort
  function! s:len_compare(s1, s2) abort
    let i1 = len(a:s1)
    let i2 = len(a:s2)
     return i1 == i2 ? 0 : i1 > i2 ? 1 : -1
  endfunction
  return sort(a:list, 's:len_compare')
endfunction


" Trim spaces: leading and trailing
" :param: string in
" :param: (1) <string> optional list of character to trim
function! vimwiki#u#trim(string, ...) abort
  let chars = ''
  if a:0 > 0
    let chars = a:1
  endif
  let res = substitute(a:string, '^[[:space:]'.chars.']\+', '', '')
  let res = substitute(res, '[[:space:]'.chars.']\+$', '', '')
  return res
endfunction


" Builtin cursor doesn't work right with unicode characters.
function! vimwiki#u#cursor(lnum, cnum) abort
  exe a:lnum
  exe 'normal! 0'.a:cnum.'|'
endfunction


" Returns: OS name, human readable
function! vimwiki#u#os_name() abort
  if vimwiki#u#is_windows()
    return 'Windows'
  elseif vimwiki#u#is_macos()
    return 'Mac'
  else
    return 'Linux'
  endif
endfunction


" Check if OS is windows
function! vimwiki#u#is_windows() abort
  return has('win32') || has('win64') || has('win95') || has('win16')
endfunction


" Check if OS is mac
function! vimwiki#u#is_macos() abort
  if has('mac') || has('macunix') || has('gui_mac')
    return 1
  endif
  " that still doesn't mean we are not on Mac OS
  let os = substitute(system('uname'), '\n', '', '')
  return os ==? 'Darwin' || os ==? 'Mac'
endfunction


function! vimwiki#u#count_first_sym(line) abort
  let first_sym = matchstr(a:line, '\S')
  return len(matchstr(a:line, first_sym.'\+'))
endfunction


" Escape string for literal magic regex match
function! vimwiki#u#escape(string) abort
  return escape(a:string, '~.*[]\^$')
endfunction


" Load concrete Wiki syntax: sets regexes and templates for headers and links
function! vimwiki#u#reload_regexes() abort
  execute 'runtime! syntax/vimwiki_'.vimwiki#vars#get_wikilocal('syntax').'.vim'
endfunction


" Load syntax-specific functionality
function! vimwiki#u#reload_regexes_custom() abort
  execute 'runtime! syntax/vimwiki_'.vimwiki#vars#get_wikilocal('syntax').'_custom.vim'
endfunction


" Backward compatible version of the built-in function shiftwidth()
function! vimwiki#u#sw() abort
  if exists('*shiftwidth')
    return shiftwidth()
  else
    return &shiftwidth
  endif
endfunc

" a:mode single character indicating the mode as defined by :h maparg
" a:key the key sequence to map
" a:plug the plug command the key sequence should be mapped to
" a:1 optional argument with the following functionality:
"   if a:1==1 then the hasmapto(<Plug>) check is skipped.
"     this can be used to map different keys to the same <Plug> definition
"   if a:1==2 then the mapping is not <buffer> specific i.e. it is global
function! vimwiki#u#map_key(mode, key, plug, ...) abort
  if a:0 && a:1 == 2
    " global mappings
    if !hasmapto(a:plug) && maparg(a:key, a:mode) ==# ''
      exe a:mode . 'map ' . a:key . ' ' . a:plug
    endif
  elseif a:0 && a:1 == 1
      " vimwiki buffer mappings, repeat mapping to the same <Plug> definition
      exe a:mode . 'map <buffer> ' . a:key . ' ' . a:plug
  else
    " vimwiki buffer mappings
    if !hasmapto(a:plug)
      exe a:mode . 'map <buffer> ' . a:key . ' ' . a:plug
    endif
  endif
endfunction


" Returns: 1 if line is a code block or math block
"
" The last two conditions are needed for this to correctly
" detect nested syntaxes within code blocks
function! vimwiki#u#is_codeblock(lnum) abort
  let syn_g = synIDattr(synID(a:lnum,1,1),'name')
  if  syn_g =~# 'Vimwiki\(Pre.*\|IndentedCodeBlock\|Math.*\)'
        \ || (syn_g !~# 'Vimwiki.*' && syn_g !=? '')
    return 1
  else
    return 0
  endif
endfunction

" Sets the filetype to vimwiki
" If g:vimwiki_filetypes variable is set
" the filetype will be vimwiki.<ft1>.<ft2> etc.
function! vimwiki#u#ft_set() abort
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
function! vimwiki#u#ft_is_vw() abort
  " Clause: is filetype defined
  if &filetype ==# '' | return 0 | endif
  if split(&filetype, '\.')[0] ==? 'vimwiki'
    return 1
  else
    return 0
  endif
endfunction


" Helper: Getter
" :param: syntax <string> to retrive, default to current
function! vimwiki#u#get_syntax_dic(...) abort
  let syntax = a:0 ? a:1 : vimwiki#vars#get_wikilocal('syntax')
  return g:vimwiki_syntaxlocal_vars[syntax]
endfunction


" Helper to mutualize
" Called: normalize and unnormalize anchor
function! vimwiki#u#get_punctuation_regex() abort
  " From: https://gist.github.com/asabaylus/3071099#gistcomment-2563127
  " Faster
  " Unused now
  if v:version <= 703
    " Retrocompatibility: Get invalid range for vim 7.03
    return '[^0-9a-zA-Z_ \-]'
  else
    return '[^0-9a-zA-Z\u4e00-\u9fff_ \-]'
  endif
endfunction


" Faster
function! vimwiki#u#get_punctuation_string() abort
  " See: https://github.github.com/gfm/#ascii-punctuation-character
  return '!"#$%&''()*+,-./:;<=>?@\[\\\]^`{}|~'
endfunction


" Helper: Expand regex from reduced typeface delimiters
" :param: list<list,delimiters>> with reduced regex
" Return: list with extended regex delimiters (not inside a word)
"   -- [['\*_', '_\*']] -> [['\*_\S\@=', '\S\@<=_\*\%(\s\|$\)\@=']]
" See: https://github.github.com/gfm/#left-flanking-delimiter-run
function! vimwiki#u#hi_expand_regex(lst) abort
  let res = []
  let p = vimwiki#u#get_punctuation_string()
  for delimiters in a:lst
    call add(res, [
          \ delimiters[0] . '\S\@=',
          \ '\S\@<=' . delimiters[1] . '\%(\_[[:space:]' . p . ']\)\@='])
  endfor
  return res
endfunction


" Helper: Create highlight region between two tags
" :param: tag <string> example '<b>'
" :param: syntax_group <string> example: VimwikiBold
" :param: contains <string> coma separated and prefixed, default VimwikiHTMLTag
" :param: (1) <boolean> is contained
" :param: (2) <string> more param ex:oneline
function! vimwiki#u#hi_tag(tag_pre, tag_post, syntax_group, contains, ...) abort
  let opt_is_contained = a:0 > 0 && a:1 > 0 ? 'contained ' : ''
  let opt_more = a:0 > 1  ? ' ' . a:2 : ''
  let opt_contains = ''
  if a:contains !=# ''
    let opt_contains = 'contains=' . a:contains . ' '
  endif
  let cmd = 'syn region ' . a:syntax_group . ' matchgroup=VimwikiDelimiter ' .
        \ opt_is_contained .
        \ 'start="' . a:tag_pre . '" ' .
        \ 'end="' . a:tag_post . '" ' .
        \ 'keepend ' .
        \ opt_contains .
        \ b:vimwiki_syntax_concealends .
        \ opt_more
  exe cmd
endfunction


" Highight typeface: see $VIMRUNTIME/syntax/html.vim
" -- Basically allow nesting with multiple definition contained
" :param: dic <dic:list:list> must contain: bold, italic and underline, even if underline is often void,
" -- see here for underline not defined: https://stackoverflow.com/questions/3003476
function! vimwiki#u#hi_typeface(dic) abort
  " Italic must go before, otherwise single * takes precedence over ** and ** is considered as
  " -- a void italic.
  " Note:
  " The last syntax defined take precedence so that user can change at runtime (:h :syn-define)
  " Some cases are contained by default:
  " -- ex: VimwikiCodeBoldUnderline is not defined in colorschemes -> VimwikiCode
  " -- see: #709 asking for concealing quotes in bold, so it must be higlighted differently
  " -- -- for the user to understand what is concealed around
  " VimwikiCheckBoxDone and VimwikiDelText are as their are even when nested in bold or italic
  " -- This is because it would add a lot of code (as n**2) at startup and is not often used
  " -- Here n=3 (bold, italic, underline)
  " Bold > Italic > Underline

  let nested = vimwiki#u#get_syntax_dic().nested

  " Italic
  for i in a:dic['italic']
    "  -- Italic 1
    call vimwiki#u#hi_tag(i[0], i[1], 'VimwikiItalic ', nested .',VimwikiItalicBold,VimwikiItalicUnderline')
    " -- Bold 2
    call vimwiki#u#hi_tag(i[0], i[1], 'VimwikiBoldItalic', nested . ',VimwikiBoldItalicUnderline', 1)
    " -- Bold 3
    call vimwiki#u#hi_tag(i[0], i[1], 'VimwikiBoldUnderlineItalic', nested, 2)
    " -- Underline 2
    call vimwiki#u#hi_tag(i[0], i[1], 'VimwikiUnderlineItalic', nested . ',VimwikiUnderlineItalicBold', 1)
    " -- Underline 3
    call vimwiki#u#hi_tag(i[0], i[1], 'VimwikiUnderlineBoldItalic', nested, 2)
  endfor

  " Bold
  for b in a:dic['bold']
    " -- Bold 1
    call vimwiki#u#hi_tag(b[0],b[1], 'VimwikiBold', nested . ',VimwikiBoldUnderline,VimwikiBoldItalic')
    " -- Italic 2
    call vimwiki#u#hi_tag(b[0], b[1], 'VimwikiItalicBold', nested . ',VimwikiItalicBoldUnderline', 1)
    " -- Italic 3
    call vimwiki#u#hi_tag(b[0], b[1], 'VimwikiItalicUnderlineBold', nested, 2)
    " -- Underline 2
    call vimwiki#u#hi_tag(b[0], b[1], 'VimwikiUnderlineBold', nested . ',VimwikiUnderlineBoldItalic', 1)
    " -- Underline 3
    call vimwiki#u#hi_tag(b[0], b[1], 'VimwikiUnderlineItalicBold', nested, 2)
  endfor

  " Bold Italic
  if has_key(a:dic, 'bold_italic')
    for bi in a:dic['bold_italic']
      call vimwiki#u#hi_tag(bi[0], bi[1], 'VimwikiBoldItalic', nested . ',VimwikiBoldItalicUnderline')
    endfor
  endif

  " Underline
  for u in a:dic['underline']
    " -- Underline 1
    call vimwiki#u#hi_tag(u[0], u[1], 'VimwikiUnderline', nested . ',VimwikiUnderlineBold,VimwikiUnderlineItalic')
    " -- Italic 2
    call vimwiki#u#hi_tag(u[0], u[1], 'VimwikiItalicUnderline', nested . ',VimwikiItalicUnderlineBold', 1)
    " -- Italic 3
    call vimwiki#u#hi_tag(u[0], u[1], 'VimwikiBoldItalicUnderline', nested, 2)
    " -- Underline 2
    call vimwiki#u#hi_tag(u[0], u[1], 'VimwikiBoldUnderline', nested . ',VimwikiBoldUnderlineItalic', 1)
    " -- Underline 3
    call vimwiki#u#hi_tag(u[0], u[1], 'VimwikiItalicBoldUnderline', nested, 2)
  endfor

  " Strikethrough
  " Note: VimwikiBoldDelText Not Implemented (see above)
  for u in a:dic['del']
    call vimwiki#u#hi_tag(u[0], u[1], 'VimwikiDelText', nested)
  endfor

  "" Code do not contain anything but can be contained very nested
  for u in a:dic['code']
    call vimwiki#u#hi_tag(u[0], u[1], 'VimwikiCode', '')
  endfor

  " Superscript
  for u in a:dic['sup']
    call vimwiki#u#hi_tag(u[0], u[1], 'VimwikiSuperScript', nested, 0, 'oneline')
  endfor

  " Subscript
  for u in a:dic['sub']
    call vimwiki#u#hi_tag(u[0], u[1], 'VimwikiSubScript', nested, 0, 'oneline')
  endfor

  " Prevent var_with_underscore to trigger italic text
  " -- See $VIMRUNTIME/syntax/markdown.vim
  syn match VimwikiError "\w\@<=[_*]\w\@="
endfunction
