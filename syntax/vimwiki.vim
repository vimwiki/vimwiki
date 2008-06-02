" Vim syntax file
" Language:     Wiki
" Author:       Maxim Kim (habamax at gmail dot com)
" Home:         http://code.google.com/p/vimwiki/
" Filenames:    *.wiki
" Last Change:  (02.06.2008 12:58)
" Version:      0.4

" Quit if syntax file is already loaded
if version < 600
    syntax clear
elseif exists("b:current_syntax")
    finish
endif

"" use max highlighting - could be quite slow if there are too many wikifiles
if g:vimwiki_maxhi
    " Every WikiWord is nonexistent
    execute 'syntax match wikiNoExistsWord /'.g:vimwiki_word1.'/'
    execute 'syntax match wikiNoExistsWord /'.g:vimwiki_word2.'/'
    " till we find them in g:vimwiki_home
    call vimwiki#WikiHighlightWords()
else
    " A WikiWord (unqualifiedWikiName)
    execute 'syntax match wikiWord /'.g:vimwiki_word1.'/'
    " A [[bracketed wiki word]]
    execute 'syntax match wikiWord /'.g:vimwiki_word2.'/'
endif


" text: "this is a link (optional tooltip)":http://www.microsoft.com
" TODO: check URL syntax against RFC
syntax match wikiLink           `\("[^"(]\+\((\([^)]\+\))\)\?":\)\?\(https\?\|ftp\|gopher\|telnet\|file\|notes\|ms-help\):\(\(\(//\)\|\(\\\\\)\)\+[A-Za-z0-9:#@%/;$~_?+-=.&\-\\\\]*\)`

" text: *strong*
" syntax match wikiBold           /\(^\|\W\)\zs\*\([^ ].\{-}\)\*/
" syntax match wikiBold           /\(^\|\W\)\zs\*.\{-}\*/
syntax match wikiBold           /\*.\{-}\*/

" text: _emphasis_
syntax match wikiItalic         /_.\{-}_/

" text: `code`
syntax match wikiCode           /`.\{-}`/

"   text: ~~deleted text~~
syntax match wikiDelText        /\~\{2}.\{-}\~\{2}/

"   text: ^superscript^
syntax match wikiSuperScript    /\^.\{-}\^/

"   text: ,,subscript,,
syntax match wikiSubScript      /,,.\{-},,/

" Emoticons: must come after the Textilisms, as later rules take precedence
" over earlier ones. This match is an approximation for the ~70 distinct
" patterns that FlexWiki knows.
syntax match wikiEmoticons      /\((.)\|:[()|$@]\|:-[DOPS()\]|$@]\|;)\|:'(\)/

" Aggregate all the regular text highlighting into wikiText
syntax cluster wikiText contains=wikiItalic,wikiBold,wikiCode,wikiDelText,wikiSuperScript,wikiSubScript,wikiLink,wikiWord,wikiEmoticons

" Header levels, 1-6
syntax match wikiH1             /\(^!\{1}.*$\|^\s*=\{1}.*=\{1}\s*$\)/
syntax match wikiH2             /\(^!\{2}.*$\|^\s*=\{2}.*=\{2}\s*$\)/
syntax match wikiH3             /\(^!\{3}.*$\|^\s*=\{3}.*=\{3}\s*$\)/
syntax match wikiH4             /\(^!\{4}.*$\|^\s*=\{4}.*=\{4}\s*$\)/
syntax match wikiH5             /\(^!\{5}.*$\|^\s*=\{5}.*=\{5}\s*$\)/
syntax match wikiH6             /\(^!\{6}.*$\|^\s*=\{6}.*=\{6}\s*$\)/

" <hr>, horizontal rule
syntax match wikiHR             /^----.*$/

" Tables. Each line starts and ends with '||'; each cell is separated by '||'
syntax match wikiTable          /||/

" Bulleted list items start with whitespace(s), then '*'
" syntax match wikiList           /^\s\+\(\*\|[1-9]\+0*\.\).*$/   contains=@wikiText
" highlight only bullets and digits.
syntax match wikiList           /^\s\+\(\*\|[1-9]\+0*\.\|#\)/

syntax match wikiTodo           /\(TODO:\|DONE:\|FIXME:\|FIXED:\)/ 

" Treat all other lines that start with spaces as PRE-formatted text.
syntax match wikiPre            /^\s\+[^[:blank:]*#].*$/

syntax region wikiPre start=/^{{{\s*$/ end=/^}}}\s*$/
syntax sync match wikiPreSync grouphere wikiPre /^{{{\s*$/

" Link FlexWiki syntax items to colors
hi def link wikiH1                    Title
hi def link wikiH2                    wikiH1
hi def link wikiH3                    wikiH2
hi def link wikiH4                    wikiH3
hi def link wikiH5                    wikiH4
hi def link wikiH6                    wikiH5
hi def link wikiHR                    wikiH6

hi def wikiBold                       term=bold cterm=bold gui=bold
hi def wikiItalic                     term=italic cterm=italic gui=italic

hi def link wikiCode                  PreProc
hi def link wikiWord                  Underlined
hi def link wikiNoExistsWord          Error

hi def link wikiEscape                Todo
hi def link wikiPre                   PreProc
hi def link wikiLink                  Underlined
hi def link wikiList                  Type
hi def link wikiTable                 Type
hi def link wikiEmoticons             Constant
hi def link wikiDelText               Comment
hi def link wikiInsText               Constant
hi def link wikiSuperScript           Constant
hi def link wikiSubScript             Constant
hi def link wikiCitation              Constant
hi def link wikiTodo                  Todo

let b:current_syntax="vimwiki"

" vim:tw=0:
