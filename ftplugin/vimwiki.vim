" vim:tabstop=2:shiftwidth=2:expandtab:foldmethod=marker:textwidth=79
" Vimwiki filetype plugin file
" Author: Maxim Kim <habamax@gmail.com>
" Home: http://code.google.com/p/vimwiki/

if exists("b:did_ftplugin")
  finish
endif
let b:did_ftplugin = 1  " Don't load another plugin for this buffer

call vimwiki#u#reload_regexes()

" UNDO list {{{
" Reset the following options to undo this plugin.
let b:undo_ftplugin = "setlocal ".
      \ "suffixesadd< isfname< formatlistpat< ".
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

" LIST STUFF {{{
" settings necessary for the automatic formatting of lists
setlocal autoindent
setlocal nosmartindent
setlocal nocindent
setlocal comments=""
setlocal formatoptions-=c
setlocal formatoptions-=r
setlocal formatoptions-=o
setlocal formatoptions-=2
setlocal formatoptions+=n

"Create 'formatlistpat'
let &formatlistpat = g:vimwiki_rxListItem

if !empty(&langmap)
  " Valid only if langmap is a comma separated pairs of chars
  let l_o = matchstr(&langmap, '\C,\zs.\zeo,')
  if l_o
    exe 'nnoremap <silent> <buffer> '.l_o.' :call vimwiki#lst#kbd_o()<CR>a'
  endif

  let l_O = matchstr(&langmap, '\C,\zs.\zeO,')
  if l_O
    exe 'nnoremap <silent> <buffer> '.l_O.' :call vimwiki#lst#kbd_O()<CR>a'
  endif
endif

" LIST STUFF }}}

" FOLDING {{{
" Folding list items {{{
function! VimwikiFoldListLevel(lnum) "{{{
  return vimwiki#lst#fold_level(a:lnum)
endfunction "}}}
" Folding list items }}}

" Folding sections and code blocks {{{
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
      \ if res != '' | echo 'Vimwiki: HTML conversion is done.' | endif
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

command! -buffer VimwikiGenerateLinks call vimwiki#base#generate_links()

command! -buffer -nargs=0 VimwikiBacklinks call vimwiki#base#backlinks()
command! -buffer -nargs=0 VWB call vimwiki#base#backlinks()

exe 'command! -buffer -nargs=* VimwikiSearch lvimgrep <args> '.
      \ escape(VimwikiGet('path').'**/*'.VimwikiGet('ext'), ' ')

exe 'command! -buffer -nargs=* VWS lvimgrep <args> '.
      \ escape(VimwikiGet('path').'**/*'.VimwikiGet('ext'), ' ')

command! -buffer -nargs=1 VimwikiGoto call vimwiki#base#goto("<args>")


" list commands
command! -buffer -nargs=+ VimwikiReturn call <SID>CR(<f-args>)
command! -buffer -range -nargs=1 VimwikiChangeSymbolTo call vimwiki#lst#change_marker(<line1>, <line2>, <f-args>, 'n')
command! -buffer -range -nargs=1 VimwikiListChangeSymbolI call vimwiki#lst#change_marker(<line1>, <line2>, <f-args>, 'i')
command! -buffer -nargs=1 VimwikiChangeSymbolInListTo call vimwiki#lst#change_marker_in_list(<f-args>)
command! -buffer -range VimwikiToggleCheckbox call vimwiki#lst#toggle_cb(<line1>, <line2>)
command! -buffer -range -nargs=+ VimwikiListChangeLvl call vimwiki#lst#change_level(<line1>, <line2>, <f-args>)
command! -buffer -range VimwikiRemoveSingleCB call vimwiki#lst#remove_cb(<line1>, <line2>)
command! -buffer VimwikiRemoveCBInList call vimwiki#lst#remove_cb_in_list()
command! -buffer VimwikiRenumberList call vimwiki#lst#adjust_numbered_list()
command! -buffer VimwikiRenumberAllLists call vimwiki#lst#adjust_whole_buffer()
command! -buffer VimwikiListToggle call vimwiki#lst#toggle_list_item()

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

" List mappings
if !hasmapto('<Plug>VimwikiToggleCheckbox')
  nmap <silent><buffer> <C-Space> <Plug>VimwikiToggleCheckbox
  vmap <silent><buffer> <C-Space> <Plug>VimwikiToggleCheckbox
  if has("unix")
    nmap <silent><buffer> <C-@> <Plug>VimwikiToggleCheckbox
    vmap <silent><buffer> <C-@> <Plug>VimwikiToggleCheckbox
  endif
endif
nnoremap <silent><script><buffer>
      \ <Plug>VimwikiToggleCheckbox :VimwikiToggleCheckbox<CR>
vnoremap <silent><script><buffer>
      \ <Plug>VimwikiToggleCheckbox :VimwikiToggleCheckbox<CR>

if !hasmapto('<Plug>VimwikiDecreaseLvlSingleItem', 'i')
  imap <silent><buffer> <C-D>
        \ <Plug>VimwikiDecreaseLvlSingleItem
endif
inoremap <silent><script><buffer> <Plug>VimwikiDecreaseLvlSingleItem
    \ <C-O>:VimwikiListChangeLvl decrease 0<CR>

if !hasmapto('<Plug>VimwikiIncreaseLvlSingleItem', 'i')
  imap <silent><buffer> <C-T>
        \ <Plug>VimwikiIncreaseLvlSingleItem
endif
inoremap <silent><script><buffer> <Plug>VimwikiIncreaseLvlSingleItem
    \ <C-O>:VimwikiListChangeLvl increase 0<CR>

if !hasmapto('<Plug>VimwikiListNextSymbol', 'i')
  imap <silent><buffer> <C-L><C-J>
        \ <Plug>VimwikiListNextSymbol
endif
inoremap <silent><script><buffer> <Plug>VimwikiListNextSymbol
      \ <C-O>:VimwikiListChangeSymbolI next<CR>

if !hasmapto('<Plug>VimwikiListPrevSymbol', 'i')
  imap <silent><buffer> <C-L><C-K>
        \ <Plug>VimwikiListPrevSymbol
endif
inoremap <silent><script><buffer> <Plug>VimwikiListPrevSymbol
      \ <C-O>:VimwikiListChangeSymbolI prev<CR>

if !hasmapto('<Plug>VimwikiListToggle', 'i')
  imap <silent><buffer> <C-L><C-M> <Plug>VimwikiListToggle
endif
inoremap <silent><script><buffer> <Plug>VimwikiListToggle <Esc>:VimwikiListToggle<CR>

nnoremap <silent> <buffer> o :call vimwiki#lst#kbd_o()<CR>
nnoremap <silent> <buffer> O :call vimwiki#lst#kbd_O()<CR>

if !hasmapto('<Plug>VimwikiRenumberList')
  nmap <silent><buffer> glr <Plug>VimwikiRenumberList
endif
nnoremap <silent><script><buffer>
      \ <Plug>VimwikiRenumberList :VimwikiRenumberList<CR>

if !hasmapto('<Plug>VimwikiRenumberAllLists')
  nmap <silent><buffer> gLr <Plug>VimwikiRenumberAllLists
  nmap <silent><buffer> gLR <Plug>VimwikiRenumberAllLists
endif
nnoremap <silent><script><buffer>
      \ <Plug>VimwikiRenumberAllLists :VimwikiRenumberAllLists<CR>

if !hasmapto('<Plug>VimwikiDecreaseLvlSingleItem')
  map <silent><buffer> glh <Plug>VimwikiDecreaseLvlSingleItem
endif
noremap <silent><script><buffer>
    \ <Plug>VimwikiDecreaseLvlSingleItem :VimwikiListChangeLvl decrease 0<CR>

if !hasmapto('<Plug>VimwikiIncreaseLvlSingleItem')
  map <silent><buffer> gll <Plug>VimwikiIncreaseLvlSingleItem
endif
noremap <silent><script><buffer>
    \ <Plug>VimwikiIncreaseLvlSingleItem :VimwikiListChangeLvl increase 0<CR>

if !hasmapto('<Plug>VimwikiDecreaseLvlWholeItem')
  map <silent><buffer> gLh <Plug>VimwikiDecreaseLvlWholeItem
  map <silent><buffer> gLH <Plug>VimwikiDecreaseLvlWholeItem
endif
noremap <silent><script><buffer>
    \ <Plug>VimwikiDecreaseLvlWholeItem :VimwikiListChangeLvl decrease 1<CR>

if !hasmapto('<Plug>VimwikiIncreaseLvlWholeItem')
  map <silent><buffer> gLl <Plug>VimwikiIncreaseLvlWholeItem
  map <silent><buffer> gLL <Plug>VimwikiIncreaseLvlWholeItem
endif
noremap <silent><script><buffer>
    \ <Plug>VimwikiIncreaseLvlWholeItem :VimwikiListChangeLvl increase 1<CR>

if !hasmapto('<Plug>VimwikiRemoveSingleCB')
  map <silent><buffer> gl<Space> <Plug>VimwikiRemoveSingleCB
endif
noremap <silent><script><buffer>
    \ <Plug>VimwikiRemoveSingleCB :VimwikiRemoveSingleCB<CR>

if !hasmapto('<Plug>VimwikiRemoveCBInList')
  map <silent><buffer> gL<Space> <Plug>VimwikiRemoveCBInList
endif
noremap <silent><script><buffer>
    \ <Plug>VimwikiRemoveCBInList :VimwikiRemoveCBInList<CR>

for s:k in keys(g:vimwiki_bullet_types)
  let s:char = (s:k == '•' ? '.' : s:k)

  if !hasmapto(':VimwikiChangeSymbolTo '.s:k.'<CR>')
    exe 'noremap <silent><buffer> gl'.s:char.' :VimwikiChangeSymbolTo '.s:k.'<CR>'
  endif
  if !hasmapto(':VimwikiChangeSymbolInListTo '.s:k.'<CR>')
    exe 'noremap <silent><buffer> gL'.s:char.' :VimwikiChangeSymbolInListTo '.s:k.'<CR>'
  endif

endfor
for s:k in g:vimwiki_number_types
  if !hasmapto(':VimwikiChangeSymbolTo '.s:k.'<CR>')
    exe 'noremap <silent><buffer> gl'.s:k[0].' :VimwikiChangeSymbolTo '.s:k.'<CR>'
  endif
  if !hasmapto(':VimwikiChangeSymbolInListTo '.s:k.'<CR>')
    exe 'noremap <silent><buffer> gL'.s:k[0].' :VimwikiChangeSymbolInListTo '.s:k.'<CR>'
  endif
endfor



function! s:CR(normal, just_mrkr) "{{{
  if g:vimwiki_table_mappings
    let res = vimwiki#tbl#kbd_cr()
    if res != ""
      exe "normal! " . res . "\<Right>"
      startinsert
      return
    endif
  endif
  call vimwiki#lst#kbd_cr(a:normal, a:just_mrkr)
endfunction "}}}

if maparg('<CR>', 'i') !~? '<Esc>:VimwikiReturn'
  inoremap <silent><buffer> <CR> <Esc>:VimwikiReturn 1 5<CR>
endif
if maparg('<S-CR>', 'i') !~? '<Esc>:VimwikiReturn'
  inoremap <silent><buffer> <S-CR> <Esc>:VimwikiReturn 2 2<CR>
endif


"Table mappings
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

onoremap <silent><buffer> al :<C-U>call vimwiki#lst#TO_list_item(0, 0)<CR>
vnoremap <silent><buffer> al :<C-U>call vimwiki#lst#TO_list_item(0, 1)<CR>

onoremap <silent><buffer> il :<C-U>call vimwiki#lst#TO_list_item(1, 0)<CR>
vnoremap <silent><buffer> il :<C-U>call vimwiki#lst#TO_list_item(1, 1)<CR>

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
