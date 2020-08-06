" vim:tabstop=2:shiftwidth=2:expandtab:textwidth=99
" Vimwiki autoload plugin file
" Description: Vimwiki variable definition and manipulation
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
"   dictionaries, one dict for every registered wiki. The last dictionary contains default values
"   (used for temporary wikis).
"
" - syntax variables. Stored in the dict g:vimwiki_syntax_variables which holds all the regexes and
"   other stuff which is needed for highlighting.
"
" - buffer-local variables. They are stored as buffer variables directly (b:foo)

" As a developer, you should, if possible, only use the get_ and set_ functions for these types of
" variables, not the underlying dicts!
" ------------------------------------------------------------------------------------------------

" Script variable
let s:margin_set_by_user = 0


" Init global and local variables
function! vimwiki#vars#init() abort
  call s:populate_global_variables()
  call s:populate_wikilocal_options()
endfunction


" ----------------------------------------------------------
" 1. Global
" ----------------------------------------------------------

" Populate global variable <- user & default
" Called: s:vimwiki#vars#init
function! s:populate_global_variables() abort
  let g:vimwiki_global_vars = {}

  call s:read_global_settings_from_user()
  call s:normalize_global_settings()

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
  " TODO look behind for . reduces the second part of the regex that is the same with '.' added
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


" Read user global settings
" Called: s:populate_global_variables
function! s:read_global_settings_from_user() abort
  let global_settings = {
        \ 'CJK_length': {'type': type(0), 'default': 0, 'min': 0, 'max': 1},
        \ 'auto_chdir': {'type': type(0), 'default': 0, 'min': 0, 'max': 1},
        \ 'auto_header': {'type': type(0), 'default': 0, 'min': 0, 'max': 1},
        \ 'autowriteall': {'type': type(0), 'default': 1, 'min': 0, 'max': 1},
        \ 'conceallevel': {'type': type(0), 'default': 2, 'min': 0, 'max': 3},
        \ 'conceal_onechar_markers': {'type': type(0), 'default': 1, 'min': 0, 'max': 1},
        \ 'conceal_pre': {'type': type(0), 'default': 0, 'min': 0, 'max': 1},
        \ 'create_link': {'type': type(0), 'default': 1, 'min':0, 'max': 1},
        \ 'diary_months': {'type': type({}), 'default':
        \   {
        \     1: 'January', 2: 'February', 3: 'March',
        \     4: 'April', 5: 'May', 6: 'June',
        \     7: 'July', 8: 'August', 9: 'September',
        \     10: 'October', 11: 'November', 12: 'December'
        \   }},
        \ 'dir_link': {'type': type(''), 'default': ''},
        \ 'ext2syntax': {'type': type({}), 'default': {'.md': 'markdown', '.mkdn': 'markdown',
        \     '.mdwn': 'markdown', '.mdown': 'markdown', '.markdown': 'markdown', '.mw': 'media'}},
        \ 'folding': {'type': type(''), 'default': '', 'possible_values': ['', 'expr', 'syntax',
        \     'list', 'custom', ':quick', 'expr:quick', 'syntax:quick', 'list:quick',
        \     'custom:quick']},
        \ 'filetypes': {'type': type([]), 'default': []},
        \ 'global_ext': {'type': type(0), 'default': 1, 'min': 0, 'max': 1},
        \ 'hl_cb_checked': {'type': type(0), 'default': 0, 'min': 0, 'max': 2},
        \ 'hl_headers': {'type': type(0), 'default': 0, 'min': 0, 'max': 1},
        \ 'html_header_numbering': {'type': type(0), 'default': 0, 'min': 0, 'max': 6},
        \ 'html_header_numbering_sym': {'type': type(''), 'default': ''},
        \ 'key_mappings': {'type': type({}), 'default':
        \   {
        \     'all_maps': 1, 'global': 1, 'headers': 1, 'text_objs': 1,
        \     'table_format': 1, 'table_mappings': 1, 'lists': 1, 'links': 1,
        \     'html': 1, 'mouse': 0,
        \   }},
        \ 'links_header': {'type': type(''), 'default': 'Generated Links', 'min_length': 1},
        \ 'links_header_level': {'type': type(0), 'default': 1, 'min': 1, 'max': 6},
        \ 'listsyms': {'type': type(''), 'default': ' .oOX', 'min_length': 2},
        \ 'listsym_rejected': {'type': type(''), 'default': '-', 'length': 1},
        \ 'map_prefix': {'type': type(''), 'default': '<Leader>w'},
        \ 'markdown_header_style': {'type': type(0), 'default': 1, 'min':0, 'max': 2},
        \ 'menu': {'type': type(''), 'default': 'Vimwiki'},
        \ 'table_auto_fmt': {'type': type(0), 'default': 1, 'min': 0, 'max': 1},
        \ 'table_reduce_last_col': {'type': type(0), 'default': 0, 'min': 0, 'max': 1},
        \ 'table_mappings': {'type': type(0), 'default': 1, 'min': 0, 'max': 1},
        \ 'tags_header': {'type': type(''), 'default': 'Generated Tags', 'min_length': 1},
        \ 'tags_header_level': {'type': type(0), 'default': 1, 'min': 1, 'max': 5},
        \ 'url_maxsave': {'type': type(0), 'default': 15, 'min': 0},
        \ 'use_calendar': {'type': type(0), 'default': 1, 'min': 0, 'max': 1},
        \ 'use_mouse': {'type': type(0), 'default': 0, 'min': 0, 'max': 1},
        \ 'user_htmls': {'type': type(''), 'default': ''},
        \ 'valid_html_tags': {'type': type(''), 'default':
        \   'b,i,s,u,sub,sup,kbd,br,hr,div,center,strong,em'},
        \ 'w32_dir_enc': {'type': type(''), 'default': ''},
        \ }

  " copy the user's settings from variables of the form g:vimwiki_<option> into the dict
  " g:vimwiki_global_vars (or set a default value)
  for key in keys(global_settings)
    if exists('g:vimwiki_'.key)
      let users_value = g:vimwiki_{key}
      let value_infos = global_settings[key]

      call s:check_users_value(key, users_value, value_infos, 1)

      let g:vimwiki_global_vars[key] = users_value
      " Remove users_value to prevent type mismatch (E706) errors in vim <7.4.1546
      unlet users_value
    else
      let g:vimwiki_global_vars[key] = global_settings[key].default
    endif
  endfor

  " validate some settings individually

  let key = 'diary_months'
  let users_value = g:vimwiki_global_vars[key]
  for month in range(1, 12)
    if !has_key(users_value, month) || type(users_value[month]) != type('') ||
          \ empty(users_value[month])
      echom printf('Vimwiki Error: The provided value ''%s'' of the option ''g:vimwiki_%s'' is'
            \ . ' invalid. See '':h g:vimwiki_%s''.', string(users_value), key, key)
      break
    endif
  endfor

  let key = 'ext2syntax'
  let users_value = g:vimwiki_global_vars[key]
  for ext in keys(users_value)
    if empty(ext) || index(['markdown', 'media', 'mediawiki', 'default'], users_value[ext]) == -1
      echom printf('Vimwiki Error: The provided value ''%s'' of the option ''g:vimwiki_%s'' is'
            \ . ' invalid. See '':h g:vimwiki_%s''.', string(users_value), key, key)
      break
    endif
  endfor
endfunction


" Normalize user global settings
" Called: s:populate_global_variables
function! s:normalize_global_settings() abort
  let keys = keys(g:vimwiki_global_vars.ext2syntax)
  for ext in keys
    " for convenience, we also allow the term 'mediawiki'
    if g:vimwiki_global_vars.ext2syntax[ext] ==# 'mediawiki'
      let g:vimwiki_global_vars.ext2syntax[ext] = 'media'
    endif

    " ensure the file extensions in ext2syntax start with a dot
    " make sure this occurs after anything else that tries to access
    " the entry using the index 'ext' since this removes that index
    if ext[0] !=# '.'
      let new_ext = '.' . ext
      let g:vimwiki_global_vars.ext2syntax[new_ext] = g:vimwiki_global_vars.ext2syntax[ext]
      call remove(g:vimwiki_global_vars.ext2syntax, ext)
    endif
  endfor

  " ensure key_mappings dictionary has all required keys
  if !has_key(g:vimwiki_global_vars.key_mappings, 'all_maps')
    let g:vimwiki_global_vars.key_mappings.all_maps = 1
  endif
  if !has_key(g:vimwiki_global_vars.key_mappings, 'global')
    let g:vimwiki_global_vars.key_mappings.global = 1
  endif
  if !has_key(g:vimwiki_global_vars.key_mappings, 'headers')
    let g:vimwiki_global_vars.key_mappings.headers = 1
  endif
  if !has_key(g:vimwiki_global_vars.key_mappings, 'text_objs')
    let g:vimwiki_global_vars.key_mappings.text_objs = 1
  endif
  if !has_key(g:vimwiki_global_vars.key_mappings, 'table_format')
    let g:vimwiki_global_vars.key_mappings.table_format = 1
  endif
  if !has_key(g:vimwiki_global_vars.key_mappings, 'table_mappings')
    let g:vimwiki_global_vars.key_mappings.table_mappings = 1
  endif
  if !has_key(g:vimwiki_global_vars.key_mappings, 'lists')
    let g:vimwiki_global_vars.key_mappings.lists = 1
  endif
  if !has_key(g:vimwiki_global_vars.key_mappings, 'links')
    let g:vimwiki_global_vars.key_mappings.links = 1
  endif
  if !has_key(g:vimwiki_global_vars.key_mappings, 'html')
    let g:vimwiki_global_vars.key_mappings.html = 1
  endif
  if !has_key(g:vimwiki_global_vars.key_mappings, 'mouse')
    let g:vimwiki_global_vars.key_mappings.mouse = 0
  endif

  " disable all key mappings if all_maps == 0
  if !g:vimwiki_global_vars.key_mappings.all_maps
    let g:vimwiki_global_vars.key_mappings.global = 0
    let g:vimwiki_global_vars.key_mappings.headers = 0
    let g:vimwiki_global_vars.key_mappings.text_objs = 0
    let g:vimwiki_global_vars.key_mappings.table_format = 0
    let g:vimwiki_global_vars.key_mappings.table_mappings = 0
    let g:vimwiki_global_vars.table_mappings = 0 " kept for backwards compatibility
    let g:vimwiki_global_vars.key_mappings.lists = 0
    let g:vimwiki_global_vars.key_mappings.links = 0
    let g:vimwiki_global_vars.key_mappings.html = 0
    let g:vimwiki_global_vars.key_mappings.mouse = 0
    let g:vimwiki_global_vars.use_mouse = 0 " kept for backwards compatibility
  endif

  " TODO remove these checks and the table_mappings and use_mouse variables
  " backwards compatibility checks
  " if the old option isn't its default value then overwrite the new option
  if g:vimwiki_global_vars.table_mappings == 0 && g:vimwiki_global_vars.key_mappings.table_mappings == 0
    let g:vimwiki_global_vars.key_mappings.table_mappings = 0
  endif
  if g:vimwiki_global_vars.use_mouse == 1 && g:vimwiki_global_vars.key_mappings.mouse == 0
    let g:vimwiki_global_vars.key_mappings.mouse = 1
  endif
endfunction


" ----------------------------------------------------------
" 2. Buffer local
" ----------------------------------------------------------

" Populate local variable <- user & default
" Called: s:vimwiki#vars#init
function! s:populate_wikilocal_options() abort
  " Init local variable container
  let g:vimwiki_wikilocal_vars = []

  " Declare default values
  " Please: keep alphabetical sort
  let default_values = {
        \ 'auto_diary_index': {'type': type(0), 'default': 0, 'min': 0, 'max': 1},
        \ 'auto_export': {'type': type(0), 'default': 0, 'min': 0, 'max': 1},
        \ 'auto_generate_links': {'type': type(0), 'default': 0, 'min': 0, 'max': 1},
        \ 'auto_generate_tags': {'type': type(0), 'default': 0, 'min': 0, 'max': 1},
        \ 'auto_tags': {'type': type(0), 'default': 0, 'min': 0, 'max': 1},
        \ 'auto_toc': {'type': type(0), 'default': 0, 'min': 0, 'max': 1},
        \ 'automatic_nested_syntaxes': {'type': type(0), 'default': 1, 'min': 0, 'max': 1},
        \ 'base_url': {'type': type(''), 'default': '', 'min_length': 1},
        \ 'commentstring': {'type': type(''), 'default': '%%%s'},
        \ 'css_name': {'type': type(''), 'default': 'style.css', 'min_length': 1},
        \ 'custom_wiki2html': {'type': type(''), 'default': ''},
        \ 'custom_wiki2html_args': {'type': type(''), 'default': ''},
        \ 'diary_frequency': {'type': type(''), 'default': 'daily', 'possible_values': ['daily', 'weekly', 'monthly', 'yearly']},
        \ 'diary_start_week_day': {'type': type(''), 'default': 'monday', 'possible_values': ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday']},
        \ 'diary_header': {'type': type(''), 'default': 'Diary', 'min_length': 1},
        \ 'diary_index': {'type': type(''), 'default': 'diary', 'min_length': 1},
        \ 'diary_rel_path': {'type': type(''), 'default': 'diary/', 'min_length': 0},
        \ 'diary_caption_level': {'type': type(0), 'default': 0, 'min': -1, 'max': 6},
        \ 'diary_sort': {'type': type(''), 'default': 'desc', 'possible_values': ['asc', 'desc']},
        \ 'exclude_files': {'type': type([]), 'default': []},
        \ 'ext': {'type': type(''), 'default': '.wiki', 'min_length': 1},
        \ 'bullet_types': {'type': type([]), 'default': []},
        \ 'cycle_bullets': {'type': type(0), 'default': 0},
        \ 'html_filename_parameterization': {'type': type(0), 'default': 0, 'min': 0, 'max': 1},
        \ 'index': {'type': type(''), 'default': 'index', 'min_length': 1},
        \ 'links_space_char': {'type': type(''), 'default': ' ', 'min_length': 1},
        \ 'list_ignore_newline': {'type': type(0), 'default': 1, 'min': 0, 'max': 1},
        \ 'list_margin': {'type': type(0), 'default': -1, 'min': -1},
        \ 'listsym_rejected': {'type': type(''), 'default': vimwiki#vars#get_global('listsym_rejected')},
        \ 'listsyms': {'type': type(''), 'default': vimwiki#vars#get_global('listsyms')},
        \ 'markdown_link_ext': {'type': type(0), 'default': 0, 'min': 0, 'max': 1},
        \ 'maxhi': {'type': type(0), 'default': 0, 'min': 0, 'max': 1},
        \ 'name': {'type': type(''), 'default': ''},
        \ 'nested_syntaxes': {'type': type({}), 'default': {}},
        \ 'path': {'type': type(''), 'default': $HOME . '/vimwiki/', 'min_length': 1},
        \ 'path_html': {'type': type(''), 'default': ''},
        \ 'rss_max_items': {'type': type(0), 'default': 10, 'min': 0},
        \ 'rss_name': {'type': type(''), 'default': 'rss.xml', 'min_length': 1},
        \ 'syntax': {'type': type(''), 'default': 'default',
        \   'possible_values': ['default', 'markdown', 'media', 'mediawiki']},
        \ 'template_default': {'type': type(''), 'default': 'default', 'min_length': 1},
        \ 'template_ext': {'type': type(''), 'default': '.tpl'},
        \ 'template_path': {'type': type(''), 'default': $HOME . '/vimwiki/templates/'},
        \ 'text_ignore_newline': {'type': type(0), 'default': 1, 'min': 0, 'max': 1},
        \ 'toc_header': {'type': type(''), 'default': 'Contents', 'min_length': 1},
        \ 'toc_header_level': {'type': type(0), 'default': 1, 'min': 1, 'max': 6},
        \ 'toc_link_format': {'type': type(0), 'default': 0, 'min': 0, 'max': 1},
        \ }

  " Fill default setting <- user or plugin values
  let default_wiki_settings = {}
  for key in keys(default_values)
    if exists('g:vimwiki_'.key)
      call s:check_users_value(key, g:vimwiki_{key}, default_values[key], 1)
      let default_wiki_settings[key] = g:vimwiki_{key}
    else
      let default_wiki_settings[key] = default_values[key].default
    endif
  endfor

  " Set the wiki-local variables according to g:vimwiki_list (or the default settings)
  if exists('g:vimwiki_list')
    for users_wiki_settings in g:vimwiki_list
      let new_wiki_settings = {}
      for key in keys(default_values)
        if has_key(users_wiki_settings, key)
          call s:check_users_value(key, users_wiki_settings[key], default_values[key], 0)
          if key ==# 'list_margin'
            let s:margin_set_by_user = 1
          endif
          let new_wiki_settings[key] = users_wiki_settings[key]
        else
          let new_wiki_settings[key] = default_wiki_settings[key]
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
  " Set up variables for the lists, depending on config and syntax
  for wiki in g:vimwiki_wikilocal_vars
    if len(wiki.bullet_types) == 0
      let wiki.bullet_types = vimwiki#vars#get_syntaxlocal('bullet_types', wiki.syntax)
    endif
      call s:populate_list_vars(wiki)
  endfor

  " Check some values individually
  let key = 'nested_syntaxes'
  for wiki_settings in g:vimwiki_wikilocal_vars
    let users_value = wiki_settings[key]
    for keyword in keys(users_value)
      if type(keyword) != type('') || empty(keyword) || type(users_value[keyword]) != type('') ||
            \ empty(users_value[keyword])
        echom printf('Vimwiki Error: The provided value ''%s'' of the option ''g:vimwiki_%s'' is'
              \ . ' invalid. See '':h g:vimwiki_%s''.', string(users_value), key, key)
        break
      endif
    endfor
  endfor

  call s:normalize_wikilocal_settings()
endfunction


" Helper, Check user setting
" warn user with echo message if not good type
" Param: 1: key <string>: varaible name
" Param: 2: vimwiki_key <obj>: user value
" Param: 3: value_infod <dict>: type and default value
" Param: 4: coming from a global variable <bool>
function! s:check_users_value(key, users_value, value_infos, comes_from_global_variable) abort
  let type_code_to_name = {
        \ type(0): 'number',
        \ type(''): 'string',
        \ type([]): 'list',
        \ type({}): 'dictionary'}

  let setting_origin = a:comes_from_global_variable ?
        \ printf('''g:vimwiki_%s''', a:key) :
        \ printf('''%s'' in g:vimwiki_list', a:key)

  let help_text = a:comes_from_global_variable ?
        \ 'g:vimwiki_' :
        \ 'vimwiki-option-'

  if has_key(a:value_infos, 'type') && type(a:users_value) != a:value_infos.type
    echom printf('Vimwiki Error: The provided value of the option %s is a %s, ' .
          \ 'but expected is a %s. See '':h '.help_text.'%s''.', setting_origin,
          \ type_code_to_name[type(a:users_value)], type_code_to_name[a:value_infos.type], a:key)
  endif

  if a:value_infos.type == type(0) && has_key(a:value_infos, 'min') &&
        \ a:users_value < a:value_infos.min
    echom printf('Vimwiki Error: The provided value ''%i'' of the option %s is'
          \ . ' too small. The minimum value is %i. See '':h '.help_text.'%s''.', a:users_value,
          \ setting_origin, a:value_infos.min, a:key)
  endif

  if a:value_infos.type == type(0) && has_key(a:value_infos, 'max') &&
        \ a:users_value > a:value_infos.max
    echom printf('Vimwiki Error: The provided value ''%i'' of the option %s is'
          \ . ' too large. The maximum value is %i. See '':h '.help_text.'%s''.', a:users_value,
          \ setting_origin, a:value_infos.max, a:key)
  endif

  if has_key(a:value_infos, 'possible_values') &&
        \ index(a:value_infos.possible_values, a:users_value) == -1
    echom printf('Vimwiki Error: The provided value ''%s'' of the option %s is'
          \ . ' invalid. Allowed values are %s. See '':h '.help_text.'%s''.', a:users_value,
          \ setting_origin, string(a:value_infos.possible_values), a:key)
  endif

  if a:value_infos.type == type('') && has_key(a:value_infos, 'length') &&
        \ strwidth(a:users_value) != a:value_infos.length
    echom printf('Vimwiki Error: The provided value ''%s'' of the option %s must'
          \ . ' contain exactly %i character(s) but has %i. See '':h '.help_text.'_%s''.',
          \ a:users_value, setting_origin, a:value_infos.length, strwidth(a:users_value), a:key)
  endif

  if a:value_infos.type == type('') && has_key(a:value_infos, 'min_length') &&
        \ strwidth(a:users_value) < a:value_infos.min_length
    echom printf('Vimwiki Error: The provided value ''%s'' of the option %s must'
          \ . ' have at least %d character(s) but has %d. See '':h '.help_text.'%s''.', a:users_value,
          \ setting_origin, a:value_infos.min_length, strwidth(a:users_value), a:key)
  endif
endfunction


" Normalize local settings
function! s:normalize_wikilocal_settings() abort
  for wiki_settings in g:vimwiki_wikilocal_vars
    let wiki_settings['path'] = s:normalize_path(wiki_settings['path'])

    let path_html = wiki_settings['path_html']
    if !empty(path_html)
      let wiki_settings['path_html'] = s:normalize_path(path_html)
    else
      let wiki_settings['path_html'] = s:normalize_path(
            \ substitute(wiki_settings['path'], '[/\\]\+$', '', '').'_html/')
    endif

    let wiki_settings['template_path'] = s:normalize_path(wiki_settings['template_path'])
    let wiki_settings['diary_rel_path'] = s:normalize_path(wiki_settings['diary_rel_path'])

    let ext = wiki_settings['ext']
    if !empty(ext) && ext[0] !=# '.'
      let wiki_settings['ext'] = '.' . ext
    endif

    " for convenience, we also allow the term 'mediawiki'
    if wiki_settings.syntax ==# 'mediawiki'
      let wiki_settings.syntax = 'media'
    endif

    if wiki_settings.syntax ==# 'markdown' && !s:margin_set_by_user
      " default list margin to 0
      let wiki_settings.list_margin = 0
    endif
  endfor
endfunction


" Helper path
" TODO move to path: Conflict with: vimwiki#path#path_norm && vimwiki#path#normalize
function! s:normalize_path(path) abort
  " trim trailing / and \ because otherwise resolve() doesn't work quite right
  let path = substitute(a:path, '[/\\]\+$', '', '')
  if path !~# '^scp:'
    return resolve(expand(path)).'/'
  else
    return path.'/'
  endif
endfunction


" ----------------------------------------------------------
" 3. Syntax specific
" ----------------------------------------------------------

" Populate syntax variable
" Exported: syntax/vimwiki.vim
" TODO refactor <= too big function
function! vimwiki#vars#populate_syntax_vars(syntax) abort
  " Create is not exists
  if !exists('g:vimwiki_syntax_variables')
    let g:vimwiki_syntax_variables = {}
  endif

  " Clause: leave if already filled
  if has_key(g:vimwiki_syntax_variables, a:syntax)
    return
  endif

  " Init syntax variable dictionary
  let g:vimwiki_syntax_variables[a:syntax] = {}
  let syntax_dic = g:vimwiki_syntax_variables[a:syntax]

  " Init Typeface (filled in custom syntax)
  let syntax_dic.dTypeface = {}

  " Autoload default syntax file
  execute 'runtime! syntax/vimwiki_'.a:syntax.'.vim'


  " TODO make that clean (i.e clearify what is local to syntax ot to buffer)
  " Get from local vars
  let bullet_types = vimwiki#vars#get_wikilocal('bullet_types')
  if !empty(bullet_types)
    let syntax_dic['bullet_types'] = bullet_types
  endif
  let syntax_dic['cycle_bullets'] =
        \ vimwiki#vars#get_wikilocal('cycle_bullets')

  " Populate generic stuff
  let header_symbol = syntax_dic.rxH
  if syntax_dic.symH
    " symmetric headers
    for i in range(1,6)
      let syntax_dic['rxH'.i.'_Template'] =
            \ repeat(header_symbol, i).' __Header__ '.repeat(header_symbol, i)
      let syntax_dic['rxH'.i] =
            \ '^\s*'.header_symbol.'\{'.i.'}[^'.header_symbol.'].*[^'.header_symbol.']'
            \ .header_symbol.'\{'.i.'}\s*$'
      let syntax_dic['rxH'.i.'_Text'] =
            \ '^\s*'.header_symbol.'\{'.i.'}\zs[^'.header_symbol.'].*[^'.header_symbol.']\ze'
            \ .header_symbol.'\{'.i.'}\s*$'
      let syntax_dic['rxH'.i.'_Start'] =
            \ '^\s*'.header_symbol.'\{'.i.'}[^'.header_symbol.'].*[^'.header_symbol.']'
            \ .header_symbol.'\{'.i.'}\s*$'
      let syntax_dic['rxH'.i.'_End'] =
            \ '^\s*'.header_symbol.'\{1,'.i.'}[^'.header_symbol.'].*[^'.header_symbol.']'
            \ .header_symbol.'\{1,'.i.'}\s*$'
    endfor
    let syntax_dic.rxHeader =
          \ '^\s*\('.header_symbol.'\{1,6}\)\zs[^'.header_symbol.'].*[^'.header_symbol.']\ze\1\s*$'
  else
    " asymmetric
    " Note: For markdown rxH=# and asymetric
    for i in range(1,6)
      let syntax_dic['rxH'.i.'_Template'] =
            \ repeat(header_symbol, i).' __Header__'
      let syntax_dic['rxH'.i] =
            \ '^\s*'.header_symbol.'\{'.i.'}[^'.header_symbol.'].*$'
      let syntax_dic['rxH'.i.'_Text'] =
            \ '^\s*'.header_symbol.'\{'.i.'}\zs[^'.header_symbol.'].*\ze$'
      let syntax_dic['rxH'.i.'_Start'] =
            \ '^\s*'.header_symbol.'\{'.i.'}[^'.header_symbol.'].*$'
      let syntax_dic['rxH'.i.'_End'] =
            \ '^\s*'.header_symbol.'\{1,'.i.'}[^'.header_symbol.'].*$'
    endfor
    " Define header regex
    " -- ATX heading := preceed by #*
    let atx_heading = '^\s*\%('.header_symbol.'\{1,6}\)'
    let atx_heading .= '\zs[^'.header_symbol.'].*\ze$'
    let syntax_dic.rxHeader = atx_heading
  endif

  let syntax_dic.rxPreStart =
        \ '^\s*'.syntax_dic.rxPreStart
  let syntax_dic.rxPreEnd =
        \ '^\s*'.syntax_dic.rxPreEnd.'\s*$'

  let syntax_dic.rxMathStart =
        \ '^\s*'.syntax_dic.rxMathStart
  let syntax_dic.rxMathEnd =
        \ '^\s*'.syntax_dic.rxMathEnd.'\s*$'

  let syntax_dic.number_kinds = []
  let syntax_dic.number_divisors = ''
  for i in syntax_dic.number_types
    call add(syntax_dic.number_kinds, i[0])
    let syntax_dic.number_divisors .= vimwiki#u#escape(i[1])
  endfor

  let char_to_rx = {'1': '\d\+', 'i': '[ivxlcdm]\+', 'I': '[IVXLCDM]\+',
        \ 'a': '\l\{1,2}', 'A': '\u\{1,2}'}

  " Create regexp for bulleted list items
  if !empty(syntax_dic.bullet_types)
    let syntax_dic.rxListBullet =
          \ join( map(copy(syntax_dic.bullet_types),
          \'vimwiki#u#escape(v:val).'
          \ .'repeat("\\+", syntax_dic.recurring_bullets)'
          \ ) , '\|')
  else
    "regex that matches nothing
    let syntax_dic.rxListBullet = '$^'
  endif

  " Create regex for numbered list items
  if !empty(syntax_dic.number_types)
    let syntax_dic.rxListNumber = '\C\%('
    for type in syntax_dic.number_types[:-2]
      let syntax_dic.rxListNumber .= char_to_rx[type[0]] .
            \ vimwiki#u#escape(type[1]) . '\|'
    endfor
    let syntax_dic.rxListNumber .=
          \ char_to_rx[syntax_dic.number_types[-1][0]].
          \ vimwiki#u#escape(syntax_dic.number_types[-1][1]) . '\)'
  else
    "regex that matches nothing
    let syntax_dic.rxListNumber = '$^'
  endif

  " 0. URL : free-standing links: keep URL UR(L) strip trailing punct: URL; URL) UR(L))
  " let g:vimwiki_rxWeblink = '[\["(|]\@<!'. g:vimwiki_rxWeblinkUrl .
  " \ '\%([),:;.!?]\=\%([ \t]\|$\)\)\@='
  let syntax_dic.rxWeblink =
        \ '\<'. g:vimwiki_global_vars.rxWeblinkUrl . '[^[:space:]><]*'
  " 0a) match URL within URL
  let syntax_dic.rxWeblinkMatchUrl =
        \ syntax_dic.rxWeblink
  " 0b) match DESCRIPTION within URL
  let syntax_dic.rxWeblinkMatchDescr = ''

  " template for matching all wiki links with a given target file
  let syntax_dic.WikiLinkMatchUrlTemplate =
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
  let syntax_dic.rxWikiLink = g:vimwiki_global_vars.rx_wikilink_prefix.
        \ g:vimwiki_global_vars.rxWikiLinkUrl.'\%('.g:vimwiki_global_vars.rx_wikilink_separator.
        \ g:vimwiki_global_vars.rxWikiLinkDescr.'\)\?'.g:vimwiki_global_vars.rx_wikilink_suffix
  let syntax_dic.rxAnyLink =
        \ syntax_dic.rxWikiLink.'\|'.
        \ g:vimwiki_global_vars.rxWikiIncl.'\|'.syntax_dic.rxWeblink
  " b) match URL within [[URL|DESCRIPTION]]
  let syntax_dic.rxWikiLinkMatchUrl =
        \ g:vimwiki_global_vars.rx_wikilink_prefix . '\zs'. g:vimwiki_global_vars.rxWikiLinkUrl
        \ .'\ze\%('. g:vimwiki_global_vars.rx_wikilink_separator
        \ . g:vimwiki_global_vars.rxWikiLinkDescr.'\)\?'.g:vimwiki_global_vars.rx_wikilink_suffix
  " c) match DESCRIPTION within [[URL|DESCRIPTION]]
  let syntax_dic.rxWikiLinkMatchDescr =
        \ g:vimwiki_global_vars.rx_wikilink_prefix . g:vimwiki_global_vars.rxWikiLinkUrl
        \ . g:vimwiki_global_vars.rx_wikilink_separator.'\%(\zs'
        \ . g:vimwiki_global_vars.rxWikiLinkDescr. '\ze\)\?'
        \ . g:vimwiki_global_vars.rx_wikilink_suffix

  " Work more if markdown
  if a:syntax ==# 'markdown'
    call s:populate_extra_markdown_vars()
  endif

  call s:normalize_syntax_settings(a:syntax)
endfunction


" Populate list variable
" or how to search and treat list (ex: *,-, 1.)
function! s:populate_list_vars(wiki) abort
  let syntax = a:wiki.syntax

  let a:wiki.rx_bullet_char = '['.escape(join(a:wiki.bullet_types, ''), ']^-\').']'
  let a:wiki.rx_bullet_chars = a:wiki.rx_bullet_char.'\+'

  let recurring_bullets = vimwiki#vars#get_syntaxlocal('recurring_bullets')
  let rxListNumber = vimwiki#vars#get_syntaxlocal('rxListNumber')

  let a:wiki.multiple_bullet_chars =
        \ recurring_bullets
        \ ? a:wiki.bullet_types : []
  
  " Create regexp for bulleted list items
  if !empty(a:wiki.bullet_types)
    let rxListBullet =
          \ join( map(copy(a:wiki.bullet_types),
          \'vimwiki#u#escape(v:val).'
          \ .'repeat("\\+", recurring_bullets)'
          \ ) , '\|')
  else
    "regex that matches nothing
    let rxListBullet = '$^'
  endif

  " the user can set the listsyms as string, but vimwiki needs a list
  let a:wiki.listsyms_list = split(a:wiki.listsyms, '\zs')

  " Guard: Check if listym_rejected is in listsyms
  if match(a:wiki.listsyms, '[' . a:wiki.listsym_rejected . ']') != -1
    echomsg 'Vimwiki Warning: the value of listsym_rejected ('''
          \ . a:wiki.listsym_rejected . ''') must not be a part of listsyms ('''
          \ . a:wiki.listsyms . ''')'
  endif

  let a:wiki.rxListItemWithoutCB =
        \ '^\s*\%(\('.rxListBullet.'\)\|\('
        \ .rxListNumber.'\)\)\s'
  let a:wiki.rxListItem =
        \ a:wiki.rxListItemWithoutCB
        \ . '\+\%(\[\(['.a:wiki.listsyms
        \ . a:wiki.listsym_rejected.']\)\]\s\)\?'
  if recurring_bullets
    let a:wiki.rxListItemAndChildren =
          \ '^\('.rxListBullet.'\)\s\+\[['
          \ . a:wiki.listsyms_list[-1]
          \ . a:wiki.listsym_rejected . ']\]\s.*\%(\n\%(\1\%('
          \ .rxListBullet.'\).*\|^$\|\s.*\)\)*'
  else
    let a:wiki.rxListItemAndChildren =
          \ '^\(\s*\)\%('.rxListBullet.'\|'
          \ . rxListNumber.'\)\s\+\[['
          \ . a:wiki.listsyms_list[-1]
          \ . a:wiki.listsym_rejected . ']\]\s.*\%(\n\%(\1\s.*\|^$\)\)*'
  endif
endfunction


" Populate markdown specific syntax variables
function! s:populate_extra_markdown_vars() abort
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
  let mkd_syntax.rxWeblink1EscapeCharsSuffix = '\(\\\)\@<!\()\)'
  let mkd_syntax.rxWeblink1Separator = ']('

  let rxWeblink1Ext = ''
  if vimwiki#vars#get_wikilocal('markdown_link_ext')
    let rxWeblink1Ext = '__FileExtension__'
  endif

  " [DESCRIPTION](FILE.MD)
  let mkd_syntax.Weblink1Template = mkd_syntax.rxWeblink1Prefix . '__LinkDescription__'.
        \ mkd_syntax.rxWeblink1Separator. '__LinkUrl__'. rxWeblink1Ext.
        \ mkd_syntax.rxWeblink1Suffix
  " [DESCRIPTION](FILE)
  let mkd_syntax.Weblink2Template = mkd_syntax.rxWeblink1Prefix . '__LinkDescription__'.
        \ mkd_syntax.rxWeblink1Separator. '__LinkUrl__'. mkd_syntax.rxWeblink1Suffix
  " [DESCRIPTION](FILE.MD#ANCHOR)
  let mkd_syntax.Weblink3Template = mkd_syntax.rxWeblink1Prefix . '__LinkDescription__'.
        \ mkd_syntax.rxWeblink1Separator. '__LinkUrl__'. rxWeblink1Ext.
        \ '#__LinkAnchor__'. mkd_syntax.rxWeblink1Suffix

  let valid_chars = '[^\\\]]'
  " spaces and '\' must be allowed for filename and escaped chars
  let valid_chars_url = '[^[:cntrl:]]'

  let mkd_syntax.rxWeblink1Prefix = vimwiki#u#escape(mkd_syntax.rxWeblink1Prefix)
  let mkd_syntax.rxWeblink1Separator = vimwiki#u#escape(mkd_syntax.rxWeblink1Separator)
  let mkd_syntax.rxWeblink1Url = valid_chars_url.'\{-}'
  let mkd_syntax.rxWeblink1Descr = valid_chars.'\{-}'
  let mkd_syntax.WikiLinkMatchUrlTemplate =
        \ mkd_syntax.rx_wikilink_md_prefix .
        \ '.*' .
        \ rx_wikilink_md_separator .
        \ '\zs__LinkUrl__\ze\%(#.*\)\?\%(__FileExtension__\)\?'.
        \ mkd_syntax.rx_wikilink_md_suffix .
        \ '\|' .
        \ mkd_syntax.rx_wikilink_md_prefix .
        \ '\zs__LinkUrl__\ze\%(#.*\)\?\%(__FileExtension__\)\?'.
        \ rx_wikilink_md_separator .
        \ mkd_syntax.rx_wikilink_md_suffix .
        \ '\|' .
        \ mkd_syntax.rxWeblink1Prefix.
        \ '.*' .
        \ mkd_syntax.rxWeblink1Separator.
        \ '\zs__LinkUrl__\ze\%(#.*\)\?\%(__FileExtension__\)\?'.
        \ mkd_syntax.rxWeblink1EscapeCharsSuffix

  " 1. [DESCRIPTION](URL)
  " 1a) match [DESCRIPTION](URL)
  let mkd_syntax.rxWeblink1 = mkd_syntax.rxWeblink1Prefix.
        \ mkd_syntax.rxWeblink1Descr . mkd_syntax.rxWeblink1Separator.
        \ mkd_syntax.rxWeblink1Url . mkd_syntax.rxWeblink1EscapeCharsSuffix
  " 1b) match URL within [DESCRIPTION](URL)
  let mkd_syntax.rxWeblink1MatchUrl = mkd_syntax.rxWeblink1Prefix.
        \ mkd_syntax.rxWeblink1Descr. mkd_syntax.rxWeblink1Separator.
        \ '\zs' . mkd_syntax.rxWeblink1Url . '\ze' . mkd_syntax.rxWeblink1EscapeCharsSuffix
  " 1c) match DESCRIPTION within [DESCRIPTION](URL)
  let mkd_syntax.rxWeblink1MatchDescr = mkd_syntax.rxWeblink1Prefix.
        \ '\zs'.mkd_syntax.rxWeblink1Descr.'\ze'. mkd_syntax.rxWeblink1Separator.
        \ mkd_syntax.rxWeblink1Url. mkd_syntax.rxWeblink1EscapeCharsSuffix

  " image ![DESCRIPTION](URL)
  let mkd_syntax.rxImage = '!' . mkd_syntax.rxWeblink1Prefix.
        \ mkd_syntax.rxWeblink1Descr . mkd_syntax.rxWeblink1Separator.
        \ mkd_syntax.rxWeblink1Url . mkd_syntax.rxWeblink1EscapeCharsSuffix

  let mkd_syntax.rxWeblink1Prefix1 = mkd_syntax.rxWeblink1Prefix
  let mkd_syntax.rxWeblink1Suffix1 = mkd_syntax.rxWeblink1Separator.
        \ mkd_syntax.rxWeblink1Url . mkd_syntax.rxWeblink1EscapeCharsSuffix

  " *a) match ANY weblink (exclude image links starting with !)
  let mkd_syntax.rxWeblink = '\(!\)\@<!'.
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
        \ g:vimwiki_global_vars.rxWikiIncl.'\|'.mkd_syntax.rxWeblink .'\|'.
        \ mkd_syntax.rxImage

  let mkd_syntax.rxMkdRef = '\['.g:vimwiki_global_vars.rxWikiLinkDescr.']:\%(\s\+\|\n\)'.
        \ mkd_syntax.rxWeblink0
  let mkd_syntax.rxMkdRefMatchDescr =
        \ '\[\zs'.g:vimwiki_global_vars.rxWikiLinkDescr.'\ze]:\%(\s\+\|\n\)'. mkd_syntax.rxWeblink0
  let mkd_syntax.rxMkdRefMatchUrl =
        \ '\['.g:vimwiki_global_vars.rxWikiLinkDescr.']:\%(\s\+\|\n\)\zs'.
        \ mkd_syntax.rxWeblink0.'\ze'
endfunction


" Normalize syntax setting
"   so that we dont have to branch for the syntax at each operation
" Called: vimwiki#vars#populate_syntax_vars
function! s:normalize_syntax_settings(syntax) abort
  let syntax_dic = g:vimwiki_syntax_variables[a:syntax]

  " Link1: used when:
  "   user press enter on a non-link (normalize_link)
  "   command generate link form file name (generate_link)
  if a:syntax ==# 'markdown'
    let syntax_dic.Link1 = syntax_dic.Weblink1Template
  else
    let syntax_dic.Link1 = vimwiki#vars#get_global('WikiLinkTemplate1')
  endif
endfunction


" ----------------------------------------------------------
" 4. Getter, Setter (exported)
" ----------------------------------------------------------

" Get syntax variable
" Param:   1: key (<string>)
" Param: (2): syntax name (<string> ex:'markdown')
function! vimwiki#vars#get_syntaxlocal(key, ...) abort
  " Retrieve desired syntax name
  if a:0
    let syntax = a:1
  else
    let syntax = vimwiki#vars#get_wikilocal('syntax')
  endif

  " Create syntax varaible dict if not exists (lazy)
  if !exists('g:vimwiki_syntax_variables') || !has_key(g:vimwiki_syntax_variables, syntax)
    call vimwiki#vars#populate_syntax_vars(syntax)
  endif

  " Return d_syntax[a:key]
  return g:vimwiki_syntax_variables[syntax][a:key]
endfunction


" Return: buffer local variable
" for the buffer we are currently in or for the given buffer (number or name).
" Populate the variable, if it doesn't exist.
function! vimwiki#vars#get_bufferlocal(key, ...) abort
  let buffer = a:0 ? a:1 : '%'

  " 'get(getbufvar(...' handles vim < v7.3.831 that didn't allow a default value for getbufvar
  let value = get(getbufvar(buffer, ''), 'vimwiki_'.a:key, '/\/\')
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
          \ vimwiki#base#get_wikilinks(vimwiki#vars#get_bufferlocal('wiki_nr'), 1, ''))
  elseif a:key ==# 'existing_wikidirs'
    call setbufvar(buffer, 'vimwiki_existing_wikidirs',
        \ vimwiki#base#get_wiki_directories(vimwiki#vars#get_bufferlocal('wiki_nr')))
  elseif a:key ==# 'prev_links'
    call setbufvar(buffer, 'vimwiki_prev_links', [])
  elseif a:key ==# 'markdown_refs'
    call setbufvar(buffer, 'vimwiki_markdown_refs', vimwiki#markdown_base#scan_reflinks())
  else
    echoerr 'Vimwiki Error: unknown buffer variable ' . string(a:key)
  endif

  return getbufvar(buffer, 'vimwiki_'.a:key)
endfunction


" Set buffer local variable
function! vimwiki#vars#set_bufferlocal(key, value, ...) abort
  let buffer = a:0 ? a:1 : '%'
  call setbufvar(buffer, 'vimwiki_' . a:key, a:value)
endfunction


" Return: wiki global variable
function! vimwiki#vars#get_global(key) abort
  return g:vimwiki_global_vars[a:key]
endfunction


" Set global variable
function! vimwiki#vars#set_global(key, value) abort
  let g:vimwiki_global_vars[a:key] = a:value
  return g:vimwiki_global_vars[a:key]
endfunction


" Return: wiki local named varaible
" Param: (1): variable name (alias key, <string>)
" Param: (2): wiki number (<int>). When absent, the wiki of the currently active buffer is
" used
function! vimwiki#vars#get_wikilocal(key, ...) abort
  if a:0
    return g:vimwiki_wikilocal_vars[a:1][a:key]
  else
    return g:vimwiki_wikilocal_vars[vimwiki#vars#get_bufferlocal('wiki_nr')][a:key]
  endif
endfunction


" Return: wiki local variable (of default wiki [index -1])
function! vimwiki#vars#get_wikilocal_default(key) abort
  return g:vimwiki_wikilocal_vars[-1][a:key]
endfunction


" Set local variable
" Param: (2): wiki number (<int>). When absent, the wiki of the currently active buffer is
" used
function! vimwiki#vars#set_wikilocal(key, value, ...) abort
  if a:0
    let wiki_nr = a:1
  else
    let wiki_nr = vimwiki#vars#get_bufferlocal('wiki_nr')
  endif
  if wiki_nr == len(g:vimwiki_wikilocal_vars) - 1
    call insert(g:vimwiki_wikilocal_vars, {}, -1)
  endif
  let g:vimwiki_wikilocal_vars[wiki_nr][a:key] = a:value
endfunction


" Append new wiki to wiki list
function! vimwiki#vars#add_temporary_wiki(settings) abort
  let new_temp_wiki_settings = copy(g:vimwiki_wikilocal_vars[-1])
  for [key, value] in items(a:settings)
    let new_temp_wiki_settings[key] = value
  endfor
  call insert(g:vimwiki_wikilocal_vars, new_temp_wiki_settings, -1)
  call s:normalize_wikilocal_settings()
endfunction


" Return: number of registered wikis + temporary
function! vimwiki#vars#number_of_wikis() abort
  return len(g:vimwiki_wikilocal_vars) - 1
endfunction
