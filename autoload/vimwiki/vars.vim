" vim:tabstop=2:shiftwidth=2:expandtab:textwidth=99
" Vimwiki autoload plugin file
" Home: https://github.com/vimwiki/vimwiki/



" ------------------------------------------------------------------------------------------------
" This file provides functions to manage the various state variables which are needed during a
" Vimwiki session.
" They consist of:
"
" - global variables. These are stored in the dict g:vimwiki_global_vars. They consist mainly of
"   global user variables and syntax stuff which is the same for every syntax.
"
" - wiki-local variables. They are stored in g:vimwiki_wikilocal_vars which is a list of
"   dictionaries. One dict for every registered wiki. The last dictionary contains default values
"   (used for temporary wikis).
"
" - syntax variables. Stored in the dict g:vimwiki_syntax_variables which holds all the regexes and
"   other stuff which is needed for highlighting.
"
" - buffer-local variables. They are stored as buffer variables directly (b:foo)

" As a developer, you should, if possible, only use the get_ and set_ functions for these types of
" variables, not the underlying dicts!
" ------------------------------------------------------------------------------------------------


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
        \ 'text_ignore_newline': 1,
        \ 'listsyms': ' .oOX',
        \ 'listsym_rejected': '-',
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

  " copy the user's settings from variables of the form g:vimwiki_<option> into the dict
  " g:vimwiki_global_vars (or set a default value)
  for key in keys(g:vimwiki_global_vars)
    if exists('g:vimwiki_'.key)
      let g:vimwiki_global_vars[key] = g:vimwiki_{key}
    endif
  endfor

  " non-configurable global variables:

  " Scheme regexes must be defined even if syntax file is not loaded yet cause users should be
  " able to <leader>w<leader>w without opening any vimwiki file first
  let g:vimwiki_global_vars.schemes = join(['wiki\d\+', 'diary', 'local'], '\|')
  let g:vimwiki_global_vars.web_schemes1 = join(['http', 'https', 'file', 'ftp', 'gopher',
        \ 'telnet', 'nntp', 'ldap', 'rsync', 'imap', 'pop', 'irc', 'ircs', 'cvs', 'svn', 'svn+ssh',
        \ 'git', 'ssh', 'fish', 'sftp'], '\|')
  let web_schemes2 =
        \ join(['mailto', 'news', 'xmpp', 'sip', 'sips', 'doi', 'urn', 'tel', 'data'], '\|')

  let g:vimwiki_global_vars.rxSchemes = '\%('.
        \ g:vimwiki_global_vars.schemes . '\|'.
        \ g:vimwiki_global_vars.web_schemes1 . '\|'.
        \ web_schemes2 .
        \ '\)'

  " match URL for common protocols; see http://en.wikipedia.org/wiki/URI_scheme
  " http://tools.ietf.org/html/rfc3986
  let rxWebProtocols =
        \ '\%('.
          \ '\%('.
            \ '\%('.g:vimwiki_global_vars.web_schemes1 . '\):'.
            \ '\%(//\)'.
          \ '\)'.
        \ '\|'.
          \ '\%('.web_schemes2.'\):'.
        \ '\)'

  let g:vimwiki_global_vars.rxWeblinkUrl = rxWebProtocols . '\S\{-1,}'. '\%(([^ \t()]*)\)\='

  let wikilink_prefix = '[['
  let wikilink_suffix = ']]'
  let wikilink_separator = '|'
  let g:vimwiki_global_vars.rx_wikilink_prefix = vimwiki#u#escape(wikilink_prefix)
  let g:vimwiki_global_vars.rx_wikilink_suffix = vimwiki#u#escape(wikilink_suffix)
  let g:vimwiki_global_vars.rx_wikilink_separator = vimwiki#u#escape(wikilink_separator)

  " templates for the creation of wiki links
  " [[URL]]
  let g:vimwiki_global_vars.WikiLinkTemplate1 = wikilink_prefix . '__LinkUrl__'. wikilink_suffix
  " [[URL|DESCRIPTION]]
  let g:vimwiki_global_vars.WikiLinkTemplate2 = wikilink_prefix . '__LinkUrl__'. wikilink_separator
        \ . '__LinkDescription__' . wikilink_suffix

  let valid_chars = '[^\\\]]'
  let g:vimwiki_global_vars.rxWikiLinkUrl = valid_chars.'\{-}'
  let g:vimwiki_global_vars.rxWikiLinkDescr = valid_chars.'\{-}'

  " this regexp defines what can form a link when the user presses <CR> in the
  " buffer (and not on a link) to create a link
  " basically, it's Ascii alphanumeric characters plus #|./@-_~ plus all
  " non-Ascii characters, except that . is not accepted as the last character
  let g:vimwiki_global_vars.rxWord = '[^[:blank:]!"$%&''()*+,:;<=>?\[\]\\^`{}]*[^[:blank:]!"$%&''()*+.,:;<=>?\[\]\\^`{}]'

  let g:vimwiki_global_vars.rx_wikilink_prefix1 = g:vimwiki_global_vars.rx_wikilink_prefix .
        \ g:vimwiki_global_vars.rxWikiLinkUrl . g:vimwiki_global_vars.rx_wikilink_separator
  let g:vimwiki_global_vars.rx_wikilink_suffix1 = g:vimwiki_global_vars.rx_wikilink_suffix

  let g:vimwiki_global_vars.rxWikiInclPrefix = '{{'
  let g:vimwiki_global_vars.rxWikiInclSuffix = '}}'
  let g:vimwiki_global_vars.rxWikiInclSeparator = '|'
  " '{{__LinkUrl__}}'
  let g:vimwiki_global_vars.WikiInclTemplate1 = g:vimwiki_global_vars.rxWikiInclPrefix
        \ .'__LinkUrl__'. g:vimwiki_global_vars.rxWikiInclSuffix
  " '{{__LinkUrl____LinkDescription__}}'
  let g:vimwiki_global_vars.WikiInclTemplate2 = g:vimwiki_global_vars.rxWikiInclPrefix
        \ . '__LinkUrl__' . g:vimwiki_global_vars.rxWikiInclSeparator . '__LinkDescription__'
        \ . g:vimwiki_global_vars.rxWikiInclSuffix

  let valid_chars = '[^\\\}]'
  let g:vimwiki_global_vars.rxWikiInclUrl = valid_chars.'\{-}'
  let g:vimwiki_global_vars.rxWikiInclArg = valid_chars.'\{-}'
  let g:vimwiki_global_vars.rxWikiInclArgs = '\%('. g:vimwiki_global_vars.rxWikiInclSeparator.
        \ g:vimwiki_global_vars.rxWikiInclArg. '\)'.'\{-}'

  " *. {{URL}[{...}]}  - i.e.  {{URL}}, {{URL|ARG1}}, {{URL|ARG1|ARG2}}, etc.
  " *a) match {{URL}[{...}]}
  let g:vimwiki_global_vars.rxWikiIncl = g:vimwiki_global_vars.rxWikiInclPrefix.
        \ g:vimwiki_global_vars.rxWikiInclUrl.
        \ g:vimwiki_global_vars.rxWikiInclArgs. g:vimwiki_global_vars.rxWikiInclSuffix
  " *b) match URL within {{URL}[{...}]}
  let g:vimwiki_global_vars.rxWikiInclMatchUrl = g:vimwiki_global_vars.rxWikiInclPrefix.
        \ '\zs'. g:vimwiki_global_vars.rxWikiInclUrl . '\ze'.
        \ g:vimwiki_global_vars.rxWikiInclArgs . g:vimwiki_global_vars.rxWikiInclSuffix

  let g:vimwiki_global_vars.rxWikiInclPrefix1 = g:vimwiki_global_vars.rxWikiInclPrefix.
        \ g:vimwiki_global_vars.rxWikiInclUrl . g:vimwiki_global_vars.rxWikiInclSeparator
  let g:vimwiki_global_vars.rxWikiInclSuffix1 = g:vimwiki_global_vars.rxWikiInclArgs.
        \ g:vimwiki_global_vars.rxWikiInclSuffix

  let g:vimwiki_global_vars.rxTodo = '\C\<\%(TODO\|DONE\|STARTED\|FIXME\|FIXED\|XXX\)\>'

  " default colors when headers of different levels are highlighted differently
  " not making it yet another option; needed by ColorScheme autocommand
  let g:vimwiki_global_vars.hcolor_guifg_light = ['#aa5858', '#507030', '#1030a0', '#103040'
        \ , '#505050', '#636363']
  let g:vimwiki_global_vars.hcolor_ctermfg_light = ['DarkRed', 'DarkGreen', 'DarkBlue', 'Black'
        \ , 'Black', 'Black']
  let g:vimwiki_global_vars.hcolor_guifg_dark = ['#e08090', '#80e090', '#6090e0', '#c0c0f0'
        \ , '#e0e0f0', '#f0f0f0']
  let g:vimwiki_global_vars.hcolor_ctermfg_dark = ['Red', 'Green', 'Blue', 'White', 'White'
        \ , 'White']
endfunction


function! s:populate_wikilocal_options()
  let default_values = {
        \ 'auto_export': 0,
        \ 'auto_tags': 0,
        \ 'auto_toc': 0,
        \ 'automatic_nested_syntaxes': 1,
        \ 'css_name': 'style.css',
        \ 'custom_wiki2html': '',
        \ 'custom_wiki2html_args': '',
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

  let default_wiki_settings = {}
  for key in keys(default_values)
    if exists('g:vimwiki_'.key)
      let default_wiki_settings[key] = g:vimwiki_{key}
    else
      let default_wiki_settings[key] = default_values[key]
    endif
  endfor

  " set the wiki-local variables according to g:vimwiki_list (or the default settings)
  if exists('g:vimwiki_list')
    for users_wiki_settings in g:vimwiki_list
      let new_wiki_settings = {}
      for key in keys(default_values)
        if has_key(users_wiki_settings, key)
          let new_wiki_settings[key] = users_wiki_settings[key]
        elseif exists('g:vimwiki_'.key)
          let new_wiki_settings[key] = g:vimwiki_{key}
        else
          let new_wiki_settings[key] = default_values[key]
        endif
      endfor

      let new_wiki_settings.is_temporary_wiki = 0

      call add(g:vimwiki_wikilocal_vars, new_wiki_settings)
    endfor
  else
    " if the user hasn't registered any wiki, we register one wiki using the default values
    let new_wiki_settings = deepcopy(default_wiki_settings)
    let new_wiki_settings.is_temporary_wiki = 0
    call add(g:vimwiki_wikilocal_vars, new_wiki_settings)
  endif

  " default values for temporary wikis
  let temporary_wiki_settings = deepcopy(default_wiki_settings)
  let temporary_wiki_settings.is_temporary_wiki = 1
  call add(g:vimwiki_wikilocal_vars, temporary_wiki_settings)

  call s:validate_settings()
endfunction


function! s:validate_settings()
  for wiki_settings in g:vimwiki_wikilocal_vars
    let wiki_settings['path'] = s:normalize_path(wiki_settings['path'])

    let path_html = wiki_settings['path_html']
    if !empty(path_html)
      let wiki_settings['path_html'] = s:normalize_path(path_html)
    else
      let wiki_settings['path_html'] = s:normalize_path(
            \ substitute(wiki_settings['path'], '[/\\]\+$', '', '').'_html/')
    endif

    let wiki_settings['template_path'] =  s:normalize_path(wiki_settings['template_path'])
    let wiki_settings['diary_rel_path'] =  s:normalize_path(wiki_settings['diary_rel_path'])
  endfor
endfunction


function! s:normalize_path(path)
  " trim trailing / and \ because otherwise resolve() doesn't work quite right
  let path = substitute(a:path, '[/\\]\+$', '', '')
  if path !~# '^scp:'
    return resolve(expand(path)).'/'
  else
    return path.'/'
  endif
endfunction


function! vimwiki#vars#populate_syntax_vars(syntax)
  if !exists('g:vimwiki_syntax_variables')
    let g:vimwiki_syntax_variables = {}
  endif

  if has_key(g:vimwiki_syntax_variables, a:syntax)
    return
  endif

  let g:vimwiki_syntax_variables[a:syntax] = {}

  execute 'runtime! syntax/vimwiki_'.a:syntax.'.vim'

  " generic stuff
  let header_symbol = g:vimwiki_syntax_variables[a:syntax].rxH
  if g:vimwiki_syntax_variables[a:syntax].symH
    " symmetric headers
    for i in range(1,6)
      let g:vimwiki_syntax_variables[a:syntax]['rxH'.i.'_Template'] =
            \ repeat(header_symbol, i).' __Header__ '.repeat(header_symbol, i)
      let g:vimwiki_syntax_variables[a:syntax]['rxH'.i] =
            \ '^\s*'.header_symbol.'\{'.i.'}[^'.header_symbol.'].*[^'.header_symbol.']'
            \ .header_symbol.'\{'.i.'}\s*$'
      let g:vimwiki_syntax_variables[a:syntax]['rxH'.i.'_Start'] =
            \ '^\s*'.header_symbol.'\{'.i.'}[^'.header_symbol.'].*[^'.header_symbol.']'
            \ .header_symbol.'\{'.i.'}\s*$'
      let g:vimwiki_syntax_variables[a:syntax]['rxH'.i.'_End'] =
            \ '^\s*'.header_symbol.'\{1,'.i.'}[^'.header_symbol.'].*[^'.header_symbol.']'
            \ .header_symbol.'\{1,'.i.'}\s*$'
    endfor
    let g:vimwiki_syntax_variables[a:syntax].rxHeader =
          \ '^\s*\('.header_symbol.'\{1,6}\)\zs[^'.header_symbol.'].*[^'.header_symbol.']\ze\1\s*$'
  else
    " asymmetric
    for i in range(1,6)
      let g:vimwiki_syntax_variables[a:syntax]['rxH'.i.'_Template'] =
            \ repeat(header_symbol, i).' __Header__'
      let g:vimwiki_syntax_variables[a:syntax]['rxH'.i] =
            \ '^\s*'.header_symbol.'\{'.i.'}[^'.header_symbol.'].*$'
      let g:vimwiki_syntax_variables[a:syntax]['rxH'.i.'_Start'] =
            \ '^\s*'.header_symbol.'\{'.i.'}[^'.header_symbol.'].*$'
      let g:vimwiki_syntax_variables[a:syntax]['rxH'.i.'_End'] =
            \ '^\s*'.header_symbol.'\{1,'.i.'}[^'.header_symbol.'].*$'
    endfor
    let g:vimwiki_syntax_variables[a:syntax].rxHeader =
          \ '^\s*\('.header_symbol.'\{1,6}\)\zs[^'.header_symbol.'].*\ze$'
  endif

  let g:vimwiki_syntax_variables[a:syntax].rxPreStart =
        \ '^\s*'.g:vimwiki_syntax_variables[a:syntax].rxPreStart
  let g:vimwiki_syntax_variables[a:syntax].rxPreEnd =
        \ '^\s*'.g:vimwiki_syntax_variables[a:syntax].rxPreEnd.'\s*$'

  let g:vimwiki_syntax_variables[a:syntax].rxMathStart =
        \ '^\s*'.g:vimwiki_syntax_variables[a:syntax].rxMathStart
  let g:vimwiki_syntax_variables[a:syntax].rxMathEnd =
        \ '^\s*'.g:vimwiki_syntax_variables[a:syntax].rxMathEnd.'\s*$'

  " list stuff
  let g:vimwiki_syntax_variables[a:syntax].rx_bullet_chars =
        \ '['.join(g:vimwiki_syntax_variables[a:syntax].bullet_types, '').']\+'

  let g:vimwiki_syntax_variables[a:syntax].multiple_bullet_chars =
        \ g:vimwiki_syntax_variables[a:syntax].recurring_bullets
        \ ? g:vimwiki_syntax_variables[a:syntax].bullet_types : []

  let g:vimwiki_syntax_variables[a:syntax].number_kinds = []
  let g:vimwiki_syntax_variables[a:syntax].number_divisors = ''
  for i in g:vimwiki_syntax_variables[a:syntax].number_types
    call add(g:vimwiki_syntax_variables[a:syntax].number_kinds, i[0])
    let g:vimwiki_syntax_variables[a:syntax].number_divisors .= vimwiki#u#escape(i[1])
  endfor

  let char_to_rx = {'1': '\d\+', 'i': '[ivxlcdm]\+', 'I': '[IVXLCDM]\+',
        \ 'a': '\l\{1,2}', 'A': '\u\{1,2}'}

  "create regexp for bulleted list items
  if !empty(g:vimwiki_syntax_variables[a:syntax].bullet_types)
    let g:vimwiki_syntax_variables[a:syntax].rxListBullet =
          \ join( map(g:vimwiki_syntax_variables[a:syntax].bullet_types,
          \'vimwiki#u#escape(v:val).'
          \ .'repeat("\\+", g:vimwiki_syntax_variables[a:syntax].recurring_bullets)'
          \ ) , '\|')
  else
    "regex that matches nothing
    let g:vimwiki_syntax_variables[a:syntax].rxListBullet = '$^'
  endif

  "create regex for numbered list items
  if !empty(g:vimwiki_syntax_variables[a:syntax].number_types)
    let g:vimwiki_syntax_variables[a:syntax].rxListNumber = '\C\%('
    for type in g:vimwiki_syntax_variables[a:syntax].number_types[:-2]
      let g:vimwiki_syntax_variables[a:syntax].rxListNumber .= char_to_rx[type[0]] .
            \ vimwiki#u#escape(type[1]) . '\|'
    endfor
    let g:vimwiki_syntax_variables[a:syntax].rxListNumber .=
          \ char_to_rx[g:vimwiki_syntax_variables[a:syntax].number_types[-1][0]].
          \ vimwiki#u#escape(g:vimwiki_syntax_variables[a:syntax].number_types[-1][1]) . '\)'
  else
    "regex that matches nothing
    let g:vimwiki_syntax_variables[a:syntax].rxListNumber = '$^'
  endif

  "the user can set the listsyms as string, but vimwiki needs a list
  let g:vimwiki_syntax_variables[a:syntax].listsyms_list =
        \ split(vimwiki#vars#get_global('listsyms'), '\zs')
  if match(vimwiki#vars#get_global('listsyms'), vimwiki#vars#get_global('listsym_rejected')) != -1
    echomsg 'Vimwiki Warning: the value of g:vimwiki_listsym_rejected ('''
          \ . vimwiki#vars#get_global('listsym_rejected')
          \ . ''') must not be a part of g:vimwiki_listsyms (''' .
          \ . vimwiki#vars#get_global('listsyms') . ''')'
  endif
  let g:vimwiki_syntax_variables[a:syntax].rxListItemWithoutCB =
        \ '^\s*\%(\('.g:vimwiki_syntax_variables[a:syntax].rxListBullet.'\)\|\('
        \ .g:vimwiki_syntax_variables[a:syntax].rxListNumber.'\)\)\s'
  let g:vimwiki_syntax_variables[a:syntax].rxListItem =
        \ g:vimwiki_syntax_variables[a:syntax].rxListItemWithoutCB
        \ . '\+\%(\[\(['.vimwiki#vars#get_global('listsyms')
        \ . vimwiki#vars#get_global('listsym_rejected').']\)\]\s\)\?'
  if g:vimwiki_syntax_variables[a:syntax].recurring_bullets
    let g:vimwiki_syntax_variables[a:syntax].rxListItemAndChildren =
          \ '^\('.g:vimwiki_syntax_variables[a:syntax].rxListBullet.'\)\s\+\[['
          \ . g:vimwiki_syntax_variables[a:syntax].listsyms_list[-1]
          \ . vimwiki#vars#get_global('listsym_rejected') . ']\]\s.*\%(\n\%(\1\%('
          \ .g:vimwiki_syntax_variables[a:syntax].rxListBullet.'\).*\|^$\|\s.*\)\)*'
  else
    let g:vimwiki_syntax_variables[a:syntax].rxListItemAndChildren =
          \ '^\(\s*\)\%('.g:vimwiki_syntax_variables[a:syntax].rxListBullet.'\|'
          \ . g:vimwiki_syntax_variables[a:syntax].rxListNumber.'\)\s\+\[['
          \ . g:vimwiki_syntax_variables[a:syntax].listsyms_list[-1]
          \ . vimwiki#vars#get_global('listsym_rejected') . ']\]\s.*\%(\n\%(\1\s.*\|^$\)\)*'
  endif

  " 0. URL : free-standing links: keep URL UR(L) strip trailing punct: URL; URL) UR(L))
  " let g:vimwiki_rxWeblink = '[\["(|]\@<!'. g:vimwiki_rxWeblinkUrl .
  " \ '\%([),:;.!?]\=\%([ \t]\|$\)\)\@='
  let g:vimwiki_syntax_variables[a:syntax].rxWeblink =
        \ '\<'. g:vimwiki_global_vars.rxWeblinkUrl . '\S*'
  " 0a) match URL within URL
  let g:vimwiki_syntax_variables[a:syntax].rxWeblinkMatchUrl =
        \ g:vimwiki_syntax_variables[a:syntax].rxWeblink
  " 0b) match DESCRIPTION within URL
  let g:vimwiki_syntax_variables[a:syntax].rxWeblinkMatchDescr = ''

  " template for matching all wiki links with a given target file
  let g:vimwiki_syntax_variables[a:syntax].WikiLinkMatchUrlTemplate =
        \ g:vimwiki_global_vars.rx_wikilink_prefix .
        \ '\zs__LinkUrl__\ze\%(#.*\)\?' .
        \ g:vimwiki_global_vars.rx_wikilink_suffix .
        \ '\|' .
        \ g:vimwiki_global_vars.rx_wikilink_prefix .
        \ '\zs__LinkUrl__\ze\%(#.*\)\?' .
        \ g:vimwiki_global_vars.rx_wikilink_separator .
        \ '.*' .
        \ g:vimwiki_global_vars.rx_wikilink_suffix

  " a) match [[URL|DESCRIPTION]]
  let g:vimwiki_syntax_variables[a:syntax].rxWikiLink = g:vimwiki_global_vars.rx_wikilink_prefix.
        \ g:vimwiki_global_vars.rxWikiLinkUrl.'\%('.g:vimwiki_global_vars.rx_wikilink_separator.
        \ g:vimwiki_global_vars.rxWikiLinkDescr.'\)\?'.g:vimwiki_global_vars.rx_wikilink_suffix
  let g:vimwiki_syntax_variables[a:syntax].rxAnyLink =
        \ g:vimwiki_syntax_variables[a:syntax].rxWikiLink.'\|'.
        \ g:vimwiki_global_vars.rxWikiIncl.'\|'.g:vimwiki_syntax_variables[a:syntax].rxWeblink
  " b) match URL within [[URL|DESCRIPTION]]
  let g:vimwiki_syntax_variables[a:syntax].rxWikiLinkMatchUrl =
        \ g:vimwiki_global_vars.rx_wikilink_prefix . '\zs'. g:vimwiki_global_vars.rxWikiLinkUrl
        \ .'\ze\%('. g:vimwiki_global_vars.rx_wikilink_separator
        \ . g:vimwiki_global_vars.rxWikiLinkDescr.'\)\?'.g:vimwiki_global_vars.rx_wikilink_suffix
  " c) match DESCRIPTION within [[URL|DESCRIPTION]]
  let g:vimwiki_syntax_variables[a:syntax].rxWikiLinkMatchDescr =
        \ g:vimwiki_global_vars.rx_wikilink_prefix . g:vimwiki_global_vars.rxWikiLinkUrl
        \ . g:vimwiki_global_vars.rx_wikilink_separator.'\%(\zs'
        \ . g:vimwiki_global_vars.rxWikiLinkDescr. '\ze\)\?'
        \ . g:vimwiki_global_vars.rx_wikilink_suffix

  if a:syntax ==# 'markdown'
    call s:populate_extra_markdown_vars()
  endif
endfunction


function! s:populate_extra_markdown_vars()
  let mkd_syntax = g:vimwiki_syntax_variables['markdown']

  " 0a) match [[URL|DESCRIPTION]]
  let mkd_syntax.rxWikiLink0 = mkd_syntax.rxWikiLink
  " 0b) match URL within [[URL|DESCRIPTION]]
  let mkd_syntax.rxWikiLink0MatchUrl = mkd_syntax.rxWikiLinkMatchUrl
  " 0c) match DESCRIPTION within [[URL|DESCRIPTION]]
  let mkd_syntax.rxWikiLink0MatchDescr = mkd_syntax.rxWikiLinkMatchDescr

  let wikilink_md_prefix = '['
  let wikilink_md_suffix = ']'
  let wikilink_md_separator = ']['
  let rx_wikilink_md_separator = vimwiki#u#escape(wikilink_md_separator)
  let mkd_syntax.rx_wikilink_md_prefix = vimwiki#u#escape(wikilink_md_prefix)
  let mkd_syntax.rx_wikilink_md_suffix = vimwiki#u#escape(wikilink_md_suffix)

  " [URL][]
  let mkd_syntax.WikiLink1Template1 = wikilink_md_prefix . '__LinkUrl__'.
        \ wikilink_md_separator. wikilink_md_suffix
  " [DESCRIPTION][URL]
  let mkd_syntax.WikiLink1Template2 = wikilink_md_prefix. '__LinkDescription__'.
        \ wikilink_md_separator. '__LinkUrl__'. wikilink_md_suffix
  let mkd_syntax.WikiLinkMatchUrlTemplate .=
        \ '\|' .
        \ mkd_syntax.rx_wikilink_md_prefix .
        \ '.*' .
        \ rx_wikilink_md_separator .
        \ '\zs__LinkUrl__\ze\%(#.*\)\?' .
        \ mkd_syntax.rx_wikilink_md_suffix .
        \ '\|' .
        \ mkd_syntax.rx_wikilink_md_prefix .
        \ '\zs__LinkUrl__\ze\%(#.*\)\?' .
        \ rx_wikilink_md_separator .
        \ mkd_syntax.rx_wikilink_md_suffix

  let valid_chars = '[^\\\[\]]'
  let mkd_syntax.rxWikiLink1Url = valid_chars.'\{-}'
  let mkd_syntax.rxWikiLink1Descr = valid_chars.'\{-}'
  let mkd_syntax.rxWikiLink1InvalidPrefix = '[\]\[]\@<!'
  let mkd_syntax.rxWikiLink1InvalidSuffix = '[\]\[]\@!'
  let mkd_syntax.rx_wikilink_md_prefix = mkd_syntax.rxWikiLink1InvalidPrefix.
        \ mkd_syntax.rx_wikilink_md_prefix
  let mkd_syntax.rx_wikilink_md_suffix = mkd_syntax.rx_wikilink_md_suffix.
        \ mkd_syntax.rxWikiLink1InvalidSuffix

  " 1. match [URL][], [DESCRIPTION][URL]
  let mkd_syntax.rxWikiLink1 = mkd_syntax.rx_wikilink_md_prefix.
        \ mkd_syntax.rxWikiLink1Url. rx_wikilink_md_separator.
        \ mkd_syntax.rx_wikilink_md_suffix.
        \ '\|'. mkd_syntax.rx_wikilink_md_prefix.
        \ mkd_syntax.rxWikiLink1Descr . rx_wikilink_md_separator.
        \ mkd_syntax.rxWikiLink1Url . mkd_syntax.rx_wikilink_md_suffix
  " 2. match URL within [URL][], [DESCRIPTION][URL]
  let mkd_syntax.rxWikiLink1MatchUrl = mkd_syntax.rx_wikilink_md_prefix.
        \ '\zs'. mkd_syntax.rxWikiLink1Url. '\ze'. rx_wikilink_md_separator.
        \ mkd_syntax.rx_wikilink_md_suffix.
        \ '\|'. mkd_syntax.rx_wikilink_md_prefix.
        \ mkd_syntax.rxWikiLink1Descr. rx_wikilink_md_separator.
        \ '\zs'. mkd_syntax.rxWikiLink1Url. '\ze'. mkd_syntax.rx_wikilink_md_suffix
  " 3. match DESCRIPTION within [DESCRIPTION][URL]
  let mkd_syntax.rxWikiLink1MatchDescr = mkd_syntax.rx_wikilink_md_prefix.
        \ '\zs'. mkd_syntax.rxWikiLink1Descr.'\ze'. rx_wikilink_md_separator.
        \ mkd_syntax.rxWikiLink1Url . mkd_syntax.rx_wikilink_md_suffix

  let mkd_syntax.rxWikiLink1Prefix1 = mkd_syntax.rx_wikilink_md_prefix
  let mkd_syntax.rxWikiLink1Suffix1 = rx_wikilink_md_separator.
        \ mkd_syntax.rxWikiLink1Url . mkd_syntax.rx_wikilink_md_suffix

  " 1. match ANY wikilink
  let mkd_syntax.rxWikiLink = mkd_syntax.rxWikiLink0 . '\|' . mkd_syntax.rxWikiLink1
  " 2. match URL within ANY wikilink
  let mkd_syntax.rxWikiLinkMatchUrl = mkd_syntax.rxWikiLink0MatchUrl . '\|' .
        \ mkd_syntax.rxWikiLink1MatchUrl
  " 3. match DESCRIPTION within ANY wikilink
  let mkd_syntax.rxWikiLinkMatchDescr = mkd_syntax.rxWikiLink0MatchDescr . '\|' .
        \ mkd_syntax.rxWikiLink1MatchDescr

  " 0. URL : free-standing links: keep URL UR(L) strip trailing punct: URL; URL) UR(L))
  let mkd_syntax.rxWeblink0 = mkd_syntax.rxWeblink
  " 0a) match URL within URL
  let mkd_syntax.rxWeblinkMatchUrl0 = mkd_syntax.rxWeblinkMatchUrl
  " 0b) match DESCRIPTION within URL
  let mkd_syntax.rxWeblinkMatchDescr0 = mkd_syntax.rxWeblinkMatchDescr

  let mkd_syntax.rxWeblink1Prefix = '['
  let mkd_syntax.rxWeblink1Suffix = ')'
  let mkd_syntax.rxWeblink1Separator = ']('
  " [DESCRIPTION](URL)
  let mkd_syntax.Weblink1Template = mkd_syntax.rxWeblink1Prefix . '__LinkDescription__'.
        \ mkd_syntax.rxWeblink1Separator. '__LinkUrl__'.
        \ mkd_syntax.rxWeblink1Suffix

  let valid_chars = '[^\\]'

  let mkd_syntax.rxWeblink1Prefix = vimwiki#u#escape(mkd_syntax.rxWeblink1Prefix)
  let mkd_syntax.rxWeblink1Suffix = vimwiki#u#escape(mkd_syntax.rxWeblink1Suffix)
  let mkd_syntax.rxWeblink1Separator = vimwiki#u#escape(mkd_syntax.rxWeblink1Separator)
  let mkd_syntax.rxWeblink1Url = valid_chars.'\{-}'
  let mkd_syntax.rxWeblink1Descr = valid_chars.'\{-}'

  " 1. [DESCRIPTION](URL)
  " 1a) match [DESCRIPTION](URL)
  let mkd_syntax.rxWeblink1 = mkd_syntax.rxWeblink1Prefix.
        \ mkd_syntax.rxWeblink1Url . mkd_syntax.rxWeblink1Separator.
        \ mkd_syntax.rxWeblink1Descr . mkd_syntax.rxWeblink1Suffix
  " 1b) match URL within [DESCRIPTION](URL)
  let mkd_syntax.rxWeblink1MatchUrl = mkd_syntax.rxWeblink1Prefix.
        \ mkd_syntax.rxWeblink1Descr. mkd_syntax.rxWeblink1Separator.
        \ '\zs' . mkd_syntax.rxWeblink1Url . '\ze' . mkd_syntax.rxWeblink1Suffix
  " 1c) match DESCRIPTION within [DESCRIPTION](URL)
  let mkd_syntax.rxWeblink1MatchDescr = mkd_syntax.rxWeblink1Prefix.
        \ '\zs'.mkd_syntax.rxWeblink1Descr.'\ze'. mkd_syntax.rxWeblink1Separator.
        \ mkd_syntax.rxWeblink1Url. mkd_syntax.rxWeblink1Suffix

  " TODO: image links too !!
  let mkd_syntax.rxWeblink1Prefix1 = mkd_syntax.rxWeblink1Prefix
  let mkd_syntax.rxWeblink1Suffix1 = mkd_syntax.rxWeblink1Separator.
        \ mkd_syntax.rxWeblink1Url . mkd_syntax.rxWeblink1Suffix

  " *a) match ANY weblink
  let mkd_syntax.rxWeblink = ''.
        \ mkd_syntax.rxWeblink1.'\|'.
        \ mkd_syntax.rxWeblink0
  " *b) match URL within ANY weblink
  let mkd_syntax.rxWeblinkMatchUrl = ''.
        \ mkd_syntax.rxWeblink1MatchUrl.'\|'.
        \ mkd_syntax.rxWeblinkMatchUrl0
  " *c) match DESCRIPTION within ANY weblink
  let mkd_syntax.rxWeblinkMatchDescr = ''.
        \ mkd_syntax.rxWeblink1MatchDescr.'\|'.
        \ mkd_syntax.rxWeblinkMatchDescr0

  let mkd_syntax.rxAnyLink = mkd_syntax.rxWikiLink.'\|'.
        \ g:vimwiki_global_vars.rxWikiIncl.'\|'.mkd_syntax.rxWeblink

  let mkd_syntax.rxMkdRef = '\['.g:vimwiki_global_vars.rxWikiLinkDescr.']:\%(\s\+\|\n\)'.
        \ mkd_syntax.rxWeblink0
  let mkd_syntax.rxMkdRefMatchDescr =
        \ '\[\zs'.g:vimwiki_global_vars.rxWikiLinkDescr.'\ze]:\%(\s\+\|\n\)'. mkd_syntax.rxWeblink0
  let mkd_syntax.rxMkdRefMatchUrl =
        \ '\['.g:vimwiki_global_vars.rxWikiLinkDescr.']:\%(\s\+\|\n\)\zs'.
        \ mkd_syntax.rxWeblink0.'\ze'
endfunction


function! vimwiki#vars#init()
  call s:populate_global_variables()
  call s:populate_wikilocal_options()
endfunction


function! vimwiki#vars#get_syntaxlocal(key, ...)
  if a:0
    let syntax = a:1
  else
    let syntax = vimwiki#vars#get_wikilocal('syntax')
  endif
  if !exists('g:vimwiki_syntax_variables') || !has_key(g:vimwiki_syntax_variables, syntax)
    call vimwiki#vars#populate_syntax_vars(syntax)
  endif

  return g:vimwiki_syntax_variables[syntax][a:key]
endfunction


" Get a variable for the buffer we are currently in or for the given buffer (number or name).
" Populate the variable, if it doesn't exist.
function! vimwiki#vars#get_bufferlocal(key, ...)
  let buffer = a:0 ? a:1 : '%'

  let value = getbufvar(buffer, 'vimwiki_'.a:key, '/\/\')
  if type(value) != 1 || value !=# '/\/\'
    return value
  elseif a:key ==# 'wiki_nr'
    call setbufvar(buffer, 'vimwiki_wiki_nr', vimwiki#base#find_wiki(expand('%:p')))
  elseif a:key ==# 'subdir'
    call setbufvar(buffer, 'vimwiki_subdir', vimwiki#base#current_subdir())
  elseif a:key ==# 'invsubdir'
    let subdir = vimwiki#vars#get_bufferlocal('subdir')
    call setbufvar(buffer, 'vimwiki_invsubdir', vimwiki#base#invsubdir(subdir))
  elseif a:key ==# 'existing_wikifiles'
    call setbufvar(buffer, 'vimwiki_existing_wikifiles',
          \ vimwiki#base#get_wikilinks(vimwiki#vars#get_bufferlocal('wiki_nr'), 1))
  elseif a:key ==# 'existing_wikidirs'
    call setbufvar(buffer, 'vimwiki_existing_wikidirs',
        \ vimwiki#base#get_wiki_directories(vimwiki#vars#get_bufferlocal('wiki_nr')))
  elseif a:key ==# 'prev_link'
    call setbufvar(buffer, 'vimwiki_prev_link', [])
  elseif a:key ==# 'markdown_refs'
    call setbufvar(buffer, 'vimwiki_markdown_refs', vimwiki#markdown_base#scan_reflinks())
  else
    echoerr 'Vimwiki Error: unknown buffer variable ' . string(a:key)
  endif

  return getbufvar(buffer, 'vimwiki_'.a:key)
endfunction


function! vimwiki#vars#set_bufferlocal(key, value, ...)
  let buffer = a:0 ? a:1 : '%'
  call setbufvar(buffer, 'vimwiki_' . a:key, a:value)
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


function! vimwiki#vars#get_wikilocal_default(key)
  return g:vimwiki_wikilocal_vars[-1][a:key]
endfunction


function! vimwiki#vars#set_wikilocal(key, value, wiki_nr)
  if a:wiki_nr == len(g:vimwiki_wikilocal_vars) - 1
    call insert(g:vimwiki_wikilocal_vars, {}, -1)
  endif
  let g:vimwiki_wikilocal_vars[a:wiki_nr][a:key] = a:value
endfunction


function! vimwiki#vars#add_temporary_wiki(settings)
  let new_temp_wiki_settings = copy(g:vimwiki_wikilocal_vars[-1])
  for [key, value] in items(a:settings)
    let new_temp_wiki_settings[key] = value
  endfor
  call insert(g:vimwiki_wikilocal_vars, new_temp_wiki_settings, -1)
  call s:validate_settings()
endfunction


" number of registered wikis + temporary
function! vimwiki#vars#number_of_wikis()
  return len(g:vimwiki_wikilocal_vars) - 1
endfunction

