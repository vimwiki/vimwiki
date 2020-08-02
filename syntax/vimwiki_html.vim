" vim:tabstop=2:shiftwidth=2:expandtab:textwidth=99
" Vimwiki syntax file
" Home: https://github.com/vimwiki/vimwiki/
" Description: Defines html syntax
" Loaded: conditionaly by syntax/vimwiki.vim
" Copied from $VIMRUNTIME
" Note: The me=s-1 was omited from the region definition
"   See: `syn region VimwikiBoldUnderlineItalic contained start="<i\>" end="</i\_s*>"me=s-1 contains=VimwikiHTMLTag...`
" Note: Not configurable

let s:html_tags = join(split(vimwiki#vars#get_global('valid_html_tags'), '\s*,\s*'), '\|')
exe 'syntax match VimwikiHTMLtag #\c</\?\%('.s:html_tags.'\)\%(\s\{-1}\S\{-}\)\{-}\s*/\?>#'


" Typeface:
let html_typeface = {
  \ 'bold': [['<b>', '</b\_s*>'], ['<strong>', '</strong\_s*>']],
  \ 'italic': [['<i>', '</i\_s*>'], ['<em>', '</em\_s*>']],
  \ 'underline': [['<u>', '</u\_s*>']],
  \ }
call vimwiki#u#hi_typeface(html_typeface)


" Comment: home made
execute 'syntax match VimwikiComment /'.vimwiki#vars#get_syntaxlocal('rxComment').
    \ '/ contains=@Spell,VimwikiTodo'

" Only do syntax highlighting for multiline comments if they exist
let s:mc_start = vimwiki#vars#get_syntaxlocal('rxMultilineCommentStart')
let s:mc_end = vimwiki#vars#get_syntaxlocal('rxMultilineCommentEnd')
if !empty(s:mc_start) && !empty(s:mc_end)
execute 'syntax region VimwikiMultilineComment start=/'.s:mc_start.
      \ '/ end=/'.s:mc_end.'/ contains=@NoSpell,VimwikiTodo'
endif
