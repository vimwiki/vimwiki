" VimWiki plugin file
" Language:     Wiki
" Author:       Maxim Kim (habamax at gmail dot com)
" Home:         http://code.google.com/p/vimwiki/
" Filenames:    *.wiki
" Last Change:  (02.06.2008 12:57)
" Version:      0.4


if exists("loaded_vimwiki") || &cp
  finish
endif
let loaded_vimwiki = 1

let s:save_cpo = &cpo
set cpo&vim


function! s:default(varname,value)
  if !exists('g:vimwiki_'.a:varname)
    let g:vimwiki_{a:varname} = a:value
  endif
endfunction

"" Could be redefined by users
call s:default('home',"")
call s:default('index',"index")
call s:default('ext','.wiki')
call s:default('upper','A-ZА-Я')
call s:default('lower','a-zа-я')
call s:default('maxhi','1')
call s:default('other','0-9_')
call s:default('smartCR',1)
call s:default('stripsym','_')
call s:default('home_html',g:vimwiki_home."html/")
" call s:default('addheading','1')

call s:default('history',[])

let upp = g:vimwiki_upper
let low = g:vimwiki_lower
let oth = g:vimwiki_other
let nup = low.oth
let nlo = upp.oth
let any = upp.nup

let g:vimwiki_word1 = '\C\<['.upp.']['.nlo.']*['.low.']['.nup.']*['.upp.']['.any.']*\>'
let g:vimwiki_word2 = '\[\[['.upp.low.oth.'[:punct:][:space:]]\{-}\]\]'

"" TODO: common regexps for syntax hiliting
"" regexps
call s:default('rxWeblink', '\("[^"(]\+\((\([^)]\+\))\)\?":\)\?\(https\?\|ftp\|gopher\|telnet\|file\|notes\|ms-help\):\(\(\(//\)\|\(\\\\\)\)\+[A-Za-z0-9:#@%/;$~_?+-=.&\-\\\\]*\)')
call s:default('rxWikiWord', g:vimwiki_word1.'\|'.g:vimwiki_word2)
call s:default('rxCode', '`.\{-}`')

execute 'autocmd! BufNewFile,BufReadPost,BufEnter *'.g:vimwiki_ext.' set ft=vimwiki'

nmap <silent><unique> <Leader>ww :call vimwiki#WikiGoHome()<CR>
nmap <silent><unique> <Leader>wh :execute "edit ".g:vimwiki_home."."<CR>
