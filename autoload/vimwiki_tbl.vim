" Vimwiki autoload plugin file
" Desc: Tables
" | Easily | manageable | text  | tables | !       |
" |--------+------------+-------+--------+---------|
" | Have   | fun!       | Drink | tea    | Period. |
"
" Author: Maxim Kim <habamax@gmail.com>
" Home: http://code.google.com/p/vimwiki/

" Load only once {{{
if exists("g:loaded_vimwiki_tbl_auto") || &cp
  finish
endif
let g:loaded_vimwiki_tbl_auto = 1
"}}}

let s:textwidth = &tw

" Misc functions {{{
function! s:wide_len(str) "{{{
  return strlen(substitute(a:str, '.', 'x', 'g'))
endfunction "}}}

function! s:is_table(line) "{{{
  return a:line =~ '^\s*\%(|[^|]\+\)\+|\s*$' || s:is_separator(a:line)
endfunction "}}}

function! s:is_separator(line) "{{{
  return a:line =~ '^\s*|\s*-\+'
endfunction "}}}

function! s:is_last_column(lnum, cnum) "{{{
  return strpart(getline(a:lnum), a:cnum - 1) =~ '^[^|]*|\s*$'
endfunction "}}}

function! s:count_separators(lnum) "{{{
  let lnum = a:lnum + 1
  while lnum < line('$')
    if !s:is_separator(getline(lnum))
      break
    endif
    let lnum += 1
  endwhile

  return (lnum-a:lnum)
endfunction "}}}

function! s:create_empty_row(cols) "{{{
  let first_cell = "|   |"
  let cell = "   |"
  let row = first_cell

  for c in range(a:cols - 1)
    let row .= cell
  endfor

  return row
endfunction "}}}

function! s:create_row_sep(cols) "{{{
  let first_cell = "|---+"
  let cell = "---+"
  let last_cell = "---|"

  if a:cols < 2
    return "|---|"
  endif

  let row = first_cell

  for c in range(a:cols - 2)
    let row .= cell
  endfor

  let row .= last_cell

  return row
endfunction "}}}

function! s:get_values(line) "{{{
  let cells = []
  let cnt = 0
  let idx = 0
  while idx != -1 && idx < strlen(a:line) - 1
    let cell = matchstr(a:line, '|\zs[^|]\+\ze|', idx)
    let cell = substitute(cell, '^\s*\(.\{-}\)\s*$', '\1', 'g')
    call add(cells, [cnt, cell])
    let cnt += 1
    let idx = matchend(a:line, '|\zs[^|]\+\ze|', idx)
  endwhile
  return cells
endfunction "}}}

function! s:get_rows(lnum) "{{{
  if !s:is_table(getline(a:lnum))
    return
  endif

  let upper_rows = []
  let lower_rows = []

  let lnum = a:lnum - 1
  while lnum > 1
    let line = getline(lnum)
    if s:is_table(line)
      call add(upper_rows, [lnum, line])
    else
      break
    endif
    let lnum -= 1
  endwhile
  call reverse(upper_rows)

  let lnum = a:lnum
  while lnum <= line('$')
    let line = getline(lnum)
    if s:is_table(line)
      call add(lower_rows, [lnum, line])
    else
      break
    endif
    let lnum += 1
  endwhile

  return upper_rows + lower_rows
endfunction "}}}

function! s:get_cell_max_lens(lnum) "{{{
  let max_lens = {}
  for [lnum, row] in s:get_rows(a:lnum)
    if s:is_separator(row)
      continue
    endif
    for [idx, cell] in s:get_values(row)
      if has_key(max_lens, idx)
        let max_lens[idx] = max([s:wide_len(cell), max_lens[idx]])
      else
        let max_lens[idx] = s:wide_len(cell)
      endif
    endfor
  endfor
  return max_lens
endfunction "}}}

function! s:get_aligned_rows(lnum, max_lens) "{{{
  let rows = []
  for [lnum, row] in s:get_rows(a:lnum)
    if s:is_separator(row)
      let new_row = s:fmt_sep(a:max_lens)
    else
      let new_row = s:fmt_row(row, a:max_lens)
    endif
    call add(rows, [lnum, new_row])
  endfor
  return rows
endfunction "}}}
" }}}

" Format functions {{{
function! s:fmt_cell(cell, max_len) "{{{
  let cell = ' '.a:cell.' '

  let diff = a:max_len - s:wide_len(a:cell)
  if diff == 0 && empty(a:cell)
    let diff = 1
  endif

  let cell .= repeat(' ', diff)
  return cell
endfunction "}}}

function! s:fmt_row(line, max_lens) "{{{
  let new_line = '|'
  let values = s:get_values(a:line)
  for [idx, cell] in values
    let new_line .= s:fmt_cell(cell, a:max_lens[idx]).'|'
  endfor

  let idx = len(values)
  while idx < len(a:max_lens)
    let new_line .= s:fmt_cell('', a:max_lens[idx]).'|'
    let idx += 1
  endwhile
  return new_line
endfunction "}}}

function! s:fmt_cell_sep(max_len) "{{{
  if a:max_len == 0
    return repeat('-', 3)
  else
    return repeat('-', a:max_len+2)
  endif
endfunction "}}}

function! s:fmt_sep(max_lens) "{{{
  let sep = '|'
  for idx in range(len(a:max_lens))
    let sep .= s:fmt_cell_sep(a:max_lens[idx]).'+'
  endfor
  let sep = substitute(sep, '+$', '|', '')
  return sep
endfunction "}}}
"}}}

" Keyboard functions "{{{
function! s:kbd_create_new_row(cols, goto_first) "{{{
  let cmd = "\<ESC>o".s:create_empty_row(a:cols)
  let cmd .= "\<ESC>:call vimwiki_tbl#format(line('.'))\<CR>"
  if a:goto_first
    let cmd .= "0f|T|a"
  else
    let cmd .= "0".(col('.')-1)."lT|a"
  endif
  return cmd
endfunction "}}}

function! s:kbd_goto_next_row() "{{{
  let cmd = "\<ESC>jt|T|a"
  return cmd
endfunction "}}}

function! s:kbd_goto_next_col(last) "{{{
  if col('.') == 1
    let cmd = "\<ESC>la"
  else
    if a:last
      let seps = s:count_separators(line('.'))
      let cmd = "\<ESC>".seps."j0f|F|la"
    else
      let cmd = "\<ESC>f|la"
    endif
  endif
  return cmd
endfunction "}}}

"}}}

" Global functions {{{
function! vimwiki_tbl#kbd_cr() "{{{
  let lnum = line('.')
  if !s:is_table(getline(lnum))
    return "\<CR>"
  endif

  if s:is_separator(getline(lnum+1)) || !s:is_table(getline(lnum+1))
    let cols = len(s:get_values(getline(lnum)))
    return s:kbd_create_new_row(cols, 0)
  else
    return s:kbd_goto_next_row()
  endif
endfunction "}}}

function! vimwiki_tbl#kbd_tab() "{{{
  let lnum = line('.')
  if !s:is_table(getline(lnum))
    return "\<Tab>"
  endif

  let last = s:is_last_column(lnum, col('.'))
  if last && !s:is_table(getline(lnum+1))
    let cols = len(s:get_values(getline(lnum)))
    return s:kbd_create_new_row(cols, 1)
  endif
  return s:kbd_goto_next_col(last)
endfunction "}}}

function! vimwiki_tbl#format(lnum) "{{{
  let line = getline(a:lnum)
  if !s:is_table(line)
    return
  endif

  let max_lens = s:get_cell_max_lens(a:lnum)

  for [lnum, row] in s:get_aligned_rows(a:lnum, max_lens)
    call setline(lnum, row)
  endfor

  let &tw = s:textwidth
endfunction "}}}

function! vimwiki_tbl#create(...) "{{{
  if a:0 > 1
    let cols = a:1
    let rows = a:2
  elseif a:0 == 1
    let cols = a:1
    let rows = 2
  elseif a:0 == 0
    let cols = 5
    let rows = 2
  endif

  if cols < 1
    let cols = 5
  endif

  if rows < 1
    let rows = 2
  endif

  let lines = []
  let row = s:create_empty_row(cols)

  call add(lines, row)
  if rows > 1
    call add(lines, s:create_row_sep(cols))
  endif

  for r in range(rows - 1)
    call add(lines, row)
  endfor

  call append(line('.'), lines)
endfunction "}}}

function! vimwiki_tbl#align_or_cmd(cmd) "{{{
  if s:is_table(getline('.'))
    call vimwiki_tbl#format(line('.'))
  else
    exe 'normal! '.a:cmd
  endif
endfunction "}}}

function! vimwiki_tbl#reset_tw(lnum) "{{{
  let line = getline(a:lnum)
  if !s:is_table(line)
    return
  endif

  let s:textwidth = &tw
  let &tw = 0
endfunction "}}}

"}}}
