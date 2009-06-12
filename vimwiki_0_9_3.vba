" Vimball Archiver by Charles E. Campbell, Jr., Ph.D.
UseVimball
finish
autoload\vimwiki.vim	[[[1
462
" Vimwiki autoload plugin file
" Author: Maxim Kim <habamax@gmail.com>
" Home: http://code.google.com/p/vimwiki/

if exists("g:loaded_vimwiki_auto") || &cp
  finish
endif
let g:loaded_vimwiki_auto = 1

let s:wiki_badsymbols = '[<>|?*/\:"]'

" MISC helper functions {{{
function! s:msg(message) "{{{
  echohl WarningMsg
  echomsg 'vimwiki: '.a:message
  echohl None
endfunction
" }}}
function! s:get_file_name_only(filename) "{{{
  let word = substitute(a:filename, '\'.VimwikiGet('ext'), "", "g")
  let word = substitute(word, '.*[/\\]', "", "g")
  return word
endfunction
" }}}
function! s:edit_file(command, filename) "{{{
  let fname = escape(a:filename, '% ')
  execute a:command.' '.fname
endfunction
" }}}
function! s:search_word(wikiRx, cmd) "{{{
  let match_line = search(a:wikiRx, 's'.a:cmd)
  if match_line == 0
    call s:msg('WikiWord not found')
  endif
endfunction
" }}}
function! s:get_word_at_cursor(wikiRX) "{{{
  let col = col('.') - 1
  let line = getline('.')
  let ebeg = -1
  let cont = match(line, a:wikiRX, 0)
  while (ebeg >= 0 || (0 <= cont) && (cont <= col))
    let contn = matchend(line, a:wikiRX, cont)
    if (cont <= col) && (col < contn)
      let ebeg = match(line, a:wikiRX, cont)
      let elen = contn - ebeg
      break
    else
      let cont = match(line, a:wikiRX, contn)
    endif
  endwh
  if ebeg >= 0
    return strpart(line, ebeg, elen)
  else
    return ""
  endif
endf "}}}
function! s:strip_word(word, sym) "{{{
  function! s:strip_word_helper(word, sym)
    return substitute(a:word, s:wiki_badsymbols, a:sym, 'g')
  endfunction

  let result = a:word
  if strpart(a:word, 0, 2) == "[["
    " get rid of [[ and ]]
    let w = strpart(a:word, 2, strlen(a:word)-4)
    " we want "link" from [[link|link desc]]
    let w = split(w, "|")[0]
    let result = s:strip_word_helper(w, a:sym)
  endif
  return result
endfunction
" }}}
function! s:is_link_to_non_wiki_file(word) "{{{
  " Check if word is link to a non-wiki file.
  " The easiest way is to check if it has extension like .txt or .html
  if a:word =~ '\.\w\{1,4}$'
    return 1
  endif
  return 0
endfunction
" }}}
function! s:print_wiki_list() "{{{
  let idx = 0
  while idx < len(g:vimwiki_list)
    if idx == g:vimwiki_current_idx
      let sep = ' * '
      echohl TablineSel
    else
      let sep = '   '
      echohl None
    endif
    echo (idx + 1).sep.VimwikiGet('path', idx)
    let idx += 1
  endwhile
  echohl None
endfunction
" }}}
function! s:wiki_select(wnum)"{{{
  if a:wnum < 1 || a:wnum > len(g:vimwiki_list)
    return
  endif
  let b:vimwiki_idx = g:vimwiki_current_idx
  let g:vimwiki_current_idx = a:wnum - 1
endfunction
" }}}
function! vimwiki#mkdir(path) "{{{
  " TODO: add exception handling...
  let path = expand(a:path)
  if !isdirectory(path) && exists("*mkdir")
    if path[-1:] == '/' || path[-1:] == '\'
      let path = path[:-2]
    endif
    call mkdir(path, "p")
  endif
endfunction
" }}}
function! s:update_wiki_link(fname, old, new) " {{{
  echo "Updating links in ".a:fname
  let has_updates = 0
  let dest = []
  for line in readfile(a:fname)
    if !has_updates && match(line, a:old) != -1
      let has_updates = 1
    endif
    call add(dest, substitute(line, a:old, escape(a:new, "&"), "g"))
  endfor
  " add exception handling...
  if has_updates
    call rename(a:fname, a:fname.'#vimwiki_upd#')
    call writefile(dest, a:fname)
    call delete(a:fname.'#vimwiki_upd#')
  endif
endfunction
" }}}
function! s:update_wiki_links(old, new) " {{{
  let files = split(glob(VimwikiGet('path').'*'.VimwikiGet('ext')), '\n')
  for fname in files
    call s:update_wiki_link(fname, a:old, a:new)
  endfor
endfunction
" }}}
function! s:get_wiki_buffers() "{{{
  let blist = []
  let bcount = 1
  while bcount<=bufnr("$")
    if bufexists(bcount)
      let bname = fnamemodify(bufname(bcount), ":p")
      if bname =~ VimwikiGet('ext')."$"
        let bitem = [bname, getbufvar(bname, "vimwiki_prev_word")]
        call add(blist, bitem)
      endif
    endif
    let bcount = bcount + 1
  endwhile
  return blist
endfunction
" }}}
function! s:open_wiki_buffer(item) "{{{
  call s:edit_file('e', a:item[0])
  if !empty(a:item[1])
    call setbufvar(a:item[0], "vimwiki_prev_word", a:item[1])
  endif
endfunction
" }}}
" }}}
" SYNTAX highlight {{{
function! vimwiki#WikiHighlightWords() "{{{
  let wikies = glob(VimwikiGet('path').'*'.VimwikiGet('ext'))
  "" remove .wiki extensions
  let wikies = substitute(wikies, '\'.VimwikiGet('ext'), "", "g")
  let g:vimwiki_wikiwords = split(wikies, '\n')
  "" remove paths
  call map(g:vimwiki_wikiwords, 'substitute(v:val, ''.*[/\\]'', "", "g")')
  "" remove backup files (.wiki~)
  call filter(g:vimwiki_wikiwords, 'v:val !~ ''.*\~$''')

  for word in g:vimwiki_wikiwords
    if word =~ g:vimwiki_word1 && !s:is_link_to_non_wiki_file(word)
      execute 'syntax match wikiWord /\%(^\|[^!]\)\zs\<'.word.'\>/'
    endif
    execute 'syntax match wikiWord /\[\[\<'.
          \ substitute(word, g:vimwiki_stripsym, s:wiki_badsymbols, "g").
          \ '\>\%(|\+.*\)*\]\]/'
  endfor
  execute 'syntax match wikiWord /\[\[.\+\.\%(jpg\|png\|gif\)\%(|\+.*\)*\]\]/'
endfunction
" }}}
function! vimwiki#hl_exists(hl)"{{{
  if !hlexists(a:hl)
    return 0
  endif
  redir => hlstatus
  exe "silent hi" a:hl
  redir END
  return (hlstatus !~ "cleared")
endfunction
"}}}

"}}}
" WIKI functions {{{
function! vimwiki#WikiNextWord() "{{{
  call s:search_word(g:vimwiki_rxWikiWord, '')
endfunction
" }}}
function! vimwiki#WikiPrevWord() "{{{
  call s:search_word(g:vimwiki_rxWikiWord, 'b')
endfunction
" }}}
function! vimwiki#WikiFollowWord(split) "{{{
  if a:split == "split"
    let cmd = ":split "
  elseif a:split == "vsplit"
    let cmd = ":vsplit "
  else
    let cmd = ":e "
  endif
  let word = s:strip_word(s:get_word_at_cursor(g:vimwiki_rxWikiWord),
        \                                      g:vimwiki_stripsym)
  " insert doesn't work properly inside :if. Check :help :if.
  if word == ""
    execute "normal! \n"
    return
  endif
  if s:is_link_to_non_wiki_file(word)
    call s:edit_file(cmd, word)
  else
    let vimwiki_prev_word = [expand('%:p'), getpos('.')]
    call s:edit_file(cmd, VimwikiGet('path').word.VimwikiGet('ext'))
    let b:vimwiki_prev_word = vimwiki_prev_word
  endif
endfunction
" }}}
function! vimwiki#WikiGoBackWord() "{{{
  if exists("b:vimwiki_prev_word")
    " go back to saved WikiWord
    let prev_word = b:vimwiki_prev_word
    execute ":e ".substitute(prev_word[0], '\s', '\\\0', 'g')
    call setpos('.', prev_word[1])
  endif
endfunction
" }}}
function! vimwiki#WikiGoHome(index) "{{{
  call s:wiki_select(a:index)
  call vimwiki#mkdir(VimwikiGet('path'))

  try
    execute ':e '.VimwikiGet('path').VimwikiGet('index').VimwikiGet('ext')
  catch /E37/ " catch 'No write since last change' error
    " this is really unsecure!!!
    execute ':'.VimwikiGet('gohome').' '.
          \ VimwikiGet('path').
          \ VimwikiGet('index').
          \ VimwikiGet('ext')
  catch /E325/ " catch 'ATTENTION' error
    " TODO: Hmmm, if open already opened index.wiki there is an error...
    " Find out what is the reason and how to avoid it. Is it dangerous?
    echomsg "Unknown error!"
  endtry
endfunction
"}}}
function! vimwiki#WikiDeleteWord() "{{{
  "" file system funcs
  "" Delete WikiWord you are in from filesystem
  let val = input('Delete ['.expand('%').'] (y/n)? ', "")
  if val != 'y'
    return
  endif
  let fname = expand('%:p')
  try
    call delete(fname)
  catch /.*/
    call s:msg('Cannot delete "'.expand('%:t:r').'"!')
    return
  endtry
  execute "bdelete! ".escape(fname, " ")

  " reread buffer => deleted WikiWord should appear as non-existent
  if expand('%:p') != ""
    execute "e"
  endif
endfunction
"}}}
function! vimwiki#WikiRenameWord() "{{{
  "" Rename WikiWord, update all links to renamed WikiWord
  let wwtorename = expand('%:t:r')
  let isOldWordComplex = 0
  if wwtorename !~ g:vimwiki_word1
    let wwtorename = substitute(wwtorename, g:vimwiki_stripsym,
          \ s:wiki_badsymbols, "g")
    let isOldWordComplex = 1
  endif

  " there is no file (new one maybe)
  if glob(expand('%:p')) == ''
    call s:msg('Cannot rename "'.expand('%:p').
          \ '". It does not exist! (New file? Save it before renaming.)')
    return
  endif

  let val = input('Rename "'.expand('%:t:r').'" (y/n)? ', "")
  if val!='y'
    return
  endif
  let newWord = input('Enter new name: ', "")
  " check newWord - it should be 'good', not empty
  if substitute(newWord, '\s', '', 'g') == ''
    call s:msg('Cannot rename to an empty filename!')
    return
  endif
  if s:is_link_to_non_wiki_file(newWord)
    call s:msg('Cannot rename to a filename with extension (ie .txt .html)!')
    return
  endif

  if newWord !~ g:vimwiki_word1
    " if newWord is 'complex wiki word' then add [[]]
    let newWord = '[['.newWord.']]'
  endif
  let newFileName = s:strip_word(newWord, g:vimwiki_stripsym).VimwikiGet('ext')

  " do not rename if word with such name exists
  let fname = glob(VimwikiGet('path').newFileName)
  if fname != ''
    call s:msg('Cannot rename to "'.newFileName.
          \ '". File with that name exist!')
    return
  endif
  " rename WikiWord file
  try
    echomsg "Renaming ".expand('%:t:r')." to ".newFileName
    let res = rename(expand('%:p'), expand(VimwikiGet('path').newFileName))
    if res != 0
      throw "Cannot rename!"
    end
  catch /.*/
    call s:msg('Cannot rename "'.expand('%:t:r').'" to "'.newFileName.'"')
    return
  endtry

  let &buftype="nofile"

  let cur_buffer = [expand('%:p'),
        \getbufvar(expand('%:p'), "vimwiki_prev_word")]

  let blist = s:get_wiki_buffers()

  " save wiki buffers
  for bitem in blist
    execute ':b '.escape(bitem[0], ' ')
    execute ':update'
  endfor

  execute ':b '.escape(cur_buffer[0], ' ')

  " remove wiki buffers
  for bitem in blist
    execute 'bwipeout '.escape(bitem[0], ' ')
  endfor

  let setting_more = &more
  setlocal nomore

  " update links
  if isOldWordComplex
    call s:update_wiki_links('\[\['.wwtorename.'\]\]', newWord)
  else
    call s:update_wiki_links('\<'.wwtorename.'\>', newWord)
  endif

  " restore wiki buffers
  for bitem in blist
    if bitem[0] != cur_buffer[0]
      call s:open_wiki_buffer(bitem)
    endif
  endfor

  call s:open_wiki_buffer([VimwikiGet('path').newFileName, cur_buffer[1]])
  " execute 'bwipeout '.escape(cur_buffer[0], ' ')

  echomsg wwtorename." is renamed to ".newWord

  let &more = setting_more
endfunction
" }}}
function! vimwiki#WikiUISelect()"{{{
  call s:print_wiki_list()
  let idx = input("Select Wiki (specify number): ")
  if idx == ""
    return
  endif
  call vimwiki#WikiGoHome(idx)
endfunction
"}}}
" }}}
" TEXT OBJECTS functions {{{

function! vimwiki#TO_header(inner) "{{{
  if !search('^\(=\+\)[^=]\+\1\s*$', 'bcW')
    return
  endif
  let level = vimwiki#count_first_sym(getline(line('.')))
  normal V
  if search('^\(=\{1,'.level.'}\)[^=]\+\1\s*$', 'W')
    call cursor(line('.') - 1, 0)
  else
    call cursor(line('$'), 0)
  endif
  if a:inner && getline(line('.')) =~ '^\s*$'
    let lnum = prevnonblank(line('.') - 1)
    call cursor(lnum, 0)
  endif
endfunction
"}}}
function! vimwiki#count_first_sym(line) "{{{
  let idx = 0
  while a:line[idx] == a:line[0] && idx < len(a:line)
    let idx += 1
  endwhile
  return idx
endfunction "}}}

function! vimwiki#AddHeaderLevel() "{{{
  let lnum = line('.')
  let line = getline(lnum)

  if line =~ '^\s*$'
    return
  endif

  if line !~ '^\(=\+\).\+\1\s*$'
    let line = substitute(line, '^\s*', ' ', '')
    let line = substitute(line, '\s*$', ' ', '')
  endif
  let level = vimwiki#count_first_sym(line)
  if level < 6
    call setline(lnum, '='.line.'=')
  endif
endfunction
"}}}
function! vimwiki#RemoveHeaderLevel() "{{{
  let lnum = line('.')
  let line = getline(lnum)

  if line =~ '^\s*$'
    return
  endif

  if line =~ '^\(=\+\).\+\1\s*$'
    let line = strpart(line, 1, len(line) - 2)
    if line =~ '^\s'
      let line = strpart(line, 1, len(line))
    endif
    if line =~ '\s$'
      let line = strpart(line, 0, len(line) - 1)
    endif
    call setline(lnum, line)
  endif
endfunction
" }}}

" }}}
autoload\vimwiki_html.vim	[[[1
894
" Vimwiki autoload plugin file
" Export to HTML
" Author: Maxim Kim <habamax@gmail.com>
" Home: http://code.google.com/p/vimwiki/

" Load only once {{{
if exists("g:loaded_vimwiki_html_auto") || &cp
  finish
endif
let g:loaded_vimwiki_html_auto = 1
"}}}
" Warn if html header or html footer do not exist only once. {{{
let s:warn_html_header = 0
let s:warn_html_footer = 0
"}}}
" TODO: move the next 2 functions into vimwiki#msg and
" vimwiki#get_file_name_only.
function! s:msg(message) "{{{
  echohl WarningMsg
  echomsg 'vimwiki: '.a:message
  echohl None
endfunction "}}}

function! s:get_file_name_only(filename) "{{{
  let word = substitute(a:filename, '\'.VimwikiGet('ext'), "", "g")
  let word = substitute(word, '.*[/\\]', "", "g")
  return word
endfunction "}}}

function! s:syntax_supported() " {{{
  return VimwikiGet('syntax') == "default"
endfunction " }}}

function! s:create_default_CSS(path) " {{{
  let path = expand(a:path)
  let css_full_name = path.VimwikiGet('css_name')
  if glob(css_full_name) == ""
    call vimwiki#mkdir(fnamemodify(css_full_name, ':p:h'))
    let lines = []

    call add(lines, 'body {margin: 1em 2em 1em 2em; font-size: 100%; line-height: 130%;}')
    call add(lines, 'h1, h2, h3, h4, h5, h6 {margin-top: 1.5em; margin-bottom: 0.5em;}')
    call add(lines, 'h1 {font-size: 2.0em; color: #3366aa;}')
    call add(lines, 'h2 {font-size: 1.6em; color: #335588;}')
    call add(lines, 'h3 {font-size: 1.2em; color: #224466;}')
    call add(lines, 'h4 {font-size: 1.2em; color: #113344;}')
    call add(lines, 'h5 {font-size: 1.1em; color: #112233;}')
    call add(lines, 'h6 {font-size: 1.1em; color: #111111;}')
    call add(lines, 'p, pre, table, ul, ol, dl {margin-top: 1em; margin-bottom: 1em;}')
    call add(lines, 'ul ul, ul ol, ol ol, ol ul {margin-top: 0.5em; margin-bottom: 0.5em;}')
    call add(lines, 'li {margin: 0.3em auto;}')
    call add(lines, 'ul {margin-left: 2em; padding-left: 0.5em;}')
    call add(lines, 'dt {font-weight: bold;}')
    call add(lines, 'img {border: none;}')
    call add(lines, 'pre {border-left: 1px solid #ccc; margin-left: 2em; padding-left: 0.5em;}')
    call add(lines, 'td {border: 1px solid #ccc; padding: 0.3em;}')
    call add(lines, 'hr {border: none; border-top: 1px solid #ccc; width: 100%;}')
    call add(lines, '.todo {font-weight: bold; background-color: #f0ece8; color: #a03020;}')
    call add(lines, '.strike {text-decoration: line-through; color: #777777;}')
    call add(lines, '.justleft {text-align: left;}')
    call add(lines, '.justright {text-align: right;}')
    call add(lines, '.justcenter {text-align: center;}')

    call writefile(lines, css_full_name)
    echomsg "Default style.css is created."
  endif
endfunction "}}}

function! s:remove_blank_lines(lines) " {{{
  while a:lines[-1] =~ '^\s*$'
    call remove(a:lines, -1)
  endwhile
endfunction "}}}

function! s:is_web_link(lnk) "{{{
  if a:lnk =~ '^\(http://\|www.\|ftp://\)'
    return 1
  endif
  return 0
endfunction "}}}

function! s:is_img_link(lnk) "{{{
  if a:lnk =~ '\.\(png\|jpg\|gif\|jpeg\)$'
    return 1
  endif
  return 0
endfunction "}}}

function! s:is_non_wiki_link(lnk) "{{{
  if a:lnk =~ '.\+\..\+$'
    return 1
  endif
  return 0
endfunction "}}}

function! s:get_html_header(title, charset) "{{{
  let lines=[]

  if VimwikiGet('html_header') != "" && !s:warn_html_header
    try
      let lines = readfile(expand(VimwikiGet('html_header')))
      call map(lines, 'substitute(v:val, "%title%", "'. a:title .'", "g")')
      return lines
    catch /E484/
      let s:warn_html_header = 1
      call s:msg("Header template ".VimwikiGet('html_header').
            \ " does not exist!")
    endtry
  endif

  " if no VimwikiGet('html_header') set up or error while reading template
  " file -- use default header.
  call add(lines, '<html>')
  call add(lines, '<head>')
  call add(lines, '<link rel="Stylesheet" type="text/css" href="'.
        \ VimwikiGet('css_name').'" />')
  call add(lines, '<title>'.a:title.'</title>')
  call add(lines, '<meta http-equiv="Content-Type" content="text/html;'.
        \ ' charset='.a:charset.'" />')
  call add(lines, '</head>')
  call add(lines, '<body>')

  return lines
endfunction "}}}

function! s:get_html_footer() "{{{
  let lines=[]

  if VimwikiGet('html_footer') != "" && !s:warn_html_footer
    try
      let lines = readfile(expand(VimwikiGet('html_footer')))
      return lines
    catch /E484/
      let s:warn_html_footer = 1
      call s:msg("Footer template ".VimwikiGet('html_footer').
            \ " does not exist!")
    endtry
  endif

  " if no VimwikiGet('html_footer') set up or error while reading template
  " file -- use default footer.
  call add(lines, "")
  call add(lines, '</body>')
  call add(lines, '</html>')

  return lines
endfunction "}}}

function! s:close_tag_code(code, ldest) "{{{
  if a:code
    call insert(a:ldest, "</pre></code>")
    return 0
  endif
  return a:code
endfunction "}}}

function! s:close_tag_pre(pre, ldest) "{{{
  if a:pre
    call insert(a:ldest, "</pre>")
    return 0
  endif
  return a:pre
endfunction "}}}

function! s:close_tag_para(para, ldest) "{{{
  if a:para
    call insert(a:ldest, "</p>")
    return 0
  endif
  return a:para
endfunction "}}}

function! s:close_tag_table(table, ldest) "{{{
  if a:table
    call insert(a:ldest, "</table>")
    return 0
  endif
  return a:table
endfunction "}}}

function! s:close_tag_list(lists, ldest) "{{{
  while len(a:lists)
    let item = remove(a:lists, -1)
    call insert(a:ldest, item[0])
  endwhile
endfunction! "}}}

function! s:close_tag_def_list(deflist, ldest) "{{{
  if a:deflist
    call insert(a:ldest, "</dl>")
    return 0
  endif
  return a:deflist
endfunction! "}}}

function! s:process_tag_pre_cl(line, code) "{{{
  let lines = []
  let code = a:code
  let processed = 0
  if !code && a:line =~ '{{{[^\(}}}\)]*\s*$'
    let class = matchstr(a:line, '{{{\zs.*$')
    let class = substitute(class, '\s\+$', '', 'g')
    if class != ""
      call add(lines, "<pre ".class.">")
    else
      call add(lines, "<pre>")
    endif
    let code = 1
    let processed = 1
  elseif code && a:line =~ '^}}}\s*$'
    let code = 0
    call add(lines, "</pre>")
    let processed = 1
  elseif code
    let processed = 1
    call add(lines, a:line)
  endif
  return [processed, lines, code]
endfunction "}}}

function! s:process_tag_pre(line, pre) "{{{
  let lines = []
  let pre = a:pre
  let processed = 0
  if a:line =~ '^\s\+[^[:blank:]*#]'
    if !pre
      call add(lines, "<pre>")
      let pre = 1
    endif
    let processed = 1
    call add(lines, a:line)
  elseif pre && a:line =~ '^\s*$'
    let processed = 1
    call add(lines, a:line)
  elseif pre
    call add(lines, "</pre>")
    let pre = 0
  endif
  return [processed, lines, pre]
endfunction "}}}

function! s:process_tag_list(line, lists) "{{{
  let lines = []
  let lstSym = ''
  let lstTagOpen = ''
  let lstTagClose = ''
  let lstRegExp = ''
  let processed = 0
  if a:line =~ '^\s\+\*'
    let lstSym = '*'
    let lstTagOpen = '<ul>'
    let lstTagClose = '</ul>'
    let lstRegExp = '^\s\+\*'
    let processed = 1
  elseif a:line =~ '^\s\+#'
    let lstSym = '#'
    let lstTagOpen = '<ol>'
    let lstTagClose = '</ol>'
    let lstRegExp = '^\s\+#'
    let processed = 1
  endif
  if lstSym != ''
    let indent = stridx(a:line, lstSym)
    let cnt = len(a:lists)
    if !cnt || (cnt && indent > a:lists[-1][1])
      call add(a:lists, [lstTagClose, indent])
      call add(lines, lstTagOpen)
    elseif (cnt && indent < a:lists[-1][1])
      while indent < a:lists[-1][1]
        let item = remove(a:lists, -1)
        call add(lines, item[0])
      endwhile
    endif
    let st_tag = '<li>'
    let en_tag = '</li>'
    let checkbox = '\s*\[\(.\?\)]'
    " apply strikethrough for checked list items
    if a:line =~ '^\s\+\%(\*\|#\)\s*\[x]'
      let st_tag .= '<span class="strike">'
      let en_tag = '</span>'.en_tag
    endif
    let chk = matchlist(a:line, lstRegExp.checkbox)
    if len(chk) > 0
      if chk[1] == 'x'
        let st_tag .= '<input type="checkbox" checked />'
      else
        let st_tag .= '<input type="checkbox" />'
      endif
    endif
    call add(lines, st_tag.
          \ substitute(a:line, lstRegExp.'\%('.checkbox.'\)\?', '', '').
          \ en_tag)
  else
    while len(a:lists)
      let item = remove(a:lists, -1)
      call add(lines, item[0])
    endwhile
  endif
  return [processed, lines]
endfunction "}}}

function! s:process_tag_def_list(line, deflist) "{{{
  let lines = []
  let deflist = a:deflist
  let processed = 0
  let matches = matchlist(a:line, '\(^.*\)::\%(\s\|$\)\(.*\)')
  if !deflist && len(matches) > 0
    call add(lines, "<dl>")
    let deflist = 1
  endif
  if deflist && len(matches) > 0
    if matches[1] != ''
      call add(lines, "<dt>".matches[1]."</dt>")
    endif
    if matches[2] != ''
      call add(lines, "<dd>".matches[2]."</dd>")
    endif
    let processed = 1
  elseif deflist
    let deflist = 0
    call add(lines, "</dl>")
  endif
  return [processed, lines, deflist]
endfunction "}}}

function! s:process_tag_para(line, para) "{{{
  let lines = []
  let para = a:para
  let processed = 0
  if a:line =~ '^\S'
    if !para
      call add(lines, "<p>")
      let para = 1
    endif
    let processed = 1
    call add(lines, a:line)
  elseif para && a:line =~ '^\s*$'
    call add(lines, "</p>")
    let para = 0
  endif
  return [processed, lines, para]
endfunction "}}}

function! s:process_tag_h(line) "{{{
  let line = a:line
  let processed = 0
  let h_level = 0
  if a:line =~ g:vimwiki_rxH6
    let h_level = 6
  elseif a:line =~ g:vimwiki_rxH5
    let h_level = 5
  elseif a:line =~ g:vimwiki_rxH4
    let h_level = 4
  elseif a:line =~ g:vimwiki_rxH3
    let h_level = 3
  elseif a:line =~ g:vimwiki_rxH2
    let h_level = 2
  elseif a:line =~ g:vimwiki_rxH1
    let h_level = 1
  endif
  if h_level > 0
    " rtrim
    let line = substitute(a:line, '\s\+$', '', 'g')
    let line = '<h'.h_level.'>'.
          \ strpart(line, h_level, len(line) - h_level * 2).
          \'</h'.h_level.'>'
    let processed = 1
  endif
  return [processed, line]
endfunction "}}}

function! s:process_tag_hr(line) "{{{
  let line = a:line
  let processed = 0
  if a:line =~ '^-----*$'
    let line = '<hr />'
    let processed = 1
  endif
  return [processed, line]
endfunction "}}}

function! s:process_tag_table(line, table) "{{{
  let table = a:table
  let lines = []
  let processed = 0
  if a:line =~ '^||.\+||.*'
    if !table
      call add(lines, "<table>")
      let table = 1
    endif
    let processed = 1

    call add(lines, "<tr>")
    let pos1 = 0
    let pos2 = 0
    let done = 0
    while !done
      let pos1 = stridx(a:line, '||', pos2)
      let pos2 = stridx(a:line, '||', pos1+2)
      if pos1==-1 || pos2==-1
        let done = 1
        let pos2 = len(a:line)
      endif
      let line = strpart(a:line, pos1+2, pos2-pos1-2)
      if line == ''
        continue
      endif
      if strpart(line, 0, 1) == ' ' &&
            \ strpart(line, len(line) - 1, 1) == ' '
        call add(lines, '<td class="justcenter">'.line.'</td>')
      elseif strpart(line, 0, 1) == ' '
        call add(lines, '<td class="justright">'.line.'</td>')
      else
        call add(lines, '<td class="justleft">'.line.'</td>')
      endif
    endwhile
    call add(lines, "</tr>")

  elseif table
    call add(lines, "</table>")
    let table = 0
  endif
  return [processed, lines, table]
endfunction "}}}

function! s:process_tags(line) "{{{
  let line = a:line
  let line = s:make_tag(line, '\[\[.\{-}\]\]',
        \ '', '', 2, 's:make_internal_link')
  let line = s:make_tag(line, '\[.\{-}\]', '', '', 1, 's:make_external_link')
  let line = s:make_tag(line, g:vimwiki_rxWeblink,
        \ '', '', 0, 's:make_barebone_link')
  let line = s:make_tag(line, '!\?'.g:vimwiki_rxWikiWord,
        \ '', '', 0, 's:make_wikiword_link')
  let line = s:make_tag(line, g:vimwiki_rxItalic, '<em>', '</em>')
  let line = s:make_tag(line, g:vimwiki_rxBold, '<strong>', '</strong>')
  let line = s:make_tag(line, g:vimwiki_rxTodo,
        \ '<span class="todo">', '</span>', 0)
  let line = s:make_tag(line, g:vimwiki_rxDelText,
        \ '<span class="strike">', '</span>', 2)
  let line = s:make_tag(line, g:vimwiki_rxSuperScript,
        \ '<sup><small>', '</small></sup>', 1)
  let line = s:make_tag(line, g:vimwiki_rxSubScript,
        \ '<sub><small>', '</small></sub>', 2)
  let line = s:make_tag(line, g:vimwiki_rxCode, '<code>', '</code>')
  " TODO: change make_tag function: delete cSym parameter -- count of symbols
  " to strip from 2 sides of tag. Add 2 new instead -- OpenWikiTag length
  " and CloseWikiTag length as for preformatted text there could be {{{,}}}
  " and <pre>,</pre>.
  let line = s:make_tag(line, g:vimwiki_rxPreStart.'.\+'.g:vimwiki_rxPreEnd,
        \ '<code>', '</code>', 3)
  return line
endfunction " }}}

function! s:safe_html(line) "{{{
  "" change dangerous html symbols: < > &

  let line = substitute(a:line, '&', '\&amp;', 'g')
  let line = substitute(line, '<', '\&lt;', 'g')
  let line = substitute(line, '>', '\&gt;', 'g')
  return line
endfunction "}}}

function! s:make_tag_helper(line, regexp_match,
      \ tagOpen, tagClose, cSymRemove, func) " {{{
  "" Substitute text found by regexp_match with tagOpen.regexp_subst.tagClose

  let pos = 0
  let lines = split(a:line, a:regexp_match, 1)
  let res_line = ""
  for line in lines
    let res_line = res_line.line
    let matched = matchstr(a:line, a:regexp_match, pos)
    if matched != ""
      let toReplace = strpart(matched,
            \ a:cSymRemove, len(matched) - 2 * a:cSymRemove)
      if a:func!=""
        let toReplace = {a:func}(toReplace)
      else
        let toReplace = a:tagOpen.toReplace.a:tagClose
      endif
      let res_line = res_line.toReplace
    endif
    let pos = matchend(a:line, a:regexp_match, pos)
  endfor
  return res_line

endfunction " }}}

function! s:make_tag(line, regexp_match, tagOpen, tagClose, ...) " {{{
  "" Make tags only if not in ` ... `
  "" ... should be function that process regexp_match deeper.

  "check if additional function exists
  let func = ""
  let cSym = 1
  if a:0 == 2
    let cSym = a:1
    let func = a:2
  elseif a:0 == 1
    let cSym = a:1
  endif

  let patt_splitter = '\(`[^`]\+`\)\|\({{{.\+}}}\)\|'.
        \ '\(<a href.\{-}</a>\)\|\(<img src.\{-}/>\)'
  if '`[^`]\+`' == a:regexp_match || '{{{.\+}}}' == a:regexp_match
    let res_line = s:make_tag_helper(a:line, a:regexp_match,
          \ a:tagOpen, a:tagClose, cSym, func)
  else
    let pos = 0
    " split line with patt_splitter to have parts of line before and after
    " href links, preformatted text
    " ie:
    " hello world `is just a` simple <a href="link.html">type of</a> prg.
    " result:
    " ['hello world ', ' simple ', 'type of', ' prg']
    let lines = split(a:line, patt_splitter, 1)
    let res_line = ""
    for line in lines
      let res_line = res_line.s:make_tag_helper(line, a:regexp_match,
            \ a:tagOpen, a:tagClose, cSym, func)
      let res_line = res_line.matchstr(a:line, patt_splitter, pos)
      let pos = matchend(a:line, patt_splitter, pos)
    endfor
  endif
  return res_line
endfunction " }}}

function! s:make_external_link(entag) "{{{
  "" Make <a href="link">link desc</a>
  "" from [link link desc]

  let line = ''
  if s:is_web_link(a:entag)
    let lnkElements = split(a:entag)
    let head = lnkElements[0]
    let rest = join(lnkElements[1:])
    if rest==""
      let rest=head
    endif
    if s:is_img_link(rest)
      if rest!=head
        let line = '<a href="'.head.'"><img src="'.rest.'" /></a>'
      else
        let line = '<img src="'.rest.'" />'
      endif
    else
      let line = '<a href="'.head.'">'.rest.'</a>'
    endif
  elseif s:is_img_link(a:entag)
    let line = '<img src="'.a:entag.'" />'
  else
    " [alskfj sfsf] shouldn't be a link. So return it as it was --
    " enclosed in [...]
    let line = '['.a:entag.']'
  endif
  return line
endfunction "}}}

function! s:make_internal_link(entag) "{{{
  " Make <a href="This is a link">This is a link</a>
  " from [[This is a link]]
  " Make <a href="link">This is a link</a>
  " from [[link|This is a link]]
  " TODO: rename function -- it makes not only internal links.
  " TODO: refactor it.

  let line = ''
  let link_parts = split(a:entag, "|", 1)

  if len(link_parts) > 1
    if len(link_parts) < 3
      let style = ""
    else
      let style = link_parts[2]
    endif

    if s:is_img_link(link_parts[1])
      let line = '<a href="'.link_parts[0].'"><img src="'.link_parts[1].
            \ '" style="'.style.'" /></a>'
    elseif len(link_parts) < 3
      if s:is_non_wiki_link(link_parts[0])
        let line = '<a href="'.link_parts[0].'">'.link_parts[1].'</a>'
      else
        let line = '<a href="'.link_parts[0].'.html">'.link_parts[1].'</a>'
      endif
    elseif s:is_img_link(link_parts[0])
      let line = '<img src="'.link_parts[0].'" alt="'.
            \ link_parts[1].'" style="'.style.'" />'
    endif
  else
    if s:is_img_link(a:entag)
      let line = '<img src="'.a:entag.'" />'
    elseif s:is_non_wiki_link(link_parts[0])
      let line = '<a href="'.a:entag.'">'.a:entag.'</a>'
    else
      let line = '<a href="'.a:entag.'.html">'.a:entag.'</a>'
    endif
  endif

  return line
endfunction "}}}

function! s:make_wikiword_link(entag) "{{{
  " Make <a href="WikiWord">WikiWord</a> from WikiWord
  " if first symbol is ! then remove it and make no link.
  if a:entag[0] == '!'
    return a:entag[1:]
  else
    let line = '<a href="'.a:entag.'.html">'.a:entag.'</a>'
    return line
  endif
endfunction "}}}

function! s:make_barebone_link(entag) "{{{
  "" Make <a href="http://habamax.ru">http://habamax.ru</a>
  "" from http://habamax.ru

  if s:is_img_link(a:entag)
    let line = '<img src="'.a:entag.'" />'
  else
    let line = '<a href="'.a:entag.'">'.a:entag.'</a>'
  endif
  return line
endfunction "}}}

function! s:get_html_from_wiki_line(line, para, pre, code,
      \ table, lists, deflist) " {{{
  let para = a:para
  let pre = a:pre
  let code = a:code
  let table = a:table
  let lists = a:lists
  let deflist = a:deflist

  let res_lines = []

  let line = s:safe_html(a:line)

  let processed = 0
  "" Code
  if !processed
    let [processed, lines, code] = s:process_tag_pre_cl(line, code)
    if processed && len(lists)
      call s:close_tag_list(lists, lines)
    endif
    if processed && table
      let table = s:close_tag_table(table, lines)
    endif
    if processed && deflist
      let deflist = s:close_tag_def_list(deflist, lines)
    endif
    if processed && pre
      let pre = s:close_tag_pre(pre, lines)
    endif
    if processed && para
      let para = s:close_tag_para(para, lines)
    endif
    call extend(res_lines, lines)
  endif

  "" Pre
  if !processed
    let [processed, lines, pre] = s:process_tag_pre(line, pre)
    if processed && len(lists)
      call s:close_tag_list(lists, lines)
    endif
    if processed && deflist
      let deflist = s:close_tag_def_list(deflist, lines)
    endif
    if processed && table
      let table = s:close_tag_table(table, lines)
    endif
    if processed && code
      let code = s:close_tag_code(code, lines)
    endif
    if processed && para
      let para = s:close_tag_para(para, lines)
    endif

    call extend(res_lines, lines)
  endif

  "" list
  if !processed
    let [processed, lines] = s:process_tag_list(line, lists)
    if processed && pre
      let pre = s:close_tag_pre(pre, lines)
    endif
    if processed && code
      let code = s:close_tag_code(code, lines)
    endif
    if processed && table
      let table = s:close_tag_table(table, lines)
    endif
    if processed && deflist
      let deflist = s:close_tag_def_list(deflist, lines)
    endif
    if processed && para
      let para = s:close_tag_para(para, lines)
    endif

    call map(lines, 's:process_tags(v:val)')

    call extend(res_lines, lines)
  endif

  "" definition lists
  if !processed
    let [processed, lines, deflist] = s:process_tag_def_list(line, deflist)

    call map(lines, 's:process_tags(v:val)')

    call extend(res_lines, lines)
  endif

  "" table
  if !processed
    let [processed, lines, table] = s:process_tag_table(line, table)

    call map(lines, 's:process_tags(v:val)')

    call extend(res_lines, lines)
  endif

  if !processed
    let [processed, line] = s:process_tag_h(line)
    if processed
      call s:close_tag_list(lists, res_lines)
      let table = s:close_tag_table(table, res_lines)
      let code = s:close_tag_code(code, res_lines)
      call add(res_lines, line)
    endif
  endif

  if !processed
    let [processed, line] = s:process_tag_hr(line)
    if processed
      call s:close_tag_list(lists, res_lines)
      let table = s:close_tag_table(table, res_lines)
      let code = s:close_tag_code(code, res_lines)
      call add(res_lines, line)
    endif
  endif

  "" P
  if !processed
    let [processed, lines, para] = s:process_tag_para(line, para)
    if processed && len(lists)
      call s:close_tag_list(lists, lines)
    endif
    if processed && pre
      let pre = s:close_tag_pre(pre, res_lines)
    endif
    if processed && code
      let code = s:close_tag_code(code, res_lines)
    endif
    if processed && table
      let table = s:close_tag_table(table, res_lines)
    endif

    call map(lines, 's:process_tags(v:val)')

    call extend(res_lines, lines)
  endif

  "" add the rest
  if !processed
    call add(res_lines, line)
  endif

  return [res_lines, para, pre, code, table, lists, deflist]

endfunction " }}}

function! s:remove_comments(lines) "{{{
  let res = []
  let multiline_comment = 0

  let idx = 0
  while idx < len(a:lines)
    let line = a:lines[idx]
    let idx += 1

    if multiline_comment
      let col = matchend(line, '-->',)
      if col != -1
        let multiline_comment = 0
        let line = strpart(line, col)
      else
        continue
      endif
    endif

    if !multiline_comment && line =~ '<!--.*-->'
      let line = substitute(line, '<!--.*-->', '', 'g')
      if line =~ '^\s*$'
        continue
      endif
    endif

    if !multiline_comment
      let col = match(line, '<!--',)
      if col != -1
        let multiline_comment = 1
        let line = strpart(line, 1, col - 1)
      endif
    endif

    call add(res, line)
  endwhile
  return res
endfunction "}}}

function! vimwiki_html#Wiki2HTML(path, wikifile) "{{{

  if !s:syntax_supported()
    call s:msg('Only vimwiki_default syntax supported!!!')
    return
  endif

  let path = expand(a:path)
  call vimwiki#mkdir(path)

  let lsource = s:remove_comments(readfile(a:wikifile))
  let ldest = s:get_html_header(s:get_file_name_only(a:wikifile),
        \ &fileencoding)


  let para = 0
  let pre = 0
  let code = 0
  let table = 0
  let deflist = 0
  let lists = []

  for line in lsource
    let oldpre = pre
    let [lines, para, pre, code, table, lists, deflist] =
          \ s:get_html_from_wiki_line(line, para, pre, code,
          \ table, lists, deflist)

    " A dirty hack: There could be a lot of empty strings before
    " s:process_tag_pre find out `pre` is over. So we should delete
    " them all. Think of the way to refactor it out.
    if (oldpre != pre) && ldest[-1] =~ '^\s*$'
      call s:remove_blank_lines(ldest)
    endif

    call extend(ldest, lines)
  endfor

  call s:remove_blank_lines(ldest)

  "" process end of file
  "" close opened tags if any
  let lines = []
  call s:close_tag_pre(pre, lines)
  call s:close_tag_para(para, lines)
  call s:close_tag_code(code, lines)
  call s:close_tag_list(lists, lines)
  call s:close_tag_def_list(deflist, lines)
  call s:close_tag_table(table, lines)
  call extend(ldest, lines)

  call extend(ldest, s:get_html_footer())

  "" make html file.
  let wwFileNameOnly = s:get_file_name_only(a:wikifile)
  call writefile(ldest, path.wwFileNameOnly.'.html')
endfunction "}}}

function! vimwiki_html#WikiAll2HTML(path) "{{{
  if !s:syntax_supported()
    call s:msg('Only vimwiki_default syntax supported!!!')
    return
  endif

  let path = expand(a:path)
  call vimwiki#mkdir(path)

  let setting_more = &more
  setlocal nomore

  let wikifiles = split(glob(VimwikiGet('path').'*'.VimwikiGet('ext')), '\n')
  for wikifile in wikifiles
    echomsg 'Processing '.wikifile
    call vimwiki_html#Wiki2HTML(path, wikifile)
  endfor
  call s:create_default_CSS(path)
  echomsg 'Done!'

  let &more = setting_more
endfunction "}}}
autoload\vimwiki_lst.vim	[[[1
187
" Vimwiki autoload plugin file
" Todo lists related stuff here.
" Author: Maxim Kim <habamax@gmail.com>
" Home: http://code.google.com/p/vimwiki/

if exists("g:loaded_vimwiki_list_auto") || &cp
  finish
endif
let g:loaded_vimwiki_lst_auto = 1

" Script variables {{{
" used in various checks
let s:rx_list_item = '\('.
      \ g:vimwiki_rxListBullet.'\|'.g:vimwiki_rxListNumber.
      \ '\)'
let s:rx_cb_list_item = s:rx_list_item.'\s*\zs\[.\?\]'
let s:rx_li_box = '\[.\?\]'
let s:rx_li_unchecked = '\[\s\?\]'
" used in substitutions
let s:rx_li_check = '\[x\]'
let s:rx_li_uncheck = '\[ \]'
" }}}

" Script functions {{{
" Set state of the list item on line number "lnum" to [ ] or [x]
function! s:set_state(lnum, on_off)"{{{
  let line = getline(a:lnum)
  if a:on_off
    let state = s:rx_li_check
  else
    let state = s:rx_li_uncheck
  endif
  let line = substitute(line, s:rx_li_box, state, '')
  call setline(a:lnum, line)
endfunction"}}}

" Get state of the list item on line number "lnum"
function! s:get_state(lnum)"{{{
  let state = 1
  let line = getline(a:lnum)
  let opt = matchstr(line, s:rx_cb_list_item)
  if opt =~ s:rx_li_unchecked
    let state = 0
  endif
  return state
endfunction"}}}

" Returns 1 if line is list item, 0 otherwise
function! s:is_cb_list_item(lnum)"{{{
  return getline(a:lnum) =~ s:rx_cb_list_item
endfunction"}}}

" Returns 1 if line is list item, 0 otherwise
function! s:is_list_item(lnum)"{{{
  return getline(a:lnum) =~ s:rx_list_item
endfunction"}}}

" Returns char column of checkbox. Used in parent/child checks.
function! s:get_li_pos(lnum) "{{{
  return stridx(getline(a:lnum), '[')
endfunction "}}}

" Returns list of line numbers of parent and all its child items.
function! s:get_child_items(lnum)"{{{
  let result = []
  let lnum = a:lnum
  let parent_pos = s:get_li_pos(lnum)

  " add parent
  call add(result, lnum)
  let lnum += 1

  while s:is_cb_list_item(lnum) &&
        \ s:get_li_pos(lnum) > parent_pos &&
        \ lnum <= line('$')

    call add(result, lnum)
    let lnum += 1
  endwhile

  return result
endfunction"}}}

" Returns list of line numbers of all items of the same level.
function! s:get_sibling_items(lnum)"{{{
  let result = []
  let lnum = a:lnum
  let ind = s:get_li_pos(lnum)

  while s:is_cb_list_item(lnum) &&
        \ s:get_li_pos(lnum) >= ind &&
        \ lnum <= line('$')

    if s:get_li_pos(lnum) == ind
      call add(result, lnum)
    endif
    let lnum += 1
  endwhile

  let lnum = a:lnum - 1
  while s:is_cb_list_item(lnum) &&
        \ s:get_li_pos(lnum) >= ind &&
        \ lnum >= 0

    if s:get_li_pos(lnum) == ind
      call add(result, lnum)
    endif
    let lnum -= 1
  endwhile

  return result
endfunction"}}}

" Returns line number of the parent of lnum item
function! s:get_parent_item(lnum)"{{{
  let lnum = a:lnum
  let ind = s:get_li_pos(lnum)

  while s:is_cb_list_item(lnum) &&
        \ s:get_li_pos(lnum) >= ind &&
        \ lnum >= 0
    let lnum -= 1
  endwhile

  if s:is_cb_list_item(lnum)
    return lnum
  else
    return a:lnum
  endif
endfunction"}}}

" Creates checkbox in a list item.
function s:create_cb_list_item(lnum) "{{{
  let line = getline(a:lnum)
  let m = matchstr(line, s:rx_list_item)
  if m != ''
    let line = m.' [ ]'.strpart(line, len(m))
    call setline(a:lnum, line)
  endif
endfunction "}}}

" Script functions }}}

" Toggle list item between [ ] and [x]
function! vimwiki_lst#ToggleListItem()"{{{
  let current_lnum = line('.')

  if !s:is_cb_list_item(current_lnum)
    if g:vimwiki_auto_checkbox
      call s:create_cb_list_item(current_lnum)
    endif
    return
  endif

  let current_state = s:get_state(current_lnum)
  if  current_state == 0
    for lnum in s:get_child_items(current_lnum)
      call s:set_state(lnum, 1)
      let new_state = 1
    endfor
  else
    for lnum in s:get_child_items(current_lnum)
      call s:set_state(lnum, 0)
      let new_state = 0
    endfor
  endif

  let c_lnum = current_lnum
  while s:is_cb_list_item(c_lnum)
    let all_items_checked = 1
    for lnum in s:get_sibling_items(c_lnum)
      if s:get_state(lnum) != 1
        let all_items_checked = 0
        break
      endif
    endfor

    let parent_lnum = s:get_parent_item(c_lnum)
    if parent_lnum == c_lnum
      break
    endif
    call s:set_state(parent_lnum, all_items_checked)


    let c_lnum = parent_lnum
  endwhile
endfunction"}}}
doc\vimwiki.txt	[[[1
1097
*vimwiki.txt*  A Personal Wiki for Vim

     __  __  ______            __      __  ______   __  __   ______     ~
    /\ \/\ \/\__  _\   /'\_/`\/\ \  __/\ \/\__  _\ /\ \/\ \ /\__  _\    ~
    \ \ \ \ \/_/\ \/  /\      \ \ \/\ \ \ \/_/\ \/ \ \ \/'/'\/_/\ \/    ~
     \ \ \ \ \ \ \ \  \ \ \__\ \ \ \ \ \ \ \ \ \ \  \ \ , <    \ \ \    ~
      \ \ \_/ \ \_\ \__\ \ \_/\ \ \ \_/ \_\ \ \_\ \__\ \ \\`\   \_\ \__ ~
       \ `\___/ /\_____\\ \_\\ \_\ `\___x___/ /\_____\\ \_\ \_\ /\_____\~
        `\/__/  \/_____/ \/_/ \/_/'\/__//__/  \/_____/ \/_/\/_/ \/_____/~

                               Version: 0.9.3 ~

==============================================================================
CONTENTS                                                    *vimwiki-contents*

  1. Intro ...................................|vimwiki|
  2. Prerequisites ...........................|vimwiki-prerequisites|
  3. Mappings ................................|vimwiki-mappings|
    3.1. Global mappings .....................|vimwiki-global-mappings|
    3.2. Local mappings ......................|vimwiki-local-mappings|
    3.3. Text objects ........................|vimwiki-text-objects|
  4. Commands ................................|vimwiki-commands|
    4.1. Global commands .....................|vimwiki-global-commands|
    4.2. Local commands ......................|vimwiki-local-commands|
  5. Wiki syntax .............................|vimwiki-syntax|
    5.1. Typefaces ...........................|vimwiki-syntax-typefaces|
    5.2. Links ...............................|vimwiki-syntax-links|
    5.3. Headers .............................|vimwiki-syntax-headers|
    5.4. Paragraphs...........................|vimwiki-syntax-paragraphs|
    5.5. Lists ...............................|vimwiki-syntax-lists|
    5.6. Tables ..............................|vimwiki-syntax-tables|
    5.7. Preformatted text ...................|vimwiki-syntax-preformatted|
    5.8. Comments ............................|vimwiki-syntax-comment|
  6. Folding/Outline .........................|vimwiki-folding|
  7. Todo lists...............................|vimwiki-todo-lists|
  8. Options .................................|vimwiki-options|
  9. Help ....................................|vimwiki-help|
  10. Author .................................|vimwiki-author|
  11. Changelog ..............................|vimwiki-changelog|
  12. License ................................|vimwiki-license|


==============================================================================
1. Intro                                                             *vimwiki*

Vimwiki is a personal wiki for Vim. Using it you can organize text files with
hyperlinks. To do a quick start press <Leader>ww (this is usually \ww) to go
to your index wiki file. By default it is located in: >
  ~/vimwiki/index.wiki
You do not have to create it manually -- vimwiki can make it for you.

Feed it with the following example:
= My knowledge base =
  * MyUrgentTasks -- things to be done _yesterday_!!!
  * ProjectGutenberg -- good books are power.
  * MusicILike, MusicIHate.

Notice that ProjectGutenberg, MyUrgentTasks, MusicILike and MusicIHate
highlighted as errors. These WikiWords (WikiWord or WikiPage -- capitalized
word connected with other capitalized words) do not exist yet.

Place cursor on ProjectGutenberg and press Enter. Now you are in
ProjectGutenberg. Edit and save it, then press Backspace to return to previous
WikiPage. You should see the difference in highlighting now.

Now it is your turn...

==============================================================================
2. Prerequisites                                       *vimwiki-prerequisites*

Make sure you have these settings in your vimrc file: >
    set nocompatible
    filetype plugin on
    syntax on

Without them Vimwiki will not work properly.


==============================================================================
3. Mappings                                                 *vimwiki-mappings*

There are global and local mappings in vimwiki.

------------------------------------------------------------------------------
3.1. Global mappings                                 *vimwiki-global-mappings*

<Leader>ww or <Plug>VimwikiGoHome
        Open index file of the [count]'s wiki.
        <Leader>ww opens first wiki from |g:vimwiki_list|.
        1<Leader>ww as above opens first wiki from |g:vimwiki_list|.
        2<Leader>ww opens second wiki from |g:vimwiki_list|.
        3<Leader>ww opens third wiki from |g:vimwiki_list|.
        etc.
        To remap: >
        :map <Leader>w <Plug>VimwikiGoHome
<
See also|:VimwikiGoHome|

<Leader>wt or <Plug>VimwikiTabGoHome
        Open index file of the [count]'s wiki in a new tab.
        <Leader>ww tabopens first wiki from |g:vimwiki_list|.
        1<Leader>ww as above tabopens first wiki from |g:vimwiki_list|.
        2<Leader>ww tabopens second wiki from |g:vimwiki_list|.
        3<Leader>ww tabopens third wiki from |g:vimwiki_list|.
        etc.
        To remap: >
        :map <Leader>t <Plug>VimwikiTabGoHome
<
See also|:VimwikiTabGoHome|

<Leader>ws or <Plug>VimwikiUISelect
        List and select available wikies.
        To remap: >
        :map <Leader>wq <Plug>VimwikiUISelect
<
See also|:VimwikiUISelect|


------------------------------------------------------------------------------
3.2. Local mappings                                   *vimwiki-local-mappings*

Normal mode (Keyboard):~
                        *vimwiki_<CR>*
<CR>                    Follow/Create WikiWord.
                        Maps to|:VimwikiFollowWord|.
                        To remap: >
                        :map <Leader>wf <Plug>VimwikiFollowWord
<
                        *vimwiki_<S-CR>*
<S-CR>                  Split and follow/create WikiWord
                        Maps to|:VimwikiSplitWord|.
                        To remap: >
                        :map <Leader>we <Plug>VimwikiSplitWord
<
                        *vimwiki_<C-CR>*
<C-CR>                  Vertical split and follow/create WikiWord
                        Maps to|:VimwikiVSplitWord|.
                        To remap: >
                        :map <Leader>wq <Plug>VimwikiVSplitWord
<
                        *vimwiki_<Backspace>*
<Backspace>             Go back to previous WikiWord
                        Maps to|:VimwikiGoBackWord|.
                        To remap: >
                        :map <Leader>wb <Plug>VimwikiGoBackWord
<
                        *vimwiki_<Tab>*
<Tab>                   Find next WikiWord
                        Maps to|:VimwikiNextWord|.
                        To remap: >
                        :map <Leader>wn <Plug>VimwikiNextWord
<
                        *vimwiki_<S-Tab>*
<S-Tab>                 Find previous WikiWord
                        Maps to|:VimwikiPrevWord|.
                        To remap: >
                        :map <Leader>wp <Plug>VimwikiPrevWord
<
                        *vimwiki_<Leader>wd*
<Leader>wd              Delete WikiWord you are in.
                        Maps to|:VimwikiDeleteWord|.
                        To remap: >
                        :map <Leader>dd <Plug>VimwikiDeleteWord
<
                        *vimwiki_<Leader>wr*
<Leader>wr              Rename WikiWord you are in.
                        Maps to|:VimwikiRenameWord|.
                        To remap: >
                        :map <Leader>rr <Plug>VimwikiRenameWord
<
                        *vimwiki_<C-Space>*
<C-Space>               Toggle list item on/off (checked/unchecked)
                        Maps to|:VimwikiToggleListItem|.
                        To remap: >
                        :map <leader>tt <Plug>VimwikiToggleListItem
<                       See |vimwiki-todo-lists|.

                        *vimwiki_=*
=                       Add header level. Create if needed.
                        There is nothing to indent with '==' command in
                        vimwiki, so it should be ok to use '=' here.

                        *vimwiki_-*
-                       Remove header level.

Normal mode (Mouse): ~
Works only if |g:vimwiki_use_mouse| is set to 1.
<2-LeftMouse>           Follow/Create WikiWord
<S-2-LeftMouse>         Split and follow/create WikiWord
<C-2-LeftMouse>         Vertical split and follow/create WikiWord
<RightMouse><LeftMouse> Go back to previous WikiWord

Note: <2-LeftMouse> is just left double click.

------------------------------------------------------------------------------
3.3. Text objects                                       *vimwiki-text-objects*

ah                      A Header with leading empty lines.
ih                      Inner Header without leading empty lines.

You can 'vah' to select a header with its contents or 'dah' to delete it or
'yah' to yank it or 'cah' to change it. ;)


==============================================================================
4. Commands                                                 *vimwiki-commands*

------------------------------------------------------------------------------
4.1. Global Commands                                 *vimwiki-global-commands*

*:VimwikiGoHome*
    Open index file of the current wiki.

*:VimwikiTabGoHome*
    Open index file of the current wiki in a new tab.

*:VimwikiUISelect*
    Open index file of the selected wiki.

------------------------------------------------------------------------------
4.2. Local commands                                   *vimwiki-local-commands*

*:VimwikiFollowWord*
    Follow/create WikiWord.

*:VimwikiGoBackWord*
    Go back to previous WikiWord you come from.

*:VimwikiSplitWord*
    Split and follow/create WikiWord.

*:VimwikiVSplitWord*
    Vertical split and follow/create WikiWord.

*:VimwikiNextWord*
    Find next WikiWord.

*:VimwikiPrevWord*
    Find previous WikiWord.

*:VimwikiDeleteWord*
    Delete WikiWord you are in.

*:VimwikiRenameWord*
    Rename WikiWord you are in.

*:Vimwiki2HTML*
    Convert current WikiPage to HTML.

*:VimwikiAll2HTML*
    Convert all WikiPages to HTML.

*:VimwikiToggleListItem*
    Toggle list item on/off (checked/unchecked)
    See |vimwiki-todo-lists|.



==============================================================================
5. Wiki syntax                                                *vimwiki-syntax*

There are a lot of different wikies out there. Most of them have their own
syntax and vimwiki is not an exception here. Default vimwiki's syntax is a
subset of google's wiki syntax markup.

As for MediaWiki's syntax -- it is not that convenient for non English
(Russian in my case :)) keyboard layouts to emphasize text as it uses a lot
of '''''' to do it. You have to switch layouts every time you want some bold
non English text. This is the answer to "Why not MediaWiki?"

Nevertheless, there is MediaWiki syntax file included in the distribution (it
doesn't have all the fancy stuff original MediaWiki syntax has though).
See |vimwiki-option-syntax|.


------------------------------------------------------------------------------
5.1. Typefaces                                      *vimwiki-syntax-typefaces*

There are a few typefaces that gives you a bit of control on how your
text should be decorated: >
  *bold text*
  _italic text_
  ~~strikeout text~~
  `code (no syntax) text`
  super^script^
  sub,,script,,

------------------------------------------------------------------------------
5.2. Links                                              *vimwiki-syntax-links*

Internal links~
WikiWords: >
  CapitalizedWordsConnected

You can limit linking of WikiWords by adding an exclamation mark in front of
it: >
  !CapitalizedWordsConnected

Link with spaces in it: >
  [[This is a link]]
or: >
  [[This is a link source|Description of the link]]


External links~
Plain link: >
 http://code.google.com/p/vimwiki

Link with description: >
 [http://habamax.ru/blog habamax home page]


Images and image links~
Image link is the link with one of jpg, png or gif endings.
Plain image link: >
 http://someaddr.com/picture.jpg
in html: >
 <img src="http://someaddr.com/picture.jpg" />

Link to a local image: >
 [[images/pabloymoira.jpg]]
in html: >
 <img src="images/pabloymoira.jpg" />
Path to image (ie. images/pabloymoira.jpg) is relative to
|vimwiki-option-path_html|.

Double bracketed link to an image: >
 [[http://habamax.ru/blog/wp-content/uploads/2009/01/2740254sm.jpg]]
in html: >
 <img src="http://habamax.ru/ ... /.jpg" />

Double bracketed link to an image with description text: >
 [[http://habamax.ru/blog/wp-content/uploads/2009/01/2740254sm.jpg|dance]]
in html: >
 <a href="http://habamax.ru/ ... /.jpg">dance</a>

Double bracketed link to an image with alternate text: >
 [[http://habamax.ru/blog/wp-content/uploads/2009/01/2740254sm.jpg|dance|]]
in html: >
 <img src="http://habamax.ru/ ... /.jpg" alt="dance"/>

Double bracketed link to an image with alternate text and some style: >
 [[http://helloworld.com/blabla.jpg|cool stuff|width:150px; height: 120px;]]
in html: >
 <img src="http://helloworld.com/ ... /.jpg" alt="cool stuff"
 style="width:150px; height:120px"/>

Double bracketed link to an image without alternate text and some style: >
 [[http://helloworld.com/blabla.jpg||width:150px; height: 120px;]]
in html: >
 <img src="http://helloworld.com/ ... /.jpg" alt=""
 style="width:150px; height:120px"/>

Thumbnail link: >
 [http://someaddr.com/bigpicture.jpg http://someaddr.com/thumbnail.jpg]
or >
 [[http://someaddr.com/bigpicture.jpg|http://someaddr.com/thumbnail.jpg]]
in html: >
 <a href="http://someaddr.com/ ... /.jpg">
  <img src="http://../thumbnail.jpg /></a>


------------------------------------------------------------------------------
5.3. Headers                                          *vimwiki-syntax-headers*

= Header level 1 =~
By default all headers are highlighted using |hl-Title| highlight group.
== Header level 2 ==~
You can set up different colors for each header level: >
  :hi wikiHeader1 guifg=#FF0000
  :hi wikiHeader2 guifg=#00FF00
  :hi wikiHeader3 guifg=#0000FF
  :hi wikiHeader4 guifg=#FF00FF
  :hi wikiHeader5 guifg=#00FFFF
  :hi wikiHeader6 guifg=#FFFF00
Set up colors for all 6 header levels or none at all.
=== Header level 3 ===~
==== Header level 4 ====~
===== Header level 5 =====~
====== Header level 6 ======~

Note: before vimwiki 0.8.2, header's markup syntax used exclamation marks:
! Header level 1
!! Header level 2
etc...

If you upgrade from pre 0.8.2 you might find the next commands useful.
To change headers from !Header to =Header= in your wiki files do: >
 :args .wiki
 :argdo %s/^\(!\+\)\([^!].*$\)/\=substitute(submatch(1),'!','=','g').submatch(2).substitute(submatch(1),'!','=','g')

Note: BACKUP FIRST!

------------------------------------------------------------------------------
5.4. Paragraphs                                    *vimwiki-syntax-paragraphs*

Paragraph is group of lines started from column 1 (no indentation). Paragraphs
divided by a blank line:

This is first paragraph
with two lines.

This is a second paragraph with
two lines.

------------------------------------------------------------------------------
5.5. Lists                                              *vimwiki-syntax-lists*

Indent list items with at least one space.
Unordered lists: >
  * Bulleted list item 1
  * Bulleted list item 2
    * Bulleted list sub item 1
    * Bulleted list sub item 2
    * more ...
      * and more ...
      * ...
    * Bulleted list sub item 3
    * etc.

Ordered lists: >
  # Numbered list item 1
  # Numbered list item 2
    # Numbered list sub item 1
    # Numbered list sub item 2
    # more ...
      # and more ...
      # ...
    # Numbered list sub item 3
    # etc.

It is possible to mix bulleted and numbered lists: >
  * Bulleted list item 1
  * Bulleted list item 2
    # Numbered list sub item 1
    # Numbered list sub item 2


Definition lists: >
Term 1:: Definition 1
Term 2::
::Definition 2
::Definition 3


------------------------------------------------------------------------------
5.6. Tables                                            *vimwiki-syntax-tables*

Tables are created by entering the content of each cell separated by ||
delimiters. You can insert other inline wiki syntax in table cells, including
typeface formatting and links.
For example:

||*Year*s||*Temperature (low)*||*Temperature (high)*||
||1900   ||-10                ||25                  ||
||1910   ||-15                ||30                  ||
||1920   ||-10                ||32                  ||
||1930   ||_N/A_              ||_N/A_               ||
||1940   ||-2                 ||40                  ||


For HTML, contents of table cell could be aligned to the right, left and
center:

|| Center || Center || Center ||
||Left    || Center ||   Right||
||   Right||Left    || Center ||
|| Center ||   Right||Left    ||

No spaces on the left side -- left alignment.
No spaces on the right side -- right alignment.
Spaces on the left and on the right -- center alignment.


------------------------------------------------------------------------------
5.7. Preformatted text                           *vimwiki-syntax-preformatted*

If the line started from whitespace and is not a list it is "preformatted" text.
For example: >

  Tyger! Tyger! burning bright
   In the forests of the night,
    What immortal hand or eye
     Could frame thy fearful symmetry?
  In what distant deeps or skies
   Burnt the fire of thine eyes?
    On what wings dare he aspire?
     What the hand dare sieze the fire?
  ...
  ...

Or use {{{ and }}} to define pre:
{{{ >
  Tyger! Tyger! burning bright
   In the forests of the night,
    What immortal hand or eye
     Could frame thy fearful symmetry?
  In what distant deeps or skies
   Burnt the fire of thine eyes?
    On what wings dare he aspire?
     What the hand dare sieze the fire?
}}}


You can add optional information to {{{ tag: >
{{{class="brush: python" >
 def hello(world):
     for x in range(10):
         print("Hello {0} number {1}".format(world, x))
}}}

Result of HTML export: >
 <pre class="brush: python">
 def hello(world):
     for x in range(10):
         print("Hello {0} number {1}".format(world, x))
 </pre>

This might be useful for coloring some programming code with external js tools
like google syntax highlighter.


------------------------------------------------------------------------------
5.8. Comments                                        *vimwiki-syntax-comments*

Text between <!-- and --> is a comment.
Ex: >
 <!-- this text would not be in HTML -->
<

==============================================================================
6. Folding/Outline                                           *vimwiki-folding*

Vimwiki can fold or outline headers and list items.

Example:
= My current task =
  * [ ] Do stuff 1
    * [ ] Do substuff 1.1
    * [ ] Do substuff 1.2
      * [ ] Do substuff 1.2.1
      * [ ] Do substuff 1.2.2
    * [ ] Do substuff 1.3
  * [ ] Do stuff 2
  * [ ] Do stuff 3

Hit |zM| :
= My current task = [8] --------------------------------------~

Hit |zr| :
= My current task =~
  * [ ] Do stuff 1 [5] --------------------------------------~
  * [ ] Do stuff 2~
  * [ ] Do stuff 3~

Hit |zr| one more time:
= My current task =~
  * [ ] Do stuff 1~
    * [ ] Do substuff 1.1~
    * [ ] Do substuff 1.2 [2] -------------------------------~
    * [ ] Do substuff 1.3~
  * [ ] Do stuff 2~
  * [ ] Do stuff 3~

NOTE: Whether you use default syntax, folding on list items should work
properly only if all of them are indented using current |shiftwidth|.
For MediaWiki * or # should be in the first column.

To turn folding on/off checkout |vimwiki-option-folding|.

==============================================================================
7. Todo lists                                             *vimwiki-todo-lists*

You can have todo lists -- lists of items you can check/uncheck.

Consider the following example:
= Toggleable list of items =
  * [x] Toggle list item on/off.
    * [x] Simple toggling between [ ] and [x].
    * [x] All list's subitems should be toggled on/off appropriately.
    * [x] Toggle child subitems only if current line is list item
    * [x] Parent list item should be toggled depending on it's child items.
  * [x] Make numbered list items toggleable too
  * [x] Add highlighting to list item boxes
  * [x] Add [ ] to the next created with o, O and <CR> list item.

Pressing <C-Space> on the first list item will toggle it and all of it's child
items.

==============================================================================
8. Options                                                   *vimwiki-options*

------------------------------------------------------------------------------
*g:vimwiki_list* *vimwiki-multiple-wikies*

Each item in g:vimwiki_list is a |Dictionary| that holds all customization
available for a wiki represented by that item. It is in form of >
  {'option1': 'value1', 'option2: 'value2', ...}

Consider the following example: >
  let g:vimwiki_list = [{'path': '~/my_site/', 'path_html': '~/public_html/'}]

It gives us one wiki located at ~/my_site/ that could be htmlized to
~/public_html/

The next example: >
  let g:vimwiki_list = [{'path': '~/my_site/', 'path_html': '~/public_html/'},
            \ {'path': '~/my_docs/', 'ext': '.mdox'}]
gives us 2 wikies, first wiki as in previous example, second one is located in
~/my_docs/ and its files have .mdox extension.

Empty |Dictionary| in the g:vimwiki_list is the wiki with default options: >
  let g:vimwiki_list = [{},
            \ {'path': '~/my_docs/', 'ext': '.mdox'}]

<
*vimwiki-option-path*
Key             Default value~
path            ~/vimwiki/
Description~
Wiki files location: >
  let g:vimwiki_list = [{'path': '~/my_site/'}]
<

*vimwiki-option-path_html*
Key             Default value~
path_html       ~/vimwiki_html/
Description~
HTML files converted from wiki files location: >
  let g:vimwiki_list = [{'path': '~/my_site/',
                       \ 'path_html': '~/my_site_html/'}]

If you omit this option path_html would be path - '/' + '_html/': >
  let g:vimwiki_list = [{'path': '~/okidoki/'}]

ie, path_html = '~/okidoki_html/'


*vimwiki-option-index*
Key             Default value~
index           index
Description~
Name of wiki index file: >
  let g:vimwiki_list = [{'path': '~/my_site/', 'index': 'main'}]

NOTE: Do not add extension.


*vimwiki-option-ext*
Key             Default value~
ext             .wiki
Description~
Extension of wiki files: >
  let g:vimwiki_list = [{'path': '~/my_site/',
                       \ 'index': 'main', 'ext': '.document'}]

<
*vimwiki-option-folding*
Key             Default value     Values~
folding         1                 0, 1
Description~
Enable/disable vimwiki's folding/outline. Folding in vimwiki is using 'expr'
foldmethod which is very flexible but really slow.
To turn it off set it to 0 as in example below: >
  let g:vimwiki_list = [{'path': '~/articles/', 'folding': 0}]
<

*vimwiki-option-syntax*
Key             Default value     Values~
syntax          default           default, media
Description~
Wiki syntax.
You can use different markup languages (currently default vimwiki and
MediaWiki) but only vimwiki's default markup could be converted to HTML at the
moment.
To use MediaWiki's wiki markup: >
  let g:vimwiki_list = [{'path': '~/my_site/', 'syntax': 'media'}]
<

*vimwiki-option-html_header*
Key             Default value~
html_header
Description~
Set up file name for html header template: >
  let g:vimwiki_list = [{'path': '~/my_site/',
          \ 'html_header': '~/public_html/header.tpl'}]

This header.tpl could look like: >
    <html>
    <head>
        <link rel="Stylesheet" type="text/css" href="style.css" />
        <title>%title%</title>
        <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    </head>
    <body>
        <div class="contents">

where %title% is replaced by a wiki page name.


*vimwiki-option-html_footer*
Key             Default value~
html_footer
Description~
Set up file name for html footer template: >
  let g:vimwiki_list = [{'path': '~/my_site/',
          \ 'html_footer': '~/public_html/footer.tpl'}]

This footer.tpl could look like: >
        </div>
    </body>
    </html>
<

*vimwiki-option-css_name*
Key             Default value~
css_name        style.css
Description~
Set up css file name: >
  let g:vimwiki_list = [{'path': '~/my_pages/',
          \ 'css_name': 'main.css'}]
<
or even >
  let g:vimwiki_list = [{'path': '~/my_pages/',
          \ 'css_name': 'css/main.css'}]
<

*vimwiki-option-gohome*
Key             Default value     Values~
gohome          split             split, vsplit, tabe
Description~
This option controls the way |:VimwikiGoHome| command works.
For instance you have 'No write since last change' buffer. After <Leader>ww
(or :VimwikiGoHome) vimwiki index file will be splitted with it. Or vertically
splitted. Or opened in a new tab.
Ex: >
  let g:vimwiki_list = [{'path': '~/my_site/', 'gohome': 'vsplit'}]
<

*vimwiki-option-maxhi*
Key             Default value     Values~
maxhi           1                 0, 1
Description~
Non-existent WikiWord highlighting could be quite slow and if you don't want
it set maxhi to 0: >
  let g:vimwiki_list = [{'path': '~/my_site/', 'maxhi': 0}]

This disables filesystem checks for WikiWords.


------------------------------------------------------------------------------
*g:vimwiki_upper* *g:vimwiki_lower*

This affects WikiWord detection.
By default WikiWord detection uses English and Russian letters.
You can set up your own: >
  let g:vimwiki_upper = "A-Z\u0410-\u042f"
  let g:vimwiki_lower = "a-z\u0430-\u044f"


------------------------------------------------------------------------------
*g:vimwiki_auto_checkbox*

if on, creates checkbox while toggling list item.

Value           Description~
0               Do not create checkbox.
1               Create checkbox.

Default: 1

Ex:
Press <C-Space> (|:VimwikiToggleListItem|) on a list item without checkbox to
create it: >
  * List item
result: >
  * [ ] List item


------------------------------------------------------------------------------
*g:vimwiki_menu*

GUI menu of available wikies to select.

Value              Description~
''                 No menu
'Vimwiki'          Top level menu "Vimwiki"
'Plugin.Vimwiki'   "Vimwiki" submenu of top level menu "Plugin"
etc.

Default: 'Vimwiki'

------------------------------------------------------------------------------
*g:vimwiki_stripsym*

Change strip symbol -- in Windows you cannot use /*?<>:" in file names so
vimwiki replaces them with neutral symbol (_ is default): >
    let g:vimwiki_stripsym = ' '

------------------------------------------------------------------------------
*g:vimwiki_use_mouse*

Use local mouse mappings from |vimwiki-local-mappings|.

Value           Description~
0               Do not use mouse mappings.
1               Use mouse mappings.

Default: 0

------------------------------------------------------------------------------
*g:vimwiki_fold_empty_lines*

Fold or not empty lines between folded headers.

Value           Description~
0               Do not fold in empty lines.
1               Fold in empty lines.

Default: 0

==============================================================================
9. Help                                                         *vimwiki-help*

As you could see I am not native English speaker (not a writer as well).
Please send me correct phrases instead of that incorrect stuff I have used
here.

Any help is really appreciated!

==============================================================================
10. Author                                                    *vimwiki-author*

I live in Moscow and you may believe me -- there are no polar bears (no brown
too) here in the streets.

I do not do programming for a living. So don't blame me for an ugly
ineffective code.

Many thanks to all of you for voting vimwiki up on www.vim.org. I do vimwiki
in my spare time I could use to dance argentine tango with beautiful women.
Your votes are kind of a good replacement. ;)

Sincerely yours,
Maxim Kim <habamax@gmail.com>.

Vimwiki's website: http://code.google.com/p/vimwiki/
Vim plugins website: http://www.vim.org/scripts/script.php?script_id=2226

==============================================================================
11. Changelog                                              *vimwiki-changelog*

0.9.3
  * [new] g:vimwiki_menu option is a string which is menu path. So one can use
    let g:vimwiki_menu = 'Plugin.Vimwiki' to set the menu to the right place.
  * [new] g:vimwiki_fold_empty_lines -- don't or do fold in empty lines
    between headers. See |g:vimwiki_fold_empty_lines|
  * [fix] Encoding error when running vimwiki in Windows XP Japanese.
    Thanks KarasAya.

0.9.2c
  * [fix] Regression: Export HTML link error with [[Link|Text]].

0.9.2b
  * [fix] Installation on Linux doesn't work. (Dos line endings in Vimball
    archive file).
  * [fix] Clear out FlexWiki ftplugin's setup. Now you don't have to hack
    filetype.vim to get rid of unexpected ':setlocal bomb' from FlexWiki's
    ftplugin.
  * [fix] When write done: it will show another done: in html file.

0.9.2a
  * [fix] Installation on Linux doesn't work. (Dos line endings in
    autoload/vimwiki_lst.vim and indent/vimwiki.vim).

0.9.2
  * [new] Option 'folding' added to turn folding on/off.
  * [new] Header text object. See |vimwiki-text-objects|.
  * [new] Add/remove Header levels with '=' and '-'. See |vimwiki_=|.
  * [new] Vimwiki GUI menu to select available wikies. See |g:vimwiki_menu|.
  * [new] You can specify the name of your css file now. See
    |vimwiki-option-css_name|
  * [new] You can add styles to image links, see |vimwiki-syntax-links|.
  * [fix] History doesn't work after |VimwikiRenameWord|.
  * [fix] Some of wikipedia links are not correctly highlighted. Links with
    parentheses.
  * [misc] Renamed vimwiki_gtd to vimwiki_lst.

0.9.1
  * [new] HTML Table cell text alignment, see |vimwiki-syntax-tables|
  * [new] Wikipage history simplified. Each vimwiki buffer now holds
    b:vimwiki_prev_word which is list of [PrevWord, getpos()].
  * [new] If highlight for groups wikiHeader1..wikiHeader6 exist (defined in
    a colorscheme) -- use it. Otherwise use Title highlight for all Headers.
  * [fix] Warn only once if 'html_header' or 'html_footer' does not exist.
  * [fix] Wrong folding for the text after the last nested list item.
  * [fix] Bold and Italic aren't highlighted in tables without spaces
    between || and * or _. ||*bold*||_asdf_ || (Thanks Brett Stahlman)

0.9.0
  * [new] You can add classes to 'pre' tag -- |vimwiki-syntax-preformatted|.
    This might be useful for coloring some programming code with external js
    tools like google syntax highlighter.
  * [new] !WikiPage is not highlighted. It is just a plain word WikiPage in
    HTML, without exclamation mark
  * [new] Definition lists, see |vimwiki-syntax-lists|.
  * [new] New implementation of |:VimwikiRenameWord|. CAUTION: It was tested
    on 2 computers only, backup your wiki before use it. Email me if it
    doesn't work for you.
  * [fix] Less than 3 symbols are not highlighted in Bold and Italic.
  * [fix] Added vimwiki autocmd group to avoid clashes with user defined
    autocmds.
  * [fix] Pressing ESC while |:VimwikiUISelect| opens current wiki index file.
    Should cancel wiki selection.

0.8.3
  * [new] <C-Space> on a list item creates checkbox.
  * [fix] With * in the first column, <CR> shouldn't insert more * (default
    syntax).
  * [fix] With MediaWiki's ** [ ], <CR> should insert it on the next line.
  * [fix] HTML export should use 'fileencoding' instead of 'encoding'.
  * [fix] Code cleanup.

0.8.2
  * [del] Removed google syntax file.
  * [new] Default vimwiki syntax is a subset of google's one. Header's has
    been changed from !Header to =Header=. It is easier to maintain only 2
    syntaxes. See |vimwiki-syntax-headers|.
  * [new] Multiline paragraphs -- less longlines.
  * [new] Comments. See |vimwiki-syntax-comments|.
  * [del] Removed setlocal textwidth = 0 from ftplugin.
  * [fix] New regexps for bold, italic, bolditalic.
  * [fix] The last item in List sometimes fold-in incorrectly.
  * [fix] Minor tweaks on default css.

0.8.1
  * [new] Vimwiki's foldmethod changed from syntax to expr. Foldtext is
    changed to be nicer with folded list items.
  * [new] Fold/outline list items.
  * [new] It is possible now to edit wiki files in arbitrary directories which
    is not in g:vimwiki_list's paths. New WikiWords are created in the path of
    the current WikiWord.
  * [new] User can remap Vimwiki's built in mappings.
  * [new] Added |g:vimwiki_use_mouse|. It is off by default.
  * [fix] Removed <C-h> mapping.

0.8.0
  * [new] Multiple wikies support. A lot of options have been changed, see
    |vimwiki-options|
  * [new] Auto create directories.
  * [new] Checked list item highlighted as comment.
  * [fix] Multiple 'set ft=vimwiki' for each buffer disabled. Vimwiki should
    load its buffers a bit faster now.

0.7.1
  * [new] <Plug>VimwikiToggleListItem added to be able to remap <C-Space> to
    anything user prefers more.
  * [fix] Toggleable list items do not work with MediaWiki markup.
  * [fix] Changing g:vimwiki_home_html to path with ~ while vimwiki is
    loaded gives errors for HTML export.
  * [del] Command :VimwikiExploreHome.

0.7.0
  * [new] GTD stuff -- toggleable list items. See |vimwiki-todo-lists|.
  * [fix] Headers do not fold inner headers. (Thanks Brett Stahlman)
  * [fix] Remove last blank lines from preformatted text at the end of file.
  * [del] Removed g:vimwiki_smartCR option.

0.6.2
  * [new] [[link|description]] is available now.
  * [fix] Barebone links (ie: http://bla-bla-bla.org/h.pl?id=98) get extra
    escaping of ? and friends so they become invalid in HTML.
  * [fix] In linux going to [[wiki with whitespaces]] and then pressing BS
    to go back to prev wikipage produce error. (Thanks Brendon Bensel for
    the fix)
  * [fix] Remove setlocal encoding and fileformat from vimwiki ftplugin.
  * [fix] Some tweaks on default style.css

0.6.1
  * [fix] [blablabla bla] shouldn't be converted to a link.
  * [fix] Remove extra annoing empty strings from PRE tag made from
    whitespaces in HTML export.
  * [fix] Moved functions related to HTML converting to new autoload module
    to increase a bit vimwiki startup time.

0.6
  * [new] Header and footer templates. See|g:vimwiki_html_header| and
    |g:vimwiki_html_footer|.
  * [fix] |:Vimwiki2HTML| does not recognize ~ as part of a valid path.

0.5.3
  * [fix] Fixed |:VimwikiRenameWord|. Error when g:vimwiki_home had
    whitespaces in path.
  * [fix] |:VimwikiSplitWord| and |:VimwikiVSplitWord| didn't work.

0.5.2
  * [new] Added |:VimwikiGoHome|, |:VimwikiTabGoHome| and
  |:VimwikiExploreHome| commands.
  * [new] Added <Leader>wt mapping to open vimwiki index file in a new tab.
  * [new] Added g:vimwiki_gohome option that controls how|:VimwikiGoHome|
    works when current buffer is changed. (Thanks Timur Zaripov)
  * [fix] Fixed |:VimwikiRenameWord|. Very bad behaviour when autochdir
    isn't set up.
  * [fix] Fixed commands :Wiki2HTML and :WikiAll2HTML to be available only
    for vimwiki buffers.
  * [fix] Renamed :Wiki2HTML and :WikiAll2HTML to |:Vimwiki2HTML| and
    |:VimwikiAll2HTML| commands.
  * [fix] Help file corrections.

0.5.1
  * [new] This help is created.
  * [new] Now you can fold headers.
  * [new] <Plug>VimwikiGoHome and <Plug>VimwikiExploreHome were added.
  * [fix] Bug with {{{HelloWikiWord}}} export to HTML is fixed.
  * [del] Sync option removed from: Syntax highlighting for preformatted
    text {{{ }}}.

0.5
  * [new] vimwiki default markup to HTML conversion improved.
  * [new] Added basic GoogleWiki and MediaWiki markup languages.
  * [new] Chinese [[complex wiki words]].

0.4
  * [new] vimwiki=>HTML converter in plain Vim language.
  * [new] Plugin autoload.

0.3.4
  * [fix] Backup files (.wiki~) caused a bunch of errors while opening wiki
    files.

0.3.3
  * FIXED: [[wiki word with dots at the end...]] didn't work.
  * [new] Added error handling for delete wiki word function.
  * [new] Added keybindings o and O for list items when g:vimwiki_smartCR=1.
  * [new] Added keybinding <Leader>wh to visit wiki home directory.

0.3.2
  * [fix] Renaming -- error if complex wiki word contains %.
  * [fix] Syntax highlighting for preformatted text {{{ }}}. Sync option
    added.
  * [fix] smartCR bug fix.

0.3.1
  * [fix] Renaming -- [[hello world?]] to [[hello? world]] links are not
    updated.
  * [fix] Buffers menu is a bit awkward after renaming.
  * [new] Use mouse to follow links. Left double-click to follow WikiWord,
    Rightclick then Leftclick to go back.

0.3
  * [new] Highlight non-existent WikiWords.
  * [new] Delete current WikiWord (<Leader>wd).
  * [new] g:vimwiki_smartCR=2 => use Vim comments (see :h comments :h
    formatoptions) feature to deal with list items. (thx -- Dmitry
    Alexandrov)
  * [new] Highlight TODO:, DONE:, FIXED:, FIXME:.
  * [new] Rename current WikiWord -- be careful on Windows you cannot rename
    wikiword to WikiWord. After renaming update all links to that renamed
    WikiWord.
  * [fix] Bug -- do not duplicate WikiWords in wiki history.
  * [fix] After renaming [[wiki word]] twice buffers are not deleted.
  * [fix] Renaming from [[wiki word]] to WikiWord result is [[WikiWord]]
  * [fix] More than one complex words on one line is bugging each other when
    try go to one of them. [[bla bla bla]] [[dodo dodo dodo]] becomes
    bla bla bla]] [[dodo dodo dodo.


0.2.2
  * [new] Added keybinding <S-CR> -- split WikiWord
  * [new] Added keybinding <C-CR> -- vertical split WikiWord

0.2.1
  * [new] Install on Linux now works.

0.2
  * [new] Added part of Google's Wiki syntax.
  * [new] Added auto insert # with ENTER.
  * [new] On/Off auto insert bullet with ENTER.
  * [new] Strip [[complex wiki name]] from symbols that cannot be used in
    file names.
  * [new] Links to non-wiki files. Non wiki files are files with extensions
    ie [[hello world.txt]] or [[my homesite.html]]

0.1
  * First public version.

==============================================================================
12. License                                                   *vimwiki-license*

GNU General Public License v2
http://www.gnu.org/licenses/old-licenses/gpl-2.0.html

To be frank I didn't read it myself. It is not that easy reading. But I hope
it's free enough to suit your needs.


 vim:tw=78:ts=8:ft=help
ftplugin\vimwiki.vim	[[[1
212
" Vimwiki filetype plugin file
" Author: Maxim Kim <habamax@gmail.com>
" Home: http://code.google.com/p/vimwiki/

if exists("b:did_ftplugin")
  finish
endif
let b:did_ftplugin = 1  " Don't load another plugin for this buffer

" UNDO list {{{
" Reset the following options to undo this plugin.
let b:undo_ftplugin = "setlocal wrap< linebreak< ".
      \ "suffixesadd< isfname< comments< ".
      \ "autowriteall< ".
      \ "formatoptions< foldtext< ".
      \ "foldmethod< foldexpr< commentstring< "
" UNDO }}}
" MISC STUFF {{{
setlocal wrap
setlocal linebreak
setlocal autowriteall
setlocal commentstring=<!--%s-->
" MISC }}}
" GOTO FILE: gf {{{
execute 'setlocal suffixesadd='.VimwikiGet('ext')
setlocal isfname-=[,]
" gf}}}
" COMMENTS: autocreate list items {{{
" for list items, and list items with checkboxes
if VimwikiGet('syntax') == 'default'
  setl comments=b:\ *\ [\ ],b:\ *[\ ],b:\ *\ [],b:\ *[],b:\ *\ [x],b:\ *[x]
  setl comments+=b:\ #\ [\ ],b:\ #[\ ],b:\ #\ [],b:\ #[],b:\ #\ [x],b:\ #[x]
  setl comments+=b:\ *,b:\ #
else
  setl comments=n:*\ [\ ],n:*[\ ],n:*\ [],n:*[],n:*\ [x],n:*[x]
  setl comments+=n:#\ [\ ],n:#[\ ],n:#\ [],n:#[],n:#\ [x],n:#[x]
  setl comments+=n:*,n:#
endif
setlocal formatoptions=ctnqro
" COMMENTS }}}
" FOLDING for headers and list items using expr fold method. {{{
if VimwikiGet('folding')
  setlocal fdm=expr
endif
setlocal foldexpr=VimwikiFoldLevel(v:lnum)
function! VimwikiFoldLevel(lnum) "{{{
  let line = getline(a:lnum)
  let nline = getline(a:lnum + 1)

  " Header folding...
  if line =~ g:vimwiki_rxHeader
    let n = vimwiki#count_first_sym(line)
    return '>' . n
  endif

  if g:vimwiki_fold_empty_lines == 0
    let nnline = getline(nextnonblank(a:lnum + 1))
    if nnline =~ g:vimwiki_rxHeader
      let n = vimwiki#count_first_sym(nnline)
      return '<' . n
    endif
  endif

  " List item folding...
  let nnum = a:lnum + 1

  let rx_list_item = '\('.
        \ g:vimwiki_rxListBullet.'\|'.g:vimwiki_rxListNumber.
        \ '\)'
  if line =~ rx_list_item && nline =~ rx_list_item
    return s:get_li_level(a:lnum, nnum)
  " list is over, remove foldlevel
  elseif line =~ rx_list_item && nline !~ rx_list_item
    return s:get_li_level_last(a:lnum)
  endif

  return '='
endfunction "}}}

function! s:get_li_level(lnum, nnum) "{{{
  if VimwikiGet('syntax') == 'media'
    let level = s:count_first_sym(getline(a:nnum)) -
          \ s:count_first_sym(getline(a:lnum))
    if level > 0
      return "a".level
    elseif level < 0
      return "s".abs(level)
    else
      return "="
    endif
  else
    let level = ((indent(a:nnum) - indent(a:lnum)) / &sw)
    if level > 0
      return "a".level
    elseif level < 0
      return "s".abs(level)
    else
      return "="
    endif
  endif
endfunction "}}}

function! s:get_li_level_last(lnum) "{{{
  if VimwikiGet('syntax') == 'media'
    return "s".(s:count_first_sym(getline(a:lnum)) - 1)
  else
    return "s".(indent(a:lnum) / &sw - 1)
  endif
endfunction "}}}

setlocal foldtext=VimwikiFoldText()
function! VimwikiFoldText() "{{{
  let line = getline(v:foldstart)
  return line.' ['.(v:foldend - v:foldstart).'] '
endfunction "}}}

" FOLDING }}}
" COMMANDS {{{
command! -buffer Vimwiki2HTML
      \ call vimwiki_html#Wiki2HTML(expand(VimwikiGet('path_html')),
      \                             expand('%'))
command! -buffer VimwikiAll2HTML
      \ call vimwiki_html#WikiAll2HTML(expand(VimwikiGet('path_html')))

command! -buffer VimwikiNextWord call vimwiki#WikiNextWord()
command! -buffer VimwikiPrevWord call vimwiki#WikiPrevWord()
command! -buffer VimwikiDeleteWord call vimwiki#WikiDeleteWord()
command! -buffer VimwikiRenameWord call vimwiki#WikiRenameWord()
command! -buffer VimwikiFollowWord call vimwiki#WikiFollowWord('nosplit')
command! -buffer VimwikiGoBackWord call vimwiki#WikiGoBackWord()
command! -buffer VimwikiSplitWord call vimwiki#WikiFollowWord('split')
command! -buffer VimwikiVSplitWord call vimwiki#WikiFollowWord('vsplit')

command! -buffer VimwikiToggleListItem call vimwiki_lst#ToggleListItem()
" COMMANDS }}}
" KEYBINDINGS {{{
if g:vimwiki_use_mouse
  nmap <buffer> <S-LeftMouse> <NOP>
  nmap <buffer> <C-LeftMouse> <NOP>
  noremap <silent><buffer> <2-LeftMouse> :VimwikiFollowWord<CR>
  noremap <silent><buffer> <S-2-LeftMouse> <LeftMouse>:VimwikiSplitWord<CR>
  noremap <silent><buffer> <C-2-LeftMouse> <LeftMouse>:VimwikiVSplitWord<CR>
  noremap <silent><buffer> <RightMouse><LeftMouse> :VimwikiGoBackWord<CR>
endif

if !hasmapto('<Plug>VimwikiFollowWord')
  nmap <silent><buffer> <CR> <Plug>VimwikiFollowWord
endif
noremap <silent><script><buffer>
      \ <Plug>VimwikiFollowWord :VimwikiFollowWord<CR>

if !hasmapto('<Plug>VimwikiSplitWord')
  nmap <silent><buffer> <S-CR> <Plug>VimwikiSplitWord
endif
noremap <silent><script><buffer>
      \ <Plug>VimwikiSplitWord :VimwikiSplitWord<CR>

if !hasmapto('<Plug>VimwikiVSplitWord')
  nmap <silent><buffer> <C-CR> <Plug>VimwikiVSplitWord
endif
noremap <silent><script><buffer>
      \ <Plug>VimwikiVSplitWord :VimwikiVSplitWord<CR>

if !hasmapto('<Plug>VimwikiGoBackWord')
  nmap <silent><buffer> <BS> <Plug>VimwikiGoBackWord
endif
noremap <silent><script><buffer>
      \ <Plug>VimwikiGoBackWord :VimwikiGoBackWord<CR>

if !hasmapto('<Plug>VimwikiNextWord')
  nmap <silent><buffer> <TAB> <Plug>VimwikiNextWord
endif
noremap <silent><script><buffer>
      \ <Plug>VimwikiNextWord :VimwikiNextWord<CR>

if !hasmapto('<Plug>VimwikiPrevWord')
  nmap <silent><buffer> <S-TAB> <Plug>VimwikiPrevWord
endif
noremap <silent><script><buffer>
      \ <Plug>VimwikiPrevWord :VimwikiPrevWord<CR>

if !hasmapto('<Plug>VimwikiDeleteWord')
  nmap <silent><buffer> <Leader>wd <Plug>VimwikiDeleteWord
endif
noremap <silent><script><buffer>
      \ <Plug>VimwikiDeleteWord :VimwikiDeleteWord<CR>

if !hasmapto('<Plug>VimwikiRenameWord')
  nmap <silent><buffer> <Leader>wr <Plug>VimwikiRenameWord
endif
noremap <silent><script><buffer>
      \ <Plug>VimwikiRenameWord :VimwikiRenameWord<CR>

if !hasmapto('<Plug>VimwikiToggleListItem')
  nmap <silent><buffer> <C-Space> <Plug>VimwikiToggleListItem
endif
noremap <silent><script><buffer>
      \ <Plug>VimwikiToggleListItem :VimwikiToggleListItem<CR>

" Text objects {{{
omap <silent><buffer> ah :<C-U>call vimwiki#TO_header(0)<CR>
vmap <silent><buffer> ah :<C-U>call vimwiki#TO_header(0)<CR>

omap <silent><buffer> ih :<C-U>call vimwiki#TO_header(1)<CR>
vmap <silent><buffer> ih :<C-U>call vimwiki#TO_header(1)<CR>

nmap <silent><buffer> = :call vimwiki#AddHeaderLevel()<CR>
nmap <silent><buffer> - :call vimwiki#RemoveHeaderLevel()<CR>

" }}}

" KEYBINDINGS }}}
indent\vimwiki.vim	[[[1
49
" Vimwiki indent file
" Author: Maxim Kim <habamax@gmail.com>
" Home: http://code.google.com/p/vimwiki/

" Only load this indent file when no other was loaded.
if exists("b:did_indent")
  finish
endif
let b:did_indent = 1

" Some preliminary settings
setlocal nolisp		" Make sure lisp indenting doesn't supersede us
setlocal autoindent	" indentexpr isn't much help otherwise

setlocal indentexpr=GetVimwikiIndent(v:lnum)
setlocal indentkeys+=<:>

" Only define the function once.
if exists("*GetVimwikiIndent")
  finish
endif

" Come here when loading the script the first time.

function GetVimwikiIndent(lnum)
  " Search backwards for the previous non-empty line.
  let plnum = prevnonblank(v:lnum - 1)
  if plnum == 0
    " This is the first non-empty line, use zero indent.
    return 0
  endif

  " TODO: use g:vimwiki_rxList here
  let lst_indent = len(matchstr(getline(a:lnum), '^\s\+\ze\(\*\|#\)'))
  if lst_indent > 0
    if lst_indent < &sw
      return &sw
    endif

    let mul = round(lst_indent*1.0/&sw)
    let ind = float2nr(mul * &sw)
    return ind
  endif


  return -1
endfunction

" vim:sw=2
plugin\vimwiki.vim	[[[1
227
" Vimwiki plugin file
" Author: Maxim Kim <habamax@gmail.com>
" Home: http://code.google.com/p/vimwiki/

if exists("loaded_vimwiki") || &cp
  finish
endif
let loaded_vimwiki = 1

let s:old_cpo = &cpo
set cpo&vim

" HELPER functions {{{
function! s:default(varname, value) "{{{
  if !exists('g:vimwiki_'.a:varname)
    let g:vimwiki_{a:varname} = a:value
  endif
endfunction "}}}

function! s:find_wiki(path) "{{{
  let idx = 0
  while idx < len(g:vimwiki_list)
    let path = expand(VimwikiGet('path', idx))
    if path[:-2] == a:path
      return idx
    endif
    let idx += 1
  endwhile
  return -1
endfunction "}}}

function! s:setup_buffer_leave()"{{{
  if !exists("b:vimwiki_idx")
    let b:vimwiki_idx=g:vimwiki_current_idx
  endif
endfunction"}}}

function! s:setup_buffer_enter() "{{{
  if exists("b:vimwiki_idx")
    let g:vimwiki_current_idx = b:vimwiki_idx
  else
    " Find what wiki current buffer belongs to.
    " If wiki does not exist in g:vimwiki_list -- add new wiki there with
    " buffer's path and ext.
    " Else set g:vimwiki_current_idx to that wiki index.
    let path = expand('%:p:h')
    let ext = '.'.expand('%:e')
    let idx = s:find_wiki(path)
    if idx == -1
      call add(g:vimwiki_list, {'path': path, 'ext': ext})
      let g:vimwiki_current_idx = len(g:vimwiki_list) - 1
    else
      let g:vimwiki_current_idx = idx
    endif

    let b:vimwiki_idx = g:vimwiki_current_idx
  endif

  if &filetype != 'vimwiki'
    setlocal ft=vimwiki
  else
    setlocal syntax=vimwiki
  endif
endfunction "}}}
" }}}

" DEFAULT wiki {{{
let s:vimwiki_defaults = {}
let s:vimwiki_defaults.path = '~/vimwiki/'
let s:vimwiki_defaults.path_html = '~/vimwiki_html/'
let s:vimwiki_defaults.css_name = 'style.css'
let s:vimwiki_defaults.index = 'index'
let s:vimwiki_defaults.ext = '.wiki'
let s:vimwiki_defaults.folding = 1
let s:vimwiki_defaults.maxhi = 1
let s:vimwiki_defaults.syntax = 'default'
let s:vimwiki_defaults.gohome = 'split'
let s:vimwiki_defaults.html_header = ''
let s:vimwiki_defaults.html_footer = ''
"}}}

" DEFAULT options {{{
if &encoding == 'utf-8'
  call s:default('upper', 'A-Z\u0410-\u042f')
  call s:default('lower', 'a-z\u0430-\u044f')
else
  call s:default('upper', 'A-Z')
  call s:default('lower', 'a-z')
endif
call s:default('other', '0-9')
call s:default('stripsym', '_')
call s:default('auto_listitem', 1)
call s:default('auto_checkbox', 1)
call s:default('use_mouse', 0)
call s:default('fold_empty_lines', 0)
call s:default('menu', 'Vimwiki')
call s:default('current_idx', 0)
call s:default('list', [s:vimwiki_defaults])

let upp = g:vimwiki_upper
let low = g:vimwiki_lower
let oth = g:vimwiki_other
let nup = low.oth
let nlo = upp.oth
let any = upp.nup

let g:vimwiki_word1 = '\C\<['.upp.']['.nlo.']*['.
      \ low.']['.nup.']*['.upp.']['.any.']*\>'
let g:vimwiki_word2 = '\[\[[^\]]\+\]\]'
let g:vimwiki_rxWikiWord = g:vimwiki_word1.'\|'.g:vimwiki_word2
"}}}

" OPTION get/set functions {{{
" return value of option for current wiki or if second parameter exists for
" wiki with a given index.
function! VimwikiGet(option, ...) "{{{
  if a:0 == 0
    let idx = g:vimwiki_current_idx
  else
    let idx = a:1
  endif
  if !has_key(g:vimwiki_list[idx], a:option) &&
        \ has_key(s:vimwiki_defaults, a:option)
    if a:option == 'path_html'
      let g:vimwiki_list[idx][a:option] =
            \VimwikiGet('path', idx)[:-2].'_html/'
    else
      let g:vimwiki_list[idx][a:option] =
            \s:vimwiki_defaults[a:option]
    endif
  endif

  " if path's ending is not a / or \
  " then add it
  if a:option == 'path' || a:option == 'path_html'
    let p = g:vimwiki_list[idx][a:option]
    if p !~ '[\/]$'
      let g:vimwiki_list[idx][a:option] = p.'/'
    endif
  endif

  return g:vimwiki_list[idx][a:option]
endfunction "}}}

" set option for current wiki or if third parameter exists for
" wiki with a given index.
function! VimwikiSet(option, value, ...) "{{{
  if a:0 == 0
    let idx = g:vimwiki_current_idx
  else
    let idx = a:1
  endif
  let g:vimwiki_list[idx][a:option] = a:value
endfunction "}}}
" }}}

" FILETYPE setup for all known wiki extensions {{{
" Getting all extensions that different wikies could have
let extensions = {}
for wiki in g:vimwiki_list
  if has_key(wiki, 'ext')
    let extensions[wiki.ext] = 1
  else
    let extensions['.wiki'] = 1
  endif
endfor

augroup filetypedetect
  " clear FlexWiki's stuff
  au! * *.wiki
augroup end

augroup vimwiki
  autocmd!
  for ext in keys(extensions)
    execute 'autocmd BufEnter *'.ext.' call s:setup_buffer_enter()'
    execute 'autocmd BufLeave,BufHidden *'.ext.' call s:setup_buffer_leave()'

    " ColorScheme could have or could have not a wikiHeader1..wikiHeader6
    " highlight groups. We need to refresh syntax after colorscheme change.
    execute 'autocmd ColorScheme *'.ext.' set syntax=vimwiki'
  endfor
augroup END
"}}}

" COMMANDS {{{
command! VimwikiUISelect call vimwiki#WikiUISelect()
command! -count VimwikiGoHome
      \ call vimwiki#WikiGoHome(v:count1)
command! -count VimwikiTabGoHome tabedit <bar>
      \ call vimwiki#WikiGoHome(v:count1)
"}}}

" MAPPINGS {{{
if !hasmapto('<Plug>VimwikiGoHome')
  map <silent><unique> <Leader>ww <Plug>VimwikiGoHome
endif
noremap <unique><script> <Plug>VimwikiGoHome :VimwikiGoHome<CR>

if !hasmapto('<Plug>VimwikiTabGoHome')
  map <silent><unique> <Leader>wt <Plug>VimwikiTabGoHome
endif
noremap <unique><script> <Plug>VimwikiTabGoHome :VimwikiTabGoHome<CR>

if !hasmapto('<Plug>VimwikiUISelect')
  map <silent><unique> <Leader>ws <Plug>VimwikiUISelect
endif
noremap <unique><script> <Plug>VimwikiUISelect :VimwikiUISelect<CR>

"}}}

" MENU {{{
function! s:build_menu(path)
  let idx = 0
  while idx < len(g:vimwiki_list)
    execute 'menu '.a:path.'.'.VimwikiGet('path', idx).
          \ ' :call vimwiki#WikiGoHome('.(idx + 1).')<CR>'
    let idx += 1
  endwhile
endfunction

if !empty(g:vimwiki_menu)
  call s:build_menu(g:vimwiki_menu)
endif
" }}}

let &cpo = s:old_cpo
syntax\vimwiki.vim	[[[1
132
" Vimwiki syntax file
" Author: Maxim Kim <habamax@gmail.com>
" Home: http://code.google.com/p/vimwiki/
" vim:tw=79:

" Quit if syntax file is already loaded
if version < 600
  syntax clear
elseif exists("b:current_syntax")
  finish
endif

"" use max highlighting - could be quite slow if there are too many wikifiles
if VimwikiGet('maxhi')
  " Every WikiWord is nonexistent
  execute 'syntax match wikiNoExistsWord /\%(^\|[^!]\)\zs'.g:vimwiki_word1.'/'
  execute 'syntax match wikiNoExistsWord /'.g:vimwiki_word2.'/'
  " till we find them in vimwiki's path
  call vimwiki#WikiHighlightWords()
else
  " A WikiWord (unqualifiedWikiName)
  execute 'syntax match wikiWord /\%(^\|[^!]\)\zs\<'.g:vimwiki_word1.'\>/'
  " A [[bracketed wiki word]]
  execute 'syntax match wikiWord /'.g:vimwiki_word2.'/'
endif

let g:vimwiki_rxWeblink = '\%("[^"(]\+\((\([^)]\+\))\)\?":\)\?'.
      \'\%(https\?\|ftp\|gopher\|telnet\|file\|notes\|ms-help\):'.
      \'\%(\%(\%(//\)\|\%(\\\\\)\)\+[A-Za-z0-9:#@%/;$~()_?+=.&\\\-]*\)'
execute 'syntax match wikiLink `'.g:vimwiki_rxWeblink.'`'

" Emoticons: must come after the Textilisms, as later rules take precedence
" over earlier ones. This match is an approximation for the ~70 distinct
syntax match wikiEmoticons /\%((.)\|:[()|$@]\|:-[DOPS()\]|$@]\|;)\|:'(\)/

let g:vimwiki_rxTodo = '\C\%(TODO:\|DONE:\|FIXME:\|FIXED:\|XXX:\)'
execute 'syntax match wikiTodo /'. g:vimwiki_rxTodo .'/'

" Load concrete Wiki syntax
execute 'runtime! syntax/vimwiki_'.VimwikiGet('syntax').'.vim'

" Tables
execute 'syntax match wikiTable /'.g:vimwiki_rxTable.'/'

execute 'syntax match wikiBold /'.g:vimwiki_rxBold.'/'

execute 'syntax match wikiItalic /'.g:vimwiki_rxItalic.'/'

execute 'syntax match wikiBoldItalic /'.g:vimwiki_rxBoldItalic.'/'

execute 'syntax match wikiItalicBold /'.g:vimwiki_rxItalicBold.'/'

execute 'syntax match wikiDelText /'.g:vimwiki_rxDelText.'/'

execute 'syntax match wikiSuperScript /'.g:vimwiki_rxSuperScript.'/'

execute 'syntax match wikiSubScript /'.g:vimwiki_rxSubScript.'/'

execute 'syntax match wikiCode /'.g:vimwiki_rxCode.'/'

" Aggregate all the regular text highlighting into wikiText
" syntax cluster wikiText contains=wikiItalic,wikiBold,wikiCode,
      " \wikiDelText,wikiSuperScript,wikiSubScript,wikiWord,wikiEmoticons

" <hr> horizontal rule
execute 'syntax match wikiHR /'.g:vimwiki_rxHR.'/'

" List items
execute 'syntax match wikiList /'.g:vimwiki_rxListBullet.'/'
execute 'syntax match wikiList /'.g:vimwiki_rxListNumber.'/'
execute 'syntax match wikiList /'.g:vimwiki_rxListDefine.'/'

" Treat all other lines that start with spaces as PRE-formatted text.
execute 'syntax match wikiPre /'.g:vimwiki_rxPre1.'/ contains=wikiComment'

execute 'syntax region wikiPre start=/'.g:vimwiki_rxPreStart.
      \ '/ end=/'.g:vimwiki_rxPreEnd.'/ contains=wikiComment'

" List item checkbox
syntax match wikiCheckBox /\[.\?\]/
execute 'syntax match wikiCheckBoxDone /'.g:vimwiki_rxListBullet.'\s*\[x\].*$/'
execute 'syntax match wikiCheckBoxDone /'.g:vimwiki_rxListNumber.'\s*\[x\].*$/'

syntax region wikiComment start='<!--' end='-->'

if !vimwiki#hl_exists("wikiHeader1")
  execute 'syntax match wikiHeader /'.g:vimwiki_rxHeader.'/'
else
  " Header levels, 1-6
  execute 'syntax match wikiHeader1 /'.g:vimwiki_rxH1.'/'
  execute 'syntax match wikiHeader2 /'.g:vimwiki_rxH2.'/'
  execute 'syntax match wikiHeader3 /'.g:vimwiki_rxH3.'/'
  execute 'syntax match wikiHeader4 /'.g:vimwiki_rxH4.'/'
  execute 'syntax match wikiHeader5 /'.g:vimwiki_rxH5.'/'
  execute 'syntax match wikiHeader6 /'.g:vimwiki_rxH6.'/'
endif

if !vimwiki#hl_exists("wikiHeader1")
  hi def link wikiHeader Title
else
  hi def link wikiHeader1 Title
  hi def link wikiHeader2 Title
  hi def link wikiHeader3 Title
  hi def link wikiHeader4 Title
  hi def link wikiHeader5 Title
  hi def link wikiHeader6 Title
endif

hi def wikiBold term=bold cterm=bold gui=bold
hi def wikiItalic term=italic cterm=italic gui=italic
hi def wikiBoldItalic term=bold cterm=bold gui=bold,italic
hi def link wikiItalicBold wikiBoldItalic

hi def link wikiCode PreProc
hi def link wikiWord Underlined
hi def link wikiNoExistsWord Error

hi def link wikiPre PreProc
hi def link wikiLink Underlined
hi def link wikiList Operator
hi def link wikiCheckBox wikiList
hi def link wikiCheckBoxDone Comment
hi def link wikiTable PreProc
hi def link wikiEmoticons Constant
hi def link wikiDelText Constant
hi def link wikiInsText Constant
hi def link wikiSuperScript Constant
hi def link wikiSubScript Constant
hi def link wikiTodo Todo
hi def link wikiComment Comment

let b:current_syntax="vimwiki"
syntax\vimwiki_default.vim	[[[1
80
" Vimwiki syntax file
" Default syntax
" Author: Maxim Kim <habamax@gmail.com>
" Home: http://code.google.com/p/vimwiki/
" vim:tw=78:

" text: *strong*
" let g:vimwiki_rxBold = '\*[^*]\+\*'
let g:vimwiki_rxBold = '\%(^\|\s\|[[:punct:]]\)\@<='.
      \'\*'.
      \'\([^*`[:space:]][^*`]*[^*`[:space:]]\|[^*`]\)'.
      \'\*'.
      \'\%([[:punct:]]\|\s\|$\)\@='

" text: _emphasis_
" let g:vimwiki_rxItalic = '_[^_]\+_'
let g:vimwiki_rxItalic = '\%(^\|\s\|[[:punct:]]\)\@<='.
      \'_'.
      \'\([^_`[:space:]][^_`]*[^_`[:space:]]\|[^_`]\)'.
      \'_'.
      \'\%([[:punct:]]\|\s\|$\)\@='

" text: *_bold italic_* or _*italic bold*_
let g:vimwiki_rxBoldItalic = '\%(^\|\s\|[[:punct:]]\)\@<='.
      \'\*_'.
      \'\([^*_`[:space:]][^*_`]*[^*_`[:space:]]\|[^*_`]\)'.
      \'_\*'.
      \'\%([[:punct:]]\|\s\|$\)\@='

let g:vimwiki_rxItalicBold = '\%(^\|\s\|[[:punct:]]\)\@<='.
      \'_\*'.
      \'\([^*_`[:space:]][^*_`]*[^*_`[:space:]]\|[^*_`]\)'.
      \'\*_'.
      \'\%([[:punct:]]\|\s\|$\)\@='

" text: `code`
let g:vimwiki_rxCode = '`[^`]\+`'

" text: ~~deleted text~~
let g:vimwiki_rxDelText = '\~\~[^~`]\+\~\~'

" text: ^superscript^
let g:vimwiki_rxSuperScript = '\^[^^`]\+\^'

" text: ,,subscript,,
let g:vimwiki_rxSubScript = ',,[^,`]\+,,'

" Header levels, 1-6
let g:vimwiki_rxH1 = '^\s*=\{1}[^=]\+.*[^=]\+=\{1}\s*$'
let g:vimwiki_rxH2 = '^\s*=\{2}[^=]\+.*[^=]\+=\{2}\s*$'
let g:vimwiki_rxH3 = '^\s*=\{3}[^=]\+.*[^=]\+=\{3}\s*$'
let g:vimwiki_rxH4 = '^\s*=\{4}[^=]\+.*[^=]\+=\{4}\s*$'
let g:vimwiki_rxH5 = '^\s*=\{5}[^=]\+.*[^=]\+=\{5}\s*$'
let g:vimwiki_rxH6 = '^\s*=\{6}[^=]\+.*[^=]\+=\{6}\s*$'
let g:vimwiki_rxHeader = '\%('.g:vimwiki_rxH1.'\)\|'.
      \ '\%('.g:vimwiki_rxH2.'\)\|'.
      \ '\%('.g:vimwiki_rxH3.'\)\|'.
      \ '\%('.g:vimwiki_rxH4.'\)\|'.
      \ '\%('.g:vimwiki_rxH5.'\)\|'.
      \ '\%('.g:vimwiki_rxH6.'\)'

" <hr>, horizontal rule
let g:vimwiki_rxHR = '^----.*$'

" Tables. Each line starts and ends with '||'; each cell is separated by '||'
let g:vimwiki_rxTable = '||'

" List items start with whitespace(s) then '*' or '#'
let g:vimwiki_rxListBullet = '^\s\+\*'
let g:vimwiki_rxListNumber = '^\s\+#'

let g:vimwiki_rxListDefine = '::\(\s\|$\)'


" Treat all other lines that start with spaces as PRE-formatted text.
let g:vimwiki_rxPre1 = '^\s\+[^[:blank:]*#].*$'

" Preformatted text
let g:vimwiki_rxPreStart = '{{{'
let g:vimwiki_rxPreEnd = '}}}'
syntax\vimwiki_media.vim	[[[1
61
" Vimwiki syntax file
" MediaWiki syntax
" Author: Maxim Kim <habamax@gmail.com>
" Home: http://code.google.com/p/vimwiki/
" vim:tw=78:

" text: '''strong'''
let g:vimwiki_rxBold = "'''[^']\\+'''"

" text: ''emphasis''
let g:vimwiki_rxItalic = "''[^']\\+''"

" text: '''''strong italic'''''
let g:vimwiki_rxBoldItalic = "'''''[^']\\+'''''"
let g:vimwiki_rxItalicBold = g:vimwiki_rxBoldItalic

" text: `code`
let g:vimwiki_rxCode = '`[^`]\+`'

" text: ~~deleted text~~
let g:vimwiki_rxDelText = '\~\~[^~]\+\~\~'

" text: ^superscript^
let g:vimwiki_rxSuperScript = '\^[^^]\+\^'

" text: ,,subscript,,
let g:vimwiki_rxSubScript = ',,[^,]\+,,'

" Header levels, 1-6
let g:vimwiki_rxH1 = '^\s*=\{1}[^=]\+.*[^=]\+=\{1}\s*$'
let g:vimwiki_rxH2 = '^\s*=\{2}[^=]\+.*[^=]\+=\{2}\s*$'
let g:vimwiki_rxH3 = '^\s*=\{3}[^=]\+.*[^=]\+=\{3}\s*$'
let g:vimwiki_rxH4 = '^\s*=\{4}[^=]\+.*[^=]\+=\{4}\s*$'
let g:vimwiki_rxH5 = '^\s*=\{5}[^=]\+.*[^=]\+=\{5}\s*$'
let g:vimwiki_rxH6 = '^\s*=\{6}[^=]\+.*[^=]\+=\{6}\s*$'
let g:vimwiki_rxHeader = '\%('.g:vimwiki_rxH1.'\)\|'.
      \ '\%('.g:vimwiki_rxH2.'\)\|'.
      \ '\%('.g:vimwiki_rxH3.'\)\|'.
      \ '\%('.g:vimwiki_rxH4.'\)\|'.
      \ '\%('.g:vimwiki_rxH5.'\)\|'.
      \ '\%('.g:vimwiki_rxH6.'\)'

" <hr>, horizontal rule
let g:vimwiki_rxHR = '^----.*$'

" Tables. Each line starts and ends with '||'; each cell is separated by '||'
let g:vimwiki_rxTable = '||'

" Bulleted list items start with whitespace(s), then '*'
" highlight only bullets and digits.
let g:vimwiki_rxListBullet = '^\s*\*\+\([^*]*$\)\@='
let g:vimwiki_rxListNumber = '^\s*#\+'

let g:vimwiki_rxListDefine = '^\%(;\|:\)\s'

" Treat all other lines that start with spaces as PRE-formatted text.
let g:vimwiki_rxPre1 = '^\s\+[^[:blank:]*#].*$'

" Preformatted text
let g:vimwiki_rxPreStart = '<pre>'
let g:vimwiki_rxPreEnd = '<\/pre>'
