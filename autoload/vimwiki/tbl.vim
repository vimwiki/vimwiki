" vim:tabstop=2:shiftwidth=2:expandtab:textwidth=99
" Vimwiki autoload plugin file
" Description: Tables
" | Easily | manageable | text  | tables | !       |
" |--------|------------|-------|--------|---------|
" | Have   | fun!       | Drink | tea    | Period. |
"
" Home: https://github.com/vimwiki/vimwiki/



if exists("g:loaded_vimwiki_tbl_auto") || &cp
  finish
endif
let g:loaded_vimwiki_tbl_auto = 1


let s:textwidth = &tw


function! s:rxSep()
  return vimwiki#vars#get_syntaxlocal('rxTableSep')
endfunction


function! s:wide_len(str)
  " vim73 has new function that gives correct string width.
  if exists("*strdisplaywidth")
    return strdisplaywidth(a:str)
  endif

  " get str display width in vim ver < 7.2
  if !vimwiki#vars#get_global('CJK_length')
    let ret = strlen(substitute(a:str, '.', 'x', 'g'))
  else
    let savemodified = &modified
    let save_cursor = getpos('.')
    exe "norm! o\<esc>"
    call setline(line("."), a:str)
    let ret = virtcol("$") - 1
    d
    call setpos('.', save_cursor)
    let &modified = savemodified
  endif
  return ret
endfunction


function! s:cell_splitter()
  return '\s*'.s:rxSep().'\s*'
endfunction


function! s:sep_splitter()
  return '-'.s:rxSep().'-'
endfunction


function! s:is_table(line)
  return s:is_separator(a:line) ||
        \ (a:line !~# s:rxSep().s:rxSep() && a:line =~# '^\s*'.s:rxSep().'.\+'.s:rxSep().'\s*$')
endfunction


function! s:is_separator(line)
  return a:line =~# '^\s*'.s:rxSep().'\(--\+'.s:rxSep().'\)\+\s*$'
endfunction


function! s:is_separator_tail(line)
  return a:line =~# '^\{-1}\%(\s*\|-*\)\%('.s:rxSep().'-\+\)\+'.s:rxSep().'\s*$'
endfunction


function! s:is_last_column(lnum, cnum)
  let line = strpart(getline(a:lnum), a:cnum - 1)
  return line =~# s:rxSep().'\s*$'  && line !~# s:rxSep().'.*'.s:rxSep().'\s*$'
endfunction


function! s:is_first_column(lnum, cnum)
  let line = strpart(getline(a:lnum), 0, a:cnum - 1)
  return line =~# '^\s*$' ||
        \ (line =~# '^\s*'.s:rxSep() && line !~# '^\s*'.s:rxSep().'.*'.s:rxSep())
endfunction


function! s:count_separators_up(lnum)
  let lnum = a:lnum - 1
  while lnum > 1
    if !s:is_separator(getline(lnum))
      break
    endif
    let lnum -= 1
  endwhile

  return (a:lnum-lnum)
endfunction


function! s:count_separators_down(lnum)
  let lnum = a:lnum + 1
  while lnum < line('$')
    if !s:is_separator(getline(lnum))
      break
    endif
    let lnum += 1
  endwhile

  return (lnum-a:lnum)
endfunction


function! s:create_empty_row(cols)
  let row = s:rxSep()
  let cell = "   ".s:rxSep()

  for c in range(a:cols)
    let row .= cell
  endfor

  return row
endfunction


function! s:create_row_sep(cols)
  let row = s:rxSep()
  let cell = "---".s:rxSep()

  for c in range(a:cols)
    let row .= cell
  endfor

  return row
endfunction


function! vimwiki#tbl#get_cells(line)
  let result = []
  let cell = ''
  let quote = ''
  let state = 'NONE'

  " 'Simple' FSM
  for idx in range(strlen(a:line))
    " The only way I know Vim can do Unicode...
    let ch = a:line[idx]
    if state ==# 'NONE'
      if ch == '|'
        let state = 'CELL'
      endif
    elseif state ==# 'CELL'
      if ch == '[' || ch == '{'
        let state = 'BEFORE_QUOTE_START'
        let quote = ch
      elseif ch == '|'
        call add(result, vimwiki#u#trim(cell))
        let cell = ""
      else
        let cell .= ch
      endif
    elseif state ==# 'BEFORE_QUOTE_START'
      if ch == '[' || ch == '{'
        let state = 'QUOTE'
        let quote .= ch
      else
        let state = 'CELL'
        let cell .= quote.ch
        let quote = ''
      endif
    elseif state ==# 'QUOTE'
      if ch == ']' || ch == '}'
        let state = 'BEFORE_QUOTE_END'
      endif
      let quote .= ch
    elseif state ==# 'BEFORE_QUOTE_END'
      if ch == ']' || ch == '}'
        let state = 'CELL'
      endif
      let cell .= quote.ch
      let quote = ''
    endif
  endfor

  if cell.quote != ''
    call add(result, vimwiki#u#trim(cell.quote, '|'))
  endif
  return result
endfunction


function! s:col_count(lnum)
  return len(vimwiki#tbl#get_cells(getline(a:lnum)))
endfunction


function! s:get_indent(lnum)
  if !s:is_table(getline(a:lnum))
    return
  endif

  let indent = 0

  let lnum = a:lnum - 1
  while lnum > 1
    let line = getline(lnum)
    if !s:is_table(line)
      let indent = indent(lnum+1)
      break
    endif
    let lnum -= 1
  endwhile

  return indent
endfunction


function! s:get_rows(lnum)
  if !s:is_table(getline(a:lnum))
    return
  endif

  let upper_rows = []
  let lower_rows = []

  let lnum = a:lnum - 1
  while lnum >= 1
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
endfunction


function! s:get_cell_max_lens(lnum, ...)
  let max_lens = {}
  for [lnum, row] in s:get_rows(a:lnum)
    if s:is_separator(row)
      continue
    endif
    let cells = a:0 > 1 ? a:1[lnum - a:2] : vimwiki#tbl#get_cells(row)
    for idx in range(len(cells))
      let value = cells[idx]
      if has_key(max_lens, idx)
        let max_lens[idx] = max([s:wide_len(value), max_lens[idx]])
      else
        let max_lens[idx] = s:wide_len(value)
      endif
    endfor
  endfor
  return max_lens
endfunction


function! s:get_aligned_rows(lnum, col1, col2)
  let rows = s:get_rows(a:lnum)
  let startlnum = rows[0][0]
  let cells = []
  for [lnum, row] in rows
    call add(cells, vimwiki#tbl#get_cells(row))
  endfor
  let max_lens = s:get_cell_max_lens(a:lnum, cells, startlnum)
  let result = []
  for [lnum, row] in rows
    if s:is_separator(row)
      let new_row = s:fmt_sep(max_lens, a:col1, a:col2)
    else
      let new_row = s:fmt_row(cells[lnum - startlnum], max_lens, a:col1, a:col2)
    endif
    call add(result, [lnum, new_row])
  endfor
  return result
endfunction


" Number of the current column. Starts from 0.
function! s:cur_column()
  let line = getline('.')
  if !s:is_table(line)
    return -1
  endif
  " TODO: do we need conditional: if s:is_separator(line)

  let curs_pos = col('.')
  let mpos = match(line, s:rxSep(), 0)
  let col = -1
  while mpos < curs_pos && mpos != -1
    let mpos = match(line, s:rxSep(), mpos+1)
    if mpos != -1
      let col += 1
    endif
  endwhile
  return col
endfunction


function! s:fmt_cell(cell, max_len)
  let cell = ' '.a:cell.' '

  let diff = a:max_len - s:wide_len(a:cell)
  if diff == 0 && empty(a:cell)
    let diff = 1
  endif

  let cell .= repeat(' ', diff)
  return cell
endfunction


function! s:fmt_row(cells, max_lens, col1, col2)
  let new_line = s:rxSep()
  for idx in range(len(a:cells))
    if idx == a:col1
      let idx = a:col2
    elseif idx == a:col2
      let idx = a:col1
    endif
    let value = a:cells[idx]
    let new_line .= s:fmt_cell(value, a:max_lens[idx]).s:rxSep()
  endfor

  let idx = len(a:cells)
  while idx < len(a:max_lens)
    let new_line .= s:fmt_cell('', a:max_lens[idx]).s:rxSep()
    let idx += 1
  endwhile
  return new_line
endfunction


function! s:fmt_cell_sep(max_len)
  if a:max_len == 0
    return repeat('-', 3)
  else
    return repeat('-', a:max_len+2)
  endif
endfunction


function! s:fmt_sep(max_lens, col1, col2)
  let new_line = s:rxSep()
  for idx in range(len(a:max_lens))
    if idx == a:col1
      let idx = a:col2
    elseif idx == a:col2
      let idx = a:col1
    endif
    let new_line .= s:fmt_cell_sep(a:max_lens[idx]).s:rxSep()
  endfor
  return new_line
endfunction


function! s:kbd_create_new_row(cols, goto_first)
  let cmd = "\<ESC>o".s:create_empty_row(a:cols)
  let cmd .= "\<ESC>:call vimwiki#tbl#format(line('.'))\<CR>"
  let cmd .= "\<ESC>0"
  if a:goto_first
    let cmd .= ":call search('\\(".s:rxSep()."\\)\\zs', 'c', line('.'))\<CR>"
  else
    let cmd .= (col('.')-1)."l"
    let cmd .= ":call search('\\(".s:rxSep()."\\)\\zs', 'bc', line('.'))\<CR>"
  endif
  let cmd .= "a"

  return cmd
endfunction


function! s:kbd_goto_next_row()
  let cmd = "\<ESC>j"
  let cmd .= ":call search('.\\(".s:rxSep()."\\)', 'c', line('.'))\<CR>"
  let cmd .= ":call search('\\(".s:rxSep()."\\)\\zs', 'bc', line('.'))\<CR>"
  let cmd .= "a"
  return cmd
endfunction


function! s:kbd_goto_prev_row()
  let cmd = "\<ESC>k"
  let cmd .= ":call search('.\\(".s:rxSep()."\\)', 'c', line('.'))\<CR>"
  let cmd .= ":call search('\\(".s:rxSep()."\\)\\zs', 'bc', line('.'))\<CR>"
  let cmd .= "a"
  return cmd
endfunction


" Used in s:kbd_goto_next_col
function! vimwiki#tbl#goto_next_col()
  let curcol = virtcol('.')
  let lnum = line('.')
  let newcol = s:get_indent(lnum)
  let max_lens = s:get_cell_max_lens(lnum)
  for cell_len in values(max_lens)
    if newcol >= curcol-1
      break
    endif
    let newcol += cell_len + 3 " +3 == 2 spaces + 1 separator |<space>...<space>
  endfor
  let newcol += 2 " +2 == 1 separator + 1 space |<space
  call vimwiki#u#cursor(lnum, newcol)
endfunction


function! s:kbd_goto_next_col(jumpdown)
  let cmd = "\<ESC>"
  if a:jumpdown
    let seps = s:count_separators_down(line('.'))
    let cmd .= seps."j0"
  endif
  let cmd .= ":call vimwiki#tbl#goto_next_col()\<CR>a"
  return cmd
endfunction


" Used in s:kbd_goto_prev_col
function! vimwiki#tbl#goto_prev_col()
  let curcol = virtcol('.')
  let lnum = line('.')
  let newcol = s:get_indent(lnum)
  let max_lens = s:get_cell_max_lens(lnum)
  let prev_cell_len = 0
  for cell_len in values(max_lens)
    let delta = cell_len + 3 " +3 == 2 spaces + 1 separator |<space>...<space>
    if newcol + delta > curcol-1
      let newcol -= (prev_cell_len + 3) " +3 == 2 spaces + 1 separator |<space>...<space>
      break
    elseif newcol + delta == curcol-1
      break
    endif
    let prev_cell_len = cell_len
    let newcol += delta
  endfor
  let newcol += 2 " +2 == 1 separator + 1 space |<space
  call vimwiki#u#cursor(lnum, newcol)
endfunction


function! s:kbd_goto_prev_col(jumpup)
  let cmd = "\<ESC>"
  if a:jumpup
    let seps = s:count_separators_up(line('.'))
    let cmd .= seps."k"
    let cmd .= "$"
  endif
  let cmd .= ":call vimwiki#tbl#goto_prev_col()\<CR>a"
  " let cmd .= ":call search('\\(".s:rxSep()."\\)\\zs', 'b', line('.'))\<CR>"
  " let cmd .= "a"
  "echomsg "DEBUG kbd_goto_prev_col> ".cmd
  return cmd
endfunction


function! vimwiki#tbl#kbd_cr()
  let lnum = line('.')
  if !s:is_table(getline(lnum))
    return ""
  endif

  if s:is_separator(getline(lnum+1)) || !s:is_table(getline(lnum+1))
    let cols = len(vimwiki#tbl#get_cells(getline(lnum)))
    return s:kbd_create_new_row(cols, 0)
  else
    return s:kbd_goto_next_row()
  endif
endfunction


function! vimwiki#tbl#kbd_tab()
  let lnum = line('.')
  if !s:is_table(getline(lnum))
    return "\<Tab>"
  endif

  let last = s:is_last_column(lnum, col('.'))
  let is_sep = s:is_separator_tail(getline(lnum))
  "echomsg "DEBUG kbd_tab> last=".last.", is_sep=".is_sep
  if (is_sep || last) && !s:is_table(getline(lnum+1))
    let cols = len(vimwiki#tbl#get_cells(getline(lnum)))
    return s:kbd_create_new_row(cols, 1)
  endif
  return s:kbd_goto_next_col(is_sep || last)
endfunction


function! vimwiki#tbl#kbd_shift_tab()
  let lnum = line('.')
  if !s:is_table(getline(lnum))
    return "\<S-Tab>"
  endif

  let first = s:is_first_column(lnum, col('.'))
  let is_sep = s:is_separator_tail(getline(lnum))
  "echomsg "DEBUG kbd_tab> ".first
  if (is_sep || first) && !s:is_table(getline(lnum-1))
    return ""
  endif
  return s:kbd_goto_prev_col(is_sep || first)
endfunction


function! vimwiki#tbl#format(lnum, ...)
  if !(&filetype ==? 'vimwiki')
    return
  endif
  let line = getline(a:lnum)
  if !s:is_table(line)
    return
  endif

  if a:0 == 2
    let col1 = a:1
    let col2 = a:2
  else
    let col1 = 0
    let col2 = 0
  endif

  let indent = s:get_indent(a:lnum)
  if &expandtab
    let indentstring = repeat(' ', indent)
  else
    let indentstring = repeat('	', indent / &tabstop) . repeat(' ', indent % &tabstop)
  endif

  for [lnum, row] in s:get_aligned_rows(a:lnum, col1, col2)
    let row = indentstring.row
    call setline(lnum, row)
  endfor

  let &tw = s:textwidth
endfunction


function! vimwiki#tbl#create(...)
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
endfunction


function! vimwiki#tbl#align_or_cmd(cmd)
  if s:is_table(getline('.'))
    call vimwiki#tbl#format(line('.'))
  else
    exe 'normal! '.a:cmd
  endif
endfunction


function! vimwiki#tbl#reset_tw(lnum)
  if !(&filetype ==? 'vimwiki')
    return
  endif
  let line = getline(a:lnum)
  if !s:is_table(line)
    return
  endif

  let s:textwidth = &tw
  let &tw = 0
endfunction


" TODO: move_column_left and move_column_right are good candidates to be refactored.
function! vimwiki#tbl#move_column_left()

  "echomsg "DEBUG move_column_left: "

  let line = getline('.')

  if !s:is_table(line)
    return
  endif

  let cur_col = s:cur_column()
  if cur_col == -1
    return
  endif

  if cur_col > 0
    call vimwiki#tbl#format(line('.'), cur_col-1, cur_col)
    call cursor(line('.'), 1)

    let sep = '\('.s:rxSep().'\).\zs'
    let mpos = -1
    let col = -1
    while col < cur_col-1
      let mpos = match(line, sep, mpos+1)
      if mpos != -1
        let col += 1
      else
        break
      endif
    endwhile

  endif
endfunction


function! vimwiki#tbl#move_column_right()

  let line = getline('.')

  if !s:is_table(line)
    return
  endif

  let cur_col = s:cur_column()
  if cur_col == -1
    return
  endif

  if cur_col < s:col_count(line('.'))-1
    call vimwiki#tbl#format(line('.'), cur_col, cur_col+1)
    call cursor(line('.'), 1)

    let sep = '\('.s:rxSep().'\).\zs'
    let mpos = -1
    let col = -1
    while col < cur_col+1
      let mpos = match(line, sep, mpos+1)
      if mpos != -1
        let col += 1
      else
        break
      endif
    endwhile
  endif
endfunction


function! vimwiki#tbl#get_rows(lnum)
  return s:get_rows(a:lnum)
endfunction


function! vimwiki#tbl#is_table(line)
  return s:is_table(a:line)
endfunction


function! vimwiki#tbl#is_separator(line)
  return s:is_separator(a:line)
endfunction


function! vimwiki#tbl#cell_splitter()
  return s:cell_splitter()
endfunction


function! vimwiki#tbl#sep_splitter()
  return s:sep_splitter()
endfunction

