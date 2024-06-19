" Title: Vimwiki variable definition and manipulation functions
"
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
" - syntax variables. Stored in the dict g:vimwiki_syntaxlocal_vars which holds all the regexes and
"   other stuff which is needed for highlighting.
"
" - buffer-local variables. They are stored as buffer variables directly (b:foo)

" As a developer, you should, if possible, only use the get_ and set_ functions for these types of
" variables, not the underlying dicts!
" ------------------------------------------------------------------------------------------------

" Script variable
let s:margin_set_by_user = 0


function! vimwiki#vars#init() abort
  " Init global and local variables
  " Init && Populate: global variable container
  let g:vimwiki_global_vars = {}
  call s:populate_global_variables()

  " Init && Populate: local variable container
  let g:vimwiki_wikilocal_vars = []
  call s:populate_wikilocal_options()
endfunction


function! s:check_users_value(key, users_value, value_infos, comes_from_global_variable) abort
  " Helper: Check user setting
  " warn user with message if not good type
  " Param: 1: key <string>: variable name
  " Param: 2: vimwiki_key <obj>: user value
  " Param: 3: value_infod <dict>: type and default value
  " Param: 4: coming from a global variable <bool>
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
    call vimwiki#u#error(printf('The provided value of the option %s is a %s, ' .
          \ 'but expected is a %s. See '':h '.help_text.'%s''.', setting_origin,
          \ type_code_to_name[type(a:users_value)], type_code_to_name[a:value_infos.type], a:key))
  endif

  if a:value_infos.type == type(0) && has_key(a:value_infos, 'min') &&
        \ a:users_value < a:value_infos.min
    call vimwiki#u#error(printf('The provided value ''%i'' of the option %s is'
          \ . ' too small. The minimum value is %i. See '':h '.help_text.'%s''.', a:users_value,
          \ setting_origin, a:value_infos.min, a:key))
  endif

  if a:value_infos.type == type(0) && has_key(a:value_infos, 'max') &&
        \ a:users_value > a:value_infos.max
    call vimwiki#u#error(printf('The provided value ''%i'' of the option %s is'
          \ . ' too large. The maximum value is %i. See '':h '.help_text.'%s''.', a:users_value,
          \ setting_origin, a:value_infos.max, a:key))
  endif

  if has_key(a:value_infos, 'possible_values') &&
        \ index(a:value_infos.possible_values, a:users_value) == -1
    call vimwiki#u#error(printf('The provided value ''%s'' of the option %s is'
          \ . ' invalid. Allowed values are %s. See '':h '.help_text.'%s''.', a:users_value,
          \ setting_origin, string(a:value_infos.possible_values), a:key))
  endif

  if a:value_infos.type == type('') && has_key(a:value_infos, 'length') &&
        \ strwidth(a:users_value) != a:value_infos.length
    call vimwiki#u#error(printf('The provided value ''%s'' of the option %s must'
          \ . ' contain exactly %i character(s) but has %i. See '':h '.help_text.'_%s''.',
          \ a:users_value, setting_origin, a:value_infos.length, strwidth(a:users_value), a:key))
  endif

  if a:value_infos.type == type('') && has_key(a:value_infos, 'min_length') &&
        \ strwidth(a:users_value) < a:value_infos.min_length
    call vimwiki#u#error(printf('The provided value ''%s'' of the option %s must'
          \ . ' have at least %d character(s) but has %d. See '':h '.help_text.'%s''.', a:users_value,
          \ setting_origin, a:value_infos.min_length, strwidth(a:users_value), a:key))
  endif
endfunction


function! s:update_key(output_dic, key, old, new) abort
  " Helper: Treat special variables
  " Set list margin
  if a:key ==# 'list_margin'
    let s:margin_set_by_user = 1
    let a:output_dic[a:key] = a:new
    return
  " Extend Tag format
  elseif a:key ==# 'tag_format'
    let a:output_dic[a:key] = {}
    call extend(a:output_dic[a:key], a:old)
    call extend(a:output_dic[a:key], a:new)
    return
  else
    let a:output_dic[a:key] = a:new
    return
  endif
endfunction

" ----------------------------------------------------------
" 1. Global {{{1
" ----------------------------------------------------------

function! s:get_default_global() abort
  " Get default wikilocal values
  " Please: keep alphabetical sort
  return {
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
        \ 'emoji_enable': {'type': type(0), 'default': 3, 'min':0, 'max': 3},
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
        \     'table_format': 1, 'table_mappings': 1, 'lists': 1, 'lists_return': 1,
        \     'links': 1, 'html': 1, 'mouse': 0,
        \   }},
        \ 'links_header': {'type': type(''), 'default': 'Generated Links', 'min_length': 1},
        \ 'links_header_level': {'type': type(0), 'default': 1, 'min': 1, 'max': 6},
        \ 'listing_hl': {'type': type(0), 'default': 0, 'min': 0, 'max': 1},
        \ 'listing_hl_command': {'type': type(''), 'default': 'pygmentize -f html'},
        \ 'listsyms': {'type': type(''), 'default': ' .oOX', 'min_length': 2},
        \ 'listsym_rejected': {'type': type(''), 'default': '-', 'length': 1},
        \ 'map_prefix': {'type': type(''), 'default': '<Leader>w'},
        \ 'markdown_header_style': {'type': type(0), 'default': 1, 'min':0, 'max': 2},
        \ 'menu': {'type': type(''), 'default': 'Vimwiki'},
        \ 'schemes_web': {'type': type([]), 'default':
        \   [
        \     'http', 'https', 'file', 'ftp', 'gopher', 'telnet', 'nntp', 'ldap',
        \     'rsync', 'imap', 'pop', 'irc', 'ircs', 'cvs', 'svn', 'svn+ssh',
        \     'git', 'ssh', 'fish', 'sftp', 'thunderlink', 'message'
        \   ]},
        \ 'schemes_any': {'type': type([]), 'default': ['mailto', 'matrix', 'news', 'xmpp', 'sip', 'sips', 'doi', 'urn', 'tel', 'data']},
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
endfunction


function! s:populate_global_variables() abort
  " Populate: global variable <- user & default
  " Called: s:vimwiki#vars#init
  call s:read_global_settings_from_user()
  call s:normalize_global_settings()
  call s:internal_global_settings()
endfunction


function! s:internal_global_settings() abort
  " Declare: normalized settings -> more usefull variables to use internally
  " non-configurable global variables:

  " Scheme regexes must be defined even if syntax file is not loaded yet cause users should be
  " able to <leader>w<leader>w without opening any vimwiki file first

  " Know internal schemes

  let g:vimwiki_global_vars.schemes_web =
        \ join(vimwiki#vars#get_global('schemes_web'), '\|')
  let g:vimwiki_global_vars.schemes_any =
        \ join(vimwiki#vars#get_global('schemes_any'), '\|')
  let g:vimwiki_global_vars.schemes_local =
        \ join(['wiki\d\+', 'diary', 'local'], '\|')

  " Concatenate known schemes => regex
  let g:vimwiki_global_vars.rxSchemes = '\%('.
        \ g:vimwiki_global_vars.schemes_local . '\|'.
        \ g:vimwiki_global_vars.schemes_web . '\|'.
        \ g:vimwiki_global_vars.schemes_any .
        \ '\)'

  " Match URL for common protocols; see http://en.wikipedia.org/wiki/URI_scheme
  " http://tools.ietf.org/html/rfc3986
  let rxWebProtocols =
        \ '\%('.
          \ '\%('.
            \ '\%('. g:vimwiki_global_vars.schemes_web . '\):'.
            \ '\%(//\)'.
          \ '\)'.
        \ '\|'.
          \ '\%('. g:vimwiki_global_vars.schemes_any .'\):'.
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


function! s:extend_global(output_dic, default_dic) abort
  " Extend global dictionary <- default <- user
  " Note: user_dic is unused here because it comes from g:vimwiki_* vars
  " Copy the user's settings from variables of the form g:vimwiki_<option> into the dict
  " g:vimwiki_global_vars (or set a default value)
  for key in keys(a:default_dic)
    let value_infos = a:default_dic[key]
    if exists('g:vimwiki_'.key)
      let user_value = g:vimwiki_{key}

      call s:check_users_value(key, user_value, value_infos, 1)

      call s:update_key(a:output_dic, key, value_infos.default, user_value)
      " Remove user_value to prevent type mismatch (E706) errors in vim <7.4.1546
      unlet user_value
    else
      let a:output_dic[key] = value_infos.default
    endif
  endfor
  return a:output_dic
endfunction


function! s:read_global_settings_from_user() abort
  " Read user global settings
  " Called: s:populate_global_variables
  let default_dic = s:get_default_global()

  " Update batch
  call s:extend_global(g:vimwiki_global_vars, default_dic)

  " Validate some settings individually
  let key = 'diary_months'
  let users_value = g:vimwiki_global_vars[key]
  for month in range(1, 12)
    if !has_key(users_value, month) || type(users_value[month]) != type('') ||
          \ empty(users_value[month])
      call vimwiki#u#error(printf('The provided value ''%s'' of the option ''g:vimwiki_%s'' is'
            \ . ' invalid. See '':h g:vimwiki_%s''.', string(users_value), key, key))
      break
    endif
  endfor

  let key = 'ext2syntax'
  let users_value = g:vimwiki_global_vars[key]
  for ext in keys(users_value)
    if empty(ext) || index(['markdown', 'media', 'mediawiki', 'default'], users_value[ext]) == -1
      call vimwiki#u#error(printf('The provided value ''%s'' of the option ''g:vimwiki_%s'' is'
            \ . ' invalid. See '':h g:vimwiki_%s''.', string(users_value), key, key))
      break
    endif
  endfor
endfunction


function! s:normalize_global_settings() abort
  " Normalize user global settings
  " Called: s:populate_global_variables
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
  if !has_key(g:vimwiki_global_vars.key_mappings, 'lists_return')
    let g:vimwiki_global_vars.key_mappings.lists_return = 1
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
    let g:vimwiki_global_vars.key_mappings.lists_return = 0
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
" 3. Wiki local {{{1
" ----------------------------------------------------------

function! s:get_default_wikilocal() abort
  " Get default wikilocal values
  " Please: keep alphabetical sort
  " Build color_tag_template regular expression
  " Must be coherent with VimwikiColorize
  let fg = 'color\s*:\s*__COLORFG__\s*;\s*'
  let bg = 'background\s*:\s*__COLORBG__\s*;\s*'
  let color_tag_rx = '<span \s*style\s*=\s*"\s*\('
        \ . fg . bg . '\|' . fg . '\|' . bg
        \ . '\)"\s*>__CONTENT__<\/span>'
  return {
        \ 'auto_diary_index': {'type': type(0), 'default': 0, 'min': 0, 'max': 1},
        \ 'auto_export': {'type': type(0), 'default': 0, 'min': 0, 'max': 1},
        \ 'auto_generate_links': {'type': type(0), 'default': 0, 'min': 0, 'max': 1},
        \ 'auto_generate_tags': {'type': type(0), 'default': 0, 'min': 0, 'max': 1},
        \ 'auto_tags': {'type': type(0), 'default': 0, 'min': 0, 'max': 1},
        \ 'auto_toc': {'type': type(0), 'default': 0, 'min': 0, 'max': 1},
        \ 'automatic_nested_syntaxes': {'type': type(0), 'default': 1, 'min': 0, 'max': 1},
        \ 'base_url': {'type': type(''), 'default': '', 'min_length': 1},
        \ 'bullet_types': {'type': type([]), 'default': []},
        \ 'color_dic': {'type': type({}), 'default': {
        \   'default': ['', '#d79921'],
        \   'red': ['#cc241d', ''],
        \   'bred': ['', '#cc241d'],
        \   'green': ['#98971a', ''],
        \   'bgreen': ['', '#98971a'],
        \   'yellow': ['#d79921', ''],
        \   'byellow': ['', '#d79921'],
        \   'blue': ['#458588', ''],
        \   'bblue': ['', '#458588'],
        \   'purple': ['#b16286', ''],
        \   'bpurple': ['', '#b16286'],
        \   'orange': ['#d65d0e', ''],
        \   'borange': ['', '#d65d0e'],
        \   'gray': ['#a89984', ''],
        \   'bgray': ['', '#a89984']}},
        \ 'color_tag_template': {'type': type({}), 'default': color_tag_rx},
        \ 'commentstring': {'type': type(''), 'default': '%%%s'},
        \ 'css_name': {'type': type(''), 'default': 'style.css', 'min_length': 1},
        \ 'custom_wiki2html': {'type': type(''), 'default': ''},
        \ 'custom_wiki2html_args': {'type': type(''), 'default': ''},
        \ 'cycle_bullets': {'type': type(0), 'default': 0},
        \ 'diary_frequency': {'type': type(''), 'default': 'daily', 'possible_values': ['daily', 'weekly', 'monthly', 'yearly']},
        \ 'diary_start_week_day': {'type': type(''), 'default': 'monday', 'possible_values': ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday']},
        \ 'diary_header': {'type': type(''), 'default': 'Diary', 'min_length': 1},
        \ 'diary_index': {'type': type(''), 'default': 'diary', 'min_length': 1},
        \ 'diary_rel_path': {'type': type(''), 'default': 'diary/', 'min_length': 0},
        \ 'diary_caption_level': {'type': type(0), 'default': 0, 'min': -1, 'max': 6},
        \ 'diary_sort': {'type': type(''), 'default': 'desc', 'possible_values': ['asc', 'desc']},
        \ 'exclude_files': {'type': type([]), 'default': []},
        \ 'ext': {'type': type(''), 'default': '.wiki', 'min_length': 1},
        \ 'html_filename_parameterization': {'type': type(0), 'default': 0, 'min': 0, 'max': 1},
        \ 'generated_links_caption': {'type': type(0), 'default': 0 },
        \ 'index': {'type': type(''), 'default': 'index', 'min_length': 1},
        \ 'links_space_char': {'type': type(''), 'default': ' ', 'min_length': 1},
        \ 'list_ignore_newline': {'type': type(0), 'default': 1, 'min': 0, 'max': 1},
        \ 'list_margin': {'type': type(0), 'default': -1, 'min': -1},
        \ 'listsym_rejected': {'type': type(''), 'default': vimwiki#vars#get_global('listsym_rejected')},
        \ 'listsyms': {'type': type(''), 'default': vimwiki#vars#get_global('listsyms')},
        \ 'listsyms_propagate': {'type': type(0), 'default': 1},
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
        \ 'template_date_format': {'type': type(''), 'default': '%Y-%m-%d'},
        \ 'text_ignore_newline': {'type': type(0), 'default': 1, 'min': 0, 'max': 1},
        \ 'tag_format': {'type': type({}), 'default': {
        \   'pre': '^\|\s',
        \   'pre_mark': ':',
        \   'in': '[^:''[:space:]]\+',
        \   'sep': ':',
        \   'post_mark': ':',
        \   'post': '\s\|$',
        \   'conceal': 0, 'cchar':''}},
        \ 'toc_header': {'type': type(''), 'default': 'Contents', 'min_length': 1},
        \ 'toc_header_level': {'type': type(0), 'default': 1, 'min': 1, 'max': 6},
        \ 'toc_link_format': {'type': type(0), 'default': 0, 'min': 0, 'max': 1},
        \ 'rx_todo': {'type': type(''), 'default': '\C\<\%(TODO\|DONE\|STARTED\|FIXME\|FIXED\|XXX\)\>'},
        \ }
endfunction

function! s:extend_local(output_dic, default_dic, global_dic, user_dic) abort
  " Extend syntaxlocal dictionary <- global <- user (default for type check)
  " IDEA: can work lazily and not on all wikis at first call
  " IDEA: have a special variable for wikitmp
  for key in keys(a:default_dic)
    " Key present
    if has_key(a:user_dic, key)
      call s:check_users_value(key, a:user_dic[key], a:default_dic[key], 0)
      call s:update_key(a:output_dic, key, a:global_dic[key], a:user_dic[key])
    else
      let a:output_dic[key] = a:global_dic[key]
    endif
  endfor
  return a:output_dic
endfunction


function! s:populate_wikilocal_options() abort
  " Populate local variable <- user & default
  " Called: s:vimwiki#vars#init
  " Retrieve default
  let default_dic = s:get_default_wikilocal()

  " Extend from global setting
  let global_wiki_dic = s:extend_global({}, default_dic)

  " Extend from g:vimwiki_list
  if !exists('g:vimwiki_list')
    " if the user hasn't registered any wiki, we register one wiki using the default values
    let new_wiki_dic = deepcopy(global_wiki_dic)
    let new_wiki_dic.is_temporary_wiki = 0
    call add(g:vimwiki_wikilocal_vars, new_wiki_dic)
  else
    for user_dic in g:vimwiki_list
      let new_wiki_dic = s:extend_local({}, default_dic, global_wiki_dic, user_dic)
      let new_wiki_dic.is_temporary_wiki = 0
      call add(g:vimwiki_wikilocal_vars, new_wiki_dic)
    endfor
  endif

  " Set default values for temporary wikis
  let temp_dic = deepcopy(global_wiki_dic)
  let temp_dic.is_temporary_wiki = 1
  call add(g:vimwiki_wikilocal_vars, temp_dic)

  " Normalize and leave
  call s:normalize_wikilocal_settings()
endfunction


function! s:normalize_wikilocal_settings() abort
  " Normalize local settings
  for wiki_settings in g:vimwiki_wikilocal_vars
    " Check some values individually
    """"""""""""""""""""""""""""""""
    " Treat lists
    " TODO remove me: I am syntaxlocal
    if !has_key(wiki_settings, 'bullet_types') || len(wiki_settings.bullet_types) == 0
      let wiki_settings.bullet_types = vimwiki#vars#get_syntaxlocal('bullet_types', wiki_settings.syntax)
    endif
    call s:populate_list_vars(wiki_settings)

    call s:populate_blockquote_vars(wiki_settings)

    " Check nested syntax
    for keyword in keys(wiki_settings.nested_syntaxes)
      if type(keyword) != type('') || empty(keyword) || type(wiki_settings.nested_syntaxes[keyword]) != type('') ||
            \ empty(wiki_settings.nested_syntaxes[keyword])
        call vimwiki#u#error(printf('The provided value ''%s'' of the option ''g:vimwiki_%s'' is'
              \ . ' invalid. See '':h g:vimwiki_%s''.', string(wiki_settings.nested_syntaxes), 'nested_syntaxes', 'nested_syntaxes'))
        break
      endif
    endfor

    " Normalize
    """"""""""""""""""""""""""""""""
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


function! s:normalize_path(path) abort
  " Helper path
  " TODO move to path: Conflict with: vimwiki#path#path_norm && vimwiki#path#normalize
  " trim trailing / and \ because otherwise resolve() doesn't work quite right
  let path = substitute(a:path, '[/\\]\+$', '', '')
  if path !~# '^scp:'
    return resolve(expand(path)).'/'
  else
    return path.'/'
  endif
endfunction


" ----------------------------------------------------------
" 2. Syntax specific {{{1
" ----------------------------------------------------------

function! s:get_default_syntaxlocal() abort
  " Get default syntaxlocal variable dictionary
  " type, default, min, max, possible_values, min_length

  return extend(s:get_common_syntaxlocal(), {
        \ 'blockquote_markers': {'type': type([]), 'default': ['>', '::']},
        \ 'bold_match': {'type': type(''), 'default': '\%(^\|\s\|[[:punct:]]\)\@<=\*__Text__\*\%([[:punct:]]\|\s\|$\)\@='},
        \ 'bold_search': {'type': type(''), 'default': '\%(^\|\s\|[[:punct:]]\)\@<=\*\zs\%([^*`[:space:]][^*`]*[^*`[:space:]]\|[^*`[:space:]]\)\ze\*\%([[:punct:]]\|\s\|$\)\@='},
        \ 'bullet_types': {'type': type([]), 'default': ['-', '*', '#']},
        \ 'header_match': {'type': type(''), 'default': '^\s*\(=\{1,6}\)=\@!\s*__Header__\s*\1=\@!\s*$'},
        \ 'header_search': {'type': type(''), 'default': '^\s*\(=\{1,6}\)\([^=].*[^=]\)\1\s*$'},
        \ 'list_markers': {'type': type([]), 'default': ['-', '1.', '*', 'I)', 'a)']},
        \ 'number_types': {'type': type([]), 'default': ['1)', '1.', 'i)', 'I)', 'a)', 'A)']},
        \ 'recurring_bullets': {'type': type(0), 'default': 0},
        \ 'header_symbol': {'type': type(''), 'default': '='},
        \ 'rxHR': {'type': type(''), 'default': '^-----*$'},
        \ 'rxListDefine': {'type': type(''), 'default': '::\(\s\|$\)'},
        \ 'math_format': {'type': type({}), 'default': {
        \   'pre_mark': '{{\$',
        \   'post_mark': '}}\$'}},
        \ 'multiline_comment_format': {'type': type({}), 'default': {
        \   'pre_mark': '%%+',
        \   'post_mark': '+%%'}},
        \ 'pre_format': {'type': type({}), 'default': {
        \   'pre_mark': '{{{',
        \   'post_mark': '}}}'}},
        \ 'symH': {'type': type(1), 'default': 1},
        \ 'typeface': {'type': type({}), 'default': {
        \   'bold': vimwiki#u#hi_expand_regex([['\*', '\*', '[*]', 0]]),
        \   'italic': vimwiki#u#hi_expand_regex([['_', '_', '[_]', 0]]),
        \   'underline': vimwiki#u#hi_expand_regex([]),
        \   'bold_italic': vimwiki#u#hi_expand_regex([['\*_', '_\*', '[*_]', 1], ['_\*', '\*_', '[*_]', 1]]),
        \   'code': [
        \       ['\%(^\|[^`]\)\@<=`\%($\|[^`]\)\@=',
        \        '\%(^\|[^`]\)\@<=`\%($\|[^`]\)\@='],
        \       ['\%(^\|[^`]\)\@<=``\%($\|[^`]\)\@=',
        \        '\%(^\|[^`]\)\@<=``\%($\|[^`]\)\@='],
        \       ],
        \   'del': [['\~\~', '\~\~']],
        \   'sup': [['\^', '\^']],
        \   'sub': [[',,', ',,']],
        \   'eq': [[s:rx_inline_math_start, s:rx_inline_math_end]],
        \   }},
        \ 'wikilink': {'type': type(''), 'default': '\[\[\zs[^\\\]|]\+\ze\%(|[^\\\]]\+\)\?\]\]'},
        \ })
endfunction

function! s:get_markdown_syntaxlocal() abort
  let atx_header_search = '^\s*\(#\{1,6}\)\([^#].*\)$'
  let atx_header_match  = '^\s*\(#\{1,6}\)#\@!\s*__Header__\s*$'

  let setex_header_search = '^\s\{0,3}\zs[^>].*\ze\n'
  let setex_header_search .= '^\s\{0,3}[=-]\{2,}$'

  let setex_header_match = '^\s\{0,3}>\@!__Header__\n'
  let setex_header_match .= '^\s\{0,3}[=-][=-]\+$'

  return extend(s:get_common_syntaxlocal(), {
        \ 'bold_match': {'type': type(''), 'default': '\%(^\|\s\|[[:punct:]]\)\@<=\*__Text__\*\%([[:punct:]]\|\s\|$\)\@='},
        \ 'bold_search': {'type': type(''), 'default': '\%(^\|\s\|[[:punct:]]\)\@<=\*\zs\%([^*`[:space:]][^*`]*[^*`[:space:]]\|[^*`[:space:]]\)\ze\*\%([[:punct:]]\|\s\|$\)\@='},
        \ 'bullet_types': {'type': type([]), 'default': ['*', '-', '+']},
        \ 'header_match': {'type': type(''), 'default': '\%(' . atx_header_match . '\|' . setex_header_match . '\)'},
        \ 'header_search': {'type': type(''), 'default': '\%(' . atx_header_search . '\|' . setex_header_search . '\)'},
        \ 'list_markers': {'type': type([]), 'default': ['-', '*', '+', '1.']},
        \ 'number_types': {'type': type([]), 'default': ['1.']},
        \ 'recurring_bullets': {'type': type(0), 'default': 0},
        \ 'header_symbol': {'type': type(''), 'default': '#'},
        \ 'rxHR': {'type': type(''), 'default': '\(^---*$\|^___*$\|^\*\*\**$\)'},
        \ 'rxListDefine': {'type': type(''), 'default': '::\%(\s\|$\)'},
        \ 'math_format': {'type': type({}), 'default': {
        \   'pre_mark': '\$\$',
        \   'post_mark': '\$\$'}},
        \ 'multiline_comment_format': {'type': type({}), 'default': {
        \   'pre_mark': '',
        \   'post_mark': ''}},
        \ 'pre_format': {'type': type({}), 'default': {
        \   'pre_mark': '\%(`\{3,}\|\~\{3,}\)',
        \   'post_mark': '\%(`\{3,}\|\~\{3,}\)'}},
        \ 'symH': {'type': type(0), 'default': 0},
        \ 'typeface': {'type': type({}), 'default': {
        \   'bold': vimwiki#u#hi_expand_regex([
        \     ['__', '__', '[_*]', 1],
        \     ['\*\*', '\*\*', '[_*]', 1],
        \     ]),
        \   'italic': vimwiki#u#hi_expand_regex([
        \     ['_', '_', '[_*]', 0],
        \     ['\*', '\*', '[_*]', 0],
        \     ['\*_', '_\*', '[_*]', 1],
        \     ['_\*', '\*_', '[_*]', 1],
        \     ]),
        \   'underline': vimwiki#u#hi_expand_regex([]),
        \   'bold_italic': vimwiki#u#hi_expand_regex([
        \     ['___', '___', '[_*]', 1],
        \     ['\*\*\*', '\*\*\*', '[_*]', 1],
        \     ]),
        \   'code': [
        \       ['\%(^\|[^`\\]\)\@<=`\%($\|[^`]\)\@=',
        \        '\%(^\|[^`]\)\@<=`\%($\|[^`]\)\@='],
        \       ['\%(^\|[^`\\]\)\@<=``\%($\|[^`]\)\@=',
        \        '\%(^\|[^`]\)\@<=``\%($\|[^`]\)\@='],
        \       ],
        \   'del': [['\~\~', '\~\~']],
        \   'sup': [['\^', '\^']],
        \   'sub': [[',,', ',,']],
        \   'eq': [[s:rx_inline_math_start, s:rx_inline_math_end]],
        \   }},
        \ 'wikilink': {'type': type(''), 'default': '\[\[\zs[^\\\]|]\+\ze\%(|[^\\\]]\+\)\?\]\]'},
        \ })
endfunction

function! s:get_media_syntaxlocal() abort
  return extend(s:get_common_syntaxlocal(), {
        \ 'bold_match': {'type': type(''), 'default': '''''''__Text__'''''''},
        \ 'bold_search': {'type': type(''), 'default': "'''\\zs[^']\\+\\ze'''"},
        \ 'bullet_types': {'type': type([]), 'default': ['*', '#']},
        \ 'header_match': {'type': type(''), 'default': '^\s*\(=\{1,6}\)=\@!\s*__Header__\s*\1=\@!\s*$'},
        \ 'header_search': {'type': type(''), 'default': '^\s*\(=\{1,6}\)\([^=].*[^=]\)\1\s*$'},
        \ 'list_markers': {'type': type([]), 'default': ['*', '#']},
        \ 'number_types': {'type': type([]), 'default': []},
        \ 'recurring_bullets': {'type': type(1), 'default': 1},
        \ 'header_symbol': {'type': type(''), 'default': '='},
        \ 'rxHR': {'type': type(''), 'default': '^-----*$'},
        \ 'rxListDefine': {'type': type(''), 'default': '^\%(;\|:\)\s'},
        \ 'math_format': {'type': type({}), 'default': {
        \   'pre_mark': '{{\$',
        \   'post_mark': '}}\$'}},
        \ 'multiline_comment_format': {'type': type({}), 'default': {
        \   'pre_mark': '',
        \   'post_mark': ''}},
        \ 'pre_format': {'type': type({}), 'default': {
        \   'pre_mark': '<pre>',
        \   'post_mark': '<\/pre>'}},
        \ 'symH': {'type': type(1), 'default': 1},
        \ 'typeface': {'type': type({}), 'default': {
        \   'bold': [['\S\@<=''''''\|''''''\S\@=', '\S\@<=''''''\|''''''\S\@=']],
        \   'italic': [['\S\@<=''''\|''''\S\@=', '\S\@<=''''\|''''\S\@=']],
        \   'underline': [],
        \   'bold_italic': [['\S\@<=''''''''''\|''''''''''\S\@=', '\S\@<=''''''''''\|''''''''''\S\@=']],
        \   'code': [
        \       ['\%(^\|[^`]\)\@<=`\%($\|[^`]\)\@=',
        \        '\%(^\|[^`]\)\@<=`\%($\|[^`]\)\@='],
        \       ['\%(^\|[^`]\)\@<=``\%($\|[^`]\)\@=',
        \        '\%(^\|[^`]\)\@<=``\%($\|[^`]\)\@='],
        \       ],
        \   'del': [['\~\~', '\~\~']],
        \   'sup': [['\^', '\^']],
        \   'sub': [[',,', ',,']],
        \   'eq': [[s:rx_inline_math_start, s:rx_inline_math_end]],
        \   }},
        \ 'wikilink': {'type': type(''), 'default': '\[\[\zs[^\\\]|]\+\ze\%(|[^\\\]]\+\)\?\]\]'},
        \ })
endfunction

function! s:get_common_syntaxlocal() abort
  let res = {}

  " Declare helper: a line with only --- or ...
  let rx_yaml_start_pre = '\%(^\%(\%1l\|^$\n\)\@<=\)'
  let rx_yaml_start_post = '\%(\%(\n^$\)\@!$\)'
  let rx_yaml_start = rx_yaml_start_pre . '---' . rx_yaml_start_post
  let rx_yaml_end = '^\%(---\|\.\.\.\)\s*$'

  let res.nested_extended = {'type': type(''), 'default': 'VimwikiError,VimwikiPre,VimwikiCode,VimwikiEqIn,VimwikiSuperScript,VimwikiSubScript,textSnipTEX'}
  let res.nested_typeface = {'type': type(''), 'default': 'VimwikiBold,VimwikiItalic,VimwikiUnderline,VimwikiDelText'}
  let res.nested = {'type': type(''), 'default': res.nested_extended.default . ',' . res.nested_typeface.default}
  let res.rxTableSep = {'type': type(''), 'default': '|'}
  " See issue #1287
  let res.yaml_metadata_block = {'type': type([]), 'default': [[rx_yaml_start, rx_yaml_end]]}

  " Declare helper for inline math nested variable
  let s:rx_inline_math_start = '\%(^\|[^$\\]\)\@<=\$\%($\|[^$[:space:]]\)\@='
  let s:rx_inline_math_end   = '\%(^\|[^$\\[:space:]]\)\@<=\$\%($\|[^$0-9]\)\@='

  " Blockquote marker (#1274)
  " -- it should not be changed but let's avoid hardcoding
  let res.blockquote_markers = {'type': type([]), 'default': ['>']}

  " HTML comment
  let res.comment_regex = {'type': type(''), 'default': '\%(^\s*%%.*$\|<!--\%([^>]\|\n\)*-->\)'}

  " Opening link with dot in the ref, see #1271 and ref and Brennen comment:
  " -- https://github.com/vimwiki/vimwiki/issues/1271#issuecomment-1482207680
  let res.open_link_add_ext = {'type': type(1), 'default': 1}

  return res
endfunction


function! vimwiki#vars#populate_syntax_vars(syntax) abort
  " Populate syntax variable
  " Exported: syntax/vimwiki.vim
  " TODO refactor <= too big function
  " TODO permit user conf in some var like g:vimwiki_syntaxlocal_vars
  " TODO internalize match and search (header and bold)
  " Create is not exists
  if !exists('g:vimwiki_syntaxlocal_vars')
    let g:vimwiki_syntaxlocal_vars = {}
  endif

  " Clause: leave if already filled
  if has_key(g:vimwiki_syntaxlocal_vars, a:syntax)
    return
  endif

  " Init internal dic
  let g:vimwiki_syntaxlocal_vars[a:syntax] = {}
  let syntax_dic = g:vimwiki_syntaxlocal_vars[a:syntax]

  " Get default dic
  let default_dic = extend({}, function('s:get_' . a:syntax . '_syntaxlocal')())

  " Extend <- default <- user global
  call s:extend_global(syntax_dic, default_dic)
  " Extend <- user wikilocal
  let wikilocal = g:vimwiki_wikilocal_vars[vimwiki#vars#get_bufferlocal('wiki_nr')]
  " TODO remake tests
  "call s:extend_local(syntax_dic, default_dic, syntax_dic, wikilocal)
  " Extend <- user syntaxlocal
  if exists('g:vimwiki_syntax_list') && has_key(g:vimwiki_syntax_list, a:syntax)
    call s:extend_local(syntax_dic, default_dic, syntax_dic, g:vimwiki_syntax_list[a:syntax])
  endif

  " TODO make that clean (i.e clarify what is local to syntax or to buffer)
  " Get from local vars
  let bullet_types = vimwiki#vars#get_wikilocal('bullet_types')
  if !empty(bullet_types)
    let syntax_dic['bullet_types'] = bullet_types
  endif
  let syntax_dic['cycle_bullets'] =
        \ vimwiki#vars#get_wikilocal('cycle_bullets')

  " Tag: get var
  " TODO rename for internal
  let syntax_dic.tag_format = {}
  let tf = syntax_dic.tag_format
  call extend(tf, vimwiki#vars#get_wikilocal('tag_format'))

  " Tag: Close regex
  for key in ['pre', 'pre_mark', 'in', 'sep', 'post_mark', 'post']
    let tf[key] = '\%(' . tf[key] . '\)'
  endfor

  " Match \s<tag[:tag:tag:tag...]>\s
  " Tag: highlighting
  " Used: syntax/vimwiki.vim
  let syntax_dic.rxTags =
        \   tf.pre . '\@<=' . tf.pre_mark . tf.in
        \ . '\%(' . tf.sep . tf.in . '\)*'
        \ . tf.post_mark . tf.post . '\@='

  " Tag: searching for all
  " Used: vimwiki#base#get_anchors <- GenerateTagLinks
  let syntax_dic.tag_search =
        \   tf.pre . tf.pre_mark . '\zs'
        \ . tf.in . '\%(' . tf.sep . tf.in . '\)*'
        \ . '\ze' . tf.post_mark . tf.post

  " Tag: matching a specific: when goto tag
  " Used: tags.vim->s:scan_tags
  " Match <[tag:tag:...tag:]__TAG__[:tag...:tag]>
  let syntax_dic.tag_match =
        \   tf.pre . tf.pre_mark
        \ . '\%(' . tf.in . tf.sep . '\)*'
        \ . '__Tag__'
        \ . '\%(' . tf.sep . tf.in . '\)*'
        \ . tf.post_mark . tf.post


  " Populate generic stuff
  let header_symbol = syntax_dic.header_symbol
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
            \ .header_symbol.'\{1,'.i.'}\s*$\|\%$'
    endfor
    let syntax_dic.rxHeader =
          \ '^\s*\('.header_symbol.'\{1,6}\)\zs[^'.header_symbol.'].*[^'.header_symbol.']\ze\1\s*$'
  else
    " asymmetric
    " Note: For markdown rxH=# and asymmetric
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
            \ '^\s*'.header_symbol.'\{1,'.i.'}[^'.header_symbol.'].*$\|\%$'
    endfor
    " Define header regex
    " -- ATX heading := preceded by #*
    let atx_heading = '^\s*\%('.header_symbol.'\{1,6}\)'
    let atx_heading .= '\zs[^'.header_symbol.'].*\ze$'
    let syntax_dic.rxHeader = atx_heading
  endif

  let syntax_dic.rxPreStart =
        \ '^\s*'.syntax_dic.pre_format.pre_mark
  let syntax_dic.rxPreEnd =
        \ '^\s*'.syntax_dic.pre_format.post_mark.'\s*$'

  let syntax_dic.rxMathStart =
        \ '^\s*'.syntax_dic.math_format.pre_mark
  let syntax_dic.rxMathEnd =
        \ '^\s*'.syntax_dic.math_format.post_mark.'\s*$'

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


function! s:populate_list_vars(wiki) abort
  " Populate list variable
  " or how to search and treat list (ex: *,-, 1.)
  " TODO this should be syntax_local
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
    call vimwiki#u#warn('the value of listsym_rejected ('''
          \ . a:wiki.listsym_rejected . ''') must not be a part of listsyms ('''
          \ . a:wiki.listsyms . ''')')
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


function! s:populate_blockquote_vars(wiki) abort
  " Populate blockquote variable
  " Start being more intelligent on blockquote line continuation
  " See: issue #1274

  " Start of line and spaces
  let a:wiki.rxBlockquoteItem = '^\s*\('

  " Content
  let blockquote_markers =  vimwiki#vars#get_syntaxlocal('blockquote_markers')
  let a:wiki.rxBlockquoteItem .= join(blockquote_markers, '\|')

  let a:wiki.rxBlockquoteItem .= '\)'
endfunction


function! s:populate_extra_markdown_vars() abort
  " Populate markdown specific syntax variables
  let mkd_syntax = g:vimwiki_syntaxlocal_vars['markdown']

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
  let mkd_syntax.rxWeblink1EscapeCharsSuffix = '\(\\\)\@<!\(>\=)\)'
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
  let mkd_syntax.rxWeblink1Separator = '\](<\='
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


function! s:normalize_syntax_settings(syntax) abort
  " Normalize syntax setting
  "   so that we dont have to branch for the syntax at each operation
  " Called: populate_syntax_vars
  let syntax_dic = g:vimwiki_syntaxlocal_vars[a:syntax]

  " Link1: used when:
  "   user press enter on a non-link (normalize_link)
  "   command generate link form file name (generate_link)
  if a:syntax ==# 'markdown'
    let syntax_dic.Link1 = syntax_dic.Weblink1Template
    let syntax_dic.Link2 = syntax_dic.Weblink1Template
  else
    let syntax_dic.Link1 = vimwiki#vars#get_global('WikiLinkTemplate1')
    let syntax_dic.Link2 = vimwiki#vars#get_global('WikiLinkTemplate2')
  endif
endfunction


" ----------------------------------------------------------
" 4. Command (exported) {{{1
" ----------------------------------------------------------

function! s:get_anywhere(key, ...) abort
  " Get variable anywhere
  " Returns: [value, location] where loc=global|wikilocal|syntaxlocal|bufferlocal|none
  " Called: cmd <- VimwikiVar
  " TODO get more performant approach when this file has been well refactored:
  " -- calls only the necessary functions and not syntaxlocal anytime
  " Alias common info
  let s:syntax = vimwiki#vars#get_wikilocal('syntax')
  let s:wiki_nr = vimwiki#vars#get_bufferlocal('wiki_nr')
  let s:wikilocal = g:vimwiki_wikilocal_vars[s:wiki_nr]
  let s:user_wiki = get(g:vimwiki_list, s:wiki_nr, {})

  " Convert value
  let value = ''
  if a:0
    exe 'let value = ' . a:1
  endif

  function! s:any_bufferlocal(key, value) abort
    if !(v:version > 703 && exists('b:vimwiki_'.a:key)) | return | endif
    exe 'let b:vimwiki_' . a:key . ' = ' . a:1
  endfunction

  " Define: Set syntax: only reparse wikilocal
  " Note: call set_wikilocal before
  function! s:any_syntaxlocal(key, value) abort
    "let syntaxlocal[a:key] = a:1
    " Prepare
    if exists('b:current_syntax')
      unlet b:current_syntax
    endif
    unlet g:vimwiki_syntaxlocal_vars

    " Build vars
    call vimwiki#vars#populate_syntax_vars(s:syntax)

    " Update syntax
    syntax clear
    runtime syntax/vimwiki.vim
    redraw
  endfunction

  " Define: Set local
  function! s:any_wikilocal(key, value) abort
    "let wikilocal[a:key] = a:1
    " Clause: The key must be in the wikilocal keys
    if !has_key(s:get_default_wikilocal(), a:key) | return | endif

    " Set: Local
    let s:user_wiki[a:key] = a:value
    call vimwiki#vars#init()
    call s:populate_wikilocal_options()
  endfunction

  function! s:any_global(key, value) abort
    "let g:vimwiki_global_vars[a:key] = a:1
    exe 'let g:vimwiki_' . a:key . ' = ' . string(a:value)
    call s:populate_global_variables()
  endfunction

  " Switch
  " -- Global
  if has_key(s:get_default_global(), a:key)
    if a:0
      call s:any_global(a:key, value)
      call s:any_wikilocal(a:key, value)
      call s:any_syntaxlocal(a:key, value)
      call s:any_bufferlocal(a:key, value)
    endif
    return [g:vimwiki_global_vars[a:key], 'global']

  " -- Wiki Local
  elseif has_key(s:get_default_wikilocal(), a:key)
    if a:0
      call s:any_wikilocal(a:key, value)
      call s:any_syntaxlocal(a:key, value)
      call s:any_bufferlocal(a:key, value)
    endif
    return [s:wikilocal[a:key], 'wikilocal']

  " -- Syntax Local
  elseif has_key(g:vimwiki_syntaxlocal_vars[s:syntax], a:key)
    if a:0
      call s:any_wikilocal(a:key, value)
      call s:any_syntaxlocal(a:key, value)
      call s:any_bufferlocal(a:key, value)
    endif
    return [g:vimwiki_syntaxlocal_vars[s:syntax][a:key], 'syntaxlocal']

  " -- Buffer Local
  elseif v:version > 703 && exists('b:vimwiki_'.a:key)
    if a:0
      call s:any_bufferlocal(a:key, value)
    endif
    return [get(getbufvar('%', ''), 'vimwiki_'.a:key, '/\/\'), 'bufferlocal']
  else
    return ['', 'none']
  endif
endfunction


function! vimwiki#vars#cmd(arg) abort
  " Set or Get a vimwiki variable
  " :param: (1) <string> command parameter: key [space] value
  " -- name of the variable [space] value to evaluate and set the variable
  " Called: VimwikiVar
  " Get key and value
  let sep1 = stridx(a:arg, ' ')
  let sep2 = sep1
  while sep2!= -1 && a:arg[sep2] ==# ' ' | let sep2 += 1 | endwhile
  let arg_key = sep1 == -1 ? a:arg : a:arg[:sep1-1]
  let arg_value = a:arg[sep2 :]

  " Case0: No argument => Print all keys and values
  if arg_key ==# ''
    " Get options keys
    " Merge default dictionary
    let d_global = s:get_default_global()
    let d_wlocal = s:get_default_wikilocal()
    let syntax = vimwiki#vars#get_wikilocal('syntax')
    let d_slocal = function('s:get_' . syntax . '_syntaxlocal')()
    let d_default = {}

    " Define helpers
    function! s:print_head(name) abort
      call vimwiki#u#echo(repeat('-', 50), 'Statement', '', '')
      call vimwiki#u#echo('  ' . a:name, 'Statement', '', '')
      call vimwiki#u#echo(repeat('-', 50), 'Statement', '', '')
    endfunction

    " Print Global
    call s:print_head('Global')
    for key in sort(keys(d_global))
      if !has_key(g:vimwiki_global_vars, key)
        continue
      endif
      if string(g:vimwiki_global_vars[key]) == string(d_global[key].default)
        let d_default[key] = string(d_global[key].default) . '          " From Global'
      else
        let msg = key .  ' = ' . string(g:vimwiki_global_vars[key])
        call vimwiki#u#echo(msg, '', 'm', '')
      endif
    endfor

    " Print SyntaxLocal
    let syntaxlocal = g:vimwiki_syntaxlocal_vars[syntax]
    call s:print_head('Syntax: ' . toupper(syntax[0]) . syntax[1:])
    for key in sort(keys(d_slocal))
      if !has_key(syntaxlocal, key)
        continue
      endif
      if string(syntaxlocal[key]) == string(d_slocal[key].default)
        let d_default[key] = string(d_slocal[key].default) . '          " From SyntaxLocal'
      else
        let msg = key .  ' = ' . string(syntaxlocal[key])
        call vimwiki#u#echo(msg, '', 'm', '')
      endif
    endfor

    " Print WikiLocal
    let wiki_nr = vimwiki#vars#get_bufferlocal('wiki_nr')
    let wikilocal = g:vimwiki_wikilocal_vars[wiki_nr]
    call s:print_head('Local: ' . wiki_nr)
    for key in sort(keys(d_wlocal))
      if !has_key(wikilocal, key)
        continue
      endif
      if string(wikilocal[key]) == string(d_wlocal[key].default)
        let d_default[key] = string(d_wlocal[key].default) . '          " From WikiLocal'
      else
        let msg = key .  ' = ' . string(wikilocal[key])
        call vimwiki#u#echo(msg, '', 'm', '')
      endif
    endfor

    " Print Default
    call s:print_head('Default')
    for key in sort(keys(d_default))
      let msg = key .  ' = ' . d_default[key]
      call vimwiki#u#echo(msg, '', 'm', '')
    endfor

  " Case1: Only key => Print value
  elseif sep1 == -1 || arg_value =~# '^\s*$'
    let [val, loc] = s:get_anywhere(arg_key)
    let msg = 'Got: ' . arg_key . ' = ' . string(val) . '   " <= From: ' . toupper(loc[0]) . loc[1:]
    call vimwiki#u#echo(msg, '', 'm')

  " Case2: Key and value => Set value
  else
    let [val, loc] = s:get_anywhere(arg_key, arg_value)
    let msg = 'Set: ' . arg_key . ' = ' . string(val) . '   " => To: ' . toupper(loc[0]) . loc[1:]
    call vimwiki#u#echo(msg, '', 'm')
  endif
endfunction


function! vimwiki#vars#complete(arglead, cmdline, pos) abort
  " Get key and value: faster than split
  " -- And must treat potential multispace in value
  let arg_list = split(a:cmdline, '\s\+')
  let sep1 = stridx(a:cmdline, ' ')
  while sep1!= -1 && a:cmdline[sep1] ==# ' ' | let sep1 += 1 | endwhile
  let sep2 = stridx(a:cmdline, ' ', sep1+1)
  while sep2!= -1 && a:cmdline[sep2] ==# ' ' | let sep2 += 1 | endwhile
  let arg_key = a:cmdline[sep1 : sep2]
  let arg_value = a:cmdline[sep2 :]

  " Case1: Complete key
  if arg_key[-1:-1] !=# ' '
    " Get options keys
    let keys = []
    call extend(keys, keys(s:get_default_global()))
    call extend(keys, keys(s:get_default_wikilocal()))

    " Filter and Return
    " -- Use smart case matching
    let arg_re = substitute(arg_key, '\u', '[\0\l\0]', 'g')
    " -- Match anywhere in variable name
    let arg_re = '.*' . arg_re . '.*'
    call filter(keys, '-1 != match(v:val, arg_re)')

    return keys
  " Case2: Complete value
  else
    " Remove trailing space
    let arg_key = substitute(arg_key, '\s\+$', '', '')
    let value = s:get_anywhere(arg_key)[0]
    return [string(value)]
  endif
endfunction


" ----------------------------------------------------------
" 4. Getter, Setter (exported) {{{1
" ----------------------------------------------------------

function! vimwiki#vars#get_syntaxlocal(key, ...) abort
  " Get syntax variable
  " Param: 1: key (<string>)
  " Param: (2): syntax name (<string> ex:'markdown')
  " Retrieve desired syntax name
  if a:0
    let syntax = a:1
  else
    let syntax = vimwiki#vars#get_wikilocal('syntax')
  endif

  " Create syntax variable dict if not exists (lazy)
  if !exists('g:vimwiki_syntaxlocal_vars') || !has_key(g:vimwiki_syntaxlocal_vars, syntax)
    call vimwiki#vars#populate_syntax_vars(syntax)
  endif

  " Return d_syntax[a:key]
  return g:vimwiki_syntaxlocal_vars[syntax][a:key]
endfunction


function! vimwiki#vars#set_syntaxlocal(key, value, ...) abort
  " Set syntax variable
  " Param: 1: key (<string>)
  " Param: 2: value (<any type>)
  " Param: (3): syntax name (<string> ex:'markdown')
  " Set desired syntax variable to value
  if a:0
    let syntax = a:1
  else
    let syntax = vimwiki#vars#get_wikilocal('syntax')
  endif

  " Create syntax variable dict if not exists (lazy)
  if !exists('g:vimwiki_syntaxlocal_vars') || !has_key(g:vimwiki_syntaxlocal_vars, syntax)
    call vimwiki#vars#populate_syntax_vars(syntax)
  endif

  " Set d_syntax[a:key]
  let g:vimwiki_syntaxlocal_vars[syntax][a:key] = a:value
endfunction


function! vimwiki#vars#get_bufferlocal(key, ...) abort
  " Return: buffer local variable
  " for the buffer we are currently in or for the given buffer (number or name).
  " Populate the variable, if it doesn't exist.
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
    call vimwiki#u#echo('unknown buffer variable ' . string(a:key))
  endif

  return getbufvar(buffer, 'vimwiki_'.a:key)
endfunction


function! vimwiki#vars#set_bufferlocal(key, value, ...) abort
  " Set buffer local variable
  let buffer = a:0 ? a:1 : '%'
  call setbufvar(buffer, 'vimwiki_' . a:key, a:value)
endfunction


function! vimwiki#vars#get_global(key) abort
  " Return: wiki global variable
  return g:vimwiki_global_vars[a:key]
endfunction


function! vimwiki#vars#set_global(key, value) abort
  " Set global variable
  let g:vimwiki_global_vars[a:key] = a:value
  return g:vimwiki_global_vars[a:key]
endfunction


function! vimwiki#vars#get_wikilocal(key, ...) abort
  " Return: wiki local named variable
  " Param: (1): variable name (alias key, <string>)
  " Param: (2): wiki number (<int>). When absent, the wiki of the currently active buffer is
  " used
  if a:0
    return g:vimwiki_wikilocal_vars[a:1][a:key]
  else
    return g:vimwiki_wikilocal_vars[vimwiki#vars#get_bufferlocal('wiki_nr')][a:key]
  endif
endfunction


function! vimwiki#vars#get_wikilocal_default(key) abort
  " Return: wiki local variable (of default wiki [index -1])
  return g:vimwiki_wikilocal_vars[-1][a:key]
endfunction


function! vimwiki#vars#set_wikilocal(key, value, ...) abort
  " Set local variable
  " Param: (2): wiki number (<int>). When absent, the wiki of the currently active buffer is
  " used
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


function! vimwiki#vars#add_temporary_wiki(settings) abort
  " Append new wiki to wiki list
  let new_temp_wiki_settings = copy(g:vimwiki_wikilocal_vars[-1])
  for [key, value] in items(a:settings)
    let new_temp_wiki_settings[key] = value
    " Remove users_value to prevent type mismatch (E706) errors in vim <7.4.1546  (Issue #681)
    unlet value
  endfor
  call insert(g:vimwiki_wikilocal_vars, new_temp_wiki_settings, -1)
  call s:normalize_wikilocal_settings()
endfunction


function! vimwiki#vars#number_of_wikis() abort
  " Return: number of registered wikis + temporary
  return len(g:vimwiki_wikilocal_vars) - 1
endfunction
" vim:tabstop=2:shiftwidth=2:expandtab:textwidth=99
