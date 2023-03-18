" vim:tabstop=2:shiftwidth=2:expandtab:textwidth=99
" Vimwiki autoload plugin file
" Description: Tag manipulation functions
" Home: https://github.com/vimwiki/vimwiki/
"
" Tags metadata in-memory format:
" metadata := { 'pagename': [entries, ...] }
" entry := { 'tagname':..., 'lineno':..., 'link':... }

" Tags metadata in-file format:
"
" Is based on CTags format (see |tags-file-format|) and
" https://ctags.sourceforge.net/FORMAT
"
" {tagaddress} is set to lineno.  We'll let vim search by exact line number; we
" can afford that, we assume metadata file is always updated before use.
"
" Pagename and link are not saved in standard ctags fields, so we'll add
" an optional field, "vimwiki:".  In this field, we encode tab-separated values
" of missing parameters -- "pagename" and "link".


let s:TAGS_METADATA_FILE_NAME = '.vimwiki_tags'


function! vimwiki#tags#update_tags(full_rebuild, all_files) abort
  " Update tags metadata.
  " Param: a:full_rebuild == 1: re-scan entire wiki
  " Param: a:full_rebuild == 0: only re-scan current page
  " a:all_files == '':   only if the file is newer than .tags
  let all_files = a:all_files !=? ''
  if !a:full_rebuild
    " Updating for one page (current)
    let page_name = vimwiki#vars#get_bufferlocal('subdir') . expand('%:t:r')
    " Collect tags in current file
    let tags = s:scan_tags(getline(1, '$'), page_name)
    " Load metadata file
    let metadata = s:load_tags_metadata()
    " Drop old tags
    let metadata = s:remove_page_from_tags(metadata, page_name)
    " Merge in the new ones
    let metadata = s:merge_tags(metadata, page_name, tags)
    " Save
    call s:write_tags_metadata(metadata)
  else " full rebuild
    let files = vimwiki#base#find_files(vimwiki#vars#get_bufferlocal('wiki_nr'), 0)
    let wiki_base_dir = vimwiki#vars#get_wikilocal('path')
    let tags_file_last_modification = getftime(vimwiki#tags#metadata_file_path())
    let metadata = s:load_tags_metadata()
    for file in files
      if all_files || getftime(file) >= tags_file_last_modification
        let subdir = vimwiki#base#subdir(wiki_base_dir, file)
        let page_name = subdir . fnamemodify(file, ':t:r')
        let tags = s:scan_tags(readfile(file), page_name)
        let metadata = s:remove_page_from_tags(metadata, page_name)
        let metadata = s:merge_tags(metadata, page_name, tags)
      endif
    endfor
    call s:write_tags_metadata(metadata)
  endif
endfunction


function! s:safesubstitute(text, search, replace, mode) abort
  " Substitute regexp but do not interpret replace
  " TODO mutualize with same function in base
  let escaped = escape(a:replace, '\&')
  return substitute(a:text, a:search, escaped, a:mode)
endfunction


function! s:scan_tags(lines, page_name) abort
  " Scan the list of text lines (argument) and produces tags metadata as a list of tag entries.
  " Code wireframe to scan for headers -- borrowed from
  " vimwiki#base#get_anchors(), with minor modifications.

  let entries = []

  " Get syntax wide regex
  let rxheader = vimwiki#vars#get_syntaxlocal('header_search')
  let tag_search_rx = vimwiki#vars#get_syntaxlocal('tag_search')
  let tag_format = vimwiki#vars#get_syntaxlocal('tag_format')

  let anchor_level = ['', '', '', '', '', '', '']
  let current_complete_anchor = ''

  let PROXIMITY_LINES_NR = 2
  let header_line_nr = - (2 * PROXIMITY_LINES_NR)

  for line_nr in range(1, len(a:lines))
    let line = a:lines[line_nr - 1]

    " ignore verbatim blocks
    if vimwiki#u#is_codeblock(line_nr)
      continue
    endif

    " process headers
    let h_match = matchlist(line, rxheader)
    if !empty(h_match) " got a header
      let header_line_nr = line_nr
      let header = vimwiki#base#normalize_anchor(h_match[2])
      let current_header_description = vimwiki#u#trim(h_match[2])
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
          if anchor_level[l] !=? ''
            let current_complete_anchor .= anchor_level[l].'#'
          endif
        endfor
        let current_complete_anchor .= header
      endif
      " See: issue #1316 to allow tags in header
      " continue " tags are not allowed in headers
    endif

    " Scan line for tags.  There can be many of them.
    let str = line
    while 1
      " Get all matches
      let tag_groups = []
      call substitute(str, tag_search_rx, '\=add(tag_groups, submatch(0))', 'g')
      if tag_groups == []
        break
      endif
      let tagend = matchend(str, tag_search_rx)
      let str = str[(tagend):]
      for tag_group in tag_groups
        for tag in split(tag_group, tag_format.sep)
          " Create metadata entry
          let entry = {}
          let entry.tagname  = tag
          let entry.lineno   = line_nr
          if line_nr <= PROXIMITY_LINES_NR && header_line_nr < 0
            " Tag appeared at the top of the file
            let entry.link   = a:page_name
            let entry.description = entry.link
          elseif line_nr <= (header_line_nr + PROXIMITY_LINES_NR)
            " Tag appeared right below a header
            let entry.link   = a:page_name . '#' . current_complete_anchor
            let entry.description = current_header_description
          else
            " Tag stands on its own
            let entry.link   = a:page_name . '#' . tag
            let entry.description = entry.link
          endif
          call add(entries, entry)
        endfor
      endfor
    endwhile

  endfor " loop over lines
  return entries
endfunction


function! vimwiki#tags#metadata_file_path() abort
  " Return: tags metadata file path
  return fnamemodify(vimwiki#path#join_path(vimwiki#vars#get_wikilocal('path'),
        \ s:TAGS_METADATA_FILE_NAME), ':p')
endfunction


function! s:load_tags_metadata() abort
  " Load tags metadata from file, returns a dictionary
  let metadata_path = vimwiki#tags#metadata_file_path()
  if !filereadable(metadata_path)
    return {}
  endif
  let metadata = {}
  for line in readfile(metadata_path)
    if line =~# '^!_TAG_.*$'
      continue
    endif
    let parts = matchlist(line, '^\(.\{-}\);"\(.*\)$')
    if parts[0] ==? '' || parts[1] ==? '' || parts[2] ==? ''
      throw 'VimwikiTags1: Metadata file corrupted'
    endif
    let std_fields = split(parts[1], '\t')
    if len(std_fields) != 3
      throw 'VimwikiTags2: Metadata file corrupted'
    endif
    let vw_part = parts[2]
    if vw_part[0] !=? "\t"
      throw 'VimwikiTags3: Metadata file corrupted'
    endif
    let vw_fields = split(vw_part[1:], "\t")
    if len(vw_fields) != 1 || vw_fields[0] !~# '^vimwiki:'
      throw 'VimwikiTags4: Metadata file corrupted'
    endif
    let vw_data = substitute(vw_fields[0], '^vimwiki:', '', '')
    let vw_data = substitute(vw_data, '\\n', "\n", 'g')
    let vw_data = substitute(vw_data, '\\r', "\r", 'g')
    let vw_data = substitute(vw_data, '\\t', "\t", 'g')
    let vw_data = substitute(vw_data, '\\\\', "\\", 'g')
    let vw_fields = split(vw_data, "\t")
    if len(vw_fields) != 3
      throw 'VimwikiTags5: Metadata file corrupted'
    endif
    let pagename = vw_fields[0]
    let entry = {}
    let entry.tagname  = std_fields[0]
    let entry.lineno   = std_fields[2]
    let entry.link     = vw_fields[1]
    let entry.description = vw_fields[2]
    if has_key(metadata, pagename)
      call add(metadata[pagename], entry)
    else
      let metadata[pagename] = [entry]
    endif
  endfor
  return metadata
endfunction


function! s:remove_page_from_tags(metadata, page_name) abort
  " Remove all entries for given page from metadata in-place.  Returns updated
  " metadata (just in case).
  if has_key(a:metadata, a:page_name)
    call remove(a:metadata, a:page_name)
    return a:metadata
  else
    return a:metadata
  endif
endfunction


function! s:merge_tags(metadata, pagename, file_metadata) abort
  " Merge metadata of one file into a:metadata
  let metadata = a:metadata
  let metadata[a:pagename] = a:file_metadata
  return metadata
endfunction


function! s:tags_entry_cmp(i1, i2) abort
  " Compare two actual lines from tags file.  Return value is in strcmp style.
  " See help on sort() -- that's what this function is going to be used for.
  " See also s:write_tags_metadata below -- that's where we compose these tags
  " file lines.
  "
  " This function is needed for tags sorting, since plain sort() compares line
  " numbers as strings, not integers, and so, for example, tag at line 14
  " precedes the same tags on the same page at line 9.  (Because string "14" is
  " alphabetically 'less than' string "9".)
  let items = []
  for orig_item in [a:i1, a:i2]
    let fields = split(orig_item, "\t")
    let item = {}
    let item.text = fields[0]."\t".fields[1]
    let item.lineno = 0 + matchstr(fields[2], '\m\d\+')
    call add(items, item)
  endfor
  if items[0].text ># items[1].text
    return 1
  elseif items[0].text <# items[1].text
    return -1
  elseif items[0].lineno > items[1].lineno
    return 1
  elseif items[0].lineno < items[1].lineno
    return -1
  else
    return 0
  endif
endfunction


function! s:write_tags_metadata(metadata) abort
  " Save metadata object into a file. Throws exceptions in case of problems.
  let metadata_path = vimwiki#tags#metadata_file_path()
  let tags = []
  for pagename in keys(a:metadata)
    for entry in a:metadata[pagename]
      let entry_data = pagename . "\t" . entry.link . "\t" . entry.description
      let entry_data = substitute(entry_data, "\\", '\\\\', 'g')
      let entry_data = substitute(entry_data, "\t", '\\t', 'g')
      let entry_data = substitute(entry_data, "\r", '\\r', 'g')
      let entry_data = substitute(entry_data, "\n", '\\n', 'g')
      call add(tags,
            \   entry.tagname  . "\t"
            \ . pagename . vimwiki#vars#get_wikilocal('ext') . "\t"
            \ . entry.lineno
            \ . ';"'
            \ . "\t" . 'vimwiki:' . entry_data
            \)
    endfor
  endfor
  call sort(tags, 's:tags_entry_cmp')
  let tag_comments = [
    \ "!_TAG_PROGRAM_VERSION\t" . g:vimwiki_version,
    \ "!_TAG_PROGRAM_URL\thttps://github.com/vimwiki/vimwiki",
    \ "!_TAG_PROGRAM_NAME\tVimwiki Tags",
    \ "!_TAG_PROGRAM_AUTHOR\tVimwiki",
    \ "!_TAG_OUTPUT_MODE\tvimwiki-tags",
    \ "!_TAG_FILE_SORTED\t1",
    \ "!_TAG_FILE_FORMAT\t2",
    \ ]
  for c in tag_comments
    call insert(tags, c)
  endfor
  call writefile(tags, metadata_path)
endfunction


function! vimwiki#tags#get_tags() abort
  " Return: list of unique tags found in the .tags file
  let metadata = s:load_tags_metadata()
  let tags = {}
  for entries in values(metadata)
    for entry in entries
      let tags[entry.tagname] = 1
    endfor
  endfor
  return keys(tags)
endfunction


function! vimwiki#tags#generate_tags(create, ...) abort
  " Generate tags in current buffer
  " Similar to vimwiki#base#generate_links.  In the current buffer, appends
  " tags and references to all their instances.  If no arguments (tags) are
  " specified, outputs all tags.
  let header_level = vimwiki#vars#get_global('tags_header_level')
  let tags_header_text = vimwiki#vars#get_global('tags_header')

  " If tag headers should only be updated, search for already present tag headers
  if !a:create
    let headers = vimwiki#base#collect_headers()
    let specific_tags = []
    let inside_tag_headers = 0
    for header in headers
      " If we ran out of the headers containing the tags, stop
      if inside_tag_headers && header[1] <= header_level
        break
      endif

      " All headers in the tag headers section correspond to tag names. Collect all of them in a list.
      if inside_tag_headers
        call add(specific_tags, header[2])
      endif

      " If we found the start of the tag headers section, remember that the following headers are now inside of it
      if header[1] == header_level && header[2] ==# tags_header_text
        let inside_tag_headers = 1
      endif
    endfor
  else
    let specific_tags = a:000
  endif

  " use a dictionary function for closure like capability
  " copy all local variables into dict (add a: if arguments are needed)
  let GeneratorTags = copy(l:)
  function! GeneratorTags.f() abort
    let need_all_tags = empty(self.specific_tags)
    let metadata = s:load_tags_metadata()

    " make a dictionary { tag_name: [tag_links, ...] }
    let tags_entries = {}
    for entries in values(metadata)
      for entry in entries
        if has_key(tags_entries, entry.tagname)
          call add(tags_entries[entry.tagname], [entry.link, entry.description])
        else
          let tags_entries[entry.tagname] = [[entry.link, entry.description]]
        endif
      endfor
      unlet entry " needed for older vims with sticky type checking since name is reused
    endfor

    let lines = []
    let bullet = repeat(' ', vimwiki#lst#get_list_margin()).vimwiki#lst#default_symbol().' '
    let current_dir = vimwiki#base#current_subdir()
    for tagname in sort(keys(tags_entries))
      if need_all_tags || index(self.specific_tags, tagname) != -1
        if len(lines) > 0
          call add(lines, '')
        endif

        let tag_tpl = printf('rxH%d_Template', self.header_level + 1)
        call add(lines, s:safesubstitute(vimwiki#vars#get_syntaxlocal(tag_tpl), '__Header__', tagname, ''))

        if vimwiki#vars#get_wikilocal('syntax') ==# 'markdown'
          for _ in range(vimwiki#vars#get_global('markdown_header_style'))
            call add(lines, '')
          endfor
        endif

        for [taglink, tagdescription] in sort(tags_entries[tagname])
          let taglink = vimwiki#path#relpath(current_dir, taglink)
          if vimwiki#vars#get_wikilocal('syntax') ==# 'markdown'
            let link_tpl = vimwiki#vars#get_syntaxlocal('Weblink3Template')
            let link_infos = vimwiki#base#resolve_link(taglink)
            if empty(link_infos.anchor)
              let link_tpl = vimwiki#vars#get_syntaxlocal('Link1')
              let entry = s:safesubstitute(link_tpl, '__LinkUrl__', taglink, '')
              let entry = s:safesubstitute(entry, '__LinkDescription__', tagdescription, '')
              let file_extension = vimwiki#vars#get_wikilocal('ext', vimwiki#vars#get_bufferlocal('wiki_nr'))
              let entry = s:safesubstitute(entry, '__FileExtension__', file_extension , '')
            else
              let link_caption = split(tagdescription, '#', 0)[-1]
              let link_text = split(taglink, '#', 1)[0]
              let entry = s:safesubstitute(link_tpl, '__LinkUrl__', link_text, '')
              let entry = s:safesubstitute(entry, '__LinkAnchor__', link_infos.anchor, '')
              let entry = s:safesubstitute(entry, '__LinkDescription__', link_caption, '')
              let file_extension = vimwiki#vars#get_wikilocal('ext', vimwiki#vars#get_bufferlocal('wiki_nr'))
              let entry = s:safesubstitute(entry, '__FileExtension__', file_extension , '')
            endif

            call add(lines, bullet . entry)
          else
            let link_tpl = vimwiki#vars#get_global('WikiLinkTemplate1')
            let file_extension = vimwiki#vars#get_wikilocal('ext', vimwiki#vars#get_bufferlocal('wiki_nr'))
            let link_tpl = s:safesubstitute(link_tpl, '__FileExtension__', file_extension , '')
            call add(lines, bullet . substitute(link_tpl, '__LinkUrl__', taglink, ''))
          endif
        endfor
      endif
    endfor

    return lines
  endfunction

  let tag_match = printf('rxH%d', header_level + 1)
  let links_rx = '^\%('.vimwiki#vars#get_syntaxlocal(tag_match).'\)\|'.
        \ '\%(^\s*$\)\|^\s*\%('.vimwiki#vars#get_syntaxlocal('rxListBullet').'\)'

  call vimwiki#base#update_listing_in_buffer(
        \ GeneratorTags,
        \ tags_header_text,
        \ links_rx,
        \ line('$')+1,
        \ header_level,
        \ a:create)
endfunction


function! vimwiki#tags#complete_tags(ArgLead, CmdLine, CursorPos) abort
  " Complete tags
  " We can safely ignore args if we use -custom=complete option, Vim engine
  " will do the job of filtering.
  let taglist = vimwiki#tags#get_tags()
  return join(taglist, "\n")
endfunction


function! vimwiki#tags#search_tags(tag_pattern) abort
  " See #1316 and rxTags in vars.vim
  let tf = vimwiki#vars#get_syntaxlocal('tag_format')

  " Craft regex
  let rx_this_tag = '/'
  let rx_this_tag .= tf.pre . '\@<=' . tf.pre_mark
  let rx_this_tag .= '\%(' . tf.in . tf.sep . '\)*'
  let rx_this_tag .= a:tag_pattern
  let rx_this_tag .= '\%(' . tf.sep . tf.in . '\)*'
  let rx_this_tag .= tf.post_mark . tf.post . '\@='
  let rx_this_tag .= '/'

  " Search in current wiki folder
  return vimwiki#base#search(rx_this_tag)
endfunction
