" vim:tabstop=2:shiftwidth=2:expandtab:foldmethod=marker:textwidth=79
" Vimwiki autoload plugin file
" Desc: Link functions for markdown syntax
" Author: Stuart Andrews <stu.andrews@gmail.com> (.. i.e. don't blame Maxim!)
" Home: http://code.google.com/p/vimwiki/


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
    execute 'vimgrep #'.g:vimwiki_rxMkdRef.'#j %'
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

" s:normalize_path
" s:path_html
" vimwiki#base#apply_wiki_options
" vimwiki#base#read_wiki_options
" vimwiki#base#validate_wiki_options
" vimwiki#base#setup_buffer_state
" vimwiki#base#cache_buffer_state
" vimwiki#base#recall_buffer_state
" vimwiki#base#print_wiki_state
" vimwiki#base#mkdir
" vimwiki#base#file_pattern
" vimwiki#base#branched_pattern
" vimwiki#base#subdir
" vimwiki#base#current_subdir
" vimwiki#base#invsubdir
" vimwiki#base#resolve_scheme
" vimwiki#base#system_open_link
" vimwiki#base#open_link
" vimwiki#base#generate_links
" vimwiki#base#goto
" vimwiki#base#backlinks
" vimwiki#base#get_links
" vimwiki#base#edit_file
" vimwiki#base#search_word
" vimwiki#base#matchstr_at_cursor
" vimwiki#base#replacestr_at_cursor
" s:print_wiki_list
" s:update_wiki_link
" s:update_wiki_links_dir
" s:tail_name
" s:update_wiki_links
" s:get_wiki_buffers
" s:open_wiki_buffer
" vimwiki#base#nested_syntax
" }}}

" WIKI link following functions {{{
" vimwiki#base#find_next_link
" vimwiki#base#find_prev_link

" vimwiki#base#follow_link
function! vimwiki#markdown_base#follow_link(split, ...) "{{{ Parse link at cursor and pass
  " to VimwikiLinkHandler, or failing that, the default open_link handler
  " echom "markdown_base#follow_link"

  if 0
    " Syntax-specific links
    " XXX: @Stuart: do we still need it?
    " XXX: @Maxim: most likely!  I am still working on a seemless way to
    " integrate regexp's without complicating syntax/vimwiki.vim
  else
    if a:split == "split"
      let cmd = ":split "
    elseif a:split == "vsplit"
      let cmd = ":vsplit "
    elseif a:split == "tabnew"
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

" vimwiki#base#go_back_link
" vimwiki#base#goto_index
" vimwiki#base#delete_link
" vimwiki#base#rename_link
" vimwiki#base#ui_select

" TEXT OBJECTS functions {{{
" vimwiki#base#TO_header
" vimwiki#base#TO_table_cell
" vimwiki#base#TO_table_col
" }}}

" HEADER functions {{{
" vimwiki#base#AddHeaderLevel
" vimwiki#base#RemoveHeaderLevel
"}}}

" LINK functions {{{
" vimwiki#base#apply_template

" s:clean_url
" vimwiki#base#normalize_link_helper
" vimwiki#base#normalize_imagelink_helper

" s:normalize_link_syntax_n
function! s:normalize_link_syntax_n() " {{{
  let lnum = line('.')

  " try WikiIncl
  let lnk = vimwiki#base#matchstr_at_cursor(g:vimwiki_rxWikiIncl)
  if !empty(lnk)
    " NO-OP !!
    if g:vimwiki_debug > 1
      echomsg "WikiIncl: ".lnk." Sub: ".lnk
    endif
    return
  endif

  " try WikiLink0: replace with WikiLink1
  let lnk = vimwiki#base#matchstr_at_cursor(g:vimwiki_rxWikiLink0)
  if !empty(lnk)
    let sub = vimwiki#base#normalize_link_helper(lnk,
          \ g:vimwiki_rxWikiLinkMatchUrl, g:vimwiki_rxWikiLinkMatchDescr,
          \ g:vimwiki_WikiLink1Template2)
    call vimwiki#base#replacestr_at_cursor(g:vimwiki_rxWikiLink0, sub)
    if g:vimwiki_debug > 1
      echomsg "WikiLink: ".lnk." Sub: ".sub
    endif
    return
  endif

  " try WikiLink1: replace with WikiLink0
  let lnk = vimwiki#base#matchstr_at_cursor(g:vimwiki_rxWikiLink1)
  if !empty(lnk)
    let sub = vimwiki#base#normalize_link_helper(lnk,
          \ g:vimwiki_rxWikiLinkMatchUrl, g:vimwiki_rxWikiLinkMatchDescr,
          \ g:vimwiki_WikiLinkTemplate2)
    call vimwiki#base#replacestr_at_cursor(g:vimwiki_rxWikiLink1, sub)
    if g:vimwiki_debug > 1
      echomsg "WikiLink: ".lnk." Sub: ".sub
    endif
    return
  endif

  " try Weblink
  let lnk = vimwiki#base#matchstr_at_cursor(g:vimwiki_rxWeblink)
  if !empty(lnk)
    let sub = vimwiki#base#normalize_link_helper(lnk,
          \ g:vimwiki_rxWeblinkMatchUrl, g:vimwiki_rxWeblinkMatchDescr,
          \ g:vimwiki_Weblink1Template)
    call vimwiki#base#replacestr_at_cursor(g:vimwiki_rxWeblink, sub)
    if g:vimwiki_debug > 1
      echomsg "WebLink: ".lnk." Sub: ".sub
    endif
    return
  endif

  " try Word (any characters except separators)
  " rxWord is less permissive than rxWikiLinkUrl which is used in
  " normalize_link_syntax_v
  let lnk = vimwiki#base#matchstr_at_cursor(g:vimwiki_rxWord)
  if !empty(lnk)
    let sub = vimwiki#base#normalize_link_helper(lnk,
          \ g:vimwiki_rxWord, '',
          \ g:vimwiki_WikiLinkTemplate1)
    call vimwiki#base#replacestr_at_cursor('\V'.lnk, sub)
    if g:vimwiki_debug > 1
      echomsg "Word: ".lnk." Sub: ".sub
    endif
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
    let visual_selection = substitute(g:vimwiki_WikiLinkTemplate1, '__LinkUrl__', '\='."'".visual_selection."'", '')

    call setreg('"', visual_selection, 'v')

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

