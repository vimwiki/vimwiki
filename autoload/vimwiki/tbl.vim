" vim:tabstop=2:shiftwidth=2:expandtab:textwidth=99
" Vimwiki autoload plugin file
" Description: Tables
" | Easily | manageable | text  | tables | !       |
" |--------|------------|-------|--------|---------|
" | Have   | fun!       | Drink | tea    | Period. |
"
" Home: https://github.com/vimwiki/vimwiki/


" Clause: Load only once
if exists('g:loaded_vimwiki_tbl_auto') || &compatible
  finish
endif
let g:loaded_vimwiki_tbl_auto = 1


function! s:s_sep() abort
  " Return string column separator
  return vimwiki#vars#get_syntaxlocal('rxTableSep')
endfunction

function! s:r_sep() abort
  " Return regex column separator
  " Not prefixed with \
  let res = '\(^\|[^\\]\)\@<='
  let res .= vimwiki#vars#get_syntaxlocal('rxTableSep')
  return res
endfunction

function! s:wide_len(str) abort
  " vim73 has new function that gives correct string width.
  if exists('*strdisplaywidth')
    return strdisplaywidth(a:str)
  endif

  " get str display width in vim ver < 7.2
  if !vimwiki#vars#get_global('CJK_length')
    let ret = strlen(substitute(a:str, '.', 'x', 'g'))
  else
    let savemodified = &modified
    let save_cursor = getpos('.')
    exe "norm! o\<esc>"
    call setline(line('.'), a:str)
    let ret = virtcol('$') - 1
    d
    call setpos('.', save_cursor)
    let &modified = savemodified
  endif
  return ret
endfunction


function! s:cell_splitter() abort
  return '\s*'.s:r_sep().'\s*'
endfunction


function! s:sep_splitter() abort
  return '-'.s:r_sep().'-'
endfunction


function! s:is_table(line) abort
  " Check if param:line is in a table
  return s:is_separator(a:line) ||
        \ (a:line !~# s:r_sep().s:r_sep() && a:line =~# '^\s*'.s:r_sep().'.\+'.s:r_sep().'\s*$')
endfunction


function! s:is_separator(line) abort
  " Check if param:line is a separator (ex: | --- | --- |)
  return a:line =~# '^\s*'.s:r_sep().'\(:\=--\+:\='.s:r_sep().'\)\+\s*$'
endfunction


function! s:is_separator_tail(line) abort
  return a:line =~# '^\{-1}\%(\s*\|-*\)\%('.s:r_sep().'-\+\)\+'.s:r_sep().'\s*$'
endfunction


function! s:is_last_column(lnum, cnum) abort
  let line = strpart(getline(a:lnum), a:cnum - 1)
  return line =~# s:r_sep().'\s*$'  && line !~# s:r_sep().'.*'.s:r_sep().'\s*$'
endfunction


function! s:is_first_column(lnum, cnum) abort
  let line = strpart(getline(a:lnum), 0, a:cnum - 1)
  return line =~# '^\s*$' ||
        \ (line =~# '^\s*'.s:r_sep() && line !~# '^\s*'.s:r_sep().'.*'.s:r_sep())
endfunction


function! s:count_separators_up(lnum) abort
  let lnum = a:lnum - 1
  while lnum > 1
    if !s:is_separator(getline(lnum))
      break
    endif
    let lnum -= 1
  endwhile

  return (a:lnum-lnum)
endfunction


function! s:count_separators_down(lnum) abort
  let lnum = a:lnum + 1
  while lnum < line('$')
    if !s:is_separator(getline(lnum))
      break
    endif
    let lnum += 1
  endwhile

  return (lnum-a:lnum)
endfunction


function! s:create_empty_row(cols) abort
  " Create an empty row of a:cols columns
  let row = s:s_sep()
  let cell = '   '.s:s_sep()

  for c in range(a:cols)
    let row .= cell
  endfor

  return row
endfunction


function! s:create_row_sep(cols) abort
  " Create an empty separator row of a:cols columns
  let row = s:s_sep()
  let cell = '---'.s:s_sep()

  for c in range(a:cols)
    let row .= cell
  endfor

  return row
endfunction


function! vimwiki#tbl#get_cells(line, ...) abort
  let result = []
  let state = 'NONE'
  let cell_start = 0
  let quote_start = 0
  let len = strlen(a:line) - 1

  " 'Simple' FSM
  while state !=# 'CELL'
    if quote_start != 0 && state !=# 'CELL'
      let state = 'CELL'
    endif
    for idx in range(quote_start, len)
      " The only way I know Vim can do Unicode...
      let ch = a:line[idx]
      if state ==# 'NONE'
        if ch ==# s:s_sep() && (idx < 1 || a:line[idx-1] !=# '\')
          let cell_start = idx + 1
          let state = 'CELL'
        endif
      elseif state ==# 'CELL'
        if ch ==# '[' || ch ==# '{'
          let state = 'BEFORE_QUOTE_START'
          let quote_start = idx
        elseif ch ==# s:s_sep() && (idx < 1 || a:line[idx-1] !=# '\')
          let cell = strpart(a:line, cell_start, idx - cell_start)
          if a:0 && a:1
            let cell = substitute(cell, '^ \(.*\) $', '\1', '')
          else
            let cell = vimwiki#u#trim(cell)
          endif
          call add(result, cell)
          let cell_start = idx + 1
        endif
      elseif state ==# 'BEFORE_QUOTE_START'
        if ch ==# '[' || ch ==# '{'
          let state = 'QUOTE'
          let quote_start = idx
        else
          let state = 'CELL'
        endif
      elseif state ==# 'QUOTE'
        if ch ==# ']' || ch ==# '}'
          let state = 'BEFORE_QUOTE_END'
        endif
      elseif state ==# 'BEFORE_QUOTE_END'
        if ch ==# ']' || ch ==# '}'
          let state = 'CELL'
        endif
      endif
    endfor
    if state ==# 'NONE'
      break
    endif
  endwhile

  return result
endfunction


function! s:col_count(lnum) abort
  return len(vimwiki#tbl#get_cells(getline(a:lnum)))
endfunction


function! s:get_indent(lnum, depth) abort
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
    if a:depth > 0 && lnum < a:lnum - a:depth
      break
    endif
  endwhile

  return indent
endfunction


function! s:get_rows(lnum, ...) abort
  let rows = []

  if !s:is_table(getline(a:lnum))
    return rows
  endif

  let lnum = a:lnum - 1
  let depth = a:0 > 0 ? a:1 : 0
  let ldepth = 0
  while lnum >= 1 && (depth == 0 || ldepth < depth)
    let line = getline(lnum)
    if s:is_table(line)
      call insert(rows, [lnum, line])
    else
      break
    endif
    let lnum -= 1
    let ldepth += 1
  endwhile

  let lnum = a:lnum
  while lnum <= line('$')
    let line = getline(lnum)
    if s:is_table(line)
      call add(rows, [lnum, line])
    else
      break
    endif
    if depth > 0
      break
    endif
    let lnum += 1
  endwhile

  return rows
endfunction


function! s:get_cell_aligns(lnum, ...) abort
  let aligns = {}
  let depth = a:0 > 0 ? a:1 : 0
  for [lnum, row] in s:get_rows(a:lnum, depth)
    if s:is_separator(row)
      let cells = vimwiki#tbl#get_cells(row)
      for idx in range(len(cells))
        let cell = cells[idx]
        if cell =~# '^--\+:'
          let aligns[idx] = 'right'
        elseif cell =~# '^:--\+:'
          let aligns[idx] = 'center'
        else
          let aligns[idx] = 'left'
        endif
      endfor
    else
      let cells = vimwiki#tbl#get_cells(row)
      for idx in range(len(cells))
        if !has_key(aligns, idx)
          let aligns[idx] = 'left'
        endif
      endfor
    endif
  endfor
  return aligns
endfunction


function! s:get_cell_aligns_fast(rows) abort
  let aligns = {}
  let clen = 0
  for [lnum, row] in a:rows
    if s:is_separator(row)
      return s:get_cell_aligns(lnum, 1)
    endif
    let cells = vimwiki#tbl#get_cells(row, 1)
    let clen = len(cells)
    for idx in range(clen)
      let cell = cells[idx]
      if !has_key(aligns, idx)
        let cs = matchlist(cell, '^\(\s*\)[^[:space:]].\{-}\(\s*\)$')
        if !empty(cs)
          let lstart = len(cs[1])
          let lend = len(cs[2])
          if lstart > 0 && lend > 0
            let aligns[idx] = 'center'
          elseif lend > 0
            let aligns[idx] = 'left'
          elseif lstart > 0
            let aligns[idx] = 'right'
          endif
        endif
      endif
    endfor
  endfor
  for idx in range(clen)
    if !has_key(aligns, idx)
      return {}
    endif
  endfor
  return aligns
endfunction


function! s:get_cell_max_lens(lnum, ...) abort
  let max_lens = {}
  let rows = a:0 > 2 ? a:3 : s:get_rows(a:lnum)
  for [lnum, row] in rows
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


function! s:get_aligned_rows(lnum, col1, col2, depth) abort
  let rows = []
  let aligns = {}
  let startlnum = 0
  let cells = []
  let max_lens = {}
  let check_all = 1
  if a:depth > 0
    let rows = s:get_rows(a:lnum, a:depth)
    let startlnum = len(rows) > 0 ? rows[0][0] : 0
    let lrows = len(rows)
    if lrows == a:depth + 1
      let line = rows[-1][1]
      if !s:is_separator(line)
        let lcells = vimwiki#tbl#get_cells(line)
        let lclen = len(lcells)
        let lmax_lens = repeat([0], lclen)
        let laligns = repeat(['left'], lclen)
        let rows[-1][1] = s:fmt_row(lcells, lmax_lens, laligns, 0, 0)
      endif
      let i = 1
      for [lnum, row] in rows
        call add(cells, vimwiki#tbl#get_cells(row, i != lrows - 1))
        let i += 1
      endfor
      let max_lens = s:get_cell_max_lens(a:lnum, cells, startlnum, rows)
      " user option not to expand last call
      if vimwiki#vars#get_global('table_reduce_last_col')
        let last_index = keys(max_lens)[-1]
        let max_lens[last_index] = 1
      endif
      let fst_lens = s:get_cell_max_lens(a:lnum, cells, startlnum, rows[0:0])
      let check_all = max_lens != fst_lens
      let aligns = s:get_cell_aligns_fast(rows[0:-2])
      let rows[-1][1] = line
    endif
  endif
  if check_all
    " all the table must be re-formatted
    let rows = s:get_rows(a:lnum)
    let startlnum = len(rows) > 0 ? rows[0][0] : 0
    let cells = []
    for [lnum, row] in rows
      call add(cells, vimwiki#tbl#get_cells(row))
    endfor
    let max_lens = s:get_cell_max_lens(a:lnum, cells, startlnum, rows)
    " user option not to expand last call
    if vimwiki#vars#get_global('table_reduce_last_col')
      let last_index = keys(max_lens)[-1]
      let max_lens[last_index] = 1
    endif
  endif
  if empty(aligns)
    let aligns = s:get_cell_aligns(a:lnum)
  endif
  let result = []
  for [lnum, row] in rows
    if s:is_separator(row)
      let new_row = s:fmt_sep(max_lens, aligns, a:col1, a:col2)
    else
      let new_row = s:fmt_row(cells[lnum - startlnum], max_lens, aligns,  a:col1, a:col2)
    endif
    call add(result, [lnum, new_row])
  endfor
  return result
endfunction


function! s:cur_column() abort
  " Number of the current column. Starts from 0.
  let line = getline('.')
  if !s:is_table(line)
    return -1
  endif
  " TODO: do we need conditional: if s:is_separator(line)

  let curs_pos = col('.')
  let mpos = match(line, s:r_sep(), 0)
  let col = -1
  while mpos < curs_pos && mpos != -1
    let mpos = match(line, s:r_sep(), mpos+1)
    if mpos != -1
      let col += 1
    endif
  endwhile
  return col
endfunction


function! s:fmt_cell(cell, max_len, align) abort
  let cell = ' '.a:cell.' '

  let diff = a:max_len - s:wide_len(a:cell)
  if diff == 0 && empty(a:cell)
    let diff = 1
  endif
  if a:align ==# 'left'
    let cell .= repeat(' ', diff)
  elseif a:align ==# 'right'
    let cell = repeat(' ',diff).cell
  else
    let cell = repeat(' ',diff/2).cell.repeat(' ',diff-diff/2)
  endif
  return cell
endfunction


function! s:fmt_row(cells, max_lens, aligns, col1, col2) abort
  let new_line = s:s_sep()
  for idx in range(len(a:cells))
    if idx == a:col1
      let idx = a:col2
    elseif idx == a:col2
      let idx = a:col1
    endif
    let value = a:cells[idx]
    let new_line .= s:fmt_cell(value, a:max_lens[idx], a:aligns[idx]).s:s_sep()
  endfor

  let idx = len(a:cells)
  while idx < len(a:max_lens)
    let new_line .= s:fmt_cell('', a:max_lens[idx], a:aligns[idx]).s:s_sep()
    let idx += 1
  endwhile
  return new_line
endfunction


function! s:fmt_cell_sep(max_len, align) abort
  let cell = ''
  if a:max_len == 0
    let cell .= '-'
  else
    let cell .= repeat('-', a:max_len)
  endif
  if a:align ==# 'right'
    return cell.'-:'
  elseif a:align ==# 'left'
    return cell.'--'
  else
    return ':'.cell.':'
  endif
endfunction


function! s:fmt_sep(max_lens, aligns, col1, col2) abort
  let new_line = s:s_sep()
  for idx in range(len(a:max_lens))
    if idx == a:col1
      let idx = a:col2
    elseif idx == a:col2
      let idx = a:col1
    endif
    let new_line .= s:fmt_cell_sep(a:max_lens[idx], a:aligns[idx]).s:s_sep()
  endfor
  return new_line
endfunction


function! s:kbd_create_new_row(cols, goto_first) abort
  let cmd = "\<ESC>o".s:create_empty_row(a:cols)
  let cmd .= "\<ESC>:call vimwiki#tbl#format(line('.'), 2)\<CR>"
  let cmd .= "\<ESC>0"
  if a:goto_first
    let cmd .= ":call search('\\(".s:r_sep()."\\)\\zs', 'c', line('.'))\<CR>"
  else
    let cmd .= (col('.')-1).'l'
    let cmd .= ":call search('\\(".s:r_sep()."\\)\\zs', 'bc', line('.'))\<CR>"
  endif
  let cmd .= 'a'

  return cmd
endfunction


function! s:kbd_goto_next_row() abort
  let cmd = "\<ESC>j"
  let cmd .= ":call search('.\\(".s:r_sep()."\\)', 'c', line('.'))\<CR>"
  let cmd .= ":call search('\\(".s:r_sep()."\\)\\zs', 'bc', line('.'))\<CR>"
  let cmd .= 'a'
  return cmd
endfunction


function! s:kbd_goto_prev_row() abort
  let cmd = "\<ESC>k"
  let cmd .= ":call search('.\\(".s:r_sep()."\\)', 'c', line('.'))\<CR>"
  let cmd .= ":call search('\\(".s:r_sep()."\\)\\zs', 'bc', line('.'))\<CR>"
  let cmd .= 'a'
  return cmd
endfunction


function! vimwiki#tbl#goto_next_col() abort
  " Used in s:kbd_goto_next_col
  let curcol = virtcol('.')
  let lnum = line('.')
  let depth = 2
  let newcol = s:get_indent(lnum, depth)
  let rows = s:get_rows(lnum, depth)
  let startlnum = len(rows) > 0 ? rows[0][0] : 0
  let cells = []
  for [lnum, row] in rows
    call add(cells, vimwiki#tbl#get_cells(row, 1))
  endfor
  let max_lens = s:get_cell_max_lens(lnum, cells, startlnum, rows)
  for cell_len in values(max_lens)
    if newcol >= curcol-1
      break
    endif
    let newcol += cell_len + 3 " +3 == 2 spaces + 1 separator |<space>...<space>
  endfor
  let newcol += 2 " +2 == 1 separator + 1 space |<space
  call vimwiki#u#cursor(lnum, newcol)
endfunction


function! s:kbd_goto_next_col(jumpdown) abort
  let cmd = "\<ESC>"
  if a:jumpdown
    let seps = s:count_separators_down(line('.'))
    let cmd .= seps.'j0'
  endif
  let cmd .= ":call vimwiki#tbl#goto_next_col()\<CR>a"
  return cmd
endfunction


function! vimwiki#tbl#goto_prev_col() abort
  " Used in s:kbd_goto_prev_col
  let curcol = virtcol('.')
  let lnum = line('.')
  let depth = 2
  let newcol = s:get_indent(lnum, depth)
  let rows = s:get_rows(lnum, depth)
  let startlnum = len(rows) > 0 ? rows[0][0] : 0
  let cells = []
  for [lnum, row] in rows
    call add(cells, vimwiki#tbl#get_cells(row, 1))
  endfor
  let max_lens = s:get_cell_max_lens(lnum, cells, startlnum, rows)
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


function! s:kbd_goto_prev_col(jumpup) abort
  let cmd = "\<ESC>"
  if a:jumpup
    let seps = s:count_separators_up(line('.'))
    let cmd .= seps.'k'
    let cmd .= '$'
  endif
  let cmd .= ":call vimwiki#tbl#goto_prev_col()\<CR>a"
  " let cmd .= ":call search('\\(".s:r_sep()."\\)\\zs', 'b', line('.'))\<CR>"
  " let cmd .= "a"
  return cmd
endfunction


function! vimwiki#tbl#kbd_cr() abort
  let lnum = line('.')
  if !s:is_table(getline(lnum))
    return ''
  endif

  if s:is_separator(getline(lnum+1)) || !s:is_table(getline(lnum+1))
    let cols = len(vimwiki#tbl#get_cells(getline(lnum)))
    return s:kbd_create_new_row(cols, 0)
  else
    return s:kbd_goto_next_row()
  endif
endfunction


function! vimwiki#tbl#kbd_tab() abort
  let lnum = line('.')
  if !s:is_table(getline(lnum))
    return "\<Tab>"
  endif

  let last = s:is_last_column(lnum, col('.'))
  let is_sep = s:is_separator_tail(getline(lnum))
  "vimwiki#u#debug("DEBUG kbd_tab> last=".last.", is_sep=".is_sep)
  if (is_sep || last) && !s:is_table(getline(lnum+1))
    let cols = len(vimwiki#tbl#get_cells(getline(lnum)))
    return s:kbd_create_new_row(cols, 1)
  endif
  return s:kbd_goto_next_col(is_sep || last)
endfunction


function! vimwiki#tbl#kbd_shift_tab() abort
  let lnum = line('.')
  if !s:is_table(getline(lnum))
    return "\<S-Tab>"
  endif

  let first = s:is_first_column(lnum, col('.'))
  let is_sep = s:is_separator_tail(getline(lnum))
  "vimwiki#u#debug("kbd_tab> ".first)
  if (is_sep || first) && !s:is_table(getline(lnum-1))
    return ''
  endif
  return s:kbd_goto_prev_col(is_sep || first)
endfunction


function! vimwiki#tbl#format(lnum, ...) abort
  " Clause in
  if !vimwiki#u#ft_is_vw()
    return
  endif
  let line = getline(a:lnum)
  if !s:is_table(line)
    return
  endif

  " Backup textwidth
  let textwidth = &textwidth

  let depth = a:0 == 1 ? a:1 : 0

  if a:0 == 2
    let col1 = a:1
    let col2 = a:2
  else
    let col1 = 0
    let col2 = 0
  endif

  let indent = s:get_indent(a:lnum, depth)
  if &expandtab
    let indentstring = repeat(' ', indent)
  else
    execute "let indentstring = repeat('\<TAB>', indent / &tabstop) . repeat(' ', indent % &tabstop)"
  endif

  " getting N = depth last rows is enough for having been formatted tables
  for [lnum, row] in s:get_aligned_rows(a:lnum, col1, col2, depth)
    let row = indentstring.row
    if getline(lnum) != row
      call setline(lnum, row)
    endif
  endfor

  " Restore user textwidth
  let &textwidth = textwidth
endfunction


function! vimwiki#tbl#create(...) abort
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


function! vimwiki#tbl#align_or_cmd(cmd, ...) abort
  if s:is_table(getline('.'))
    call call('vimwiki#tbl#format', [line('.')] + a:000)
  else
    exe 'normal! '.a:cmd
  endif
endfunction


function! vimwiki#tbl#move_column_left() abort
  " TODO: move_column_left and move_column_right are good candidates to be refactored.
  " Clause in
  let line = getline('.')
  if !s:is_table(line)
    return
  endif
  let cur_col = s:cur_column()
  if cur_col == -1
    return
  endif
  if cur_col <= 0
    return
  endif

  call vimwiki#tbl#format(line('.'), cur_col-1, cur_col)
  call cursor(line('.'), 1)

  let sep = '\('.s:r_sep().'\).\zs'
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
endfunction


function! vimwiki#tbl#move_column_right() abort
  " Clause in
  let line = getline('.')
  if !s:is_table(line)
    return
  endif
  let cur_col = s:cur_column()
  if cur_col == -1
    return
  endif
  if cur_col >= s:col_count(line('.'))-1
    return
  endif

  " Format table && Put cursor on first col
  call vimwiki#tbl#format(line('.'), cur_col, cur_col+1)
  call cursor(line('.'), 1)

  " Change add one to all col
  let sep = '\('.s:r_sep().'\).\zs'
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
endfunction


function! vimwiki#tbl#get_rows(lnum) abort
  return s:get_rows(a:lnum)
endfunction


function! vimwiki#tbl#is_table(line) abort
  return s:is_table(a:line)
endfunction


function! vimwiki#tbl#is_separator(line) abort
  return s:is_separator(a:line)
endfunction


function! vimwiki#tbl#cell_splitter() abort
  return s:cell_splitter()
endfunction


function! vimwiki#tbl#sep_splitter() abort
  return s:sep_splitter()
endfunction
