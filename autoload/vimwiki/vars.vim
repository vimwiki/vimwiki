" vim:tabstop=2:shiftwidth=2:expandtab:textwidth=99
" Vimwiki autoload plugin file
" Desc: stuff concerning Vimwiki's state
" Home: https://github.com/vimwiki/vimwiki/


" copy the user's settings from variables of the form g:vimwiki_<option> into g:vimwiki_global_vars
" (or set a default value)
function! s:populate_global_variables()
  let g:vimwiki_global_vars = {
        \ 'CJK_length': 0,
        \ 'auto_chdir': 0,
        \ 'autowriteall': 1,
        \ 'conceallevel': 2,
        \ 'diary_months':
              \ {
              \ 1: 'January', 2: 'February', 3: 'March',
              \ 4: 'April', 5: 'May', 6: 'June',
              \ 7: 'July', 8: 'August', 9: 'September',
              \ 10: 'October', 11: 'November', 12: 'December'
              \ },
        \ 'dir_link': '',
        \ 'ext2syntax': {},
        \ 'folding': '',
        \ 'global_ext': 1,
        \ 'hl_cb_checked': 0,
        \ 'hl_headers': 0,
        \ 'html_header_numbering': 0,
        \ 'html_header_numbering_sym': '',
        \ 'list_ignore_newline': 1,
        \ 'listsyms': ' .oOX',
        \ 'map_prefix': '<Leader>w',
        \ 'menu': 'Vimwiki',
        \ 'table_auto_fmt': 1,
        \ 'table_mappings': 1,
        \ 'toc_header': 'Contents',
        \ 'url_maxsave': 15,
        \ 'use_calendar': 1,
        \ 'use_mouse': 0,
        \ 'user_htmls': '',
        \ 'valid_html_tags': 'b,i,s,u,sub,sup,kbd,br,hr,div,center,strong,em',
        \ 'w32_dir_enc': '',
        \ }

  for key in keys(g:vimwiki_global_vars)
    if exists('g:vimwiki_'.key)
      let g:vimwiki_global_vars[key] = g:vimwiki_{key}
    endif
  endfor

  " non-configurable global variables

  " Scheme regexes should be defined even if syntax file is not loaded yet cause users should be
  " able to <leader>w<leader>w without opening any vimwiki file first
  let g:vimwiki_global_vars['schemes'] = 'wiki\d\+,diary,local'
  let g:vimwiki_global_vars['web_schemes1'] = 'http,https,file,ftp,gopher,telnet,nntp,ldap,rsync'.
        \ ',imap,pop,irc,ircs,cvs,svn,svn+ssh,git,ssh,fish,sftp'
  let web_schemes2 = 'mailto,news,xmpp,sip,sips,doi,urn,tel'

  let rx_schemes = '\%('.
        \ join(split(g:vimwiki_global_vars['schemes'], '\s*,\s*'), '\|').'\|'.
        \ join(split(g:vimwiki_global_vars['web_schemes1'], '\s*,\s*'), '\|').'\|'.
        \ join(split(web_schemes2, '\s*,\s*'), '\|').
        \ '\)'

  let g:vimwiki_global_vars['rxSchemeUrl'] = rx_schemes.':.*'
  let g:vimwiki_global_vars['rxSchemeUrlMatchScheme'] = '\zs'.rx_schemes.'\ze:.*'
  let g:vimwiki_global_vars['rxSchemeUrlMatchUrl'] = rx_schemes.':\zs.*\ze'

  " match URL for common protocols; see http://en.wikipedia.org/wiki/URI_scheme
  " http://tools.ietf.org/html/rfc3986
  let rxWebProtocols =
        \ '\%('.
          \ '\%('.
            \ '\%('.join(split(g:vimwiki_global_vars['web_schemes1'], '\s*,\s*'), '\|').'\):'.
            \ '\%(//\)'.
          \ '\)'.
        \ '\|'.
          \ '\%('.join(split(web_schemes2, '\s*,\s*'), '\|').'\):'.
        \ '\)'

  let g:vimwiki_global_vars['rxWeblinkUrl'] = rxWebProtocols . '\S\{-1,}'. '\%(([^ \t()]*)\)\='
endfunction


function! s:normalize_path(path) "{{{
  " trim trailing / and \ because otherwise resolve() doesn't work quite right
  let path = substitute(a:path, '[/\\]\+$', '', '')
  if path !~# '^scp:'
    return resolve(expand(path)).'/'
  else
    return path.'/'
  endif
endfunction "}}}


" g:vimwiki_wikilocal_vars is a list of dictionaries. One dict for every registered wiki. The last
" dictionary contains default values (used for temporary wikis)
function! s:populate_wikilocal_options()
  let default_values = {
        \ 'auto_export': 0,
        \ 'auto_tags': 0,
        \ 'auto_toc': 0,
        \ 'css_name': 'style.css',
        \ 'custom_wiki2html': '',
        \ 'diary_header': 'Diary',
        \ 'diary_index': 'diary',
        \ 'diary_rel_path': 'diary/',
        \ 'diary_sort': 'desc',
        \ 'ext': '.wiki',
        \ 'index': 'index',
        \ 'list_margin': -1,
        \ 'maxhi': 0,
        \ 'nested_syntaxes': {},
        \ 'path': '~/vimwiki/',
        \ 'path_html': '',
        \ 'syntax': 'default',
        \ 'template_default': 'default',
        \ 'template_ext': '.tpl',
        \ 'template_path': '~/vimwiki/templates/',
        \ }

  let g:vimwiki_wikilocal_vars = []

  if exists('g:vimwiki_list')
    for users_options in g:vimwiki_list
      let new_options_dict = {}
      for key in keys(default_values)
        if has_key(users_options, key)
          let new_options_dict[key] = users_options[key]
        elseif exists('g:vimwiki_'.key)
          let new_options_dict[key] = g:vimwiki_{key}
        else
          let new_options_dict[key] = default_values[key]
        endif
      endfor
      call add(g:vimwiki_wikilocal_vars, new_options_dict)
    endfor
  endif

  " default values for temporary wikis
  let temporary_options_dict = {}
  for key in keys(default_values)
    if exists('g:vimwiki_'.key)
      let temporary_options_dict[key] = g:vimwiki_{key}
    else
      let temporary_options_dict[key] = default_values[key]
    endif
  endfor
  call add(g:vimwiki_wikilocal_vars, default_values)

  call s:validate_options()
endfunction


function! s:validate_options()
  for options_dict in g:vimwiki_wikilocal_vars
    let options_dict['path'] = s:normalize_path(options_dict['path'])

    let path_html = options_dict['path_html']
    if !empty(path_html)
      let options_dict['path_html'] = s:normalize_path(path_html)
    else
      let options_dict['path_html'] = s:normalize_path(
            \ substitute(options_dict['path'], '[/\\]\+$', '', '').'_html/')
    endif

    let options_dict['template_path'] =  s:normalize_path(options_dict['template_path'])
    let options_dict['diary_rel_path'] =  s:normalize_path(options_dict['diary_rel_path'])
  endfor
endfunction


" TODO
function! s:populate_syntax_vars(syntax)
  if !exists('g:vimwiki_syntax_variables')
    let g:vimwiki_syntax_variables = {}
  endif
endfunction


function! vimwiki#vars#init()
  call s:populate_global_variables()
  call s:populate_wikilocal_options()
endfunction


function! vimwiki#vars#get_syntaxlocal(syntax, key)
  if !exists('g:vimwiki_syntax_variables') || !has_key(g:vimwiki_syntax_variables, a:syntax)
    call s:populate_syntax_vars(a:syntax)
  endif

  return g:vimwiki_syntax_variables[a:syntax][a:key]
endfunction


" Get a variable for the buffer we are currently in.
" Populate the variable, if it doesn't exist.
function! vimwiki#vars#get_bufferlocal(key)
  if exists('b:vimwiki_'.a:key)
    return b:vimwiki_{a:key}
  elseif a:key ==# 'wiki_nr'
    let b:vimwiki_wiki_nr = vimwiki#base#find_wiki(expand('%:p'))
    return b:vimwiki_wiki_nr
  endif
endfunction


function! vimwiki#vars#set_buffer_var(key, value)
  let b:vimwiki_{a:key} = a:value
endfunction


function! vimwiki#vars#get_global(key)
  return g:vimwiki_global_vars[a:key]
endfunction


" the second argument can be a wiki number. When absent, the wiki of the currently active buffer is
" used
function! vimwiki#vars#get_wikilocal(key, ...)
  if a:0
    return g:vimwiki_wikilocal_vars[a:1][a:key]
  else
    return g:vimwiki_wikilocal_vars[vimwiki#vars#get_bufferlocal('wiki_nr')][a:key]
  endif
endfunction


function! vimwiki#vars#set_wikilocal(key, value, wiki_nr)
  if a:wiki_nr == len(g:vimwiki_wikilocal_vars) - 1
    call insert(g:vimwiki_wikilocal_vars, {}, -1)
  endif
  let g:vimwiki_wikilocal_vars[a:wiki_nr][a:key] = a:value
endfunction


" number of registered wikis + temporary
function! vimwiki#vars#number_of_wikis()
  return len(g:vimwiki_wikilocal_vars) - 1
endfunction
