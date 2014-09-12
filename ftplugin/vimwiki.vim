" vim:tabstop=2:shiftwidth=2:expandtab:foldmethod=marker:textwidth=79
" Vimwiki filetype plugin file
" Author: Maxim Kim <habamax@gmail.com>
" Home: http://code.google.com/p/vimwiki/

if exists("b:did_ftplugin")
  finish
endif
let b:did_ftplugin = 1  " Don't load another plugin for this buffer

" UNDO list {{{
" Reset the following options to undo this plugin.
let b:undo_ftplugin = "setlocal ".
      \ "suffixesadd< isfname< comments< ".
      \ "formatoptions< foldtext< ".
      \ "foldmethod< foldexpr< commentstring< "
" UNDO }}}

" MISC STUFF {{{

setlocal commentstring=%%%s

if g:vimwiki_conceallevel && exists("+conceallevel")
  let &l:conceallevel = g:vimwiki_conceallevel
endif

" MISC }}}

" GOTO FILE: gf {{{
execute 'setlocal suffixesadd='.VimwikiGet('ext')
setlocal isfname-=[,]
" gf}}}

" Autocreate list items {{{
" for list items, and list items with checkboxes
setlocal formatoptions+=tnro
setlocal formatoptions-=cq
if VimwikiGet('syntax') == 'default'
  setl comments=b:*,b:#,b:-
  setl formatlistpat=^\\s*[*#-]\\s*
elseif VimwikiGet('syntax') == 'markdown'
  setlocal comments=fb:*,fb:-,fb:+,nb:> commentstring=\ >\ %s
  setlocal formatlistpat=^\\s*\\d\\+\\.\\s\\+\\\|^[-*+]\\s\\+j
else
  setl comments=n:*,n:#
endif

if !empty(&langmap)
  " Valid only if langmap is a comma separated pairs of chars
  let l_o = matchstr(&langmap, '\C,\zs.\zeo,')
  if l_o
    exe 'nnoremap <buffer> '.l_o.' :call vimwiki#lst#kbd_oO("o")<CR>a'
  endif

  let l_O = matchstr(&langmap, '\C,\zs.\zeO,')
  if l_O
    exe 'nnoremap <buffer> '.l_O.' :call vimwiki#lst#kbd_oO("O")<CR>a'
  endif
endif

" COMMENTS }}}

" FOLDING for headers and list items using expr fold method. {{{

" Folding list items using expr fold method. {{{

function! s:get_base_level(lnum) "{{{
  let lnum = a:lnum - 1
  while lnum > 0
    if getline(lnum) =~ g:vimwiki_rxHeader
      return vimwiki#u#count_first_sym(getline(lnum))
    endif
    let lnum -= 1
  endwhile
  return 0
endfunction "}}}

function! s:find_forward(rx_item, lnum) "{{{
  let lnum = a:lnum + 1

  while lnum <= line('$')
    let line = getline(lnum)
    if line =~ a:rx_item
          \ || line =~ '^\S'
          \ || line =~ g:vimwiki_rxHeader
      break
    endif
    let lnum += 1
  endwhile

  return [lnum, getline(lnum)]
endfunction "}}}

function! s:find_backward(rx_item, lnum) "{{{
  let lnum = a:lnum - 1

  while lnum > 1
    let line = getline(lnum)
    if line =~ a:rx_item
          \ || line =~ '^\S'
      break
    endif
    let lnum -= 1
  endwhile

  return [lnum, getline(lnum)]
endfunction "}}}

function! s:get_li_level(lnum) "{{{
  if VimwikiGet('syntax') == 'media'
    let level = vimwiki#u#count_first_sym(getline(a:lnum))
  else
    let level = (indent(a:lnum) / &sw)
  endif
  return level
endfunction "}}}

function! s:get_start_list(rx_item, lnum) "{{{
  let lnum = a:lnum
  while lnum >= 1
    let line = getline(lnum)
    if line !~ a:rx_item && line =~ '^\S'
      return nextnonblank(lnum + 1)
    endif
    let lnum -= 1
  endwhile
  return 0
endfunction "}}}

function! VimwikiFoldListLevel(lnum) "{{{
  let line = getline(a:lnum)

  "" XXX Disabled: Header/section folding...
  "if line =~ g:vimwiki_rxHeader
  "  return '>'.vimwiki#u#count_first_sym(line)
  "endif

  "let nnline = getline(a:lnum+1)

  "" Unnecessary?
  "if nnline =~ g:vimwiki_rxHeader
  "  return '<'.vimwiki#u#count_first_sym(nnline)
  "endif
  "" Very slow when called on every single line!
  "let base_level = s:get_base_level(a:lnum)

  "FIXME does not work correctly
  let base_level = 0

  if line =~ g:vimwiki_rxListItem
    let [nnum, nline] = s:find_forward(g:vimwiki_rxListItem, a:lnum)
    let level = s:get_li_level(a:lnum)
    let leveln = s:get_li_level(nnum)
    let adj = s:get_li_level(s:get_start_list(g:vimwiki_rxListItem, a:lnum))

    if leveln > level
      return ">".(base_level+leveln-adj)
    " check if multilined list item
    elseif (nnum-a:lnum) > 1
          \ && (nline =~ g:vimwiki_rxListItem || nnline !~ '^\s*$')
      return ">".(base_level+level+1-adj)
    else
      return (base_level+level-adj)
    endif
  else
    " process multilined list items
    let [pnum, pline] = s:find_backward(g:vimwiki_rxListItem, a:lnum)
    if pline =~ g:vimwiki_rxListItem
      if indent(a:lnum) >= indent(pnum) && line !~ '^\s*$'
        let level = s:get_li_level(pnum)
        let adj = s:get_li_level(s:get_start_list(g:vimwiki_rxListItem, pnum))
        return (base_level+level+1-adj)
      endif
    endif
  endif

  return base_level
endfunction "}}}
" Folding list items }}}

" Folding sections and code blocks using expr fold method. {{{
function! VimwikiFoldLevel(lnum) "{{{
  let line = getline(a:lnum)

  " Header/section folding...
  if line =~ g:vimwiki_rxHeader
    return '>'.vimwiki#u#count_first_sym(line)
  " Code block folding...
  elseif line =~ '^\s*'.g:vimwiki_rxPreStart
    return 'a1'
  elseif line =~ '^\s*'.g:vimwiki_rxPreEnd.'\s*$'
    return 's1'
  else
    return "="
  endif

endfunction "}}}

" Constants used by VimwikiFoldText {{{
" use \u2026 and \u21b2 (or \u2424) if enc=utf-8 to save screen space
let s:ellipsis = (&enc ==? 'utf-8') ? "\u2026" : "..."
let s:ell_len = strlen(s:ellipsis)
let s:newline = (&enc ==? 'utf-8') ? "\u21b2 " : "  "
let s:tolerance = 5
" }}}

function! s:shorten_text_simple(text, len) "{{{ unused
  let spare_len = a:len - len(a:text)
  return (spare_len>=0) ? [a:text,spare_len] : [a:text[0:a:len].s:ellipsis, -1]
endfunction "}}}

" s:shorten_text(text, len) = [string, spare] with "spare" = len-strlen(string)
" for long enough "text", the string's length is within s:tolerance of "len"
" (so that -s:tolerance <= spare <= s:tolerance, "string" ends with s:ellipsis)
function! s:shorten_text(text, len) "{{{ returns [string, spare]
  let spare_len = a:len - strlen(a:text)
  if (spare_len + s:tolerance >= 0)
    return [a:text, spare_len]
  endif
  " try to break on a space; assumes a:len-s:ell_len >= s:tolerance
  let newlen = a:len - s:ell_len
  let idx = strridx(a:text, ' ', newlen + s:tolerance)
  let break_idx = (idx + s:tolerance >= newlen) ? idx : newlen
  return [a:text[0:break_idx].s:ellipsis, newlen - break_idx]
endfunction "}}}

function! VimwikiFoldText() "{{{
  let line = getline(v:foldstart)
  let main_text = substitute(line, '^\s*', repeat(' ',indent(v:foldstart)), '')
  let fold_len = v:foldend - v:foldstart + 1
  let len_text = ' ['.fold_len.'] '
  if line !~ '^\s*'.g:vimwiki_rxPreStart
    let [main_text, spare_len] = s:shorten_text(main_text, 50)
    return main_text.len_text
  else
    " fold-text for code blocks: use one or two of the starting lines
    let [main_text, spare_len] = s:shorten_text(main_text, 24)
    let line1 = substitute(getline(v:foldstart+1), '^\s*', ' ', '')
    let [content_text, spare_len] = s:shorten_text(line1, spare_len+20)
    if spare_len > s:tolerance && fold_len > 3
      let line2 = substitute(getline(v:foldstart+2), '^\s*', s:newline, '')
      let [more_text, spare_len] = s:shorten_text(line2, spare_len+12)
      let content_text .= more_text
    endif
    return main_text.len_text.content_text
  endif
endfunction "}}}

" Folding sections and code blocks }}}
" FOLDING }}}

" COMMANDS {{{
command! -buffer Vimwiki2HTML
      \ silent w <bar> 
      \ let res = vimwiki#html#Wiki2HTML(expand(VimwikiGet('path_html')),
      \                             expand('%'))
      \<bar>
      \ if res != '' | echo 'Vimwiki: HTML conversion is done, output: '.expand(VimwikiGet('path_html')) | endif
command! -buffer Vimwiki2HTMLBrowse
      \ silent w <bar>
      \ call vimwiki#base#system_open_link(vimwiki#html#Wiki2HTML(
      \         expand(VimwikiGet('path_html')),
      \         expand('%')))
command! -buffer VimwikiAll2HTML
      \ call vimwiki#html#WikiAll2HTML(expand(VimwikiGet('path_html')))

command! -buffer VimwikiNextLink call vimwiki#base#find_next_link()
command! -buffer VimwikiPrevLink call vimwiki#base#find_prev_link()
command! -buffer VimwikiDeleteLink call vimwiki#base#delete_link()
command! -buffer VimwikiRenameLink call vimwiki#base#rename_link()
command! -buffer VimwikiFollowLink call vimwiki#base#follow_link('nosplit')
command! -buffer VimwikiGoBackLink call vimwiki#base#go_back_link()
command! -buffer VimwikiSplitLink call vimwiki#base#follow_link('split')
command! -buffer VimwikiVSplitLink call vimwiki#base#follow_link('vsplit')

command! -buffer -nargs=? VimwikiNormalizeLink call vimwiki#base#normalize_link(<f-args>)

command! -buffer VimwikiTabnewLink call vimwiki#base#follow_link('tabnew')

command! -buffer -range VimwikiToggleListItem call vimwiki#lst#ToggleListItem(<line1>, <line2>)

command! -buffer VimwikiGenerateLinks call vimwiki#base#generate_links()

command! -buffer -nargs=0 VimwikiBacklinks call vimwiki#base#backlinks()
command! -buffer -nargs=0 VWB call vimwiki#base#backlinks()

exe 'command! -buffer -nargs=* VimwikiSearch lvimgrep <args> '.
      \ escape(VimwikiGet('path').'**/*'.VimwikiGet('ext'), ' ')

exe 'command! -buffer -nargs=* VWS lvimgrep <args> '.
      \ escape(VimwikiGet('path').'**/*'.VimwikiGet('ext'), ' ')

command! -buffer -nargs=1 VimwikiGoto call vimwiki#base#goto("<args>")


" list commands
command! -buffer -nargs=* VimwikiListChangeLevel call vimwiki#lst#change_level(<f-args>)

" table commands
command! -buffer -nargs=* VimwikiTable call vimwiki#tbl#create(<f-args>)
command! -buffer VimwikiTableAlignQ call vimwiki#tbl#align_or_cmd('gqq')
command! -buffer VimwikiTableAlignW call vimwiki#tbl#align_or_cmd('gww')
command! -buffer VimwikiTableMoveColumnLeft call vimwiki#tbl#move_column_left()
command! -buffer VimwikiTableMoveColumnRight call vimwiki#tbl#move_column_right()

" diary commands
command! -buffer VimwikiDiaryNextDay call vimwiki#diary#goto_next_day()
command! -buffer VimwikiDiaryPrevDay call vimwiki#diary#goto_prev_day()

" COMMANDS }}}

" KEYBINDINGS {{{
if g:vimwiki_use_mouse
  nmap <buffer> <S-LeftMouse> <NOP>
  nmap <buffer> <C-LeftMouse> <NOP>
  nnoremap <silent><buffer> <2-LeftMouse> :call vimwiki#base#follow_link("nosplit", "\<lt>2-LeftMouse>")<CR>
  nnoremap <silent><buffer> <S-2-LeftMouse> <LeftMouse>:VimwikiSplitLink<CR>
  nnoremap <silent><buffer> <C-2-LeftMouse> <LeftMouse>:VimwikiVSplitLink<CR>
  nnoremap <silent><buffer> <RightMouse><LeftMouse> :VimwikiGoBackLink<CR>
endif


if !hasmapto('<Plug>Vimwiki2HTML')
  nmap <buffer> <Leader>wh <Plug>Vimwiki2HTML
endif
nnoremap <script><buffer>
      \ <Plug>Vimwiki2HTML :Vimwiki2HTML<CR>

if !hasmapto('<Plug>Vimwiki2HTMLBrowse')
  nmap <buffer> <Leader>whh <Plug>Vimwiki2HTMLBrowse
endif
nnoremap <script><buffer>
      \ <Plug>Vimwiki2HTMLBrowse :Vimwiki2HTMLBrowse<CR>

if !hasmapto('<Plug>VimwikiFollowLink')
  nmap <silent><buffer> <CR> <Plug>VimwikiFollowLink
endif
nnoremap <silent><script><buffer>
      \ <Plug>VimwikiFollowLink :VimwikiFollowLink<CR>

if !hasmapto('<Plug>VimwikiSplitLink')
  nmap <silent><buffer> <S-CR> <Plug>VimwikiSplitLink
endif
nnoremap <silent><script><buffer>
      \ <Plug>VimwikiSplitLink :VimwikiSplitLink<CR>

if !hasmapto('<Plug>VimwikiVSplitLink')
  nmap <silent><buffer> <C-CR> <Plug>VimwikiVSplitLink
endif
nnoremap <silent><script><buffer>
      \ <Plug>VimwikiVSplitLink :VimwikiVSplitLink<CR>

if !hasmapto('<Plug>VimwikiNormalizeLink')
  nmap <silent><buffer> + <Plug>VimwikiNormalizeLink
endif
nnoremap <silent><script><buffer>
      \ <Plug>VimwikiNormalizeLink :VimwikiNormalizeLink 0<CR>

if !hasmapto('<Plug>VimwikiNormalizeLinkVisual')
  vmap <silent><buffer> + <Plug>VimwikiNormalizeLinkVisual
endif
vnoremap <silent><script><buffer>
      \ <Plug>VimwikiNormalizeLinkVisual :<C-U>VimwikiNormalizeLink 1<CR>

if !hasmapto('<Plug>VimwikiNormalizeLinkVisualCR')
  vmap <silent><buffer> <CR> <Plug>VimwikiNormalizeLinkVisualCR
endif
vnoremap <silent><script><buffer>
      \ <Plug>VimwikiNormalizeLinkVisualCR :<C-U>VimwikiNormalizeLink 1<CR>

if !hasmapto('<Plug>VimwikiTabnewLink')
  nmap <silent><buffer> <D-CR> <Plug>VimwikiTabnewLink
  nmap <silent><buffer> <C-S-CR> <Plug>VimwikiTabnewLink
endif
nnoremap <silent><script><buffer>
      \ <Plug>VimwikiTabnewLink :VimwikiTabnewLink<CR>

if !hasmapto('<Plug>VimwikiGoBackLink')
  nmap <silent><buffer> <BS> <Plug>VimwikiGoBackLink
endif
nnoremap <silent><script><buffer>
      \ <Plug>VimwikiGoBackLink :VimwikiGoBackLink<CR>

if !hasmapto('<Plug>VimwikiNextLink')
  nmap <silent><buffer> <TAB> <Plug>VimwikiNextLink
endif
nnoremap <silent><script><buffer>
      \ <Plug>VimwikiNextLink :VimwikiNextLink<CR>

if !hasmapto('<Plug>VimwikiPrevLink')
  nmap <silent><buffer> <S-TAB> <Plug>VimwikiPrevLink
endif
nnoremap <silent><script><buffer>
      \ <Plug>VimwikiPrevLink :VimwikiPrevLink<CR>

if !hasmapto('<Plug>VimwikiDeleteLink')
  nmap <silent><buffer> <Leader>wd <Plug>VimwikiDeleteLink
endif
nnoremap <silent><script><buffer>
      \ <Plug>VimwikiDeleteLink :VimwikiDeleteLink<CR>

if !hasmapto('<Plug>VimwikiRenameLink')
  nmap <silent><buffer> <Leader>wr <Plug>VimwikiRenameLink
endif
nnoremap <silent><script><buffer>
      \ <Plug>VimwikiRenameLink :VimwikiRenameLink<CR>

if !hasmapto('<Plug>VimwikiToggleListItem')
  nmap <silent><buffer> <C-Space> <Plug>VimwikiToggleListItem
  vmap <silent><buffer> <C-Space> <Plug>VimwikiToggleListItem
  if has("unix")
    nmap <silent><buffer> <C-@> <Plug>VimwikiToggleListItem
  endif
endif
nnoremap <silent><script><buffer>
      \ <Plug>VimwikiToggleListItem :VimwikiToggleListItem<CR>

if !hasmapto('<Plug>VimwikiDiaryNextDay')
  nmap <silent><buffer> <C-Down> <Plug>VimwikiDiaryNextDay
endif
nnoremap <silent><script><buffer>
      \ <Plug>VimwikiDiaryNextDay :VimwikiDiaryNextDay<CR>

if !hasmapto('<Plug>VimwikiDiaryPrevDay')
  nmap <silent><buffer> <C-Up> <Plug>VimwikiDiaryPrevDay
endif
nnoremap <silent><script><buffer>
      \ <Plug>VimwikiDiaryPrevDay :VimwikiDiaryPrevDay<CR>

function! s:CR() "{{{
  let res = vimwiki#lst#kbd_cr()
  if res == "\<CR>" && g:vimwiki_table_mappings
    let res = vimwiki#tbl#kbd_cr()
  endif
  return res
endfunction "}}}

" List and Table <CR> mapping
inoremap <buffer> <expr> <CR> <SID>CR()

" List mappings
nnoremap <buffer> o :<C-U>call vimwiki#lst#kbd_oO('o')<CR>
nnoremap <buffer> O :<C-U>call vimwiki#lst#kbd_oO('O')<CR>
nnoremap <buffer> gll :VimwikiListChangeLevel <<<CR>
nnoremap <buffer> glm :VimwikiListChangeLevel >><CR>
nnoremap <buffer> gl* :VimwikiListChangeLevel *<CR>
nnoremap <buffer> gl8 :VimwikiListChangeLevel *<CR>
if VimwikiGet('syntax') == 'default'
  nnoremap <buffer> gl- :VimwikiListChangeLevel -<CR>
  nnoremap <buffer> gl# :VimwikiListChangeLevel #<CR>
  nnoremap <buffer> gl3 :VimwikiListChangeLevel #<CR>
elseif VimwikiGet('syntax') == 'markdown'
  nnoremap <buffer> gl- :VimwikiListChangeLevel -<CR>
  nnoremap <buffer> gl1 :VimwikiListChangeLevel 1.<CR>
elseif VimwikiGet('syntax') == 'media'
  nnoremap <buffer> gl# :VimwikiListChangeLevel #<CR>
  nnoremap <buffer> gl3 :VimwikiListChangeLevel #<CR>
endif


" Table mappings
if g:vimwiki_table_mappings
  inoremap <expr> <buffer> <Tab> vimwiki#tbl#kbd_tab()
  inoremap <expr> <buffer> <S-Tab> vimwiki#tbl#kbd_shift_tab()
endif

nnoremap <buffer> gqq :VimwikiTableAlignQ<CR>
nnoremap <buffer> gww :VimwikiTableAlignW<CR>
if !hasmapto('<Plug>VimwikiTableMoveColumnLeft')
  nmap <silent><buffer> <A-Left> <Plug>VimwikiTableMoveColumnLeft
endif
nnoremap <silent><script><buffer>
      \ <Plug>VimwikiTableMoveColumnLeft :VimwikiTableMoveColumnLeft<CR>
if !hasmapto('<Plug>VimwikiTableMoveColumnRight')
  nmap <silent><buffer> <A-Right> <Plug>VimwikiTableMoveColumnRight
endif
nnoremap <silent><script><buffer>
      \ <Plug>VimwikiTableMoveColumnRight :VimwikiTableMoveColumnRight<CR>



" Text objects {{{
onoremap <silent><buffer> ah :<C-U>call vimwiki#base#TO_header(0, 0)<CR>
vnoremap <silent><buffer> ah :<C-U>call vimwiki#base#TO_header(0, 1)<CR>

onoremap <silent><buffer> ih :<C-U>call vimwiki#base#TO_header(1, 0)<CR>
vnoremap <silent><buffer> ih :<C-U>call vimwiki#base#TO_header(1, 1)<CR>

onoremap <silent><buffer> a\ :<C-U>call vimwiki#base#TO_table_cell(0, 0)<CR>
vnoremap <silent><buffer> a\ :<C-U>call vimwiki#base#TO_table_cell(0, 1)<CR>

onoremap <silent><buffer> i\ :<C-U>call vimwiki#base#TO_table_cell(1, 0)<CR>
vnoremap <silent><buffer> i\ :<C-U>call vimwiki#base#TO_table_cell(1, 1)<CR>

onoremap <silent><buffer> ac :<C-U>call vimwiki#base#TO_table_col(0, 0)<CR>
vnoremap <silent><buffer> ac :<C-U>call vimwiki#base#TO_table_col(0, 1)<CR>

onoremap <silent><buffer> ic :<C-U>call vimwiki#base#TO_table_col(1, 0)<CR>
vnoremap <silent><buffer> ic :<C-U>call vimwiki#base#TO_table_col(1, 1)<CR>

if !hasmapto('<Plug>VimwikiAddHeaderLevel')
  nmap <silent><buffer> = <Plug>VimwikiAddHeaderLevel
endif
nnoremap <silent><buffer> <Plug>VimwikiAddHeaderLevel :
      \<C-U>call vimwiki#base#AddHeaderLevel()<CR>

if !hasmapto('<Plug>VimwikiRemoveHeaderLevel')
  nmap <silent><buffer> - <Plug>VimwikiRemoveHeaderLevel
endif
nnoremap <silent><buffer> <Plug>VimwikiRemoveHeaderLevel :
      \<C-U>call vimwiki#base#RemoveHeaderLevel()<CR>


" }}}

" KEYBINDINGS }}}

" AUTOCOMMANDS {{{
if VimwikiGet('auto_export')
  " Automatically generate HTML on page write.
  augroup vimwiki
    au BufWritePost <buffer> 
      \ call vimwiki#html#Wiki2HTML(expand(VimwikiGet('path_html')),
      \                             expand('%'))
  augroup END
endif

" AUTOCOMMANDS }}}

" PASTE, CAT URL {{{
" html commands
command! -buffer VimwikiPasteUrl call vimwiki#html#PasteUrl(expand('%:p'))
command! -buffer VimwikiCatUrl call vimwiki#html#CatUrl(expand('%:p'))
" }}}

" DEBUGGING {{{
command! VimwikiPrintWikiState call vimwiki#base#print_wiki_state()
command! VimwikiReadLocalOptions call vimwiki#base#read_wiki_options(1)
" }}}
