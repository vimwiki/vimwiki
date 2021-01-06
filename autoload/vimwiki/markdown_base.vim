" vim:tabstop=2:shiftwidth=2:expandtab:textwidth=99
" Vimwiki autoload plugin file
" Description: Link functions for markdown syntax
" Home: https://github.com/vimwiki/vimwiki/


function! s:safesubstitute(text, search, replace, mode) abort
  " Substitute regexp but do not interpret replace
  let escaped = escape(a:replace, '\&')
  return substitute(a:text, a:search, escaped, a:mode)
endfunction


function! vimwiki#markdown_base#scan_reflinks() abort
  let mkd_refs = {}
  " construct list of references using vimgrep
  try
    " Why noautocmd? Because https://github.com/vimwiki/vimwiki/issues/121
    noautocmd execute 'vimgrep #'.vimwiki#vars#get_syntaxlocal('rxMkdRef').'#j %'
  catch /^Vim\%((\a\+)\)\=:E480/   " No Match
    "Ignore it, and move on to the next file
  endtry

  for d in getqflist()
    let matchline = join(getline(d.lnum, min([d.lnum+1, line('$')])), ' ')
    let descr = matchstr(matchline, vimwiki#vars#get_syntaxlocal('rxMkdRefMatchDescr'))
    let url = matchstr(matchline, vimwiki#vars#get_syntaxlocal('rxMkdRefMatchUrl'))
    if descr !=? '' && url !=? ''
      let mkd_refs[descr] = url
    endif
  endfor
  call vimwiki#vars#set_bufferlocal('markdown_refs', mkd_refs)
  return mkd_refs
endfunction


function! vimwiki#markdown_base#open_reflink(link) abort
  " try markdown reference links
  let link = a:link
  let mkd_refs = vimwiki#vars#get_bufferlocal('markdown_refs')
  if has_key(mkd_refs, link)
    let url = mkd_refs[link]
    call vimwiki#base#system_open_link(url)
    return 1
  else
    return 0
  endif
endfunction


function! s:normalize_link_syntax_n() abort
  let lnum = line('.')

  " try WikiIncl
  let lnk = vimwiki#base#matchstr_at_cursor(vimwiki#vars#get_global('rxWikiIncl'))
  if !empty(lnk)
    " NO-OP !!
    return
  endif

  " try WikiLink0: replace with WikiLink1
  let lnk = vimwiki#base#matchstr_at_cursor(vimwiki#vars#get_syntaxlocal('rxWikiLink0'))
  if !empty(lnk)
    let sub = vimwiki#base#normalize_link_helper(lnk,
          \ vimwiki#vars#get_syntaxlocal('rxWikiLinkMatchUrl'),
          \ vimwiki#vars#get_syntaxlocal('rxWikiLinkMatchDescr'),
          \ vimwiki#vars#get_syntaxlocal('WikiLink1Template2'))
    call vimwiki#base#replacestr_at_cursor(vimwiki#vars#get_syntaxlocal('rxWikiLink0'), sub)
    return
  endif

  " try WikiLink1: replace with WikiLink0
  let lnk = vimwiki#base#matchstr_at_cursor(vimwiki#vars#get_syntaxlocal('rxWikiLink1'))
  if !empty(lnk)
    let sub = vimwiki#base#normalize_link_helper(lnk,
          \ vimwiki#vars#get_syntaxlocal('rxWikiLinkMatchUrl'),
          \ vimwiki#vars#get_syntaxlocal('rxWikiLinkMatchDescr'),
          \ vimwiki#vars#get_global('WikiLinkTemplate2'))
    call vimwiki#base#replacestr_at_cursor(vimwiki#vars#get_syntaxlocal('rxWikiLink1'), sub)
    return
  endif

  " try Weblink
  let lnk = vimwiki#base#matchstr_at_cursor(vimwiki#vars#get_syntaxlocal('rxWeblink'))
  if !empty(lnk)
    let sub = vimwiki#base#normalize_link_helper(lnk,
          \ vimwiki#vars#get_syntaxlocal('rxWeblinkMatchUrl'),
          \ vimwiki#vars#get_syntaxlocal('rxWeblinkMatchDescr'),
          \ vimwiki#vars#get_syntaxlocal('Weblink1Template'))
    call vimwiki#base#replacestr_at_cursor(vimwiki#vars#get_syntaxlocal('rxWeblink'), sub)
    return
  endif

  " try Word (any characters except separators)
  " rxWord is less permissive than rxWikiLinkUrl which is used in
  " normalize_link_syntax_v
  let lnk = vimwiki#base#matchstr_at_cursor(vimwiki#vars#get_global('rxWord'))
  if !empty(lnk)
    if vimwiki#base#is_diary_file(expand('%:p'))
      let sub = vimwiki#base#normalize_link_in_diary(lnk)
    else
      let sub = vimwiki#base#normalize_link_helper(lnk,
            \ vimwiki#vars#get_global('rxWord'), '',
            \ vimwiki#vars#get_syntaxlocal('Link1'))
    endif
    call vimwiki#base#replacestr_at_cursor('\V'.lnk, sub)
    return
  endif
endfunction


function! vimwiki#markdown_base#normalize_link() abort
  " TODO mutualize with base
  call s:normalize_link_syntax_n()
endfunction
