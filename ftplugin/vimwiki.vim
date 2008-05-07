" Vim filetype plugin file
" Language:     Wiki
" Maintainer:   Maxim Kim (habamax at gmail dot com)
" Home:         http://code.google.com/p/vimwiki/
" Author:       Maxim Kim
" Filenames:    *.wiki
" Last Change:  (07.05.2008 19:25)
" Version:      0.2.2

if exists("b:did_ftplugin")
  finish
endif

let b:did_ftplugin = 1  " Don't load another plugin for this buffer

" Reset the following options to undo this plugin.
let b:undo_ftplugin = "setl tw< wrap< lbr< fenc< ff< sua< isf< awa<"

setlocal textwidth=0
setlocal wrap
setlocal linebreak
setlocal fileencoding=utf-8
setlocal fileformat=unix
setlocal autowriteall
" for gf
setlocal suffixesadd=.wiki
setlocal isfname-=[,]


"" Defaults
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:default(varname,value)
  if !exists('g:vimwiki_'.a:varname)
    let g:vimwiki_{a:varname} = a:value
  endif
endfunction

"" Could be redefined by users
call s:default('index',"")
call s:default('home',"")
call s:default('upper','A-ZА-Я')
call s:default('lower','a-zа-я')
call s:default('other','0-9_')
call s:default('ext','.wiki')
call s:default('smartCR',1)
call s:default('stripsym','_')

call s:default('history',[])

let upp = g:vimwiki_upper
let low = g:vimwiki_lower
let oth = g:vimwiki_other
let nup = low.oth
let nlo = upp.oth
let any = upp.nup

let g:vimwiki_word1 = '['.upp.']['.nlo.']*['.low.']['.nup.']*['.upp.']['.any.']*'
let g:vimwiki_word2 = '\[\[['.upp.low.oth.'[:punct:][:space:]]\+\]\]'

let s:wiki_word = '\C\<'.g:vimwiki_word1.'\>\|'.g:vimwiki_word2


"" Functions {{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:SearchWord(wikiRx,cmd)
    let hl = &hls
    let lasts = @/
    let @/ = a:wikiRx
    set nohls
    try
        :silent exe 'normal ' a:cmd
    catch /Pattern not found/
        echoh WarningMsg
        echo "No WikiWord found."
        echoh None
    endt
    let @/ = lasts
    let &hls = hl
endfunction


function! s:WikiNextWord()
    call s:SearchWord(s:wiki_word, 'n')
endfunction

function! s:WikiPrevWord()
    call s:SearchWord(s:wiki_word, 'N')
endfunction

function! s:WikiGetWordAtCursor(wikiRX)
    let col = col('.') - 1
    let line = getline('.')
    let ebeg = -1
    let cont = match(line, a:wikiRX, 0)
    while (ebeg >= 0 || (0 <= cont) && (cont <= col))
        let contn = matchend(line, a:wikiRX, cont)
        if (cont <= col) && (col < contn)
            let ebeg = match(line, a:wikiRX, cont)
            let elen = contn - ebeg
            break
        else
            let cont = match(line, a:wikiRX, contn)
        endif
    endwh
    if ebeg >= 0
        return strpart(line, ebeg, elen)
    else
        return ""
    endif
endf

function! s:WikiStripWord(word, sym)
    function! s:WikiStripWordHelper(word, sym)
        return substitute(a:word, '[<>|?*/\:"]', a:sym, 'g')
    endfunction

    let result = a:word
    if strpart(a:word, 0, 2) == "[["
        let result = s:WikiStripWordHelper(strpart(a:word, 2, strlen(a:word)-4), a:sym)
    endif
    return result
endfunction


" Check if word is link to a non-wiki file.
" The easiest way is to check if it has extension like .txt or .html
function! s:WikiLinkToNonWikiFile(word)
    if a:word =~ '\..\{1,4}$'
        return 1
    endif
    return 0
endfunction

if !exists('*s:WikiFollowWord')
    function! s:WikiFollowWord(split)
        if a:split == "split"
            let cmd = ":split "
        elseif a:split == "vsplit"
            let cmd = ":vsplit "
        else
            let cmd = ":e "
        endif
        let word = s:WikiStripWord(s:WikiGetWordAtCursor(s:wiki_word), g:vimwiki_stripsym)
        " insert doesn't work properly inside :if. Check :help :if.
        if word == ""
            execute "normal! \n"
            return
        endif
        if s:WikiLinkToNonWikiFile(word)
            execute cmd.word
        else
            " history is [['WikiWord.wiki', 11], ['AnotherWikiWord', 3] ... etc]
            " where numbers are column positions we should return when coming back.
            call insert(g:vimwiki_history, [expand('%:p'), col('.')])
            execute cmd.g:vimwiki_home.word.g:vimwiki_ext
        endif
    endfunction

    function! s:WikiGoBackWord()
        if len(g:vimwiki_history) > 0
            let word = remove(g:vimwiki_history, 0)
            " go back to saved WikiWord
            execute ":e ".get(word, 0)
            call cursor(line('.'), get(word,1))
        endif
    endfunction
endif

function! s:WikiNewLine()
    function! WikiAutoListItemInsert(listSym)
        let sym = escape(a:listSym, '*')
        let prevline = getline(line('.')-1)
        if prevline =~ '^\s*'.sym
            let curline = substitute(getline('.'),'^\s\+',"","g")
            if prevline =~ '^\s*'.sym.'\s*$'
                " there should be easier way ...
                execute 'normal kA '."\<ESC>".'"_dF'.a:listSym.'JX'
                return 1
            endif
            let ind = indent(line('.')-1)
            call setline(line('.'), strpart(prevline, 0, ind).a:listSym.' '.curline)
            call cursor(line('.'), ind+3)
            return 1
        endif
        return 0
    endfunction

    if WikiAutoListItemInsert('*')
        return
    endif

    if WikiAutoListItemInsert('#')
        return
    endif

    " delete <space>
    execute 'normal x'
endfunction


" Functions }}}

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

nmap <buffer> <CR> :call <SID>WikiFollowWord('nosplit')<CR>
nmap <buffer> <S-CR> :call <SID>WikiFollowWord('split')<CR>
nmap <buffer> <C-CR> :call <SID>WikiFollowWord('vsplit')<CR>
nmap <buffer> <BS> :call <SID>WikiGoBackWord()<CR>

nmap <buffer> <TAB> :call <SID>WikiNextWord()<CR>
nmap <buffer> <S-TAB> :call <SID>WikiPrevWord()<CR>

if g:vimwiki_smartCR
    inoremap <CR> <CR> <C-O>:call <SID>WikiNewLine()<CR>
endif
" Keybindings }}}
