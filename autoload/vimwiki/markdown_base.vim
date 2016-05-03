" vim:tabstop=2:shiftwidth=2:expandtab:foldmethod=marker:textwidth=79
" Vimwiki autoload plugin file
" Desc: Link functions for markdown syntax
" Home: https://github.com/vimwiki/vimwiki/


" MISC helper functions {{{

" vimwiki#markdown_base#reset_mkd_refs
function! vimwiki#markdown_base#reset_mkd_refs() "{{{
  call VimwikiClear('markdown_refs')
endfunction "}}}

" vimwiki#markdown_base#scan_reflinks
function! vimwiki#markdown_base#scan_reflinks() " {{{
  let mkd_refs = {}
  " construct list of references using vimgrep
  try
    " Why noautocmd? Because https://github.com/vimwiki/vimwiki/issues/121
    noautocmd execute 'vimgrep #'.g:vimwiki_rxMkdRef.'#j %'
  catch /^Vim\%((\a\+)\)\=:E480/   " No Match
    "Ignore it, and move on to the next file
  endtry
  " 
  for d in getqflist()
    let matchline = join(getline(d.lnum, min([d.lnum+1, line('$')])), ' ')
    let descr = matchstr(matchline, g:vimwiki_rxMkdRefMatchDescr)
    let url = matchstr(matchline, g:vimwiki_rxMkdRefMatchUrl)
    if descr != '' && url != ''
      let mkd_refs[descr] = url
    endif
  endfor
  call VimwikiSet('markdown_refs', mkd_refs)
  return mkd_refs
endfunction "}}}


" vimwiki#markdown_base#get_reflinks
function! vimwiki#markdown_base#get_reflinks() " {{{
  let done = 1
  try
    let mkd_refs = VimwikiGet('markdown_refs')
  catch
    " work-around hack
    let done = 0
    " ... the following command does not work inside catch block !?
    " > let mkd_refs = vimwiki#markdown_base#scan_reflinks()
  endtry
  if !done
    let mkd_refs = vimwiki#markdown_base#scan_reflinks()
  endif
  return mkd_refs
endfunction "}}}

" vimwiki#markdown_base#open_reflink
" try markdown reference links
function! vimwiki#markdown_base#open_reflink(link) " {{{
  " echom "vimwiki#markdown_base#open_reflink"
  let link = a:link
  let mkd_refs = vimwiki#markdown_base#get_reflinks()
  if has_key(mkd_refs, link)
    let url = mkd_refs[link]
    call vimwiki#base#system_open_link(url)
    return 1
  else
    return 0
  endif
endfunction " }}}
" }}}

" WIKI link following functions {{{

" vimwiki#markdown_base#follow_link
function! vimwiki#markdown_base#follow_link(split, ...) "{{{ Parse link at cursor and pass 
  " to VimwikiLinkHandler, or failing that, the default open_link handler
  " echom "markdown_base#follow_link"

  if 0
    " Syntax-specific links
    " XXX: @Stuart: do we still need it?
    " XXX: @Maxim: most likely!  I am still working on a seemless way to
    " integrate regexp's without complicating syntax/vimwiki.vim
  else
    if a:split ==# "split"
      let cmd = ":split "
    elseif a:split ==# "vsplit"
      let cmd = ":vsplit "
    elseif a:split ==# "tabnew"
      let cmd = ":tabnew "
    else
      let cmd = ":e "
    endif

    " try WikiLink
    let lnk = matchstr(vimwiki#base#matchstr_at_cursor(g:vimwiki_rxWikiLink),
          \ g:vimwiki_rxWikiLinkMatchUrl)
    " try WikiIncl
    if lnk == ""
      let lnk = matchstr(vimwiki#base#matchstr_at_cursor(g:vimwiki_rxWikiIncl),
          \ g:vimwiki_rxWikiInclMatchUrl)
    endif
    " try Weblink
    if lnk == ""
      let lnk = matchstr(vimwiki#base#matchstr_at_cursor(g:vimwiki_rxWeblink),
            \ g:vimwiki_rxWeblinkMatchUrl)
    endif

    if lnk != ""
      if !VimwikiLinkHandler(lnk)
        if !vimwiki#markdown_base#open_reflink(lnk)
          " remove the extension from the filename if exists
          let lnk = substitute(lnk, VimwikiGet('ext').'$', '', '')
          call vimwiki#base#open_link(cmd, lnk)
        endif
      endif
      return
    endif

    if a:0 > 0
      execute "normal! ".a:1
    else		
      call vimwiki#base#normalize_link(0)
    endif
  endif

endfunction " }}}

" LINK functions {{{

" s:normalize_link_syntax_n
function! s:normalize_link_syntax_n() " {{{
  let lnum = line('.')

  " try WikiIncl
  let lnk = vimwiki#base#matchstr_at_cursor(g:vimwiki_rxWikiIncl)
  if !empty(lnk)
    " NO-OP !!
    return
  endif

  " try WikiLink0: replace with WikiLink1
  let lnk = vimwiki#base#matchstr_at_cursor(g:vimwiki_rxWikiLink0)
  if !empty(lnk)
    let sub = vimwiki#base#normalize_link_helper(lnk,
          \ g:vimwiki_rxWikiLinkMatchUrl, g:vimwiki_rxWikiLinkMatchDescr,
          \ g:vimwiki_WikiLink1Template2)
    call vimwiki#base#replacestr_at_cursor(g:vimwiki_rxWikiLink0, sub)
    return
  endif
  
  " try WikiLink1: replace with WikiLink0
  let lnk = vimwiki#base#matchstr_at_cursor(g:vimwiki_rxWikiLink1)
  if !empty(lnk)
    let sub = vimwiki#base#normalize_link_helper(lnk,
          \ g:vimwiki_rxWikiLinkMatchUrl, g:vimwiki_rxWikiLinkMatchDescr,
          \ g:vimwiki_WikiLinkTemplate2)
    call vimwiki#base#replacestr_at_cursor(g:vimwiki_rxWikiLink1, sub)
    return
  endif
  
  " try Weblink
  let lnk = vimwiki#base#matchstr_at_cursor(g:vimwiki_rxWeblink)
  if !empty(lnk)
    let sub = vimwiki#base#normalize_link_helper(lnk,
          \ g:vimwiki_rxWeblinkMatchUrl, g:vimwiki_rxWeblinkMatchDescr,
          \ g:vimwiki_Weblink1Template)
    call vimwiki#base#replacestr_at_cursor(g:vimwiki_rxWeblink, sub)
    return
  endif

  " try Word (any characters except separators)
  " rxWord is less permissive than rxWikiLinkUrl which is used in
  " normalize_link_syntax_v
  let lnk = vimwiki#base#matchstr_at_cursor(g:vimwiki_rxWord)
  if !empty(lnk)
    let sub = vimwiki#base#normalize_link_helper(lnk,
          \ g:vimwiki_rxWord, '',
          \ g:vimwiki_Weblink1Template)
    call vimwiki#base#replacestr_at_cursor('\V'.lnk, sub)
    return
  endif

endfunction " }}}

" s:normalize_link_syntax_v
function! s:normalize_link_syntax_v() " {{{
  let lnum = line('.')
  let sel_save = &selection
  let &selection = "old"
  let rv = @"
  let rt = getregtype('"')
  let done = 0

  try
    norm! gvy
    let visual_selection = @"
    let link = substitute(g:vimwiki_Weblink1Template, '__LinkUrl__', '\='."'".visual_selection."'", '')
    let link = substitute(link, '__LinkDescription__', '\='."'".visual_selection."'", '')

    call setreg('"', link, 'v')

    " paste result
    norm! `>pgvd

  finally
    call setreg('"', rv, rt)
    let &selection = sel_save
  endtry

endfunction " }}}

" vimwiki#base#normalize_link
function! vimwiki#markdown_base#normalize_link(is_visual_mode) "{{{
  if 0
    " Syntax-specific links
  else
    if !a:is_visual_mode
      call s:normalize_link_syntax_n()
    elseif visualmode() ==# 'v' && line("'<") == line("'>")
      " action undefined for 'line-wise' or 'multi-line' visual mode selections
      call s:normalize_link_syntax_v()
    endif
  endif
endfunction "}}}

" }}}

" -------------------------------------------------------------------------
" Load syntax-specific Wiki functionality
" -------------------------------------------------------------------------

