" Vim filetype plugin file
" Language:     Wiki
" Author:       Maxim Kim (habamax at gmail dot com)
" Home:         http://code.google.com/p/vimwiki/
" Filenames:    *.wiki
" Last Change:  (16.05.2008 14:28)
" Version:      0.3.1

if exists("b:did_ftplugin")
  finish
endif

let b:did_ftplugin = 1  " Don't load another plugin for this buffer


"" Defaults
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Reset the following options to undo this plugin.
let b:undo_ftplugin = "setl tw< wrap< lbr< fenc< ff< sua< isf< awa< com< fo<"

setlocal textwidth=0
setlocal wrap
setlocal linebreak
setlocal fileencoding=utf-8
setlocal fileformat=unix
setlocal autowriteall
" for gf
execute 'setlocal suffixesadd='.g:vimwiki_ext
setlocal isfname-=[,]

if g:vimwiki_smartCR>=2
    setlocal comments=b:*,b:#
    setlocal formatoptions=ctnqro
endif

"" Keybindings {{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
nmap <buffer> <Up>   gk
nmap <buffer> k      gk
vmap <buffer> <Up>   gk
vmap <buffer> k      gk

nmap <buffer> <Down> gj
nmap <buffer> j      gj
vmap <buffer> <Down> gj
vmap <buffer> j      gj

imap <buffer> <Down>   <C-o>gj
imap <buffer> <Up>     <C-o>gk

nmap <silent><buffer> <CR> :call WikiFollowWord('nosplit')<CR>
nmap <silent><buffer> <S-CR> :call WikiFollowWord('split')<CR>
nmap <silent><buffer> <C-CR> :call WikiFollowWord('vsplit')<CR>

nmap <buffer> <S-LeftMouse> <NOP>
nmap <buffer> <C-LeftMouse> <NOP>
noremap <silent><buffer> <2-LeftMouse> :call WikiFollowWord('nosplit')<CR>
noremap <silent><buffer> <S-2-LeftMouse> <LeftMouse>:call WikiFollowWord('split')<CR>
noremap <silent><buffer> <C-2-LeftMouse> <LeftMouse>:call WikiFollowWord('vsplit')<CR>

nmap <silent><buffer> <BS> :call WikiGoBackWord()<CR>
nmap <silent><buffer> <RightMouse><LeftMouse> :call WikiGoBackWord()<CR>

nmap <silent><buffer> <TAB> :call WikiNextWord()<CR>
nmap <silent><buffer> <S-TAB> :call WikiPrevWord()<CR>

nmap <silent><buffer> <Leader>wd :call WikiDeleteWord()<CR>
nmap <silent><buffer> <Leader>wr :call WikiRenameWord()<CR>

if g:vimwiki_smartCR==1
    inoremap <silent><buffer><CR> <CR><Space><C-O>:call WikiNewLine()<CR>
endif
" Keybindings }}}
