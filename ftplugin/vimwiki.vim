" Vim filetype plugin file
" Language:     Wiki
" Author:       Maxim Kim (habamax at gmail dot com)
" Home:         http://code.google.com/p/vimwiki/
" Filenames:    *.wiki
" Last Change:  (02.06.2008 12:58)
" Version:      0.4

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

"" keybindings {{{
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

nmap <silent><buffer> <CR> :call vimwiki#WikiFollowWord('nosplit')<CR>
nmap <silent><buffer> <S-CR> :call vimwiki#WikiFollowWord('split')<CR>
nmap <silent><buffer> <C-CR> :call vimwiki#WikiFollowWord('vsplit')<CR>

nmap <buffer> <S-LeftMouse> <NOP>
nmap <buffer> <C-LeftMouse> <NOP>
noremap <silent><buffer> <2-LeftMouse> :call vimwiki#WikiFollowWord('nosplit')<CR>
noremap <silent><buffer> <S-2-LeftMouse> <LeftMouse>:call vimwiki#WikiFollowWord('split')<CR>
noremap <silent><buffer> <C-2-LeftMouse> <LeftMouse>:call vimwiki#WikiFollowWord('vsplit')<CR>

nmap <silent><buffer> <BS> :call vimwiki#WikiGoBackWord()<CR>
"<BS> mapping doesn't work in vim console
nmap <silent><buffer> <C-h> :call vimwiki#WikiGoBackWord()<CR>
nmap <silent><buffer> <RightMouse><LeftMouse> :call vimwiki#WikiGoBackWord()<CR>

nmap <silent><buffer> <TAB> :call vimwiki#WikiNextWord()<CR>
nmap <silent><buffer> <S-TAB> :call vimwiki#WikiPrevWord()<CR>

nmap <silent><buffer> <Leader>wd :call vimwiki#WikiDeleteWord()<CR>
nmap <silent><buffer> <Leader>wr :call vimwiki#WikiRenameWord()<CR>

if g:vimwiki_smartCR==1
    inoremap <silent><buffer><CR> <CR><Space><C-O>:call vimwiki#WikiNewLine('checkup')<CR>
    noremap <silent><buffer>o o<Space><C-O>:call vimwiki#WikiNewLine('checkup')<CR>
    noremap <silent><buffer>O O<Space><C-O>:call vimwiki#WikiNewLine('checkdown')<CR>
endif
" keybindings }}}

"" commands {{{2
" command! -nargs=1 Wiki2HTML call WikiExportHTML(expand(<f-args>))
command! Wiki2HTML call vimwiki#Wiki2HTML(g:vimwiki_home_html, expand('%'))
command! WikiAll2HTML call vimwiki#WikiAll2HTML(g:vimwiki_home_html)

"" commands 2}}}

