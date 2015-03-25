" vim:tabstop=2:shiftwidth=2:expandtab:foldmethod=marker:textwidth=79
" Vimwiki autoload plugin file


let s:TAGS_METADATA_FILE_NAME = '.tags'

" Tags metadata in-memory format:
" metadata := [ entry, ... ]
" entry := { 'tagname':..., 'pagename':..., 'lineno':..., 'link':... }

" Tags metadata in-file format:
"
" Is based on CTags format (see |tags-file-format|).
"
" {tagaddress} is set to lineno.  We'll let vim search by exact line number; we
" can afford that, we assume metadata file is always updated before use.
"
" Pagename and link are not saved in standard ctags fields, so we'll add
" an optional field, "vimwiki:".  In this field, we encode tab-separated values
" of missing parameters -- "pagename" and "link".

" vimwiki#tags#update_tags
"   Update tags metadata.
"   a:full_rebuild == 1: re-scan entire wiki
"   a:full_rebuild == 0: only re-scan current page
function! vimwiki#tags#update_tags(full_rebuild) "{{{
  if !a:full_rebuild
    " Updating for one page (current)
    let page_name = VimwikiGet('subdir') . expand('%:t:r')
    " Collect tags in current file
    let tags = s:scan_tags(getline(1, '$'), page_name)
    " Load metadata file
    let metadata = vimwiki#tags#load_tags_metadata()
    " Drop old tags
    let metadata = s:remove_page_from_tags(metadata, page_name)
    " Merge in the new ones
    let metadata = s:merge_tags(metadata, tags)
    " Save
    call s:write_tags_metadata(metadata)
  else " full rebuild
    let files = vimwiki#base#find_files(g:vimwiki_current_idx, 0)
    let metadata = []
    for file in files
      let page_name = fnamemodify(file, ':t:r')
      let tags = s:scan_tags(readfile(file), page_name)
      let metadata = s:merge_tags(metadata, tags)
    endfor
    call s:write_tags_metadata(metadata)
  endif
endfunction " }}}

" s:scan_tags
"   Scans the list of text lines (argument) and produces tags metadata.
function! s:scan_tags(lines, page_name) "{{{

  let metadata = []
  let page_name = a:page_name

  " Code wireframe to scan for headers -- borrowed from
  " vimwiki#base#get_anchors(), with minor modifications.

  let rxheader = g:vimwiki_{VimwikiGet('syntax')}_header_search
  let rxtag = g:vimwiki_{VimwikiGet('syntax')}_tag_search

  let anchor_level = ['', '', '', '', '', '', '']
  let current_complete_anchor = ''

  let PROXIMITY_LINES_NR = 5
  let header_line_nr = - (2 * PROXIMITY_LINES_NR)

  for line_nr in range(1, len(a:lines))
    let line = a:lines[line_nr - 1]

    " process headers
    let h_match = matchlist(line, rxheader)
    if !empty(h_match) " got a header
      let header_line_nr = line_nr
      let header = vimwiki#u#trim(h_match[2])
      let level = len(h_match[1])
      let anchor_level[level-1] = header
      for l in range(level, 6)
        let anchor_level[l] = ''
      endfor
      if level == 1
        let current_complete_anchor = header
      else
        let current_complete_anchor = ''
        for l in range(level-1)
          if anchor_level[l] != ''
            let current_complete_anchor .= anchor_level[l].'#'
          endif
        endfor
        let current_complete_anchor .= header
      endif
      continue " tags are not allowed in headers
    endif

    " TODO ignore verbatim blocks

    " Scan line for tags.  There can be many of them.
    let str = line
    while 1
      let tag_group = matchstr(str, rxtag)
      if tag_group == ''
        break
      endif
      let tagend = matchend(str, rxtag)
      let str = str[(tagend):]
      for tag in split(tag_group, ':')
        " Create metadata entry
        let entry = {}
        let entry.tagname  = tag
        let entry.pagename = page_name
        let entry.lineno   = line_nr
        if line_nr <= (header_line_nr + PROXIMITY_LINES_NR)
          let entry.link   = page_name . '#' . current_complete_anchor
        elseif header_line_nr < 0
          " Tag appeared before the first header
          let entry.link   = page_name
        else
          let entry.link   = page_name . '#' . tag
        endif
        call add(metadata, entry)
      endfor
    endwhile

  endfor " loop over lines
  return metadata
endfunction " }}}

" s:metadata_file_path
"   Returns tags metadata file path
function! s:metadata_file_path() abort "{{{
  return fnamemodify(VimwikiGet('path') . '/' . s:TAGS_METADATA_FILE_NAME, ':p')
endfunction " }}}

" vimwiki#tags#load_tags_metadata
"   Loads tags metadata from file, returns a dictionary
function! vimwiki#tags#load_tags_metadata() abort "{{{
  let metadata_path = s:metadata_file_path()
  if !filereadable(metadata_path)
    return []
  endif
  let metadata = []
  for line in readfile(metadata_path)
    if line =~ '^!_TAG_FILE_'
      continue
    endif
    let parts = matchlist(line, '^\(.\{-}\);"\(.*\)$')
    if parts[0] == '' || parts[1] == '' || parts[2] == ''
      throw 'VimwikiTags1: Metadata file corrupted'
    endif
    let std_fields = split(parts[1], '\t')
    if len(std_fields) != 3
      throw 'VimwikiTags2: Metadata file corrupted'
    endif
    let vw_part = parts[2]
    if vw_part[0] != "\t"
      throw 'VimwikiTags3: Metadata file corrupted'
    endif
    let vw_fields = split(vw_part[1:], "\t")
    if len(vw_fields) != 1 || vw_fields[0] !~ '^vimwiki:'
      throw 'VimwikiTags4: Metadata file corrupted'
    endif
    let vw_data = substitute(vw_fields[0], '^vimwiki:', '', '')
    let vw_data = substitute(vw_data, '\\n', "\n", 'g')
    let vw_data = substitute(vw_data, '\\r', "\r", 'g')
    let vw_data = substitute(vw_data, '\\t', "\t", 'g')
    let vw_data = substitute(vw_data, '\\\\', "\\", 'g')
    let vw_fields = split(vw_data, "\t")
    if len(vw_fields) != 2
      throw 'VimwikiTags5: Metadata file corrupted'
    endif
    let entry = {}
    let entry.tagname  = std_fields[0]
    let entry.pagename = vw_fields[0]
    let entry.lineno   = std_fields[2]
    let entry.link     = vw_fields[1]
    call add(metadata, entry)
  endfor
  return metadata
endfunction " }}}

" s:remove_page_from_tags
"   Removes all entries for given page from metadata in-place.  Returns updated
"   metadata (just in case).
function! s:remove_page_from_tags(metadata, page_name) "{{{
  let metadata = filter(a:metadata,
        \ "v:val.pagename != '" . substitute(a:page_name, "'", "''", '') . "'")
  return metadata
endfunction " }}}

" s:merge_tags
"   Merges two tags metadata objects into (new) one.
function! s:merge_tags(metadata1, metadata2) "{{{
  return a:metadata1 + a:metadata2
endfunction " }}}

" s:write_tags_metadata
"   Saves metadata object into a file. Throws exceptions in case of problems.
function! s:write_tags_metadata(metadata) "{{{
  let metadata_path = s:metadata_file_path()
  let entries = []
  for entry in a:metadata
    let entry_data = entry.pagename . "\t" . entry.link
    let entry_data = substitute(entry_data, "\\", '\\\\', 'g')
    let entry_data = substitute(entry_data, "\t", '\\t', 'g')
    let entry_data = substitute(entry_data, "\r", '\\r', 'g')
    let entry_data = substitute(entry_data, "\n", '\\n', 'g')
    call add(entries,
          \   entry.tagname  . "\t"
          \ . entry.pagename . VimwikiGet('ext') . "\t"
          \ . entry.lineno
          \ . ';"'
          \ . "\t" . "vimwiki:" . entry_data
          \)
  endfor
  call sort(entries)
  call insert(entries, "!_TAG_FILE_SORTED\t1\t{anything}")
  call writefile(entries, metadata_path)
endfunction " }}}

" vimwiki#tags#get_tags
"   Returns list of unique tags found in metadata
function! vimwiki#tags#get_tags(metadata) "{{{
  let tags = {}
  for entry in a:metadata
    let tags[entry.tagname] = 1
  endfor
  return keys(tags)
endfunction " }}}

" vimwiki#tags#generate_tags
"   Similar to vimwiki#base#generate_links.  In the current buffer, appends
"   tags and references to all their instances.  If no arguments (tags) are
"   specified, outputs all tags.
function! vimwiki#tags#generate_tags(...) abort "{{{
  let need_all_tags = (a:0 == 0)
  let specific_tags = a:000

  let metadata = vimwiki#tags#load_tags_metadata()

  call append(line('$'), [
        \ '',
        \ substitute(g:vimwiki_rxH1_Template, '__Header__', 'Generated Tags', '') ])

  call sort(metadata)

  let bullet = repeat(' ', vimwiki#lst#get_list_margin()).
        \ vimwiki#lst#default_symbol().' '
  let current_tag = ''
  for entry in metadata
    if need_all_tags || index(specific_tags, entry.tagname) != -1
      if entry.tagname != current_tag
        let current_tag = entry.tagname
        call append(line('$'), [
              \ '',
              \ substitute(g:vimwiki_rxH2_Template, '__Header__', entry.tagname, ''),
              \ '' ])
      endif
      call append(line('$'), bullet . '[[' . entry.link . ']]')
    endif
  endfor
endfunction " }}}

" vimwiki#tags#complete_tags
function! vimwiki#tags#complete_tags(ArgLead, CmdLine, CursorPos) abort " {{{
  " We can safely ignore args if we use -custom=complete option, Vim engine
  " will do the job of filtering.
  let metadata = vimwiki#tags#load_tags_metadata()
  let taglist = vimwiki#tags#get_tags(metadata)
  return join(taglist, "\n")
endfunction " }}}

