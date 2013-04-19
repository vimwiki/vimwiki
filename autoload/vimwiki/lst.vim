" vim:tabstop=2:shiftwidth=2:expandtab:foldmethod=marker:textwidth=79
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

" Get unicode string symbol at index
function! s:str_idx(str, idx) "{{{
  " Unfortunatly vimscript cannot get symbol at index in unicode string such as
  " '✗○◐●✓'
  return matchstr(a:str, '\%'.a:idx.'v.')
endfunction "}}}

" Get checkbox regexp
function! s:rx_li_symbol(rate) "{{{
  let result = ''
  if a:rate == 100
    let result = s:str_idx(g:vimwiki_listsyms, 5)
  elseif a:rate == 0
    let result = s:str_idx(g:vimwiki_listsyms, 1)
  elseif a:rate >= 67
    let result = s:str_idx(g:vimwiki_listsyms, 4)
  elseif a:rate >= 34
    let result = s:str_idx(g:vimwiki_listsyms, 3)
  else
    let result = s:str_idx(g:vimwiki_listsyms, 2)
  endif

  return '\['.result.'\]'
endfunction "}}}

" Get blank checkbox
function! s:blank_checkbox() "{{{
  return '['.s:str_idx(g:vimwiki_listsyms, 1).'] '
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
    let level = vimwiki#u#count_first_sym(getline(a:lnum))
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

  while lnum != 0 && s:get_level(lnum) >= ind
    if s:get_level(lnum) == ind && s:is_cb_list_item(lnum)
      call add(result, lnum)
    endif
    let lnum = s:next_list_item(lnum)
  endwhile

  let lnum = s:prev_list_item(a:lnum)
  while lnum != 0 && s:get_level(lnum) >= ind
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
    let li_content = substitute(strpart(line, len(m)), '^\s*', '', '')
    let line = substitute(m, '\s*$', ' ', '').s:blank_checkbox().li_content
    call setline(a:lnum, line)
  endif
endfunction "}}}

" Tells if all of the sibling list items are checked or not.
function! s:all_siblings_checked(lnum) "{{{
  let result = 0
  let cnt = 0
  let siblings = s:get_sibling_items(a:lnum)
  for lnum in siblings
    let cnt += s:get_state(lnum)
  endfor
  let result = cnt/len(siblings)
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

" Toggle list item between [ ] and [X]
function! vimwiki#lst#ToggleListItem(line1, line2) "{{{
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

function! vimwiki#lst#kbd_cr() "{{{
  " This function is heavily relies on proper 'set comments' option.
  let cr = "\<CR>"
  if getline('.') =~ s:rx_cb_list_item()
    let cr .= s:blank_checkbox()
  endif
  return cr
endfunction "}}}

function! vimwiki#lst#kbd_oO(cmd) "{{{
  " cmd should be 'o' or 'O'

  let l:count = v:count1
  while l:count > 0

    let beg_lnum = foldclosed('.')
    let end_lnum = foldclosedend('.')
    if end_lnum != -1 && a:cmd ==# 'o'
      let lnum = end_lnum
      let line = getline(beg_lnum)
    else
      let line = getline('.')
      let lnum = line('.')
    endif

    let m = matchstr(line, s:rx_list_item())
    let res = ''
    if line =~ s:rx_cb_list_item()
      let res = substitute(m, '\s*$', ' ', '').s:blank_checkbox()
    elseif line =~ s:rx_list_item()
      let res = substitute(m, '\s*$', ' ', '')
    elseif &autoindent || &smartindent
      let res = matchstr(line, '^\s*')
    endif

    if a:cmd ==# 'o'
      call append(lnum, res)
      call cursor(lnum + 1, col('$'))
    else
      call append(lnum - 1, res)
      call cursor(lnum, col('$'))
    endif

    let l:count -= 1
  endwhile

  startinsert!

endfunction "}}}

function! vimwiki#lst#default_symbol() "{{{
  " TODO: initialize default symbol from syntax/vimwiki_xxx.vim
  if VimwikiGet('syntax') == 'default'
    return '-'
  else
    return '*'
  endif
endfunction "}}}

function vimwiki#lst#get_list_margin() "{{{
  if VimwikiGet('list_margin') < 0
    return &sw
  else
    return VimwikiGet('list_margin')
  endif
endfunction "}}}

function s:get_list_sw() "{{{
  if VimwikiGet('syntax') == 'media'
    return 1
  else
    return &sw
  endif
endfunction  "}}}

function s:get_list_nesting_level(lnum) "{{{
  if VimwikiGet('syntax') == 'media'
    if getline(a:lnum) !~ s:rx_list_item()
      let level = 0
    else 
      let level = vimwiki#u#count_first_sym(getline(a:lnum)) - 1
      let level = level < 0 ? 0 : level
    endif
  else
    let level = indent(a:lnum)   
  endif
  return level
endfunction  "}}}

function s:get_list_indent(lnum) "{{{
  if VimwikiGet('syntax') == 'media'
    return indent(a:lnum)
  else
    return 0
  endif
endfunction  "}}}

function! s:compose_list_item(n_indent, n_nesting, sym_nest, sym_bullet, li_content, ...) "{{{
  if a:0
    let sep = a:1
  else
    let sep = ''
  endif
  let li_indent = repeat(' ', max([0,a:n_indent])).sep
  let li_nesting = repeat(a:sym_nest, max([0,a:n_nesting])).sep
  if len(a:sym_bullet) > 0
    let li_bullet = a:sym_bullet.' '.sep
  else
    let li_bullet = ''.sep
  endif
  return li_indent.li_nesting.li_bullet.a:li_content
endfunction "}}}

function s:compose_cb_bullet(prev_cb_bullet, sym) "{{{
  return a:sym.matchstr(a:prev_cb_bullet, '\S*\zs\s\+.*')
endfunction "}}}

function! vimwiki#lst#change_level(...) "{{{
  let default_sym = vimwiki#lst#default_symbol()
  let cmd = '>>'
  let sym = default_sym

  " parse argument
  if a:0
    if a:1 != '<<' && a:1 != '>>'
      let cmd = '--'
      let sym = a:1
    else
      let cmd = a:1
    endif
  endif
  " is symbol valid
  if sym.' ' !~ s:rx_cb_list_item() && sym.' ' !~ s:rx_list_item()
    return
  endif

  " parsing setup
  let lnum = line('.')
  let line = getline('.')

  let list_margin = vimwiki#lst#get_list_margin()
  let list_sw = s:get_list_sw()
  let n_nesting = s:get_list_nesting_level(lnum)
  let n_indent = s:get_list_indent(lnum)

  " remove indent and nesting
  let li_bullet_and_content = strpart(line, n_nesting + n_indent)

  " list bullet and checkbox
  let cb_bullet = matchstr(li_bullet_and_content, s:rx_list_item()). 
        \ matchstr(li_bullet_and_content, s:rx_cb_list_item())

  " XXX: it could be not unicode proof --> if checkboxes are set up with unicode syms
  " content
  let li_content = strpart(li_bullet_and_content, len(cb_bullet))

  " trim
  let cb_bullet = vimwiki#u#trim(cb_bullet)
  let li_content = vimwiki#u#trim(li_content)

  " nesting symbol
  if VimwikiGet('syntax') == 'media'
    if len(cb_bullet) > 0
      let sym_nest = cb_bullet[0]
    else
      let sym_nest = sym
    endif
  else
    let sym_nest = ' '
  endif

  if g:vimwiki_debug
    echomsg "PARSE: Sw [".list_sw."]"
    echomsg s:compose_list_item(n_indent, n_nesting, sym_nest, cb_bullet, li_content, '|')
  endif

  " change level
  if cmd == '--' 
    let cb_bullet = s:compose_cb_bullet(cb_bullet, sym)
    if VimwikiGet('syntax') == 'media'
      let sym_nest = sym
    endif
  elseif cmd == '>>' 
    if cb_bullet == ''
      let cb_bullet = sym
    else
      let n_nesting = n_nesting + list_sw
    endif
  elseif cmd == '<<' 
    let n_nesting = n_nesting - list_sw
    if VimwikiGet('syntax') == 'media'
      if n_nesting < 0
        let cb_bullet = ''
      endif
    else
      if n_nesting < list_margin
        let cb_bullet = ''
      endif
    endif
  endif

  let n_nesting = max([0, n_nesting])

  if g:vimwiki_debug
    echomsg "SHIFT:"
    echomsg s:compose_list_item(n_indent, n_nesting, sym_nest, cb_bullet, li_content, '|')
  endif

  " XXX: this is the code that adds the initial indent
  let add_nesting = VimwikiGet('syntax') != 'media'
  if n_indent + n_nesting*(add_nesting) < list_margin
    let n_indent = list_margin - n_nesting*(add_nesting)
  endif

  if g:vimwiki_debug
    echomsg "INDENT:"
    echomsg s:compose_list_item(n_indent, n_nesting, sym_nest, cb_bullet, li_content, '|')
  endif

  let line = s:compose_list_item(n_indent, n_nesting, sym_nest, cb_bullet, li_content)

  " replace
  call setline(lnum, line)
  call cursor(lnum, match(line, '\S') + 1)
endfunction "}}}
