" vim:tabstop=2:shiftwidth=2:expandtab:foldmethod=marker:textwidth=79
" Vimwiki autoload plugin file
" Export to HTML
" Authors: Maxim Kim <habamax@gmail.com>
"          Daniel Schemala <istjanichtzufassen@gmail.com>
" Home: http://code.google.com/p/vimwiki/


fu! vimwiki#vw2html#applytemplate(content)
  let tpl_file = s:get_template(s:template)
  let tpl_content = join(readfile(tpl_file), '\n')

  let tpl_content = substitute(tpl_content, "%title%", s:title, "g")
  let tpl_content = substitute(tpl_content, "%root_path%", s:root_path(VimwikiGet('subdir')), "g")

  let css_name = expand(VimwikiGet('css_name'))
  let css_name = substitute(css_name, '\', '/', 'g')
  "XXX
	"let s:css_file = s:default_CSS_full_name(a:output_dir)
  let tpl_content = substitute(tpl_content, "%css%", css_name, "g")

  let enc = &fileencoding
  if enc == ''
    let enc = &encoding
  endif
  let tpl_content = substitute(tpl_content, "%encoding%", enc, "g")

  let tpl_content = substitute(tpl_content, "%content%", a:content, "g")

  return tpl_content
endf

fu! vimwiki#vw2html#header(string)
	let res = matchlist(a:string, '\s*\(=\{1,6}\)\([^=].\{-}[^=]\)\1\s*\r')
	let level = strlen(res[1])
	let center = a:string =~ '^\s' ? ' class="justcenter"' : ''
	return '<h'.level.center.'>'.res[2].'</h'.level.'>'
endf

fu! vimwiki#vw2html#breakorspace(string)
	return '<br />'
endf

let s:current_indent = 0

fu! vimwiki#vw2html#saveindent(string)
	let s:current_indent = matchstr(a:string, '^\s*')
	return ''
endfu

function! vimwiki#vw2html#checkbox(bulletandcb, type)
	let [bullet, cb] = a:bulletandcb
	if cb != ''
		let idx = index([' ', '.', 'o', 'O', 'X'], cb)
		let cb = ' class="done'.idx.'"'
	endif
	let typeattr = ''
	if a:type != '-'
		let typeattr = ' type="'.a:type.'"'
	endif
	return '<li' . typeattr . cb . '>'
endfunction

fu! vimwiki#vw2html#startpre(class)
	if a:class !~ '^\s*$'
		return '<pre ' . a:class . '>'
	else
		return '<pre>'
	endif
endf

fu! vimwiki#vw2html#endpre(string)
	let str = substitute(a:string, '\r\s*}}}\s*\r$', '', '')
	let lines = split(str, '\r')
	let result = []
	for line in lines
		if line =~ '^'.s:current_indent
			call add(result, substitute(line, '^'.s:current_indent, '', ''))
		else
			call add(result, substitute(line, '^\s*', '', ''))
		endif
	endfor
	return join(result, '\n').'</pre>'
endf

fu! vimwiki#vw2html#startmathblock(environment)
	if a:environment =~ '^\s*%.*%\s*$'
		"the current environment is saved in a variable for the close function
		"this is safe, because mathblocks can't be nested
		let s:cur_env = substitute(a:environment, '^\s*%\s*\(.*\)%$', '\1', '')
		return '\begin{' . s:cur_env . '}'
	else
		let s:cur_env = ''
		return '\['
	endif
endf

fu! vimwiki#vw2html#endmathblock(string)
	let str = substitute(a:string, '\r\s*}}$\s*\r$', '', '')
	if s:cur_env != ''
		return str . '\end{' . s:cur_env . '}'
	else
		return str . '\]'
	endif
endf

fu! vimwiki#vw2html#process_line(string)
	let list = matchlist(a:string, '\(.*\)\(' . g:vimwiki_rxWikiLink . '\)\(.*\)')
	if !empty(list)
		let url = matchstr(list[2], g:vimwiki_rxWikiLinkMatchUrl)
		let descr = matchstr(list[2], g:vimwiki_rxWikiLinkMatchDescr)
		let descr = (substitute(descr,'^\s*\(.*\)\s*$','\1','') != '' ? descr : url)
		let [idx, scheme, path, subdir, lnk, ext, url] = vimwiki#base#resolve_scheme(url, 1)
		let link = vimwiki#html#linkify_link(url, descr)

		return vimwiki#vw2html#process_line(list[1]) . link . s:process_wikiincl(list[3])
	else
		return s:process_wikiincl(a:string)
	endif
endf

fu! s:process_wikiincl(string)
	let list = matchlist(a:string, '\(.*\)\(' . g:vimwiki_rxWikiIncl . '\)\(.*\)')
	if !empty(list)
		let str = list[2]
		" custom transclusions
		let line = VimwikiWikiIncludeHandler(str)
		" otherwise, assume image transclusion
		if line == ''
		  let url_0 = matchstr(str, g:vimwiki_rxWikiInclMatchUrl)
		  let descr = matchstr(str, vimwiki#html#incl_match_arg(1))
		  let verbatim_str = matchstr(str, vimwiki#html#incl_match_arg(2))
		  " resolve url
		  let [idx, scheme, path, subdir, lnk, ext, url] = 
				\ vimwiki#base#resolve_scheme(url_0, 1)

		  " Issue 343: Image transclusions: schemeless links have .html appended.
		  " If link is schemeless pass it as it is
		  if scheme == ''
			let url = lnk
		  endif

		  let url = escape(url, '#')
		  let line = vimwiki#html#linkify_image(url, descr, verbatim_str)
		endif
		return s:process_wikiincl(list[1]) . line . s:process_weblink(list[3])
	else
		return s:process_weblink(a:string)
	endif
endf

fu! s:process_weblink(string)
	let list = matchlist(a:string, '\(.*\)\(' . g:vimwiki_rxWeblink . '\)\(.*\)')
	if !empty(list)
		let str = list[2]
		let url = matchstr(str, g:vimwiki_rxWeblinkMatchUrl)
		let descr = matchstr(str, g:vimwiki_rxWeblinkMatchDescr)
		let line = vimwiki#html#linkify_link(url, descr)
		return s:process_weblink(list[1]) . line . s:process_code(list[3])
	else
		return s:process_code(a:string)
	endif
endf

function! s:mid(value, cnt) "{{{
  return strpart(a:value, a:cnt, len(a:value) - 2 * a:cnt)
endfunction "}}}

function! s:safe_html_tags(line) "{{{
  let line = substitute(a:line,'<','\&lt;', 'g')
  let line = substitute(line,'>','\&gt;', 'g')
  return line
endfunction "}}}

fu! s:process_code(string)
	let list = matchlist(a:string, '\(.*\)\(' . g:vimwiki_rxCode . '\)\(.*\)')
	if !empty(list)
		let str = '<code>'.s:safe_html_tags(s:mid(list[2], 1)).'</code>'
		return s:process_code(list[1]) . str . s:process_eqin(list[3])
	else
		return s:process_eqin(a:string)
	endif
endf

fu! s:process_eqin(string)
	let list = matchlist(a:string, '\(.*\)\(' . g:vimwiki_rxEqIn . '\)\(.*\)')
	if !empty(list)
		" mathJAX wants \( \) for inline maths
		let str = '\('.s:mid(list[2], 1).'\)'
		return s:process_eqin(list[1]) . str . s:process_italic(list[3])
	else
		return s:process_italic(a:string)
	endif
endf

fu! s:process_italic(string)
	let list = matchlist(a:string, '\(.*\)\(' . g:vimwiki_rxItalic . '\)\(.*\)')
	if !empty(list)
		let str = '<em>'.s:mid(list[2], 1).'</em>'
		return s:process_italic(list[1]) . str . s:process_bold(list[3])
	else
		return s:process_bold(a:string)
	endif
endf

fu! s:process_bold(string)
	let list = matchlist(a:string, '\(.*\)\(' . g:vimwiki_rxBold . '\)\(.*\)')
	if !empty(list)
		let str = '<strong>'.s:mid(list[2], 1).'</strong>'
		return s:process_bold(list[1]) . str . s:process_todo(list[3])
	else
		return s:process_todo(a:string)
	endif
endf

fu! s:process_todo(string)
	let list = matchlist(a:string, '\(.*\)\(' . g:vimwiki_rxTodo . '\)\(.*\)')
	if !empty(list)
		let str = '<span class="todo">'.list[2].'</span>'
		return s:process_todo(list[1]) . str . s:process_deltext(list[3])
	else
		return s:process_deltext(a:string)
	endif
endf

fu! s:process_deltext(string)
	let list = matchlist(a:string, '\(.*\)\(' . g:vimwiki_rxDelText . '\)\(.*\)')
	if !empty(list)
		let str = '<del>'.s:mid(list[2], 2).'</del>'
		return s:process_deltext(list[1]) . str . s:process_super(list[3])
	else
		return s:process_super(a:string)
	endif
endf

fu! s:process_super(string)
	let list = matchlist(a:string, '\(.*\)\(' . g:vimwiki_rxSuperScript . '\)\(.*\)')
	if !empty(list)
		let str = '<sup><small>'.s:mid(list[2], 1).'</small></sup>'
		return s:process_super(list[1]) . str . s:process_sub(list[3])
	else
		return s:process_sub(a:string)
	endif
endf

fu! s:process_sub(string)
	let list = matchlist(a:string, '\(.*\)\(' . g:vimwiki_rxSubScript . '\)\(.*\)')
	if !empty(list)
		let str = '<sub><small>'.s:mid(list[2], 2).'</small></sub>'
		return s:process_sub(list[1]) . str . list[3]
	else
		return a:string
	endif
endf

function! vimwiki#vw2html#processplaceholder(string)
  let list = matchlist(a:string, '%\(\w\+\)\W*\(.*\)\r')
  let placeholder = list[1]
  let rest = list[2]
  if placeholder == 'title'
    let s:title = rest
  elseif placeholder == 'toc'
    let s:toc = rest
  elseif placeholder == 'template'
    let s:template = rest
  elseif placeholder == 'nohtml'
    echon "\r"."%nohtml placeholder found"
    call peggi#peggi#abort()
  endif
  return ''
endfunction

fu! vimwiki#vw2html#make_table(cells)
	function! s:makespaninfolist(length)
		let list = []
		for i in range(a:length)
			call add(list, [1,1])
		endfor
		return list
	endfunction
	
	let header_list = a:cells[0]
	let matrix_body = reverse(a:cells[1])

	let result = ['</table>']
	let spaninfo = s:makespaninfolist(len(matrix_body[0]))
	for line in matrix_body
		let old_spaninfo = spaninfo
		let spaninfo = s:makespaninfolist(len(line))
		for idx in range(len(spaninfo))
			let spaninfo[idx][0] = len(old_spaninfo) > idx ? old_spaninfo[idx][0] : 1
		endfor

		call add(result, '</tr>')
		for idx in range(len(line)-1, 0, -1)
			let cell = line[idx]
			if cell =~ '^\s*>\s*'
				if idx > 0
					let spaninfo[idx-1][1] = spaninfo[idx][1] + 1
				else
					call add(result, '<td></td>')
				endif
			elseif cell =~ '^\s*\\\/\s*'
				let spaninfo[idx][0] += 1
			else
				let htmlspaninfo = ''
				if spaninfo[idx][1] > 1
					let htmlspaninfo .= ' colspan="' . spaninfo[idx][1] . '"'
				endif
				if spaninfo[idx][0] > 1
					let htmlspaninfo .= ' rowspan="' . spaninfo[idx][0] . '"'
					let spaninfo[idx][0] = 1
				endif
				call add(result, '<td' . htmlspaninfo . '>'.vimwiki#vw2html#process_line(cell).'</td>')
			endif
		endfor
		call add(result, '<tr>')
	endfor
	call add(result, '<table>')
	return join(reverse(result), '')
endf

unlet! s:grammar
let s:grammar = '
			\ file = ((emptyline | header | hline | paragraph.tag("p"))°).applytemplate()
			\ emptyline = /\s*\r/.skip()
			\ header = /\s*\(=\{1,6}\)[^=][^\r]\{-}[^=]\1\s*\r/.header()
			\ hline = /-----*\r/.replace("<hr/>")
			\ paragraph = (table | list | preformatted_text | math_block | deflist | commentline | placeholder | ordinarytextline)+
			\ ordinarytextline = !emptyline !header !hline &> text
      \ placeholder = /%\(toc\|title\|nohtml\|template\)[^\r]*\r/.processplaceholder()
			\ commentline = /%%[^\r]*\r/.skip()
			\ text = /[^\r]*/.process_line() /\r/.breakorspace()
			\ 
			\ table = &> &bar (table_header? , table_block).make_table()                        { [''/[string,…], block] -> string }
			\ table_header = (table_header_line , (/\r/ table_div /\r/).skip()).take("0")       { [string, …] }
			\ table_block = (table_line , (/\r/.skip() , table_line).take("1")*).insertfirst()  { [[string, …], … ] }
			\ table_div = /|[-|]\+|/                                                            { string }
			\ table_header_line = (bar , (header_cell bar)#).take("1")                          { [string, …] }
			\ table_line = (bar , (body_cell bar)#).take("1")                                   { [string, …] }
			\ body_cell = /[^\r|]\+/.strip()                                                    { string }
			\ header_cell = /[^\r|]\+/.strip()                                                  { string }
			\ bar = /|/.skip()                                                                  { string }
			\ 
			\ list = &liststart (blist | rlist | Rlist | alist | Alist | nlist)
			\ blist = &bullet ((&> blist_item)+).tag("ul")
			\ rlist = &rstartnumber ((&> rlist_item)+).tag("ol")
			\ Rlist = &Rstartnumber ((&> Rlist_item)+).tag("ol")
			\ alist = &alphanumber ((&> alist_item)+).tag("ol")
			\ Alist = &Alphanumber ((&> Alist_item)+).tag("ol")
			\ nlist = &number ((&> nlist_item)+).tag("ol")
			\ blist_item^ = (bullet , checkbox?).checkbox("-") list_item_content
			\ rlist_item^ = (rnumber , checkbox?).checkbox("i") list_item_content
			\ Rlist_item^ = (Rnumber , checkbox?).checkbox("I") list_item_content
			\ alist_item^ = (alphanumber , checkbox?).checkbox("a") list_item_content
			\ Alist_item^ = (Alphanumber , checkbox?).checkbox("A") list_item_content
			\ nlist_item^ = (number , checkbox?).checkbox("1") list_item_content
			\ bullet = /\s*[-*#•]\s\+/
			\ rstartnumber = /\s*i\{1,3})\s\+/
			\ Rstartnumber = /\s*I\{1,3})\s\+/
			\ rnumber = /\s*[ivxlcdm]\+)\s\+/
			\ Rnumber = /\s*[IVXLCDM]\+)\s\+/
			\ alphanumber = /\s*\l\{1,2})\s\+/
			\ Alphanumber = /\s*\u\{1,2})\s\+/
			\ number = /\s*\d\+[.)]\s\+/
			\ liststart = /\s*\([-*#•]\|\d\+\.\|\d\+)\|[ivxlcdm]\+)\|[IVXLCDM]\+)\|\l\{1,2})\|\u\{1,2})\)\s\+/
			\ checkbox = "[".skip() /[ .oOX]/ /\]\s\+/.skip()
			\ list_item_content = text (&> paragraph)? (emptyline paragraph.tag("p"))°
			\ 
			\ preformatted_text = &> "{{{".saveindent() /[^\r]*/.startpre() /\r/.skip() /\_.\{-}\r\s*}}}\s*\r/.endpre()
			\ math_block = &> "{{$".skip() /[^\r]*/.startmathblock() /\r/.skip() /\_.\{-}\r\s*}}\$\s*\r/.endmathblock()
			\ 
			\ deflist = (&> deflist_item+).tag("dl")
			\ deflist_item^ = term (/\s\+/ short_definition)? /\r/.skip() (&>= long_definition)°
			\ term = /[^\r:]*[[:alnum:]][^\r:]*/.tag("dt") "::".skip()
			\ short_definition = /[^\r]\+/.tag("dd")
			\ long_definition^ = /::\s\+/.skip() list_item_content.tag("dd")
			\
			\'



fu! s:start(input_file, output_dir)
	call vimwiki#base#mkdir(a:output_dir)
	let s:filename_without_ext = fnamemodify(a:input_file, ':t:r')
	let output_path = a:output_dir . '/' . s:filename_without_ext .'.html'

	let g:peggi_debug = 0
	let g:peggi_transformation_prefix = 'vimwiki#vw2html#'
  let s:title = s:filename_without_ext
  let s:toc = 0
  let s:template = ''
	call writefile(split(peggi#peggi#parse_file(s:grammar, a:input_file, 'file'), '\\n'), output_path)
endf


function! s:use_custom_wiki2html() "{{{
  let custom_wiki2html = VimwikiGet('custom_wiki2html')
  return !empty(custom_wiki2html) && s:file_exists(custom_wiki2html)
endfunction " }}}


function! vimwiki#vw2html#CustomWiki2HTML(path, wikifile, force) "{{{
  call vimwiki#base#mkdir(a:path)
  echomsg system(VimwikiGet('custom_wiki2html'). ' '.
      \ a:force. ' '.
      \ VimwikiGet('syntax'). ' '.
      \ strpart(VimwikiGet('ext'), 1). ' '.
      \ shellescape(a:path, 1). ' '.
      \ shellescape(a:wikifile, 1). ' '.
      \ shellescape(s:default_CSS_full_name(a:path), 1). ' '.
      \ (len(VimwikiGet('template_path'))    > 1 ? shellescape(expand(VimwikiGet('template_path')), 1) : '-'). ' '.
      \ (len(VimwikiGet('template_default')) > 0 ? VimwikiGet('template_default')                      : '-'). ' '.
      \ (len(VimwikiGet('template_ext'))     > 0 ? VimwikiGet('template_ext')                          : '-'). ' '.
      \ (len(VimwikiGet('subdir'))           > 0 ? shellescape(s:root_path(VimwikiGet('subdir')), 1)   : '-'))
endfunction " }}}



function! vimwiki#vw2html#Wiki2HTML(path_html, wikifile) "{{{
	if VimwikiGet('syntax') != "default"
		echomsg 'vimwiki: conversion to HTML is not supported for this syntax!'
		return
	endif
	let starttime = reltime()
  let path_html = expand(a:path_html).VimwikiGet('subdir') 
  let wikifile = fnamemodify(a:wikifile, ":p")
	if s:use_custom_wiki2html()
		let force = 1
		call vimwiki#html#CustomWiki2HTML(path_html, wikifile, force)
	else
		call s:start(wikifile, path_html)
	endif
	let time1 = vimwiki#u#time(starttime)
endfunction "}}}


function! s:save_vimwiki_buffer() "{{{
  if &filetype == 'vimwiki'
    silent update
  endif
endfunction "}}}

function! s:syntax_supported() " {{{
  return VimwikiGet('syntax') == "default"
endfunction " }}}

function! vimwiki#vw2html#WikiAll2HTML(path_html) "{{{
	if !s:syntax_supported() && !s:use_custom_wiki2html()
		echomsg 'vimwiki: conversion to HTML is not supported for this syntax!'
		return
	endif
	let starttime = reltime()

	echomsg 'Saving vimwiki files...'
	let save_eventignore = &eventignore
	let &eventignore = "all"
	let cur_buf = bufname('%')
	bufdo call s:save_vimwiki_buffer()
	exe 'buffer '.cur_buf
	let &eventignore = save_eventignore

	let path_html = expand(a:path_html)
	call vimwiki#base#mkdir(path_html)

	echomsg 'Deleting non-wiki html files...'
	call s:delete_html_files(path_html)

	echomsg 'Converting wiki to html files...'
	let setting_more = &more
	setlocal nomore

	let wikifiles = split(glob(VimwikiGet('path').'**/*'.VimwikiGet('ext')), '\n')
	for wikifile in wikifiles
		let wikifile = fnamemodify(wikifile, ":p")

		let subdir = vimwiki#base#subdir(VimwikiGet('path'), wikifile)
    echom subdir
    let wikifile = wikifile . subdir

		if !s:is_html_uptodate(wikifile)
			echomsg 'Processing '.wikifile
			call s:start(wikifile, path_html)
		else
			echomsg 'Skipping '.wikifile
		endif
	endfor

	call s:create_default_CSS(path_html)
	echomsg 'Done!'

	let &more = setting_more
	let time1 = vimwiki#u#time(starttime)
	call VimwikiLog_extend('html',[htmlfile,time1])
endfunction "}}}

function! s:default_CSS_full_name(path) " {{{
  let path = expand(a:path)
  let css_full_name = path.'/'.VimwikiGet('css_name')
  return css_full_name
endfunction "}}}

function! s:create_default_CSS(path) " {{{
  let css_full_name = s:default_CSS_full_name(a:path)
  if glob(css_full_name) == ""
    call vimwiki#base#mkdir(fnamemodify(css_full_name, ':p:h'))
    let default_css = s:find_autoload_file('style.css')
    if default_css != ''
      let lines = readfile(default_css)
      call writefile(lines, css_full_name)
      echomsg "Default style.css has been created."
    endif
  endif
endfunction "}}}


function! s:find_autoload_file(name) " {{{
  for path in split(&runtimepath, ',')
    let fname = path.'/autoload/vimwiki/'.a:name
    if glob(fname) != ''
      return fname
    endif
  endfor
  return ''
endfunction " }}}


function! s:delete_html_files(path) "{{{
	let htmlfiles = split(glob(a:path.'**/*.html'), '\n')
	for fname in htmlfiles
		" ignore user html files, e.g. search.html,404.html
		if stridx(g:vimwiki_user_htmls, fnamemodify(fname, ":t")) >= 0
			continue
		endif

		" delete if there is no corresponding wiki file
		let subdir = vimwiki#base#subdir(VimwikiGet('path_html'), fname)
		let wikifile = VimwikiGet('path').subdir.
					\fnamemodify(fname, ":t:r").VimwikiGet('ext')
		if filereadable(wikifile)
			continue
		endif

		try
			call delete(fname)
		catch
			echomsg 'vimwiki: Cannot delete '.fname
		endtry
	endfor
endfunction "}}}

function! s:is_html_uptodate(wikifile) "{{{
	let tpl_time = -1

	let tpl_file = s:get_template('')
	if tpl_file != ''
		let tpl_time = getftime(tpl_file)
	endif

	let wikifile = fnamemodify(a:wikifile, ":p")
	let htmlfile = expand(VimwikiGet('path_html').VimwikiGet('subdir').
				\fnamemodify(wikifile, ":t:r").".html")

	if getftime(wikifile) <= getftime(htmlfile) && tpl_time <= getftime(htmlfile)
		return 1
	endif
	return 0
endfunction "}}}

function s:get_template(tpl_from_placeholder) "{{{
  let tpl_in_tplpath = 
        \ expand(VimwikiGet('template_path') .
        \ (a:tpl_from_placeholder != '' ? a:tpl_from_placeholder : VimwikiGet('template_default')) .
        \ VimwikiGet('template_ext'))

  return filereadable(tpl_in_tplpath) ? tpl_in_tplpath : s:find_autoload_file('default.tpl')
endfunction "}}}

function! s:root_path(subdir) "{{{
  return repeat('../', len(split(a:subdir, '[/\\]')))
endfunction "}}}

