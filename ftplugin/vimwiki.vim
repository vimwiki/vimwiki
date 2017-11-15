" vim:tabstop=2:shiftwidth=2:expandtab:foldmethod=marker:textwidth=79
" Vimwiki filetype plugin file
" Home: https://github.com/vimwiki/vimwiki/

if exists("b:did_ftplugin")
  finish
endif
let b:did_ftplugin = 1  " Don't load another plugin for this buffer

call vimwiki#u#reload_regexes()
call vimwiki#u#reload_omni_regexes()

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

" GOTO FILE: gf {{{
execute 'setlocal suffixesadd='.VimwikiGet('ext')
setlocal isfname-=[,]
" gf}}}

exe "setlocal tags+=" . escape(vimwiki#tags#metadata_file_path(), ' \|"')

" MISC }}}

" COMPLETION {{{
function! Complete_wikifiles(findstart, base)
  if a:findstart == 1
    let column = col('.')-2
    let line = getline('.')[:column]
    let startoflink = match(line, '\[\[\zs[^\\[\]]*$')
    if startoflink != -1
      let s:line_context = '['
      return startoflink
    endif
    if VimwikiGet('syntax') ==? 'markdown'
      let startofinlinelink = match(line, '\[.*\](\zs[^)]*$')
      if startofinlinelink != -1
        let s:line_context = '['
        return startofinlinelink
      endif
    endif
    let startoftag = match(line, ':\zs[^:[:space:]]*$')
    if startoftag != -1
      let s:line_context = ':'
      return startoftag
    endif
    let s:line_context = ''
    return -1
  else
    " Completion works for wikilinks/anchors, and for tags. s:line_content
    " tells us, which string came before a:base. There seems to be no easier
    " solution, because calling col('.') here returns garbage.
    if s:line_context == ''
      return []
    elseif s:line_context == ':'
      " Tags completion
      let tags = vimwiki#tags#get_tags()
      if a:base != ''
        call filter(tags,
            \ "v:val[:" . (len(a:base)-1) . "] == '" . substitute(a:base, "'", "''", '') . "'" )
      endif
      return tags
    elseif a:base !~# '#'
      " we look for wiki files

      if a:base =~# '^wiki\d:'
        let wikinumber = eval(matchstr(a:base, '^wiki\zs\d'))
        if wikinumber >= len(g:vimwiki_list)
          return []
        endif
        let prefix = matchstr(a:base, '^wiki\d:\zs.*')
        let scheme = matchstr(a:base, '^wiki\d:\ze')
      elseif a:base =~# '^diary:'
        let wikinumber = -1
        let prefix = matchstr(a:base, '^diary:\zs.*')
        let scheme = matchstr(a:base, '^diary:\ze')
      else " current wiki
        let wikinumber = g:vimwiki_current_idx
        let prefix = a:base
        let scheme = ''
      endif

      let links = vimwiki#base#get_wikilinks(wikinumber, 1)
      let result = []
      for wikifile in links
        if wikifile =~ '^'.vimwiki#u#escape(prefix)
          call add(result, scheme . wikifile)
        endif
      endfor
      return result

    else
      " we look for anchors in the given wikifile

      let segments = split(a:base, '#', 1)
      let given_wikifile = segments[0] == '' ? expand('%:t:r') : segments[0]
      let link_infos = vimwiki#base#resolve_link(given_wikifile.'#')
      let wikifile = link_infos.filename
      let syntax = VimwikiGet('syntax', link_infos.index)
      let anchors = vimwiki#base#get_anchors(wikifile, syntax)

      let filtered_anchors = []
      let given_anchor = join(segments[1:], '#')
      for anchor in anchors
        if anchor =~# '^'.vimwiki#u#escape(given_anchor)
          call add(filtered_anchors, segments[0].'#'.anchor)
        endif
      endfor
      return filtered_anchors

    endif
  endif
endfunction

setlocal omnifunc=Complete_wikifiles
" COMPLETION }}}

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
  let s:l_o = matchstr(&langmap, '\C,\zs.\zeo,')
  if s:l_o
    exe 'nnoremap <silent> <buffer> '.s:l_o.' :call vimwiki#lst#kbd_o()<CR>a'
  endif

  let s:l_O = matchstr(&langmap, '\C,\zs.\zeO,')
  if s:l_O
    exe 'nnoremap <silent> <buffer> '.s:l_O.' :call vimwiki#lst#kbd_O()<CR>a'
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
  if line =~# g:vimwiki_rxHeader
    return '>'.vimwiki#u#count_first_sym(line)
  " Code block folding...
  elseif line =~# g:vimwiki_rxPreStart
    return 'a1'
  elseif line =~# g:vimwiki_rxPreEnd
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
  " strlen() returns lenght in bytes, not in characters, so we'll have to do a
  " trick here -- replace all non-spaces with dot, calculate lengths and
  " indexes on it, then use original string to break at selected index.
  let text_pattern = substitute(a:text, '\m\S', '.', 'g')
  let spare_len = a:len - strlen(text_pattern)
  if (spare_len + s:tolerance >= 0)
    return [a:text, spare_len]
  endif
  " try to break on a space; assumes a:len-s:ell_len >= s:tolerance
  let newlen = a:len - s:ell_len
  let idx = strridx(text_pattern, ' ', newlen + s:tolerance)
  let break_idx = (idx + s:tolerance >= newlen) ? idx : newlen
  return [matchstr(a:text, '\m^.\{'.break_idx.'\}').s:ellipsis,
        \ newlen - break_idx]
endfunction "}}}

function! VimwikiFoldText() "{{{
  let line = getline(v:foldstart)
  let main_text = substitute(line, '^\s*', repeat(' ',indent(v:foldstart)), '')
  let fold_len = v:foldend - v:foldstart + 1
  let len_text = ' ['.fold_len.'] '
  if line !~# g:vimwiki_rxPreStart
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
      \ if filewritable(expand('%')) | silent noautocmd w | endif
      \ <bar>
      \ let res = vimwiki#html#Wiki2HTML(expand(VimwikiGet('path_html')),
      \                             expand('%'))
      \ <bar>
      \ if res != '' | echo 'Vimwiki: HTML conversion is done, output: '.expand(VimwikiGet('path_html')) | endif
command! -buffer Vimwiki2HTMLBrowse
      \ if filewritable(expand('%')) | silent noautocmd w | endif
      \ <bar>
      \ call vimwiki#base#system_open_link(vimwiki#html#Wiki2HTML(
      \         expand(VimwikiGet('path_html')),
      \         expand('%')))
command! -buffer VimwikiAll2HTML
      \ call vimwiki#html#WikiAll2HTML(expand(VimwikiGet('path_html')))

command! -buffer VimwikiTOC call vimwiki#base#table_of_contents(1)

command! -buffer VimwikiNextLink call vimwiki#base#find_next_link()
command! -buffer VimwikiPrevLink call vimwiki#base#find_prev_link()
command! -buffer VimwikiDeleteLink call vimwiki#base#delete_link()
command! -buffer VimwikiRenameLink call vimwiki#base#rename_link()
command! -buffer VimwikiFollowLink call vimwiki#base#follow_link('nosplit', 0, 1)
command! -buffer VimwikiGoBackLink call vimwiki#base#go_back_link()
command! -buffer VimwikiSplitLink call vimwiki#base#follow_link('hsplit', 0, 1)
command! -buffer VimwikiVSplitLink call vimwiki#base#follow_link('vsplit', 0, 1)

command! -buffer -nargs=? VimwikiNormalizeLink call vimwiki#base#normalize_link(<f-args>)

command! -buffer VimwikiTabnewLink call vimwiki#base#follow_link('tab', 0, 1)

command! -buffer VimwikiGenerateLinks call vimwiki#base#generate_links()

command! -buffer -nargs=0 VimwikiBacklinks call vimwiki#base#backlinks()
command! -buffer -nargs=0 VWB call vimwiki#base#backlinks()

exe 'command! -buffer -nargs=* VimwikiSearch lvimgrep <args> '.
      \ escape(VimwikiGet('path').'**/*'.VimwikiGet('ext'), ' ')

exe 'command! -buffer -nargs=* VWS lvimgrep <args> '.
      \ escape(VimwikiGet('path').'**/*'.VimwikiGet('ext'), ' ')

command! -buffer -nargs=+ -complete=custom,vimwiki#base#complete_links_escaped
      \ VimwikiGoto call vimwiki#base#goto(<f-args>)

command! -buffer VimwikiCheckLinks call vimwiki#base#check_links()

" list commands
command! -buffer -nargs=+ VimwikiReturn call <SID>CR(<f-args>)
command! -buffer -range -nargs=1 VimwikiChangeSymbolTo call vimwiki#lst#change_marker(<line1>, <line2>, <f-args>, 'n')
command! -buffer -range -nargs=1 VimwikiListChangeSymbolI call vimwiki#lst#change_marker(<line1>, <line2>, <f-args>, 'i')
command! -buffer -nargs=1 VimwikiChangeSymbolInListTo call vimwiki#lst#change_marker_in_list(<f-args>)
command! -buffer -range VimwikiToggleListItem call vimwiki#lst#toggle_cb(<line1>, <line2>)
command! -buffer -range VimwikiToggleRejectedListItem call vimwiki#lst#toggle_rejected_cb(<line1>, <line2>)
command! -buffer -range VimwikiIncrementListItem call vimwiki#lst#increment_cb(<line1>, <line2>)
command! -buffer -range VimwikiDecrementListItem call vimwiki#lst#decrement_cb(<line1>, <line2>)
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

" tags commands
command! -buffer -bang
      \ VimwikiRebuildTags call vimwiki#tags#update_tags(1, '<bang>')
command! -buffer -nargs=* -complete=custom,vimwiki#tags#complete_tags
      \ VimwikiSearchTags VimwikiSearch /:<args>:/
command! -buffer -nargs=* -complete=custom,vimwiki#tags#complete_tags
      \ VimwikiGenerateTags call vimwiki#tags#generate_tags(<f-args>)

" COMMANDS }}}

" KEYBINDINGS {{{
if g:vimwiki_use_mouse
  nmap <buffer> <S-LeftMouse> <NOP>
  nmap <buffer> <C-LeftMouse> <NOP>
  nnoremap <silent><buffer> <2-LeftMouse> :call vimwiki#base#follow_link('nosplit', 0, 1, "\<lt>2-LeftMouse>")<CR>
  nnoremap <silent><buffer> <S-2-LeftMouse> <LeftMouse>:VimwikiSplitLink<CR>
  nnoremap <silent><buffer> <C-2-LeftMouse> <LeftMouse>:VimwikiVSplitLink<CR>
  nnoremap <silent><buffer> <RightMouse><LeftMouse> :VimwikiGoBackLink<CR>
endif


if !hasmapto('<Plug>Vimwiki2HTML')
  exe 'nmap <buffer> '.g:vimwiki_map_prefix.'h <Plug>Vimwiki2HTML'
endif
nnoremap <script><buffer>
      \ <Plug>Vimwiki2HTML :Vimwiki2HTML<CR>

if !hasmapto('<Plug>Vimwiki2HTMLBrowse')
  exe 'nmap <buffer> '.g:vimwiki_map_prefix.'hh <Plug>Vimwiki2HTMLBrowse'
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
  exe 'nmap <silent><buffer> '.g:vimwiki_map_prefix.'d <Plug>VimwikiDeleteLink'
endif
nnoremap <silent><script><buffer>
      \ <Plug>VimwikiDeleteLink :VimwikiDeleteLink<CR>

if !hasmapto('<Plug>VimwikiRenameLink')
  exe 'nmap <silent><buffer> '.g:vimwiki_map_prefix.'r <Plug>VimwikiRenameLink'
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
if !hasmapto('<Plug>VimwikiToggleListItem')
  nmap <silent><buffer> <C-Space> <Plug>VimwikiToggleListItem
  vmap <silent><buffer> <C-Space> <Plug>VimwikiToggleListItem
  if has("unix")
    nmap <silent><buffer> <C-@> <Plug>VimwikiToggleListItem
    vmap <silent><buffer> <C-@> <Plug>VimwikiToggleListItem
  endif
endif
if !hasmapto('<Plug>VimwikiToggleRejectedListItem')
  nmap <silent><buffer> glx <Plug>VimwikiToggleRejectedListItem
  vmap <silent><buffer> glx <Plug>VimwikiToggleRejectedListItem
endif
nnoremap <silent><script><buffer>
      \ <Plug>VimwikiToggleListItem :VimwikiToggleListItem<CR>
vnoremap <silent><script><buffer>
      \ <Plug>VimwikiToggleListItem :VimwikiToggleListItem<CR>
nnoremap <silent><script><buffer>
      \ <Plug>VimwikiToggleRejectedListItem :VimwikiToggleRejectedListItem<CR>
vnoremap <silent><script><buffer>
      \ <Plug>VimwikiToggleRejectedListItem :VimwikiToggleRejectedListItem<CR>

if !hasmapto('<Plug>VimwikiIncrementListItem')
  nmap <silent><buffer> gln <Plug>VimwikiIncrementListItem
  vmap <silent><buffer> gln <Plug>VimwikiIncrementListItem
endif
if !hasmapto('<Plug>VimwikiDecrementListItem')
  nmap <silent><buffer> glp <Plug>VimwikiDecrementListItem
  vmap <silent><buffer> glp <Plug>VimwikiDecrementListItem
endif
nnoremap <silent><script><buffer>
      \ <Plug>VimwikiIncrementListItem :VimwikiIncrementListItem<CR>
vnoremap <silent><script><buffer>
      \ <Plug>VimwikiIncrementListItem :VimwikiIncrementListItem<CR>
nnoremap <silent><script><buffer>
      \ <Plug>VimwikiDecrementListItem :VimwikiDecrementListItem<CR>
vnoremap <silent><script><buffer>
      \ <Plug>VimwikiDecrementListItem :VimwikiDecrementListItem<CR>

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

nnoremap <silent> <buffer> o :<C-U>call vimwiki#lst#kbd_o()<CR>
nnoremap <silent> <buffer> O :<C-U>call vimwiki#lst#kbd_O()<CR>

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

for s:char in keys(g:vimwiki_bullet_types)
  if !hasmapto(':VimwikiChangeSymbolTo '.s:char.'<CR>')
    exe 'noremap <silent><buffer> gl'.s:char.' :VimwikiChangeSymbolTo '.s:char.'<CR>'
  endif
  if !hasmapto(':VimwikiChangeSymbolInListTo '.s:char.'<CR>')
    exe 'noremap <silent><buffer> gL'.s:char.' :VimwikiChangeSymbolInListTo '.s:char.'<CR>'
  endif
endfor

for s:typ in g:vimwiki_number_types
  if !hasmapto(':VimwikiChangeSymbolTo '.s:typ.'<CR>')
    exe 'noremap <silent><buffer> gl'.s:typ[0].' :VimwikiChangeSymbolTo '.s:typ.'<CR>'
  endif
  if !hasmapto(':VimwikiChangeSymbolInListTo '.s:typ.'<CR>')
    exe 'noremap <silent><buffer> gL'.s:typ[0].' :VimwikiChangeSymbolInListTo '.s:typ.'<CR>'
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

if !hasmapto('VimwikiReturn', 'i')
  if maparg('<CR>', 'i') !~? '<Esc>:VimwikiReturn'
    inoremap <silent><buffer> <CR> <Esc>:VimwikiReturn 1 5<CR>
  endif
  if maparg('<S-CR>', 'i') !~? '<Esc>:VimwikiReturn'
    inoremap <silent><buffer> <S-CR> <Esc>:VimwikiReturn 2 2<CR>
  endif
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

if VimwikiGet('auto_toc')
  " Automatically update the TOC *before* the file is written
  augroup vimwiki
    au BufWritePre <buffer> call vimwiki#base#table_of_contents(0)
  augroup END
endif

if VimwikiGet('auto_tags')
  " Automatically update tags metadata on page write.
  augroup vimwiki
    au BufWritePost <buffer> call vimwiki#tags#update_tags(0, '')
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
