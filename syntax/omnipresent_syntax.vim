" vim:tabstop=2:shiftwidth=2:expandtab:foldmethod=marker:textwidth=79
" Vimwiki syntax file
" Desc: Syntax definitions which are always available
" Home: https://github.com/vimwiki/vimwiki/


" Define Regexes of anchors for every syntax.
" This has to be separated from vimwiki_default.vim, vimwiki_markdown.vim, etc.
" because the latter are only loaded and available if the current wiki has the
" corresponding syntax
let g:vimwiki_default_header_search = '^\s*\(=\{1,6}\)\([^=].*[^=]\)\1\s*$'
let g:vimwiki_default_header_match = '^\s*\(=\{1,6}\)=\@!\s*__Header__\s*\1=\@!\s*$'
let g:vimwiki_default_bold_search = '\%(^\|\s\|[[:punct:]]\)\@<=\*\zs\%([^*`[:space:]][^*`]*[^*`[:space:]]\|[^*`[:space:]]\)\ze\*\%([[:punct:]]\|\s\|$\)\@='
let g:vimwiki_default_bold_match = '\%(^\|\s\|[[:punct:]]\)\@<=\*__Text__\*\%([[:punct:]]\|\s\|$\)\@='
let g:vimwiki_default_wikilink = '\[\[\zs[^\\\]|]\+\ze\%(|[^\\\]]\+\)\?\]\]'
let g:vimwiki_default_tag_search = '\(^\|\s\)\zs:\([^:''[:space:]]\+:\)\+\ze\(\s\|$\)'
let g:vimwiki_default_tag_match =  '\(^\|\s\):\([^:''[:space:]]\+:\)*__Tag__:\([^:[:space:]]\+:\)*\(\s\|$\)'

let g:vimwiki_markdown_header_search = '^\s*\(#\{1,6}\)\([^#].*\)$'
let g:vimwiki_markdown_header_match = '^\s*\(#\{1,6}\)#\@!\s*__Header__\s*$'
let g:vimwiki_markdown_bold_search = '\%(^\|\s\|[[:punct:]]\)\@<=\*\zs\%([^*`[:space:]][^*`]*[^*`[:space:]]\|[^*`[:space:]]\)\ze\*\%([[:punct:]]\|\s\|$\)\@='
let g:vimwiki_markdown_bold_match = '\%(^\|\s\|[[:punct:]]\)\@<=\*__Text__\*\%([[:punct:]]\|\s\|$\)\@='
let g:vimwiki_markdown_wikilink = g:vimwiki_default_wikilink "XXX plus markdown-style links
let g:vimwiki_markdown_tag_search = g:vimwiki_default_tag_search
let g:vimwiki_markdown_tag_match = g:vimwiki_default_tag_match

let g:vimwiki_media_header_search = '^\s*\(=\{1,6}\)\([^=].*[^=]\)\1\s*$'
let g:vimwiki_media_header_match = '^\s*\(=\{1,6}\)=\@!\s*__Header__\s*\1=\@!\s*$'
let g:vimwiki_media_bold_search = "'''\\zs[^']\\+\\ze'''"
let g:vimwiki_media_bold_match = '''''''__Text__'''''''
" ^- this strange looking thing is equivalent to "'''__Text__'''" but since we later
" want to call escape() on this string, we must keep it in single quotes
let g:vimwiki_media_wikilink = g:vimwiki_default_wikilink
let g:vimwiki_media_tag_search = g:vimwiki_default_tag_search " XXX rework to mediawiki categories format?
let g:vimwiki_media_tag_match = g:vimwiki_default_tag_match " XXX rework to mediawiki categories format?
