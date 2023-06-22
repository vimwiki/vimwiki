" vim:tabstop=2:shiftwidth=2:expandtab:textwidth=99
" Vimwiki autoload plugin file
" Description: HTML export
" Home: https://github.com/vimwiki/vimwiki/


if exists('g:loaded_vimwiki_html_auto') || &compatible
  finish
endif
let g:loaded_vimwiki_html_auto = 1

" FIXME: Magics: Why not use the current syntax highlight
" This is due to historical copy paste and laziness of markdown user
" text: *strong*
" let s:default_syntax.rxBold = '\*[^*]\+\*'
let s:rxBold = '\%(^\|\s\|[[:punct:]]\)\@<='.
      \'\*'.
      \'\%([^*`[:space:]][^*`]*[^*`[:space:]]\|[^*`[:space:]]\)'.
      \'\*'.
      \'\%([[:punct:]]\|\s\|$\)\@='

" text: _emphasis_ or *emphasis*
let s:rxItalic = '\%(^\|\s\|[[:punct:]]\)\@<='.
      \'_'.
      \'\%([^_`[:space:]][^_`]*[^_`[:space:]]\|[^_`[:space:]]\)'.
      \'_'.
      \'\%([[:punct:]]\|\s\|$\)\@='


" text: $ equation_inline $
let s:rxEqIn = '\$[^$`]\+\$'

" text: `code`
let s:rxCode = '`[^`]\+`'

" text: ~~deleted text~~
let s:rxDelText = '\~\~[^~`]\+\~\~'

" text: ^superscript^
let s:rxSuperScript = '\^[^^`]\+\^'

" text: ,,subscript,,
let s:rxSubScript = ',,[^,`]\+,,'


function! s:root_path(subdir) abort
  return repeat('../', len(split(a:subdir, '[/\\]')))
endfunction


function! s:syntax_supported() abort
  return vimwiki#vars#get_wikilocal('syntax') ==? 'default'
endfunction


function! s:remove_blank_lines(lines) abort
  while !empty(a:lines) && a:lines[-1] =~# '^\s*$'
    call remove(a:lines, -1)
  endwhile
endfunction


function! s:is_web_link(lnk) abort
  if a:lnk =~# '^\%(https://\|http://\|www.\|ftp://\|file://\|mailto:\)'
    return 1
  endif
  return 0
endfunction


function! s:is_img_link(lnk) abort
  if tolower(a:lnk) =~# '\.\%(png\|jpg\|gif\|jpeg\)$'
    return 1
  endif
  return 0
endfunction


function! s:has_abs_path(fname) abort
  if a:fname =~# '\(^.:\)\|\(^/\)'
    return 1
  endif
  return 0
endfunction


function! s:find_autoload_file(name) abort
  for path in split(&runtimepath, ',')
    let fname = path.'/autoload/vimwiki/'.a:name
    let match = glob(fname)
    if match !=? ''
      return match
    endif
  endfor
  return ''
endfunction


function! s:default_CSS_full_name(path) abort
  let path = expand(a:path)
  let css_full_name = path . vimwiki#vars#get_wikilocal('css_name')
  return css_full_name
endfunction


function! s:create_default_CSS(path) abort
  let css_full_name = s:default_CSS_full_name(a:path)
  if glob(css_full_name) ==? ''
    call vimwiki#path#mkdir(fnamemodify(css_full_name, ':p:h'))
    let default_css = s:find_autoload_file('style.css')
    if default_css !=? ''
      let lines = readfile(default_css)
      call writefile(lines, css_full_name)
      return 1
    endif
  endif
  return 0
endfunction


function! s:template_full_name(name) abort
  let name = a:name
  if name ==? ''
    let name = vimwiki#vars#get_wikilocal('template_default')
  endif

  " Suffix Path by a / is not
  let path = vimwiki#vars#get_wikilocal('template_path')
  if strridx(path, '/') +1 != len(path)
    let path .= '/'
  endif

  let ext = vimwiki#vars#get_wikilocal('template_ext')

  let fname = expand(path . name . ext)

  if filereadable(fname)
    return fname
  else
    return ''
  endif
endfunction


function! s:get_html_template(template) abort
  " TODO: refactor it!!!
  let lines=[]

  if a:template !=? ''
    let template_name = s:template_full_name(a:template)
    try
      let lines = readfile(template_name)
      return lines
    catch /E484/
      call vimwiki#u#echo('HTML template '.template_name. ' does not exist!')
    endtry
  endif

  let default_tpl = s:template_full_name('')

  if default_tpl ==? ''
    let default_tpl = s:find_autoload_file('default.tpl')
  endif

  let lines = readfile(default_tpl)
  return lines
endfunction


function! s:safe_html_preformatted(line) abort
  let line = substitute(a:line,'<','\&lt;', 'g')
  let line = substitute(line,'>','\&gt;', 'g')
  return line
endfunction


function! s:escape_html_attribute(string) abort
  return substitute(a:string, '"', '\&quot;', 'g')
endfunction


function! s:safe_html_line(line) abort
  " escape & < > when producing HTML text
  " s:lt_pattern, s:gt_pattern depend on g:vimwiki_valid_html_tags
  " and are set in vimwiki#html#Wiki2HTML()
  let line = substitute(a:line, '&', '\&amp;', 'g')
  let line = substitute(line,s:lt_pattern,'\&lt;', 'g')
  let line = substitute(line,s:gt_pattern,'\&gt;', 'g')

  return line
endfunction


function! s:delete_html_files(path) abort
  let htmlfiles = split(glob(a:path.'**/*.html'), '\n')
  for fname in htmlfiles
    " ignore user html files, e.g. search.html,404.html
    if stridx(vimwiki#vars#get_global('user_htmls'), fnamemodify(fname, ':t')) >= 0
      continue
    endif

    " delete if there is no corresponding wiki file
    let subdir = vimwiki#base#subdir(vimwiki#vars#get_wikilocal('path_html'), fname)
    let wikifile = vimwiki#vars#get_wikilocal('path').subdir.
          \fnamemodify(fname, ':t:r').vimwiki#vars#get_wikilocal('ext')
    if filereadable(wikifile)
      continue
    endif

    try
      call delete(fname)
    catch
      call vimwiki#u#error('Cannot delete '.fname)
    endtry
  endfor
endfunction


function! s:mid(value, cnt) abort
  return strpart(a:value, a:cnt, len(a:value) - 2 * a:cnt)
endfunction


function! s:subst_func(line, regexp, func, ...) abort
  " Substitute text found by regexp with result of
  " func(matched) function.

  let pos = 0
  let lines = split(a:line, a:regexp, 1)
  let res_line = ''
  for line in lines
    let res_line = res_line.line
    let matched = matchstr(a:line, a:regexp, pos)
    if matched !=? ''
      if a:0
        let res_line = res_line.{a:func}(matched, a:1)
      else
        let res_line = res_line.{a:func}(matched)
      endif
    endif
    let pos = matchend(a:line, a:regexp, pos)
  endfor
  return res_line
endfunction


function! s:process_date(placeholders, default_date) abort
  if !empty(a:placeholders)
    for [placeholder, row, idx] in a:placeholders
      let [type, param] = placeholder
      if type ==# 'date' && !empty(param)
        return param
      endif
    endfor
  endif
  return a:default_date
endfunction


function! s:process_title(placeholders, default_title) abort
  if !empty(a:placeholders)
    for [placeholder, row, idx] in a:placeholders
      let [type, param] = placeholder
      if type ==# 'title' && !empty(param)
        return param
      endif
    endfor
  endif
  return a:default_title
endfunction


function! s:is_html_uptodate(wikifile) abort
  let tpl_time = -1

  let tpl_file = s:template_full_name('')
  if tpl_file !=? ''
    let tpl_time = getftime(tpl_file)
  endif

  let wikifile = fnamemodify(a:wikifile, ':p')

  if vimwiki#vars#get_wikilocal('html_filename_parameterization')
    let parameterized_wikiname = s:parameterized_wikiname(wikifile)
    let htmlfile = expand(vimwiki#vars#get_wikilocal('path_html') .
          \ vimwiki#vars#get_bufferlocal('subdir') . parameterized_wikiname)
  else
    let htmlfile = expand(vimwiki#vars#get_wikilocal('path_html') .
          \ vimwiki#vars#get_bufferlocal('subdir') . fnamemodify(wikifile, ':t:r').'.html')
  endif

  if getftime(wikifile) <= getftime(htmlfile) && tpl_time <= getftime(htmlfile)
    return 1
  endif
  return 0
endfunction

function! s:parameterized_wikiname(wikifile) abort
  let initial = fnamemodify(a:wikifile, ':t:r')
  let lower_sanitized = tolower(initial)
  let substituted = substitute(lower_sanitized, '[^a-z0-9_-]\+','-', 'g')
  let substituted = substitute(substituted, '\-\+','-', 'g')
  let substituted = substitute(substituted, '^-', '', 'g')
  let substituted = substitute(substituted, '-$', '', 'g')
  return substitute(substituted, '\-\+','-', 'g') . '.html'
endfunction

function! s:html_insert_contents(html_lines, content) abort
  let lines = []
  for line in a:html_lines
    if line =~# '%content%'
      let parts = split(line, '%content%', 1)
      if empty(parts)
        call extend(lines, a:content)
      else
        for idx in range(len(parts))
          call add(lines, parts[idx])
          if idx < len(parts) - 1
            call extend(lines, a:content)
          endif
        endfor
      endif
    else
      call add(lines, line)
    endif
  endfor
  return lines
endfunction


function! s:tag_eqin(value) abort
  " mathJAX wants \( \) for inline maths
  return '\('.s:mid(a:value, 1).'\)'
endfunction


function! s:tag_em(value) abort
  return '<em>'.s:mid(a:value, 1).'</em>'
endfunction


function! s:tag_strong(value, header_ids) abort
  let text = s:mid(a:value, 1)
  let id = s:escape_html_attribute(text)
  let complete_id = ''
  for l in range(6)
    if a:header_ids[l][0] !=? ''
      let complete_id .= a:header_ids[l][0].'-'
    endif
  endfor
  if a:header_ids[5][0] ==? ''
    let complete_id = complete_id[:-2]
  endif
  let complete_id .= '-'.id
  return '<span id="'.s:escape_html_attribute(complete_id).'"></span><strong id="'
        \ .id.'">'.text.'</strong>'
endfunction


function! s:tag_tags(value, header_ids) abort
  let complete_id = ''
  for level in range(6)
    if a:header_ids[level][0] !=? ''
      let complete_id .= a:header_ids[level][0].'-'
    endif
  endfor
  if a:header_ids[5][0] ==? ''
    let complete_id = complete_id[:-2]
  endif
  let complete_id = s:escape_html_attribute(complete_id)

  let result = []
  for tag in split(a:value, ':')
    let id = s:escape_html_attribute(tag)
    call add(result, '<span id="'.complete_id.'-'.id.'"></span><span class="tag" id="'
          \ .id.'">'.tag.'</span>')
  endfor
  return join(result)
endfunction


function! s:tag_todo(value) abort
  return '<span class="todo">'.a:value.'</span>'
endfunction


function! s:tag_strike(value) abort
  return '<del>'.s:mid(a:value, 2).'</del>'
endfunction


function! s:tag_super(value) abort
  return '<sup><small>'.s:mid(a:value, 1).'</small></sup>'
endfunction


function! s:tag_sub(value) abort
  return '<sub><small>'.s:mid(a:value, 2).'</small></sub>'
endfunction


function! s:tag_code(value) abort
  let l:retstr = '<code'

  let l:str = s:mid(a:value, 1)
  let l:match = match(l:str, '^#[a-fA-F0-9]\{6\}$')

  if l:match != -1
    let l:r = eval('0x'.l:str[1:2])
    let l:g = eval('0x'.l:str[3:4])
    let l:b = eval('0x'.l:str[5:6])

    let l:fg_color =
          \ (((0.299 * r + 0.587 * g + 0.114 * b) / 0xFF) > 0.5)
          \ ? 'black' : 'white'

    let l:retstr .=
          \ " style='background-color:" . l:str .
          \ ';color:' . l:fg_color . ";'"
  endif

  let l:retstr .= '>'.s:safe_html_preformatted(l:str).'</code>'
  return l:retstr
endfunction


function! s:incl_match_arg(nn_index) abort
  "   match n-th ARG within {{URL[|ARG1|ARG2|...]}}
  " *c,d,e),...
  let rx = vimwiki#vars#get_global('rxWikiInclPrefix'). vimwiki#vars#get_global('rxWikiInclUrl')
  let rx = rx . repeat(vimwiki#vars#get_global('rxWikiInclSeparator') .
        \ vimwiki#vars#get_global('rxWikiInclArg'), a:nn_index-1)
  if a:nn_index > 0
    let rx = rx. vimwiki#vars#get_global('rxWikiInclSeparator'). '\zs' .
          \ vimwiki#vars#get_global('rxWikiInclArg') . '\ze'
  endif
  let rx = rx . vimwiki#vars#get_global('rxWikiInclArgs') .
        \ vimwiki#vars#get_global('rxWikiInclSuffix')
  return rx
endfunction


function! s:linkify_link(src, descr) abort
  let src_str = ' href="'.s:escape_html_attribute(a:src).'"'
  let descr = vimwiki#u#trim(a:descr)
  let descr = (descr ==? '' ? a:src : descr)
  let descr_str = (descr =~# vimwiki#vars#get_global('rxWikiIncl')
        \ ? s:tag_wikiincl(descr)
        \ : descr)
  return '<a'.src_str.'>'.descr_str.'</a>'
endfunction


function! s:linkify_image(src, descr, verbatim_str) abort
  let src_str = ' src="'.a:src.'"'
  let descr_str = (a:descr !=? '' ? ' alt="'.a:descr.'"' : '')
  let verbatim_str = (a:verbatim_str !=? '' ? ' '.a:verbatim_str : '')
  return '<img'.src_str.descr_str.verbatim_str.' />'
endfunction


function! s:tag_weblink(value) abort
  " Weblink Template -> <a href="url">descr</a>
  let str = a:value
  let url = matchstr(str, vimwiki#vars#get_syntaxlocal('rxWeblinkMatchUrl'))
  let descr = matchstr(str, vimwiki#vars#get_syntaxlocal('rxWeblinkMatchDescr'))
  let line = s:linkify_link(url, descr)
  return line
endfunction


function! s:tag_wikiincl(value) abort
  " {{imgurl|arg1|arg2}}    -> ???
  " {{imgurl}}                -> <img src="imgurl"/>
  " {{imgurl|descr|style="A"}} -> <img src="imgurl" alt="descr" style="A" />
  " {{imgurl|descr|class="B"}} -> <img src="imgurl" alt="descr" class="B" />
  let str = a:value
  " custom transclusions
  let line = VimwikiWikiIncludeHandler(str)
  " otherwise, assume image transclusion
  if line ==? ''
    let url_0 = matchstr(str, vimwiki#vars#get_global('rxWikiInclMatchUrl'))
    let descr = matchstr(str, s:incl_match_arg(1))
    let verbatim_str = matchstr(str, s:incl_match_arg(2))

    let link_infos = vimwiki#base#resolve_link(url_0)

    if link_infos.scheme =~# '\mlocal\|wiki\d\+\|diary'
      let url = vimwiki#path#relpath(fnamemodify(s:current_html_file, ':h'), link_infos.filename)
      " strip the .html extension when we have wiki links, so that the user can
      " simply write {{image.png}} to include an image from the wiki directory
      if link_infos.scheme =~# '\mwiki\d\+\|diary'
        let url = fnamemodify(url, ':r')
      endif
    else
      let url = link_infos.filename
    endif

    let url = escape(url, '#')
    let line = s:linkify_image(url, descr, verbatim_str)
  endif
  return line
endfunction


function! s:tag_wikilink(value) abort
  " [[url]]                   -> <a href="url.html">url</a>
  " [[url|descr]]             -> <a href="url.html">descr</a>
  " [[url|{{...}}]]           -> <a href="url.html"> ... </a>
  " [[fileurl.ext|descr]]     -> <a href="fileurl.ext">descr</a>
  " [[dirurl/|descr]]         -> <a href="dirurl/index.html">descr</a>
  " [[url#a1#a2]]             -> <a href="url.html#a1-a2">url#a1#a2</a>
  " [[#a1#a2]]                -> <a href="#a1-a2">#a1#a2</a>
  let str = a:value
  let url = matchstr(str, vimwiki#vars#get_syntaxlocal('rxWikiLinkMatchUrl'))
  let descr = matchstr(str, vimwiki#vars#get_syntaxlocal('rxWikiLinkMatchDescr'))
  let descr = vimwiki#u#trim(descr)
  let descr = (descr !=? '' ? descr : url)

  let line = VimwikiLinkConverter(url, s:current_wiki_file, s:current_html_file)
  if line ==? ''
    let link_infos = vimwiki#base#resolve_link(url, s:current_wiki_file)

    if link_infos.scheme ==# 'file'
      " external file links are always absolute
      let html_link = link_infos.filename
    elseif link_infos.scheme ==# 'local'
      let html_link = vimwiki#path#relpath(fnamemodify(s:current_html_file, ':h'),
            \ link_infos.filename)
    elseif link_infos.scheme =~# '\mwiki\d\+\|diary'
      " wiki links are always relative to the current file
      let html_link = vimwiki#path#relpath(
            \ fnamemodify(s:current_wiki_file, ':h'),
            \ fnamemodify(link_infos.filename, ':r'))
      if html_link !~? '\m/$'
        let html_link .= '.html'
      endif
    else " other schemes, like http, are left untouched
      let html_link = link_infos.filename
    endif

    if link_infos.anchor !=? ''
      let anchor = substitute(link_infos.anchor, '#', '-', 'g')
      let html_link .= '#'.anchor
    endif
    let line = html_link
  endif

  let line = s:linkify_link(line, descr)
  return line
endfunction


function! s:tag_remove_internal_link(value) abort
  let value = s:mid(a:value, 2)

  let line = ''
  if value =~# '|'
    let link_parts = split(value, '|', 1)
  else
    let link_parts = split(value, '][', 1)
  endif

  if len(link_parts) > 1
    if len(link_parts) < 3
      let style = ''
    else
      let style = link_parts[2]
    endif
    let line = link_parts[1]
  else
    let line = value
  endif
  return line
endfunction


function! s:tag_remove_external_link(value) abort
  let value = s:mid(a:value, 1)

  let line = ''
  if s:is_web_link(value)
    let lnkElements = split(value)
    let head = lnkElements[0]
    let rest = join(lnkElements[1:])
    if rest ==? ''
      let rest = head
    endif
    let line = rest
  elseif s:is_img_link(value)
    let line = '<img src="'.value.'" />'
  else
    " [alskfj sfsf] shouldn't be a link. So return it as it was --
    " enclosed in [...]
    let line = '['.value.']'
  endif
  return line
endfunction


function! s:make_tag(line, regexp, func, ...) abort
  " Make tags for a given matched regexp.
  " Exclude preformatted text and href links.
  " FIXME
  let patt_splitter = '\(`[^`]\+`\)\|'.
                    \ '\('.vimwiki#vars#get_syntaxlocal('rxPreStart').'.\+'.
                    \ vimwiki#vars#get_syntaxlocal('rxPreEnd').'\)\|'.
                    \ '\(<a href.\{-}</a>\)\|'.
                    \ '\(<img src.\{-}/>\)\|'.
                    \ '\(<pre.\{-}</pre>\)\|'.
                    \ '\('.s:rxEqIn.'\)'

  "FIXME FIXME !!! these can easily occur on the same line!
  "XXX  {{{ }}} ??? obsolete
  if '`[^`]\+`' ==# a:regexp || '{{{.\+}}}' ==# a:regexp ||
        \ s:rxEqIn ==# a:regexp
    let res_line = s:subst_func(a:line, a:regexp, a:func)
  else
    let pos = 0
    " split line with patt_splitter to have parts of line before and after
    " href links, preformatted text
    " ie:
    " hello world `is just a` simple <a href="link.html">type of</a> prg.
    " result:
    " ['hello world ', ' simple ', 'type of', ' prg']
    let lines = split(a:line, patt_splitter, 1)
    let res_line = ''
    for line in lines
      if a:0
        let res_line = res_line.s:subst_func(line, a:regexp, a:func, a:1)
      else
        let res_line = res_line.s:subst_func(line, a:regexp, a:func)
      endif
      let res_line = res_line.matchstr(a:line, patt_splitter, pos)
      let pos = matchend(a:line, patt_splitter, pos)
    endfor
  endif
  return res_line
endfunction


function! s:process_tags_remove_links(line) abort
  let line = a:line
  let line = s:make_tag(line, '\[\[.\{-}\]\]', 's:tag_remove_internal_link')
  let line = s:make_tag(line, '\[.\{-}\]', 's:tag_remove_external_link')
  return line
endfunction


function! s:process_tags_typefaces(line, header_ids) abort
  let line = a:line
  " Convert line tag by tag
  let line = s:make_tag(line, s:rxItalic, 's:tag_em')
  let line = s:make_tag(line, s:rxBold, 's:tag_strong', a:header_ids)
  let line = s:make_tag(line, vimwiki#vars#get_wikilocal('rx_todo'), 's:tag_todo')
  let line = s:make_tag(line, s:rxDelText, 's:tag_strike')
  let line = s:make_tag(line, s:rxSuperScript, 's:tag_super')
  let line = s:make_tag(line, s:rxSubScript, 's:tag_sub')
  let line = s:make_tag(line, s:rxCode, 's:tag_code')
  let line = s:make_tag(line, s:rxEqIn, 's:tag_eqin')
  let line = s:make_tag(line, vimwiki#vars#get_syntaxlocal('rxTags'), 's:tag_tags', a:header_ids)
  return line
endfunction


function! s:process_tags_links(line) abort
  let line = a:line
  let line = s:make_tag(line, vimwiki#vars#get_syntaxlocal('rxWikiLink'), 's:tag_wikilink')
  let line = s:make_tag(line, vimwiki#vars#get_global('rxWikiIncl'), 's:tag_wikiincl')
  let line = s:make_tag(line, vimwiki#vars#get_syntaxlocal('rxWeblink'), 's:tag_weblink')
  return line
endfunction


function! s:process_inline_tags(line, header_ids) abort
  let line = s:process_tags_links(a:line)
  let line = s:process_tags_typefaces(line, a:header_ids)
  return line
endfunction


function! s:close_tag_pre(pre, ldest) abort
  if a:pre[0]
    call insert(a:ldest, '</pre>')
    return 0
  endif
  return a:pre
endfunction


function! s:close_tag_math(math, ldest) abort
  if a:math[0]
    call insert(a:ldest, "\\\]")
    return 0
  endif
  return a:math
endfunction


function! s:close_tag_precode(quote, ldest) abort
  if a:quote
    call insert(a:ldest, '</pre></code>')
    return 0
  endif
  return a:quote
endfunction

function! s:close_tag_arrow_quote(arrow_quote, ldest) abort
  if a:arrow_quote
    call insert(a:ldest, '</p></blockquote>')
    return 0
  endif
  return a:arrow_quote
endfunction

function! s:close_tag_para(para, ldest) abort
  if a:para
    call insert(a:ldest, '</p>')
    return 0
  endif
  return a:para
endfunction


function! s:close_tag_table(table, ldest, header_ids) abort
  " The first element of table list is a string which tells us if table should be centered.
  " The rest elements are rows which are lists of columns:
  " ['center',
  "   [ CELL1, CELL2, CELL3 ],
  "   [ CELL1, CELL2, CELL3 ],
  "   [ CELL1, CELL2, CELL3 ],
  " ]
  " And CELLx is: { 'body': 'col_x', 'rowspan': r, 'colspan': c }

  function! s:sum_rowspan(table) abort
    let table = a:table

    " Get max cells
    let max_cells = 0
    for row in table[1:]
      let n_cells = len(row)
      if n_cells > max_cells
        let max_cells = n_cells
      end
    endfor

    " Sum rowspan
    for cell_idx in range(max_cells)
      let rows = 1

      for row_idx in range(len(table)-1, 1, -1)
        if cell_idx >= len(table[row_idx])
          let rows = 1
          continue
        endif

        if table[row_idx][cell_idx].rowspan == 0
          let rows += 1
        else " table[row_idx][cell_idx].rowspan == 1
          let table[row_idx][cell_idx].rowspan = rows
          let rows = 1
        endif
      endfor
    endfor
  endfunction

  function! s:sum_colspan(table) abort
    for row in a:table[1:]
      let cols = 1

      for cell_idx in range(len(row)-1, 0, -1)
        if row[cell_idx].colspan == 0
          let cols += 1
        else "row[cell_idx].colspan == 1
          let row[cell_idx].colspan = cols
          let cols = 1
        endif
      endfor
    endfor
  endfunction

  function! s:close_tag_row(row, header, ldest, header_ids) abort
    call add(a:ldest, '<tr>')

    " Set tag element of columns
    if a:header
      let tag_name = 'th'
    else
      let tag_name = 'td'
    end

    " Close tag of columns
    for cell in a:row
      if cell.rowspan == 0 || cell.colspan == 0
        continue
      endif

      if cell.rowspan > 1
        let rowspan_attr = ' rowspan="' . cell.rowspan . '"'
      else "cell.rowspan == 1
        let rowspan_attr = ''
      endif
      if cell.colspan > 1
        let colspan_attr = ' colspan="' . cell.colspan . '"'
      else "cell.colspan == 1
        let colspan_attr = ''
      endif

      call add(a:ldest, '<' . tag_name . rowspan_attr . colspan_attr .'>')
      call add(a:ldest, s:process_inline_tags(cell.body, a:header_ids))
      call add(a:ldest, '</'. tag_name . '>')
    endfor

    call add(a:ldest, '</tr>')
  endfunction

  let table = a:table
  let ldest = a:ldest
  if len(table)
    call s:sum_rowspan(table)
    call s:sum_colspan(table)

    if table[0] ==# 'center'
      call add(ldest, "<table class='center'>")
    else
      call add(ldest, '<table>')
    endif

    " Empty lists are table separators.
    " Search for the last empty list. All the above rows would be a table header.
    " We should exclude the first element of the table list as it is a text tag
    " that shows if table should be centered or not.
    let head = 0
    for idx in range(len(table)-1, 1, -1)
      if empty(table[idx])
        let head = idx
        break
      endif
    endfor
    if head > 0
      call add(ldest, '<thead>')
      for row in table[1 : head-1]
        if !empty(filter(row, '!empty(v:val)'))
          call s:close_tag_row(row, 1, ldest, a:header_ids)
        endif
      endfor
      call add(ldest, '</thead>')
      call add(ldest, '<tbody>')
      for row in table[head+1 :]
        call s:close_tag_row(row, 0, ldest, a:header_ids)
      endfor
      call add(ldest, '</tbody>')
    else
      for row in table[1 :]
        call s:close_tag_row(row, 0, ldest, a:header_ids)
      endfor
    endif
    call add(ldest, '</table>')
    let table = []
  endif
  return table
endfunction


function! s:close_tag_list(lists, ldest) abort
  while len(a:lists)
    let item = remove(a:lists, 0)
    call insert(a:ldest, item[0])
  endwhile
endfunction


function! s:close_tag_def_list(deflist, ldest) abort
  if a:deflist
    call insert(a:ldest, '</dl>')
    return 0
  endif
  return a:deflist
endfunction


function! s:process_tag_pre(line, pre) abort
  " pre is the list of [is_in_pre, indent_of_pre]
  "XXX always outputs a single line or empty list!
  let lines = []
  let pre = a:pre
  let processed = 0
  "XXX huh?
  "if !pre[0] && a:line =~# '^\s*{{{[^\(}}}\)]*\s*$'
  if !pre[0] && a:line =~# '^\s*{{{'
    let class = matchstr(a:line, '{{{\zs.*$')
    "FIXME class cannot contain arbitrary strings
    let class = substitute(class, '\s\+$', '', 'g')
    if class !=? ''
      call add(lines, '<pre '.class.'>')
    else
      call add(lines, '<pre>')
    endif
    let pre = [1, len(matchstr(a:line, '^\s*\ze{{{'))]
    let processed = 1
  elseif pre[0] && a:line =~# '^\s*}}}\s*$'
    let pre = [0, 0]
    call add(lines, '</pre>')
    let processed = 1
  elseif pre[0]
    let processed = 1
    "XXX destroys indent in general!
    "call add(lines, substitute(a:line, '^\s\{'.pre[1].'}', '', ''))
    call add(lines, s:safe_html_preformatted(a:line))
  endif
  return [processed, lines, pre]
endfunction


function! s:process_tag_math(line, math) abort
  " math is the list of [is_in_math, indent_of_math]
  let lines = []
  let math = a:math
  let processed = 0
  if !math[0] && a:line =~# '^\s*{{\$[^\(}}$\)]*\s*$'
    let class = matchstr(a:line, '{{$\zs.*$')
    "FIXME class cannot be any string!
    let class = substitute(class, '\s\+$', '', 'g')
    " store the environment name in a global variable in order to close the
    " environment properly
    let s:current_math_env = matchstr(class, '^%\zs\S\+\ze%')
    if s:current_math_env !=? ''
      call add(lines, substitute(class, '^%\(\S\+\)%', '\\begin{\1}', ''))
    elseif class !=? ''
      call add(lines, "\\\[".class)
    else
      call add(lines, "\\\[")
    endif
    let math = [1, len(matchstr(a:line, '^\s*\ze{{\$'))]
    let processed = 1
  elseif math[0] && a:line =~# '^\s*}}\$\s*$'
    let math = [0, 0]
    if s:current_math_env !=? ''
      call add(lines, "\\end{".s:current_math_env.'}')
    else
      call add(lines, "\\\]")
    endif
    let processed = 1
  elseif math[0]
    let processed = 1
    call add(lines, substitute(a:line, '^\s\{'.math[1].'}', '', ''))
  endif
  return [processed, lines, math]
endfunction


function! s:process_tag_precode(line, quote) abort
  " Process indented precode
  let lines = []
  let line = a:line
  let quote = a:quote
  let processed = 0

  " Check if start
  if line =~# '^\s\{4,}'
    let line = substitute(line, '^\s*', '', '')
    if !quote
    " Check if must decrease level
      let line = '<pre><code>' . line
      let quote = 1
    endif
    let processed = 1
    call add(lines, line)

  " Check if end
  elseif quote
    call add(lines, '</code></pre>')
    let quote = 0
  endif

  return [processed, lines, quote]
endfunction

function! s:process_tag_arrow_quote(line, arrow_quote) abort
  let lines = []
  let arrow_quote = a:arrow_quote
  let processed = 0
  let line = a:line

  " Check if must increase level
  if line =~# '^' . repeat('\s*&gt;', arrow_quote + 1)
    " Increase arrow_quote
    while line =~# '^' . repeat('\s*&gt;', arrow_quote + 1)
      call add(lines, '<blockquote>')
      call add(lines, '<p>')
      let arrow_quote .= 1
    endwhile

    " Treat & Add line
    let stripped_line = substitute(a:line, '^\%(\s*&gt;\)\+', '', '')
    if stripped_line =~# '^\s*$'
      call add(lines, '</p>')
      call add(lines, '<p>')
    endif
    call add(lines, stripped_line)
    let processed = 1

  " Check if must decrease level
  elseif arrow_quote > 0
    while line !~# '^' . repeat('\s*&gt;', arrow_quote - 1)
      call add(lines, '</p>')
      call add(lines, '</blockquote>')
      let arrow_quote -= 1
    endwhile
  endif
  return [processed, lines, arrow_quote]
endfunction


function! s:process_tag_list(line, lists, lstLeadingSpaces) abort
  function! s:add_checkbox(line, rx_list) abort
    let st_tag = '<li>'
    let chk = matchlist(a:line, a:rx_list)
    if !empty(chk) && len(chk[1]) > 0
      let completion = index(vimwiki#vars#get_wikilocal('listsyms_list'), chk[1])
      let n = len(vimwiki#vars#get_wikilocal('listsyms_list'))
      if completion == 0
        let st_tag = '<li class="done0">'
      elseif completion == -1 && chk[1] == vimwiki#vars#get_global('listsym_rejected')
        let st_tag = '<li class="rejected">'
      elseif completion > 0 && completion < n
        let completion = float2nr(round(completion / (n-1.0) * 3.0 + 0.5 ))
        let st_tag = '<li class="done'.completion.'">'
      endif
    endif
    return [st_tag, '']
  endfunction


  let in_list = (len(a:lists) > 0)
  let lstLeadingSpaces = a:lstLeadingSpaces

  " If it is not list yet then do not process line that starts from *bold*
  " text.
  " XXX necessary? in *bold* text, no space must follow the first *
  if !in_list
    let pos = match(a:line, '^\s*' . s:rxBold)
    if pos != -1
      return [0, [], lstLeadingSpaces]
    endif
  endif

  let lines = []
  let processed = 0
  let checkboxRegExp = '\s*\[\(.\)\]\s*'
  let maybeCheckboxRegExp = '\%('.checkboxRegExp.'\)\?'

  if a:line =~# '^\s*'.s:bullets.'\s'
    let lstSym = matchstr(a:line, s:bullets)
    let lstTagOpen = '<ul>'
    let lstTagClose = '</ul>'
    let lstRegExp = '^\s*'.s:bullets.'\s'
  elseif a:line =~# '^\s*'.s:numbers.'\s'
    let lstSym = matchstr(a:line, s:numbers)
    let lstTagOpen = '<ol>'
    let lstTagClose = '</ol>'
    let lstRegExp = '^\s*'.s:numbers.'\s'
  else
    let lstSym = ''
    let lstTagOpen = ''
    let lstTagClose = ''
    let lstRegExp = ''
  endif

  " If we're at the start of a list, figure out how many spaces indented we are so we can later
  " determine whether we're indented enough to be at the setart of a blockquote
  if lstSym !=# ''
    let lstLeadingSpaces = strlen(matchstr(a:line, lstRegExp.maybeCheckboxRegExp))
  endif

  " Jump empty lines
  if in_list && a:line =~# '^$'
    " Just Passing my way, do you mind ?
    let [processed, lines, quote] = s:process_tag_precode(a:line, g:state.quote)
    let processed = 1
    return [processed, lines, lstLeadingSpaces]
  endif

  " Can embedded indented code in list (Issue #55)
  let b_permit = in_list
  let blockquoteRegExp = '^\s\{' . (lstLeadingSpaces + 2) . ',}[^[:space:]>*-]'
  let b_match = lstSym ==# '' && a:line =~# blockquoteRegExp
  let b_match = b_match || g:state.quote
  if b_permit && b_match
    let [processed, lines, g:state.quote] = s:process_tag_precode(a:line, g:state.quote)
    if processed == 1
      return [processed, lines, lstLeadingSpaces]
    endif
  endif

  " New switch
  if lstSym !=? ''
    " To get proper indent level 'retab' the line -- change all tabs
    " to spaces*tabstop
    let line = substitute(a:line, '\t', repeat(' ', &tabstop), 'g')
    let indent = stridx(line, lstSym)

    let [st_tag, en_tag] = s:add_checkbox(line, lstRegExp.checkboxRegExp)

    if !in_list
      call add(a:lists, [lstTagClose, indent])
      call add(lines, lstTagOpen)
    elseif (in_list && indent > a:lists[-1][1])
      let item = remove(a:lists, -1)
      call add(lines, item[0])

      call add(a:lists, [lstTagClose, indent])
      call add(lines, lstTagOpen)
    elseif (in_list && indent < a:lists[-1][1])
      while len(a:lists) && indent < a:lists[-1][1]
        let item = remove(a:lists, -1)
        call add(lines, item[0])
      endwhile
    elseif in_list
      let item = remove(a:lists, -1)
      call add(lines, item[0])
    endif

    call add(a:lists, [en_tag, indent])
    call add(lines, st_tag)
    call add(lines, substitute(a:line, lstRegExp.maybeCheckboxRegExp, '', ''))
    let processed = 1

  elseif in_list && a:line =~# '^\s\+\S\+'
    if vimwiki#vars#get_wikilocal('list_ignore_newline')
      call add(lines, a:line)
    else
      call add(lines, '<br />'.a:line)
    endif
    let processed = 1

  " Close tag
  else
    call s:close_tag_list(a:lists, lines)
  endif

  return [processed, lines, lstLeadingSpaces]
endfunction


function! s:process_tag_def_list(line, deflist) abort
  let lines = []
  let deflist = a:deflist
  let processed = 0
  let matches = matchlist(a:line, '\(^.*\)::\%(\s\|$\)\(.*\)')
  if !deflist && len(matches) > 0
    call add(lines, '<dl>')
    let deflist = 1
  endif
  if deflist && len(matches) > 0
    if matches[1] !=? ''
      call add(lines, '<dt>'.matches[1].'</dt>')
    endif
    if matches[2] !=? ''
      call add(lines, '<dd>'.matches[2].'</dd>')
    endif
    let processed = 1
  elseif deflist
    let deflist = 0
    call add(lines, '</dl>')
  endif
  return [processed, lines, deflist]
endfunction


function! s:process_tag_para(line, para) abort
  let lines = []
  let para = a:para
  let processed = 0
  if a:line =~# '^\s\{,3}\S'
    if !para
      call add(lines, '<p>')
      let para = 1
    endif
    let processed = 1
    if vimwiki#vars#get_wikilocal('text_ignore_newline')
      call add(lines, a:line)
    else
      call add(lines, a:line.'<br />')
    endif
  elseif para && a:line =~# '^\s*$'
    call add(lines, '</p>')
    let para = 0
  endif
  return [processed, lines, para]
endfunction


function! s:process_tag_h(line, id) abort
  let line = a:line
  let processed = 0
  let h_level = 0
  let h_text = ''
  let h_id = ''

  if a:line =~# vimwiki#vars#get_syntaxlocal('rxHeader')
    let h_level = vimwiki#u#count_first_sym(a:line)
  endif
  if h_level > 0

    let h_text = vimwiki#u#trim(matchstr(line, vimwiki#vars#get_syntaxlocal('rxHeader')))
    let h_number = ''
    let h_complete_id = ''
    let h_id = s:escape_html_attribute(h_text)
    let centered = (a:line =~# '^\s')

    if h_text !=# vimwiki#vars#get_wikilocal('toc_header')

      let a:id[h_level-1] = [h_text, a:id[h_level-1][1]+1]

      " reset higher level ids
      for level in range(h_level, 5)
        let a:id[level] = ['', 0]
      endfor

      for l in range(h_level-1)
        let h_number .= a:id[l][1].'.'
        if a:id[l][0] !=? ''
          let h_complete_id .= a:id[l][0].'-'
        endif
      endfor
      let h_number .= a:id[h_level-1][1]
      let h_complete_id .= a:id[h_level-1][0]

      if vimwiki#vars#get_global('html_header_numbering')
        let num = matchstr(h_number,
              \ '^\(\d.\)\{'.(vimwiki#vars#get_global('html_header_numbering')-1).'}\zs.*')
        if !empty(num)
          let num .= vimwiki#vars#get_global('html_header_numbering_sym')
        endif
        let h_text = num.' '.h_text
      endif
      let h_complete_id = s:escape_html_attribute(h_complete_id)
      let h_part  = '<div id="'.h_complete_id.'">'
      let h_part .= '<h'.h_level.' id="'.h_id.'"'
      let a_tag = '<a href="#'.h_complete_id.'">'

    else

      let h_part = '<div id="'.h_id.'" class="toc">'
      let h_part .= '<h'.h_level.' id="'.h_id.'"'
      let a_tag = '<a href="#'.h_id.'">'

    endif

    if centered
      let h_part .= ' class="header justcenter">'
    else
      let h_part .= ' class="header">'
    endif

    let h_text = s:process_inline_tags(h_text, a:id)

    let line = h_part.a_tag.h_text.'</a></h'.h_level.'></div>'

    let processed = 1
  endif
  return [processed, line]
endfunction


function! s:process_tag_hr(line) abort
  let line = a:line
  let processed = 0
  if a:line =~# '^-----*$'
    let line = '<hr />'
    let processed = 1
  endif
  return [processed, line]
endfunction


function! s:process_tag_table(line, table, header_ids) abort
  function! s:table_empty_cell(value) abort
    let cell = {}

    if a:value =~# '^\s*\\/\s*$'
      let cell.body    = ''
      let cell.rowspan = 0
      let cell.colspan = 1
    elseif a:value =~# '^\s*&gt;\s*$'
      let cell.body    = ''
      let cell.rowspan = 1
      let cell.colspan = 0
    elseif a:value =~# '^\s*$'
      let cell.body    = '&nbsp;'
      let cell.rowspan = 1
      let cell.colspan = 1
    else
      let cell.body    = a:value
      let cell.rowspan = 1
      let cell.colspan = 1
    endif

    return cell
  endfunction

  function! s:table_add_row(table, line) abort
    if empty(a:table)
      if a:line =~# '^\s\+'
        let row = ['center', []]
      else
        let row = ['normal', []]
      endif
    else
      let row = [[]]
    endif
    return row
  endfunction

  let table = a:table
  let lines = []
  let processed = 0

  if vimwiki#tbl#is_separator(a:line)
    call extend(table, s:table_add_row(a:table, a:line))
    let processed = 1
  elseif vimwiki#tbl#is_table(a:line)
    call extend(table, s:table_add_row(a:table, a:line))

    let processed = 1
    " let cells = split(a:line, vimwiki#tbl#cell_splitter(), 1)[1: -2]
    let cells = vimwiki#tbl#get_cells(a:line)
    call map(cells, 's:table_empty_cell(v:val)')
    call extend(table[-1], cells)
  else
    let table = s:close_tag_table(table, lines, a:header_ids)
  endif
  return [processed, lines, table]
endfunction


function! s:parse_line(line, state) abort
  let state = {}
  let state.para = a:state.para
  let state.quote = a:state.quote
  let state.arrow_quote = a:state.arrow_quote
  let state.active_multiline_comment = a:state.active_multiline_comment
  let state.list_leading_spaces = a:state.list_leading_spaces
  let state.pre = a:state.pre[:]
  let state.math = a:state.math[:]
  let state.table = a:state.table[:]
  let state.lists = a:state.lists[:]
  let state.deflist = a:state.deflist
  let state.placeholder = a:state.placeholder
  let state.header_ids = a:state.header_ids

  let res_lines = []
  let processed = 0
  let line = a:line

  " Handle multiline comments, keeping in mind that they can mutate the
  " current line while not marking as processed in the scenario where some
  " text remains that needs to go through additional processing
  if !processed
    let mc_format = vimwiki#vars#get_syntaxlocal('multiline_comment_format')
    let mc_start = mc_format.pre_mark
    let mc_end = mc_format.post_mark

    " If either start or end is empty, we want to skip multiline handling
    if !empty(mc_start) && !empty(mc_end)
      " If we have an active multiline comment, we prepend the start of the
      " multiline to our current line to make searching easier, knowing that
      " it will be removed using substitute in all scenarios
      if state.active_multiline_comment
        let line = mc_start.line
      endif

      " Remove all instances of multiline comment pairs (start + end), using
      " a lazy match so that we stop at the first ending multiline comment
      " rather than potentially absorbing multiple
      let line = substitute(line, mc_start.'.\{-\}'.mc_end, '', 'g')

      " Check for a dangling multiline comment (comprised only of start) and
      " remove all characters beyond it, also indicating that we are dangling
      let mc_start_pos = match(line, mc_start)
      if mc_start_pos >= 0
        " NOTE: mc_start_pos is the byte offset, so should be fine with strpart
        let line = strpart(line, 0, mc_start_pos)
      endif

      " If we had a dangling multiline comment, we want to flag as such
      let state.active_multiline_comment = mc_start_pos >= 0
    endif
  endif

  if !processed
    " allows insertion of plain text to the final html conversion
    " for example:
    " %plainhtml <div class="mycustomdiv">
    " inserts the line above to the final html file (without %plainhtml prefix)
    let trigger = '%plainhtml'
    if line =~# '^\s*' . trigger
      let lines = []
      let processed = 1

      " if something precedes the plain text line,
      " make sure everything gets closed properly
      " before inserting plain text. this ensures that
      " the plain text is not considered as
      " part of the preceding structure
      if processed && len(state.table)
        let state.table = s:close_tag_table(state.table, lines, state.header_ids)
      endif
      if processed && state.deflist
        let state.deflist = s:close_tag_def_list(state.deflist, lines)
      endif
      if processed && state.quote
        let state.quote = s:close_tag_precode(state.quote, lines)
      endif
      if processed && state.arrow_quote
        let state.arrow_quote = s:close_tag_arrow_quote(state.arrow_quote, lines)
      endif
      if processed && state.para
        let state.para = s:close_tag_para(state.para, lines)
      endif

      " remove the trigger prefix
      let pp = split(line, trigger)[0]

      call add(lines, pp)
      call extend(res_lines, lines)
    endif
  endif

  let line = s:safe_html_line(line)

  " pres
  if !processed
    let [processed, lines, state.pre] = s:process_tag_pre(line, state.pre)
    " pre is just fine to be in the list -- do not close list item here.
    " if processed && len(state.lists)
      " call s:close_tag_list(state.lists, lines)
    " endif
    if !processed
      let [processed, lines, state.math] = s:process_tag_math(line, state.math)
    endif
    if processed && len(state.table)
      let state.table = s:close_tag_table(state.table, lines, state.header_ids)
    endif
    if processed && state.deflist
      let state.deflist = s:close_tag_def_list(state.deflist, lines)
    endif
    if processed && state.quote
      let state.quote = s:close_tag_precode(state.quote, lines)
    endif
    if processed && state.arrow_quote
      let state.arrow_quote = s:close_tag_arrow_quote(state.arrow_quote, lines)
    endif
    if processed && state.para
      let state.para = s:close_tag_para(state.para, lines)
    endif
    call extend(res_lines, lines)
  endif

  if !processed
    if line =~# vimwiki#vars#get_syntaxlocal('comment_regex')
      let processed = 1
    endif
  endif

  " nohtml -- placeholder
  if !processed
    if line =~# '\m^\s*%nohtml\s*$'
      let processed = 1
      let state.placeholder = ['nohtml']
    endif
  endif

  " title -- placeholder
  if !processed
    if line =~# '\m^\s*%title\%(\s.*\)\?$'
      let processed = 1
      let param = matchstr(line, '\m^\s*%title\s\+\zs.*')
      let state.placeholder = ['title', param]
    endif
  endif

  " date -- placeholder
  if !processed
    if line =~# '\m^\s*%date\%(\s.*\)\?$'
      let processed = 1
      let param = matchstr(line, '\m^\s*%date\s\+\zs.*')
      let state.placeholder = ['date', param]
    endif
  endif

  " html template -- placeholder
  if !processed
    if line =~# '\m^\s*%template\%(\s.*\)\?$'
      let processed = 1
      let param = matchstr(line, '\m^\s*%template\s\+\zs.*')
      let state.placeholder = ['template', param]
    endif
  endif


  " tables
  if !processed
    let [processed, lines, state.table] = s:process_tag_table(line, state.table, state.header_ids)
    call extend(res_lines, lines)
  endif


  " lists
  if !processed
    let [processed, lines, state.list_leading_spaces] = s:process_tag_list(line, state.lists, state.list_leading_spaces)
    if processed && state.quote
      let state.quote = s:close_tag_precode(state.quote, lines)
    endif
    if processed && state.arrow_quote
      let state.arrow_quote = s:close_tag_arrow_quote(state.arrow_quote, lines)
    endif
    if processed && state.pre[0]
      let state.pre = s:close_tag_pre(state.pre, lines)
    endif
    if processed && state.math[0]
      let state.math = s:close_tag_math(state.math, lines)
    endif
    if processed && len(state.table)
      let state.table = s:close_tag_table(state.table, lines, state.header_ids)
    endif
    if processed && state.deflist
      let state.deflist = s:close_tag_def_list(state.deflist, lines)
    endif
    if processed && state.para
      let state.para = s:close_tag_para(state.para, lines)
    endif

    call map(lines, 's:process_inline_tags(v:val, state.header_ids)')

    call extend(res_lines, lines)
  endif


  " headers
  if !processed
    let [processed, line] = s:process_tag_h(line, state.header_ids)
    if processed
      call s:close_tag_list(state.lists, res_lines)
      let state.table = s:close_tag_table(state.table, res_lines, state.header_ids)
      let state.pre = s:close_tag_pre(state.pre, res_lines)
      let state.math = s:close_tag_math(state.math, res_lines)
      let state.quote = s:close_tag_precode(state.quote || state.arrow_quote, res_lines)
      let state.arrow_quote = s:close_tag_arrow_quote(state.arrow_quote, lines)
      let state.para = s:close_tag_para(state.para, res_lines)

      call add(res_lines, line)
    endif
  endif


  " quotes
  if !processed
    let [processed, lines, state.quote] = s:process_tag_precode(line, state.quote)
    if processed && len(state.lists)
      call s:close_tag_list(state.lists, lines)
    endif
    if processed && state.deflist
      let state.deflist = s:close_tag_def_list(state.deflist, lines)
    endif
    if processed && state.arrow_quote
      let state.quote = s:close_tag_arrow_quote(state.arrow_quote, lines)
    endif
    if processed && len(state.table)
      let state.table = s:close_tag_table(state.table, lines, state.header_ids)
    endif
    if processed && state.pre[0]
      let state.pre = s:close_tag_pre(state.pre, lines)
    endif
    if processed && state.math[0]
      let state.math = s:close_tag_math(state.math, lines)
    endif
    if processed && state.para
      let state.para = s:close_tag_para(state.para, lines)
    endif

    call map(lines, 's:process_inline_tags(v:val, state.header_ids)')

    call extend(res_lines, lines)
  endif

  " arrow quotes
  if !processed
    let [processed, lines, state.arrow_quote] = s:process_tag_arrow_quote(line, state.arrow_quote)
    if processed && state.quote
      let state.quote = s:close_tag_precode(state.quote, lines)
    endif
    if processed && len(state.lists)
      call s:close_tag_list(state.lists, lines)
    endif
    if processed && state.deflist
      let state.deflist = s:close_tag_def_list(state.deflist, lines)
    endif
    if processed && len(state.table)
      let state.table = s:close_tag_table(state.table, lines, state.header_ids)
    endif
    if processed && state.pre[0]
      let state.pre = s:close_tag_pre(state.pre, lines)
    endif
    if processed && state.math[0]
      let state.math = s:close_tag_math(state.math, lines)
    endif
    if processed && state.para
      let state.para = s:close_tag_para(state.para, lines)
    endif

    call map(lines, 's:process_inline_tags(v:val, state.header_ids)')

    call extend(res_lines, lines)
  endif


  " horizontal rules
  if !processed
    let [processed, line] = s:process_tag_hr(line)
    if processed
      call s:close_tag_list(state.lists, res_lines)
      let state.table = s:close_tag_table(state.table, res_lines, state.header_ids)
      let state.pre = s:close_tag_pre(state.pre, res_lines)
      let state.math = s:close_tag_math(state.math, res_lines)
      call add(res_lines, line)
    endif
  endif


  " definition lists
  if !processed
    let [processed, lines, state.deflist] = s:process_tag_def_list(line, state.deflist)

    call map(lines, 's:process_inline_tags(v:val, state.header_ids)')

    call extend(res_lines, lines)
  endif


  "" P
  if !processed
    let [processed, lines, state.para] = s:process_tag_para(line, state.para)
    if processed && len(state.lists)
      call s:close_tag_list(state.lists, lines)
    endif
    if processed && (state.quote || state.arrow_quote)
      let state.quote = s:close_tag_precode(state.quote || state.arrow_quote, lines)
    endif
    if processed && state.arrow_quote
      let state.arrow_quote = s:close_tag_arrow_quote(state.arrow_quote, lines)
    endif
    if processed && state.pre[0]
      let state.pre = s:close_tag_pre(state.pre, res_lines)
    endif
    if processed && state.math[0]
      let state.math = s:close_tag_math(state.math, res_lines)
    endif
    if processed && len(state.table)
      let state.table = s:close_tag_table(state.table, res_lines, state.header_ids)
    endif

    call map(lines, 's:process_inline_tags(v:val, state.header_ids)')

    call extend(res_lines, lines)
  endif


  "" add the rest
  if !processed
    call add(res_lines, line)
  endif

  return [res_lines, state]
endfunction


function! s:use_custom_wiki2html() abort
  let custom_wiki2html = vimwiki#vars#get_wikilocal('custom_wiki2html')
  return !empty(custom_wiki2html) &&
        \ (s:file_exists(custom_wiki2html) || s:binary_exists(custom_wiki2html))
endfunction

function! s:shellescape(str) abort
  let result = a:str
  "" This fix CustomWiki2HTML at root dir problem in Windows
  if result[len(result) - 1] ==# '\'
    let result = result[:-2]
  endif
  return shellescape(result)
endfunction

function! vimwiki#html#CustomWiki2HTML(root_path, path, wikifile, force) abort
  call vimwiki#path#mkdir(a:path)
  let output = system(vimwiki#vars#get_wikilocal('custom_wiki2html'). ' '.
      \ a:force. ' '.
      \ vimwiki#vars#get_wikilocal('syntax'). ' '.
      \ strpart(vimwiki#vars#get_wikilocal('ext'), 1). ' '.
      \ s:shellescape(a:path). ' '.
      \ s:shellescape(a:wikifile). ' '.
      \ s:shellescape(s:default_CSS_full_name(a:root_path)). ' '.
      \ (len(vimwiki#vars#get_wikilocal('template_path')) > 1 ?
      \     s:shellescape(expand(vimwiki#vars#get_wikilocal('template_path'))) : '-'). ' '.
      \ (len(vimwiki#vars#get_wikilocal('template_default')) > 0 ?
      \     vimwiki#vars#get_wikilocal('template_default') : '-'). ' '.
      \ (len(vimwiki#vars#get_wikilocal('template_ext')) > 0 ?
      \     vimwiki#vars#get_wikilocal('template_ext') : '-'). ' '.
      \ (len(vimwiki#vars#get_bufferlocal('subdir')) > 0 ?
      \     s:shellescape(s:root_path(vimwiki#vars#get_bufferlocal('subdir'))) : '-'). ' '.
      \ (len(vimwiki#vars#get_wikilocal('custom_wiki2html_args')) > 0 ?
      \     vimwiki#vars#get_wikilocal('custom_wiki2html_args') : '-'))
  " Print if non void
  if output !~? '^\s*$'
    call vimwiki#u#echo(string(output))
  endif
endfunction

function! s:convert_file_to_lines(wikifile, current_html_file) abort
  let result = {}

  " the currently processed file name is needed when processing links
  " yeah yeah, shame on me for using (quasi-) global variables
  let s:current_wiki_file = a:wikifile
  let s:current_html_file = a:current_html_file

  let lsource = readfile(a:wikifile)
  let ldest = []

  " nohtml placeholder -- to skip html generation.
  let nohtml = 0

  " template placeholder
  let template_name = ''

  " for table of contents placeholders.
  let placeholders = []

  " current state of converter
  let state = {}
  let state.para = 0
  let state.quote = 0
  let state.arrow_quote = 0
  let state.active_multiline_comment = 0
  let state.list_leading_spaces = 0
  let state.pre = [0, 0] " [in_pre, indent_pre]
  let state.math = [0, 0] " [in_math, indent_math]
  let state.table = []
  let state.deflist = 0
  let state.lists = []
  let state.placeholder = []
  let state.header_ids = [['', 0], ['', 0], ['', 0], ['', 0], ['', 0], ['', 0]]
       " [last seen header text in this level, number]

  " Cheat, see cheaters who access me
  let g:state = state

  " prepare constants for s:safe_html_line()
  let s:lt_pattern = '<'
  let s:gt_pattern = '>'
  if vimwiki#vars#get_global('valid_html_tags') !=? ''
    let tags = join(split(vimwiki#vars#get_global('valid_html_tags'), '\s*,\s*'), '\|')
    let s:lt_pattern = '\c<\%(/\?\%('.tags.'\)\%(\s\{-1}\S\{-}\)\{-}/\?>\)\@!'
    let s:gt_pattern = '\c\%(</\?\%('.tags.'\)\%(\s\{-1}\S\{-}\)\{-}/\?\)\@<!>'
  endif

  " prepare regexps for lists
  let s:bullets = vimwiki#vars#get_wikilocal('rx_bullet_char')
  let s:numbers = '\C\%(#\|\d\+)\|\d\+\.\|[ivxlcdm]\+)\|[IVXLCDM]\+)\|\l\{1,2})\|\u\{1,2})\)'

  for line in lsource
    let oldquote = state.quote
    let [lines, state] = s:parse_line(line, state)

    " Hack: There could be a lot of empty strings before s:process_tag_precode
    " find out `quote` is over. So we should delete them all. Think of the way
    " to refactor it out.
    if oldquote != state.quote
      call s:remove_blank_lines(ldest)
    endif

    if !empty(state.placeholder)
      if state.placeholder[0] ==# 'nohtml'
        let nohtml = 1
        break
      elseif state.placeholder[0] ==# 'template'
        let template_name = state.placeholder[1]
      else
        call add(placeholders, [state.placeholder, len(ldest), len(placeholders)])
      endif
      let state.placeholder = []
    endif

    call extend(ldest, lines)
  endfor


  let result['nohtml'] = nohtml
  if nohtml
    call vimwiki#u#echo("\r".'%nohtml placeholder found', '', 'n')
    return result
  endif

  call s:remove_blank_lines(ldest)

  " process end of file
  " close opened tags if any
  let lines = []
  call s:close_tag_precode(state.quote, lines)
  call s:close_tag_arrow_quote(state.arrow_quote, lines)
  call s:close_tag_para(state.para, lines)
  call s:close_tag_pre(state.pre, lines)
  call s:close_tag_math(state.math, lines)
  call s:close_tag_list(state.lists, lines)
  call s:close_tag_def_list(state.deflist, lines)
  call s:close_tag_table(state.table, lines, state.header_ids)
  call extend(ldest, lines)

  let result['html'] = ldest

  let result['template_name'] = template_name
  let result['title'] = s:process_title(placeholders, fnamemodify(a:wikifile, ':t:r'))
  let result['date'] = s:process_date(placeholders, strftime(vimwiki#vars#get_wikilocal('template_date_format')))
  let result['wiki_path'] = strpart(s:current_wiki_file, strlen(vimwiki#vars#get_wikilocal('path')))

  return result
endfunction

function! s:convert_file_to_lines_template(wikifile, current_html_file) abort
  let converted = s:convert_file_to_lines(a:wikifile, a:current_html_file)
  if converted['nohtml'] == 1
    return []
  endif
  let html_lines = s:get_html_template(converted['template_name'])

  " processing template variables (refactor to a function)
  call map(html_lines, 'substitute(v:val, "%title%", converted["title"], "g")')
  call map(html_lines, 'substitute(v:val, "%date%", converted["date"], "g")')
  call map(html_lines, 'substitute(v:val, "%root_path%", "'.
        \ s:root_path(vimwiki#vars#get_bufferlocal('subdir')) .'", "g")')
  call map(html_lines, 'substitute(v:val, "%wiki_path%", converted["wiki_path"], "g")')

  let css_name = expand(vimwiki#vars#get_wikilocal('css_name'))
  let css_name = substitute(css_name, '\', '/', 'g')
  call map(html_lines, 'substitute(v:val, "%css%", css_name, "g")')

  let rss_name = expand(vimwiki#vars#get_wikilocal('rss_name'))
  let rss_name = substitute(rss_name, '\', '/', 'g')
  call map(html_lines, 'substitute(v:val, "%rss%", rss_name, "g")')

  let enc = &fileencoding
  if enc ==? ''
    let enc = &encoding
  endif
  call map(html_lines, 'substitute(v:val, "%encoding%", enc, "g")')

  let html_lines = s:html_insert_contents(html_lines, converted['html']) " %contents%

  return html_lines
endfunction

function! s:convert_file(path_html, wikifile) abort
  let done = 0
  let root_path_html = a:path_html
  let wikifile = fnamemodify(a:wikifile, ':p')
  let path_html = expand(a:path_html).vimwiki#vars#get_bufferlocal('subdir')
  let htmlfile = fnamemodify(wikifile, ':t:r').'.html'

  if s:use_custom_wiki2html()
    let force = 1
    call vimwiki#html#CustomWiki2HTML(root_path_html, path_html, wikifile, force)
    let done = 1
    if vimwiki#vars#get_wikilocal('html_filename_parameterization')
      return path_html . s:parameterized_wikiname(htmlfile)
    else
      return path_html.htmlfile
    endif
  endif

  if s:syntax_supported() && done == 0
    let html_lines = s:convert_file_to_lines_template(wikifile, path_html . htmlfile)
    if html_lines == []
      return ''
    endif
    call vimwiki#path#mkdir(path_html)

    if g:vimwiki_global_vars['listing_hl'] > 0 && has('unix')
      let i = 0
      while i < len(html_lines)
        if html_lines[i] =~# '^<pre .*type=.\+>'
          let type = split(split(split(html_lines[i], 'type=')[1], '>')[0], '\s\+')[0]
          let attr = split(split(html_lines[i], '<pre ')[0], '>')[0]
          let start = i + 1
          let cur = start

          while html_lines[cur] !~# '^<\/pre>'
            let cur += 1
          endwhile

          let tmp = ('tmp'. split(system('mktemp -p . --suffix=.' . type, 'silent'), 'tmp')[-1])[:-2]
          call system('echo ' . shellescape(join(html_lines[start : cur - 1], "\n")) . ' > ' . tmp)
          call system(g:vimwiki_global_vars['listing_hl_command'] . ' ' . tmp  . ' > ' . tmp . '.html')
          let html_out = system('cat ' . tmp . '.html')
          call system('rm ' . tmp . ' ' . tmp . '.html')
          let i = cur
          let html_lines = html_lines[0 : start - 1] + split(html_out, "\n") + html_lines[cur : ]
        endif
        let i += 1
      endwhile
    endif

    call writefile(html_lines, path_html.htmlfile)
    return path_html . htmlfile
  endif

  call vimwiki#u#error('Conversion to HTML is not supported for this syntax')
  return ''
endfunction


function! vimwiki#html#Wiki2HTML(path_html, wikifile) abort
  let result = s:convert_file(a:path_html, vimwiki#path#wikify_path(a:wikifile))
  if result !=? ''
    call s:create_default_CSS(a:path_html)
  endif
  return result
endfunction


function! vimwiki#html#WikiAll2HTML(path_html, force) abort
  if !s:syntax_supported() && !s:use_custom_wiki2html()
    call vimwiki#u#error('Conversion to HTML is not supported for this syntax')
    return
  endif

  call vimwiki#u#echo('Saving Vimwiki files ...')
  let save_eventignore = &eventignore
  let &eventignore = 'all'
  try
    wall
  catch
    " just ignore errors
  endtry
  let &eventignore = save_eventignore

  let path_html = expand(a:path_html)
  call vimwiki#path#mkdir(path_html)

  if !vimwiki#vars#get_wikilocal('html_filename_parameterization')
    call vimwiki#u#echo('Deleting non-wiki html files ...')
    call s:delete_html_files(path_html)
  endif

  let setting_more = &more
  call vimwiki#u#echo('Converting wiki to html files ...')
  setlocal nomore

  " temporarily adjust current_subdir global state variable
  let current_subdir = vimwiki#vars#get_bufferlocal('subdir')
  let current_invsubdir = vimwiki#vars#get_bufferlocal('invsubdir')

  let wikifiles = split(glob(vimwiki#vars#get_wikilocal('path').'**/*'.
        \ vimwiki#vars#get_wikilocal('ext')), '\n')
  for wikifile in wikifiles
    let wikifile = fnamemodify(wikifile, ':p')

    " temporarily adjust 'subdir' and 'invsubdir' state variables
    let subdir = vimwiki#base#subdir(vimwiki#vars#get_wikilocal('path'), wikifile)
    call vimwiki#vars#set_bufferlocal('subdir', subdir)
    call vimwiki#vars#set_bufferlocal('invsubdir', vimwiki#base#invsubdir(subdir))

    if a:force || !s:is_html_uptodate(wikifile)
      call vimwiki#u#echo('Processing '.wikifile)

      call s:convert_file(path_html, wikifile)
    else
      call vimwiki#u#echo('Skipping '.wikifile)
    endif
  endfor
  " reset 'subdir' state variable
  call vimwiki#vars#set_bufferlocal('subdir', current_subdir)
  call vimwiki#vars#set_bufferlocal('invsubdir', current_invsubdir)

  let created = s:create_default_CSS(path_html)
  if created
    call vimwiki#u#echo('Default style.css has been created')
  endif
  call vimwiki#u#echo('HTML exported to '.path_html)
  call vimwiki#u#echo('Done!')

  let &more = setting_more
endfunction


function! s:file_exists(fname) abort
  return !empty(getftype(expand(a:fname)))
endfunction


function! s:binary_exists(fname) abort
  return executable(expand(a:fname))
endfunction


function! s:get_wikifile_url(wikifile) abort
  return vimwiki#vars#get_wikilocal('path_html') .
    \ vimwiki#base#subdir(vimwiki#vars#get_wikilocal('path'), a:wikifile).
    \ fnamemodify(a:wikifile, ':t:r').'.html'
endfunction


function! vimwiki#html#PasteUrl(wikifile) abort
  execute 'r !echo file://'.s:get_wikifile_url(a:wikifile)
endfunction


function! vimwiki#html#CatUrl(wikifile) abort
  execute '!echo file://'.s:get_wikifile_url(a:wikifile)
endfunction


function! s:rss_header() abort
  let title = vimwiki#vars#get_wikilocal('diary_header')
  let rss_url = vimwiki#vars#get_wikilocal('base_url') . vimwiki#vars#get_wikilocal('rss_name')
  let link = vimwiki#vars#get_wikilocal('base_url')
        \ . vimwiki#vars#get_wikilocal('diary_rel_path')
        \ . vimwiki#vars#get_wikilocal('diary_index') . '.html'
  let description = title
  let pubdate = strftime('%a, %d %b %Y %T %z')
  let header = [
        \ '<?xml version="1.0" encoding="UTF-8" ?>',
        \ '<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">',
        \ '<channel>',
        \ ' <title>' . title . '</title>',
        \ ' <link>' . link . '</link>',
        \ ' <description>' . description . '</description>',
        \ ' <pubDate>' . pubdate . '</pubDate>',
        \ ' <atom:link href="' . rss_url . '" rel="self" type="application/rss+xml" />'
        \ ]
  return header
endfunction

function! s:rss_footer() abort
  let footer = ['</channel>', '</rss>']
  return footer
endfunction

function! s:rss_item(path, title) abort
  let diary_rel_path = vimwiki#vars#get_wikilocal('diary_rel_path')
  let full_path = vimwiki#vars#get_wikilocal('path')
        \ . diary_rel_path . a:path . vimwiki#vars#get_wikilocal('ext')
  let fname_base = fnamemodify(a:path, ':t:r')
  let htmlfile = fname_base . '.html'

  let converted = s:convert_file_to_lines(full_path, htmlfile)
  if converted['nohtml'] == 1
    return []
  endif

  let link = vimwiki#vars#get_wikilocal('base_url')
        \ . diary_rel_path
        \ . fname_base . '.html'
  let pubdate = strftime('%a, %d %b %Y %T %z', getftime(full_path))

  let item_pre = [' <item>',
        \ '  <title>' . a:title . '</title>',
        \ '  <link>' . link . '</link>',
        \ '  <guid isPermaLink="false">' . fname_base . '</guid>',
        \ '  <description><![CDATA[']
  let item_post = [']]></description>',
        \ '  <pubDate>' . pubdate . '</pubDate>',
        \ ' </item>'
        \]
  return item_pre + converted['html'] + item_post
endfunction

function! s:generate_rss(path) abort
  let rss_path = a:path . vimwiki#vars#get_wikilocal('rss_name')
  let max_items = vimwiki#vars#get_wikilocal('rss_max_items')

  let rss_lines = []
  call extend(rss_lines, s:rss_header())

  let captions = vimwiki#diary#diary_file_captions()
  let i = 0
  for diary in vimwiki#diary#diary_sort(keys(captions))
    if i >= max_items
      break
    endif
    let title = captions[diary]['top']
    if title ==? ''
      let title = diary
    endif
    call extend(rss_lines, s:rss_item(diary, title))
    let i += 1
  endfor

  call extend(rss_lines, s:rss_footer())
  call writefile(rss_lines, rss_path)
endfunction

function! vimwiki#html#diary_rss() abort
  call vimwiki#u#echo('Saving RSS feed ...')
  let path_html = expand(vimwiki#vars#get_wikilocal('path_html'))
  call vimwiki#path#mkdir(path_html)
  call s:generate_rss(path_html)
endfunction
