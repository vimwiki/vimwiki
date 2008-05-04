" Vim syntax file
" Language:     Wiki
" Maintainer:   Maxim Kim (habamax at gmail dot com)
" Home:         http://code.google.com/p/vimwiki/
" Author:       Maxim Kim
" Filenames:    *.wiki
" Last Change:  (04.05.2008 17:45)
" Version:      0.1
" Based on FlexWiki

" Quit if syntax file is already loaded
if version < 600
    syntax clear
elseif exists("b:current_syntax")
    finish
endif

" A WikiWord (unqualifiedWikiName)
execute 'syntax match wikiWord /'.g:vimwiki_word1.'/'
" A [bracketed wiki word]
execute 'syntax match wikiWord /'.g:vimwiki_word2.'/'

" text: "this is a link (optional tooltip)":http://www.microsoft.com
" TODO: check URL syntax against RFC
syntax match wikiLink           `\("[^"(]\+\((\([^)]\+\))\)\?":\)\?\(https\?\|ftp\|gopher\|telnet\|file\|notes\|ms-help\):\(\(\(//\)\|\(\\\\\)\)\+[A-Za-z0-9:#@%/;$~_?+-=.&\-\\\\]*\)`

" text: *strong*
syntax match wikiBold           /\(^\|\W\)\zs\*\([^ ].\{-}\)\*/
" '''bold'''
syntax match wikiBold           /'''\([^'].\{-}\)'''/

" text: _emphasis_
syntax match wikiItalic         /\(^\|\W\)\zs_\([^ ].\{-}\)_/
" ''italic''
syntax match wikiItalic         /''\([^'].\{-}\)''/

" ``deemphasis``
syntax match wikiDeEmphasis     /``\([^`].\{-}\)``/

" text: @code@ 
syntax match wikiCode           /\(^\|\s\|(\|\[\)\zs@\([^@]\+\)@/

"   text: -deleted text-
syntax match wikiDelText        /\(^\|\s\+\)\zs-\([^ <a ]\|[^ <img ]\|[^ -].*\)-/

"   text: +inserted text+
syntax match wikiInsText        /\(^\|\W\)\zs+\([^ ].\{-}\)+/

"   text: ^superscript^
syntax match wikiSuperScript    /\(^\|\W\)\zs^\([^ ].\{-}\)^/

"   text: ~subscript~
syntax match wikiSubScript      /\(^\|\W\)\zs\~\([^ ].\{-}\)\~/

"   text: ??citation??
syntax match wikiCitation       /\(^\|\W\)\zs??\([^ ].\{-}\)??/

" Emoticons: must come after the Textilisms, as later rules take precedence
" over earlier ones. This match is an approximation for the ~70 distinct
" patterns that FlexWiki knows.
syntax match wikiEmoticons      /\((.)\|:[()|$@]\|:-[DOPS()\]|$@]\|;)\|:'(\)/

" Aggregate all the regular text highlighting into flexwikiText
syntax cluster wikiText contains=wikiItalic,wikiBold,wikiCode,wikiDeEmphasis,wikiDelText,wikiInsText,wikiSuperScript,wikiSubScript,wikiCitation,wikiLink,wikiWord,wikiEmoticons

" single-line WikiPropertys
syntax match wikiSingleLineProperty /^:\?[A-Z_][_a-zA-Z0-9]\+:/

" Header levels, 1-6
syntax match wikiH1             /^!.*$/
syntax match wikiH2             /^!!.*$/
syntax match wikiH3             /^!!!.*$/
syntax match wikiH4             /^!!!!.*$/
syntax match wikiH5             /^!!!!!.*$/
syntax match wikiH6             /^!!!!!!.*$/

" <hr>, horizontal rule
syntax match wikiHR             /^----.*$/

" Formatting can be turned off by ""enclosing it in pairs of double quotes""
syntax match wikiEscape         /"".\{-}""/

" Tables. Each line starts and ends with '||'; each cell is separated by '||'
syntax match wikiTable          /||/

" Treat all other lines that start with spaces as PRE-formatted text.
syntax match wikiPre            /^[ \t]\+.*$/

" Bulleted list items start with whitespace(s), then '*'
" syntax match wikiList           /^\s\+\(\*\|[1-9]\+0*\.\).*$/   contains=@wikiText
" highlight only bullets and digits.
syntax match wikiList           /^\s\+\(\*\|[1-9]\+0*\.\)/




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

hi def link wikiCode                  Statement
hi def link wikiWord                  Underlined

hi def link wikiEscape                Todo
hi def link wikiPre                   PreProc
hi def link wikiLink                  Underlined
hi def link wikiList                  Type
hi def link wikiTable                 Type
hi def link wikiEmoticons             Constant
hi def link wikiDelText               Comment
hi def link wikiDeEmphasis            Comment
hi def link wikiInsText               Constant
hi def link wikiSuperScript           Constant
hi def link wikiSubScript             Constant
hi def link wikiCitation              Constant

hi def link wikiSingleLineProperty    Identifier

let b:current_syntax="VimWiki"

" vim:tw=0:
