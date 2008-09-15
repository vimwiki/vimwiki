" Vimball Archiver by Charles E. Campbell, Jr., Ph.D.
UseVimball
finish
plugin\vimwiki.vim	[[[1
55
" VimWiki plugin file
" Language:    Wiki
" Author:      Maxim Kim (habamax at gmail dot com)
" Home:        http://code.google.com/p/vimwiki/
" Filenames:   *.wiki
" Last Change: [15.09.2008 - 12:07]
" Version:     0.5


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
call s:default('syntax','default')

call s:default('history',[])

let upp = g:vimwiki_upper
let low = g:vimwiki_lower
let oth = g:vimwiki_other
let nup = low.oth
let nlo = upp.oth
let any = upp.nup

let g:vimwiki_word1 = '\C\<['.upp.']['.nlo.']*['.low.']['.nup.']*['.upp.']['.any.']*\>'
" let g:vimwiki_word2 = '\[\[['.upp.low.oth.'[:punct:][:space:]]\{-}\]\]'
let g:vimwiki_word2 = '\[\[[^\]]\+\]\]'
let g:vimwiki_rxWikiWord = g:vimwiki_word1.'\|'.g:vimwiki_word2

execute 'autocmd! BufNewFile,BufReadPost,BufEnter *'.g:vimwiki_ext.' set ft=vimwiki'

nmap <silent><unique> <Leader>ww :call vimwiki#WikiGoHome()<CR>
nmap <silent><unique> <Leader>wh :execute "edit ".g:vimwiki_home<CR>
ftplugin\vimwiki.vim	[[[1
126
" Vim filetype plugin file
" Language:     Wiki
" Author:       Maxim Kim (habamax at gmail dot com)
" Home:         http://code.google.com/p/vimwiki/
" Filenames:    *.wiki
" Last Change: [15.09.2008 - 12:09]
" Version:      0.5

if exists("b:did_ftplugin")
  finish
endif

let b:did_ftplugin = 1  " Don't load another plugin for this buffer


"" Defaults
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Reset the following options to undo this plugin.
let b:undo_ftplugin = "setl tw< wrap< lbr< fenc< ff< sua< isf< awa< com< fo< fdt< fdm< fde<"

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

"" TODO: folding for Headers using syntax fold method.

" setlocal foldmethod=expr
" setlocal foldexpr=VimWikiFoldLevel(v:lnum)

" function! s:wikiHeaderLevel(header)
    " let c = 0
    " while a:header[c]=='!'
        " let c += 1
    " endwhile
    " return c
" endfunction

" function! VimWikiFoldLevel(lnum)
    " let str = getline(a:lnum)
    " let strnext = getline(a:lnum+1)
    " if str =~ '^!'
        " if strnext =~ '^!'
            " return '<1'
        " else
            " return '1'
        " endif
    " elseif strnext =~ '^!'
        " return '<1'
    " else
        " return '1'
    " endif
" endfunction


" setlocal foldtext=VimWikiFoldText()
" function! VimWikiFoldText()
  " let line = getline(v:foldstart)
  " let sub = substitute(line, '!', '', '')
  " let sub = substitute(sub, '!', v:folddashes.v:folddashes, 'g')
  " let lines_nr = v:foldend-v:foldstart
  " return '+'.v:folddashes.v:folddashes.sub.' ('.lines_nr.')'
" endfunction


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

autoload\vimwiki.vim	[[[1
901
" VimWiki plugin file
" Language:    Wiki
" Author:      Maxim Kim (habamax at gmail dot com)
" Home:        http://code.google.com/p/vimwiki/
" Filenames:   *.wiki
" Last Change: [15.09.2008 - 12:23]
" Version:     0.5

if exists("g:loaded_vimwiki_auto") || &cp
 finish
endif
let g:loaded_vimwiki_auto = 1

let s:wiki_badsymbols = '[<>|?*/\:"]'

"" vimwiki functions {{{2
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:msg(message) "{{{
    echohl WarningMsg
    echomsg 'vimwiki: '.a:message
    echohl None
endfunction "}}}

function! s:getFileNameOnly(filename) "{{{
    let word = substitute(a:filename, '\'.g:vimwiki_ext, "", "g")
    let word = substitute(word, '.*[/\\]', "", "g")
    return word
endfunction "}}}

function! s:editfile(command, filename) "{{{
    let fname = escape(a:filename, '% ')
    execute a:command.' '.fname

    " if fname is new
    " if g:vimwiki_addheading!=0 && glob(fname) == ''
    " execute 'normal I! '.s:getfilename(fname)
    " update
    " endif
endfunction "}}}

function! s:SearchWord(wikiRx,cmd) "{{{
    let hl = &hls
    let lasts = @/
    let @/ = a:wikiRx
    set nohls
    try
        :silent exe 'normal ' a:cmd
    catch /Pattern not found/
        call s:msg('WikiWord not found')
    endt
    let @/ = lasts
    let &hls = hl
endfunction "}}}

function! s:WikiGetWordAtCursor(wikiRX) "{{{
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
endf "}}}

function! s:WikiStripWord(word, sym) "{{{
    function! s:WikiStripWordHelper(word, sym)
        return substitute(a:word, s:wiki_badsymbols, a:sym, 'g')
    endfunction

    let result = a:word
    if strpart(a:word, 0, 2) == "[["
        let result = s:WikiStripWordHelper(strpart(a:word, 2, strlen(a:word)-4), a:sym)
    endif
    return result
endfunction "}}}

function! s:WikiIsLinkToNonWikiFile(word) "{{{
    " Check if word is link to a non-wiki file.
    " The easiest way is to check if it has extension like .txt or .html
    if a:word =~ '\.\w\{1,4}$'
        return 1
    endif
    return 0
endfunction "}}}

"" WikiWord history helper functions {{{
" history is [['WikiWord.wiki', 11], ['AnotherWikiWord', 3] ... etc]
" where numbers are column positions we should return to when coming back.
function! s:GetHistoryWord(historyItem)
    return get(a:historyItem, 0)
endfunction
function! s:GetHistoryColumn(historyItem)
    return get(a:historyItem, 1)
endfunction
"}}}

function! vimwiki#WikiNextWord() "{{{
    call s:SearchWord(g:vimwiki_rxWikiWord, 'n')
endfunction "}}}

function! vimwiki#WikiPrevWord() "{{{
    call s:SearchWord(g:vimwiki_rxWikiWord, 'N')
endfunction "}}}

function! vimwiki#WikiFollowWord(split) "{{{
    if a:split == "split"
        let cmd = ":split "
    elseif a:split == "vsplit"
        let cmd = ":vsplit "
    else
        let cmd = ":e "
    endif
    let word = s:WikiStripWord(s:WikiGetWordAtCursor(g:vimwiki_rxWikiWord), g:vimwiki_stripsym)
    " insert doesn't work properly inside :if. Check :help :if.
    if word == ""
        execute "normal! \n"
        return
    endif
    if s:WikiIsLinkToNonWikiFile(word)
        call s:editfile(cmd, word)
    else
        call insert(g:vimwiki_history, [expand('%:p'), col('.')])
        call s:editfile(cmd, g:vimwiki_home.word.g:vimwiki_ext)
    endif
endfunction "}}}

function! vimwiki#WikiGoBackWord() "{{{
    if !empty(g:vimwiki_history)
        let word = remove(g:vimwiki_history, 0)
        " go back to saved WikiWord
        execute ":e ".s:GetHistoryWord(word)
        call cursor(line('.'), s:GetHistoryColumn(word))
    endif
endfunction "}}}

function! vimwiki#WikiNewLine(direction) "{{{
    "" direction == checkup - use previous line for checking
    "" direction == checkdown - use next line for checking
    function! s:WikiAutoListItemInsert(listSym, dir)
        let sym = escape(a:listSym, '*')
        if a:dir=='checkup'
            let linenum = line('.')-1
        else
            let linenum = line('.')+1
        end
        let prevline = getline(linenum)
        if prevline =~ '^\s\+'.sym
            let curline = substitute(getline('.'),'^\s\+',"","g")
            if prevline =~ '^\s*'.sym.'\s*$'
                " there should be easier way ...
                execute 'normal kA '."\<ESC>".'"_dF'.a:listSym.'JX'
                return 1
            endif
            let ind = indent(linenum)
            call setline(line('.'), strpart(prevline, 0, ind).a:listSym.' '.curline)
            call cursor(line('.'), ind+3)
            return 1
        endif
        return 0
    endfunction

    if s:WikiAutoListItemInsert('*', a:direction)
        return
    endif

    if s:WikiAutoListItemInsert('#', a:direction)
        return
    endif

    " delete <space>
    if getline('.') =~ '^\s\+$'
        execute 'normal x'
    else
        execute 'normal X'
    endif
endfunction "}}}

function! vimwiki#WikiHighlightWords() "{{{
    let wikies = glob(g:vimwiki_home.'*')
    "" remove .wiki extensions
    let wikies = substitute(wikies, '\'.g:vimwiki_ext, "", "g")
    let g:vimwiki_wikiwords = split(wikies, '\n')
    "" remove paths
    call map(g:vimwiki_wikiwords, 'substitute(v:val, ''.*[/\\]'', "", "g")')
    "" remove backup files (.wiki~)
    call filter(g:vimwiki_wikiwords, 'v:val !~ ''.*\~$''')

    for word in g:vimwiki_wikiwords
        if word =~ g:vimwiki_word1 && !s:WikiIsLinkToNonWikiFile(word)
            execute 'syntax match wikiWord /\<'.word.'\>/'
        else
            execute 'syntax match wikiWord /\[\['.substitute(word,  g:vimwiki_stripsym, s:wiki_badsymbols, "g").'\]\]/'
        endif
    endfor
endfunction "}}}

function! vimwiki#WikiGoHome()"{{{
    execute ':e '.g:vimwiki_home.g:vimwiki_index.g:vimwiki_ext
    let g:vimwiki_history = []
endfunction"}}}

function! vimwiki#WikiDeleteWord() "{{{
    "" file system funcs
    "" Delete WikiWord you are in from filesystem
    let val = input('Delete ['.expand('%').'] (y/n)? ', "")
    if val!='y'
        return
    endif
    let fname = expand('%:p')
    " call WikiGoBackWord()
    try
        call delete(fname)
    catch /.*/
        call s:msg('Cannot delete "'.expand('%:r').'"!')
        return
    endtry
    execute "bdelete! ".escape(fname, " ")

    " delete from g:vimwiki_history list
    call filter (g:vimwiki_history, 's:GetHistoryWord(v:val) != fname')
    " as we got back to previous WikiWord - delete it from history - as much
    " as possible
    let hword = s:GetHistoryWord(remove(g:vimwiki_history, 0))
    while !empty(g:vimwiki_history) && hword == s:GetHistoryWord(g:vimwiki_history[0])
        let hword = s:GetHistoryWord(remove(g:vimwiki_history, 0))
    endwhile

    " reread buffer => deleted WikiWord should appear as non-existent
    execute "e"
endfunction "}}}

function! vimwiki#WikiRenameWord() "{{{
    "" Rename WikiWord, update all links to renamed WikiWord
    let wwtorename = expand('%:r')
    let isOldWordComplex = 0
    if wwtorename !~ g:vimwiki_word1
        let wwtorename = substitute(wwtorename,  g:vimwiki_stripsym, s:wiki_badsymbols, "g")
        let isOldWordComplex = 1
    endif

    " there is no file (new one maybe)
    if glob(g:vimwiki_home.expand('%')) == ''
        call s:msg('Cannot rename "'.expand('%').'". It does not exist!')
        return
    endif

    let val = input('Rename "'.expand('%:r').'" (y/n)? ', "")
    if val!='y'
        return
    endif
    let newWord = input('Enter new name: ', "")
    " check newWord - it should be 'good', not empty
    if substitute(newWord, '\s', '', 'g') == ''
        call s:msg('Cannot rename to an empty filename!')
        return
    endif
    if s:WikiIsLinkToNonWikiFile(newWord)
        call s:msg('Cannot rename to a filename with extension (ie .txt .html)!')
        return
    endif

    if newWord !~ g:vimwiki_word1
        " if newWord is 'complex wiki word' then add [[]]
        let newWord = '[['.newWord.']]'
    endif
    let newFileName = s:WikiStripWord(newWord, g:vimwiki_stripsym).g:vimwiki_ext

    " do not rename if word with such name exists
    let fname = glob(g:vimwiki_home.newFileName)
    if fname != ''
        call s:msg('Cannot rename to "'.newFileName.'". File with that name exist!')
        return
    endif
    " rename WikiWord file
    try
        call rename(expand('%'), newFileName)
        bd
        "function call doesn't work
        call s:editfile('e', newFileName)
    catch /.*/
        call s:msg('Cannot rename "'.expand('%:r').'" to "'.newFileName.'"')
        return
    endtry

    " save open buffers
    let openbuffers = []
    let bcount = 1
    while bcount<=bufnr("$")
        if bufexists(bcount)
            call add(openbuffers, bufname(bcount))
        endif
        let bcount = bcount + 1
    endwhile

    " update links
    execute ':args '.g:vimwiki_home.'*'.g:vimwiki_ext
    if isOldWordComplex
        execute ':silent argdo %s/\[\['.wwtorename.'\]\]/'.newWord.'/geI | update'
    else
        execute ':silent argdo %s/\<'.wwtorename.'\>/'.newWord.'/geI | update'
    endif
    execute ':argd *'.g:vimwiki_ext

    " restore open buffers
    let bcount = 1
    while bcount<=bufnr("$")
        if bufexists(bcount)
            if index(openbuffers, bufname(bcount)) == -1
                execute 'silent bdelete '.escape(bufname(bcount), " ")
            end
        endif
        let bcount = bcount + 1
    endwhile

    "" DONE: after renaming GUI caption is a bit corrupted?
    "" FIXED: buffers menu is also not in the "normal" state, howto Refresh menu?
    execute "emenu Buffers.Refresh\ menu"

endfunction "}}}

" Functions 2}}}

"" vimwiki html functions {{{2
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:WikiCreateDefaultCSS(path) " {{{
    if glob(a:path.'style.css') == ""
        let lines = ['body { margin: 1em 5em 1em 5em; font-size: 100%;}']
        call add(lines, 'p, ul {line-height: 1.5;}')
        call add(lines, '.todo {font-weight: bold; text-decoration: underline; color: #FF0000; }')
        call add(lines, '.strike {text-decoration: line-through; }')
        call add(lines, 'h1 {font-size: 2.0em;}')
        call add(lines, 'h2 {font-size: 1.4em;}')
        call add(lines, 'h3 {font-size: 1.0em;}')
        call add(lines, 'h4 {font-size: 0.8em;}')
        call add(lines, 'h5 {font-size: 0.7em;}')
        call add(lines, 'h6 {font-size: 0.6em;}')
        call add(lines, 'h1 { border-bottom: 1px solid #3366cc; text-align: left; padding: 0em 1em 0.3em 0em; }')
        call add(lines, 'h3 { background: #e5ecf9; border-top: 1px solid #3366cc; padding: 0.1em 0.3em 0.1em 0.5em; }')
        call add(lines, 'ul { margin-left: 2em; padding-left: 0.5em; }')
        call add(lines, 'pre { border-left: 0.2em solid #ccc; margin-left: 2em; padding-left: 0.5em; }')
        call add(lines, 'td { border: 1px solid #ccc; padding: 0.3em; }')
        call add(lines, 'hr { border: none; border-top: 1px solid #ccc; }')

        call writefile(lines, a:path.'style.css')
        echomsg "Default style.css is created."
    endif
endfunction "}}}

function! s:syntax_supported()
    return g:vimwiki_syntax == "default"
endfunction

function! vimwiki#WikiAll2HTML(path) "{{{
    if !s:syntax_supported()
        call s:msg('Wiki2Html: Only vimwiki_default syntax supported!!!')
        return
    endif

    if !isdirectory(a:path)
        call s:msg('Please create '.a:path.' directory first!')
        return
    endif
    let wikifiles = split(glob(g:vimwiki_home.'*'.g:vimwiki_ext), '\n')
    for wikifile in wikifiles
        echomsg 'Processing '.wikifile
        call vimwiki#Wiki2HTML(a:path, wikifile)
    endfor
    call s:WikiCreateDefaultCSS(g:vimwiki_home_html)
    echomsg 'Wikifiles converted.'
endfunction "}}}

function! vimwiki#Wiki2HTML(path, wikifile) "{{{
    if !s:syntax_supported()
        call s:msg('Wiki2Html: Only vimwiki_default syntax supported!!!')
        return
    endif

    if !isdirectory(a:path)
        call s:msg('Please create '.a:path.' directory first!')
        return
    endif

    "" helper funcs
    function! s:isWebLink(lnk) "{{{
        if a:lnk =~ '^\(http://\|www.\|ftp://\)'
            return 1
        endif
        return 0
    endfunction "}}}
    function! s:isImgLink(lnk) "{{{
        if a:lnk =~ '.\(png\|jpg\|gif\|jpeg\)$'
            return 1
        endif
        return 0
    endfunction "}}}

    function! s:HTMLHeader(title, charset) "{{{
        let lines=[]
        call add(lines, "")
        call add(lines, '<html>')
        call add(lines, '<head>')
        call add(lines, '<link rel="Stylesheet" type="text/css" href="style.css" />')
        call add(lines, '<title>'.a:title.'</title>')
        call add(lines, '<meta http-equiv="Content-Type" content="text/html; charset='.a:charset.'" />')
        call add(lines, '</head>')
        call add(lines, '<body>')
        return lines
    endfunction "}}}

    function! s:HTMLFooter() "{{{
        let lines=[]
        call add(lines, "")
        call add(lines, '</body>')
        call add(lines, '</html>')
        return lines
    endfunction "}}}

    function! s:closeCode(code, ldest) "{{{
        if a:code
            call add(a:ldest, "</pre></code>")
            return 0
        endif
        return a:code
    endfunction "}}}

    function! s:closePre(pre, ldest) "{{{
        if a:pre
            call add(a:ldest, "</pre>")
            return 0
        endif
        return a:pre
    endfunction "}}}

    function! s:closeTable(table, ldest) "{{{
        if a:table
            call add(a:ldest, "</table>")
            return 0
        endif
        return a:table
    endfunction "}}}

    function! s:closeList(lists, ldest) "{{{
        while len(a:lists)
            let item = remove(a:lists, -1)
            call add(a:ldest, item[0])
        endwhile
    endfunction! "}}}

    function! s:processCode(line, code) "{{{
        let lines = []
        let code = a:code
        let processed = 0
        if !code && a:line =~ '^{{{\s*$'
            let code = 1
            call add(lines, "<code><pre>")
            let processed = 1
        elseif code && a:line =~ '^}}}\s*$'
            let code = 0
            call add(lines, "</pre></code>")
            let processed = 1
        elseif code
            let processed = 1
            call add(lines, a:line)
        endif
        return [processed, lines, code]
    endfunction "}}}

    function! s:processPre(line, pre) "{{{
        let lines = []
        let pre = a:pre
        let processed = 0
        if a:line =~ '^\s\+[^[:blank:]*#]'
            if !pre
                call add(lines, "<pre>")
                let pre = 1
            endif
            let processed = 1
            call add(lines, a:line)
        elseif pre && a:line =~ '^\s*$'
            let processed = 1
            call add(lines, a:line)
        elseif pre 
            call add(lines, "</pre>")
            let pre = 0
        endif
        return [processed, lines, pre]
    endfunction "}}}

    function! s:processList(line, lists) "{{{
        let lines = []
        let lstSym = ''
        let lstTagOpen = ''
        let lstTagClose = ''
        let lstRegExp = ''
        let processed = 0
        if a:line =~ '^\s\+\*'
            let lstSym = '*'
            let lstTagOpen = '<ul>'
            let lstTagClose = '</ul>'
            let lstRegExp = '^\s\+\*'
            let processed = 1
        elseif a:line =~ '^\s\+#' 
            let lstSym = '#'
            let lstTagOpen = '<ol>'
            let lstTagClose = '</ol>'
            let lstRegExp = '^\s\+#'
            let processed = 1
        endif
        if lstSym != ''
            let indent = stridx(a:line, lstSym)
            let cnt = len(a:lists)
            if !cnt || (cnt && indent > a:lists[-1][1])
                call add(a:lists, [lstTagClose, indent])
                call add(lines, lstTagOpen)
            elseif (cnt && indent < a:lists[-1][1])
                while indent < a:lists[-1][1]
                    let item = remove(a:lists, -1)
                    call add(lines, item[0])
                endwhile
            endif
            call add(lines, '<li>'.substitute(a:line, lstRegExp, '', '').'</li>')
        else
            while len(a:lists)
                let item = remove(a:lists, -1)
                call add(lines, item[0])
            endwhile
        endif
        return [processed, lines]
    endfunction "}}}

    function! s:processP(line) "{{{
        let lines = []
        if a:line =~ '^\S'
            call add(lines, '<p>'.a:line.'</p>')
            return [1, lines]
        endif
        return [0, lines]
    endfunction "}}}

    function! s:processHeading(line) "{{{
        let line = a:line
        let processed = 0
        if a:line =~ g:vimwiki_rxH6
            let line = '<h6>'.strpart(a:line, 6).'</h6>'
            let processed = 1
        elseif a:line =~ g:vimwiki_rxH5
            let line = '<h5>'.strpart(a:line, 5).'</h5>'
            let processed = 1
        elseif a:line =~ g:vimwiki_rxH4
            let line = '<h4>'.strpart(a:line, 4).'</h4>'
            let processed = 1
        elseif a:line =~ g:vimwiki_rxH3
            let line = '<h3>'.strpart(a:line, 3).'</h3>'
            let processed = 1
        elseif a:line =~ g:vimwiki_rxH2
            let line = '<h2>'.strpart(a:line, 2).'</h2>'
            let processed = 1
        elseif a:line =~ g:vimwiki_rxH1
            let line = '<h1>'.strpart(a:line, 1).'</h1>'
            let processed = 1
        endif
        return [processed, line]
    endfunction "}}}

    function! s:processHR(line) "{{{
        let line = a:line
        let processed = 0
        if a:line =~ '^-----*$'
            let line = '<hr />'
            let processed = 1
        endif
        return [processed, line]
    endfunction "}}}

    function! s:processTable(line, table) "{{{
        let table = a:table
        let lines = []
        let processed = 0
        if a:line =~ '^||.\+||.*'
            if !table
                call add(lines, "<table>")
                let table = 1
            endif
            let processed = 1

            call add(lines, "<tr>")
            let pos1 = 0
            let pos2 = 0
            let done = 0
            while !done
                let pos1 = stridx(a:line, '||', pos2)
                let pos2 = stridx(a:line, '||', pos1+2)
                if pos1==-1 || pos2==-1
                    let done = 1
                    let pos2 = len(a:line)
                endif
                let line = strpart(a:line, pos1+2, pos2-pos1-2)
                if line != ''
                    call add(lines, "<td>".line."</td>")
                endif
            endwhile
            call add(lines, "</tr>")

        elseif table
            call add(lines, "</table>")
            let table = 0
        endif
        return [processed, lines, table]
    endfunction "}}}

    "" change dangerous html symbols - < > & (line)
    function! s:safeHTML(line) "{{{
        let line = substitute(a:line, '&', '\&amp;', 'g')
        let line = substitute(line, '<', '\&lt;', 'g')
        let line = substitute(line, '>', '\&gt;', 'g')
        return line
    endfunction "}}}

    "" Substitute text found by regexp_match with tagOpen.regexp_subst.tagClose
    function! s:MakeTagHelper(line, regexp_match, tagOpen, tagClose, cSymRemove, func) " {{{
        let pos = 0
        let lines = split(a:line, a:regexp_match, 1)
        let res_line = ""
        for line in lines
            let res_line = res_line.line
            let matched = matchstr(a:line, a:regexp_match, pos)
            if matched != ""
                let toReplace = strpart(matched, a:cSymRemove, len(matched)-2*a:cSymRemove)
                if a:func!=""
                    let toReplace = {a:func}(escape(toReplace, '\&*[]?%'))
                else
                    " let toReplace = a:tagOpen.escape(toReplace, '\&*[]?%').a:tagClose
                    let toReplace = a:tagOpen.toReplace.a:tagClose
                endif
                let res_line = res_line.toReplace
            endif
            let pos = matchend(a:line, a:regexp_match, pos)
        endfor
        return res_line

    endfunction " }}}

    "" Make tags only if not in ` ... `
    "" ... should be function that process regexp_match deeper.
    function! s:MakeTag(line, regexp_match, tagOpen, tagClose, ...) " {{{
        "check if additional function exists
        let func = ""
        let cSym = 1
        if a:0 == 2
            let cSym = a:1
            let func = a:2
        elseif a:0 == 1
            let cSym = a:1
        endif

        let patt_splitter = g:vimwiki_rxCode
        let patt_splitter = '\('.g:vimwiki_rxCode.'\)\|\(<a href.\{-}</a>\)\|\(<img src.\{-}/>\)'
        if g:vimwiki_rxCode == a:regexp_match
            let res_line = s:MakeTagHelper(a:line, a:regexp_match, a:tagOpen, a:tagClose, cSym, func)
        else
            let pos = 0
            let lines = split(a:line, patt_splitter, 1)
            let res_line = ""
            for line in lines
                let res_line = res_line.s:MakeTagHelper(line, a:regexp_match, a:tagOpen, a:tagClose, cSym, func)
                let res_line = res_line.matchstr(a:line, patt_splitter, pos)
                let pos = matchend(a:line, patt_splitter, pos)
            endfor
        endif
        return res_line
    endfunction " }}}

    "" Make <a href="link">link desc</a>
    "" from [link link desc]
    function! s:MakeExternalLink(entag) "{{{
        let line = ''
        if s:isWebLink(a:entag)
            let lnkElements = split(a:entag)
            let head = lnkElements[0]
            let rest = join(lnkElements[1:])
            if rest==""
                let rest=head
            endif
            if s:isImgLink(rest)
                if rest!=head
                    let line = '<a href="'.head.'"><img src="'.rest.'" /></a>'
                else
                    let line = '<img src="'.rest.'" />'
                endif
            else
                let line = '<a href="'.head.'">'.rest.'</a>'
            endif
        else
            if s:isImgLink(a:entag)
                let line = '<img src="'.a:entag.'" />'
            else
                let line = '<a href="'.a:entag.'">'.a:entag.'</a>'
            endif
        endif
        return line
    endfunction "}}}

    "" Make <a href="This is a link">This is a link</a>
    "" from [[This is a link]]
    function! s:MakeInternalLink(entag) "{{{
        let line = ''
        if s:isImgLink(a:entag)
            let line = '<img src="'.a:entag.'" />'
        else
            let line = '<a href="'.a:entag.'.html">'.a:entag.'</a>'
        endif
        return line
    endfunction "}}}

    "" Make <a href="WikiWord">WikiWord</a>
    "" from WikiWord
    function! s:MakeWikiWordLink(entag) "{{{
        let line = '<a href="'.a:entag.'.html">'.a:entag.'</a>'
        return line
    endfunction "}}}

    "" Make <a href="http://habamax.ru">http://habamax.ru</a>
    "" from http://habamax.ru
    function! s:MakeBareBoneLink(entag) "{{{
        if s:isImgLink(a:entag)
            let line = '<img src="'.a:entag.'" />'
        else
            let line = '<a href="'.a:entag.'">'.a:entag.'</a>'
        endif
        return line
    endfunction "}}}

    let lsource=readfile(a:wikifile)
    let ldest = s:HTMLHeader(s:getFileNameOnly(a:wikifile), &encoding)

    let pre = 0
    let code = 0
    let table = 0
    let lists = []

    for line in lsource
        let processed = 0
        let lines = []

        let line = s:safeHTML(line)

        "" code
        if !processed
            let [processed, lines, code] = s:processCode(line, code)
            if processed && len(lists)
                call s:closeList(lists, ldest)
            endif
            if processed && table
                let table = s:closeTable(table, ldest)
            endif
            if processed && pre
                let pre = s:closePre(pre, ldest)
            endif
            call extend(ldest, lines)
        endif

        "" Pre
        if !processed
            let [processed, lines, pre] = s:processPre(line, pre)
            if processed && len(lists)
                call s:closeList(lists, ldest)
            endif
            if processed && table
                let table = s:closeTable(table, ldest)
            endif
            if processed && code
                let code = s:closeCode(code, ldest)
            endif
            call extend(ldest, lines)
        endif


        "" list
        if !processed
            let [processed, lines] = s:processList(line, lists)
            if processed && pre
                let pre = s:closePre(pre, ldest)
            endif
            if processed && code
                let code = s:closeCode(code, ldest)
            endif
            if processed && table
                let table = s:closeTable(table, ldest)
            endif
            call map(lines, 's:MakeTag(v:val, ''\[\[.\{-}\]\]'', '''', '''', 2, ''s:MakeInternalLink'')')
            call map(lines, 's:MakeTag(v:val, ''\[.\{-}\]'', '''', '''', 1, ''s:MakeExternalLink'')')
            call map(lines, 's:MakeTag(v:val, g:vimwiki_rxWeblink, '''', '''', 0, ''s:MakeBareBoneLink'')')
            call map(lines, 's:MakeTag(v:val, g:vimwiki_rxWikiWord, '''', '''', 0, ''s:MakeWikiWordLink'')')
            call map(lines, 's:MakeTag(v:val, g:vimwiki_rxItalic, ''<em>'', ''</em>'')')
            call map(lines, 's:MakeTag(v:val, g:vimwiki_rxBold, ''<strong>'', ''</strong>'')')
            call map(lines, 's:MakeTag(v:val, g:vimwiki_rxTodo, ''<span class="todo">'', ''</span>'', 0)')
            call map(lines, 's:MakeTag(v:val, g:vimwiki_rxDelText, ''<span class="strike">'', ''</span>'', 2)')
            call map(lines, 's:MakeTag(v:val, g:vimwiki_rxSuperScript, ''<sup><small>'', ''</small></sup>'', 1)')
            call map(lines, 's:MakeTag(v:val, g:vimwiki_rxSubScript, ''<sub><small>'', ''</small></sub>'', 2)')
            call map(lines, 's:MakeTag(v:val, g:vimwiki_rxCode, ''<code>'', ''</code>'')')
            call extend(ldest, lines)
        endif

        "" table
        if !processed
            let [processed, lines, table] = s:processTable(line, table)
            call map(lines, 's:MakeTag(v:val, ''\[\[.\{-}\]\]'', '''', '''', 2, ''s:MakeInternalLink'')')
            call map(lines, 's:MakeTag(v:val, ''\[.\{-}\]'', '''', '''', 1, ''s:MakeExternalLink'')')
            call map(lines, 's:MakeTag(v:val, g:vimwiki_rxWeblink, '''', '''', 0, ''s:MakeBareBoneLink'')')
            call map(lines, 's:MakeTag(v:val, g:vimwiki_rxWikiWord, '''', '''', 0, ''s:MakeWikiWordLink'')')
            call map(lines, 's:MakeTag(v:val, g:vimwiki_rxItalic, ''<em>'', ''</em>'')')
            call map(lines, 's:MakeTag(v:val, g:vimwiki_rxBold, ''<strong>'', ''</strong>'')')
            call map(lines, 's:MakeTag(v:val, g:vimwiki_rxTodo, ''<span class="todo">'', ''</span>'', 0)')
            call map(lines, 's:MakeTag(v:val, g:vimwiki_rxDelText, ''<span class="strike">'', ''</span>'', 2)')
            call map(lines, 's:MakeTag(v:val, g:vimwiki_rxSuperScript, ''<sup><small>'', ''</small></sup>'', 1)')
            call map(lines, 's:MakeTag(v:val, g:vimwiki_rxSubScript, ''<sub><small>'', ''</small></sub>'', 2)')
            call map(lines, 's:MakeTag(v:val, g:vimwiki_rxCode, ''<code>'', ''</code>'')')
            call extend(ldest, lines)
        endif

        if !processed
            let [processed, line] = s:processHeading(line)
            if processed
                call s:closeList(lists, ldest)
                let table = s:closeTable(table, ldest)
                let code = s:closeCode(code, ldest)
                call add(ldest, line)
            endif
        endif

        if !processed
            let [processed, line] = s:processHR(line)
            if processed
                call s:closeList(lists, ldest)
                let table = s:closeTable(table, ldest)
                let code = s:closeCode(code, ldest)
                call add(ldest, line)
            endif
        endif

        "" P
        if !processed
            let line = s:MakeTag(line, '\[\[.\{-}\]\]', '', '', 2, 's:MakeInternalLink')
            let line = s:MakeTag(line, '\[.\{-}\]', '', '', 1, 's:MakeExternalLink')
            let line = s:MakeTag(line, g:vimwiki_rxWeblink, '', '', 0, 's:MakeBareBoneLink')
            let line = s:MakeTag(line, g:vimwiki_rxWikiWord, '', '', 0, 's:MakeWikiWordLink')
            let line = s:MakeTag(line, g:vimwiki_rxItalic, '<em>', '</em>')
            let line = s:MakeTag(line, g:vimwiki_rxBold, '<strong>', '</strong>')
            let line = s:MakeTag(line, g:vimwiki_rxTodo, '<span class="todo">', '</span>', 0)
            let line = s:MakeTag(line, g:vimwiki_rxDelText, '<span class="strike">', '</span>', 2)
            let line = s:MakeTag(line, g:vimwiki_rxSuperScript, '<sup><small>', '</small></sup>', 1)
            let line = s:MakeTag(line, g:vimwiki_rxSubScript, '<sub><small>', '</small></sub>', 2)
            let line = s:MakeTag(line, g:vimwiki_rxCode, '<code>', '</code>')
            let [processed, lines] = s:processP(line)
            if processed && pre
                let pre = s:closePre(pre, ldest)
            endif
            if processed && code
                let code = s:closeCode(code, ldest)
            endif
            if processed && table
                let table = s:closeTable(table, ldest)
            endif
            call extend(ldest, lines)
        endif

        "" add the rest
        if !processed
            call add(ldest, line)
        endif
    endfor

    "" process end of file
    "" close opened tags if any
    call s:closePre(pre, ldest)
    call s:closeCode(code, ldest)
    call s:closeList(lists, ldest)
    call s:closeTable(table, ldest)


    call extend(ldest, s:HTMLFooter())

    "" make html file.
    "" TODO: add html headings, css, etc.
    let wwFileNameOnly = s:getFileNameOnly(a:wikifile)
    call writefile(ldest, a:path.wwFileNameOnly.'.html')
endfunction "}}}

" 2}}}
syntax\vimwiki.vim	[[[1
114
" Vim syntax file
" Language:    Wiki
" Author:      Maxim Kim (habamax at gmail dot com)
" Home:        http://code.google.com/p/vimwiki/
" Filenames:   *.wiki
" Last Change: [15.09.2008 - 12:07]
" Version:     0.5

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
let g:vimwiki_rxWeblink = '\("[^"(]\+\((\([^)]\+\))\)\?":\)\?\(https\?\|ftp\|gopher\|telnet\|file\|notes\|ms-help\):\(\(\(//\)\|\(\\\\\)\)\+[A-Za-z0-9:#@%/;$~_?+-=.&\-\\\\]*\)'
execute 'syntax match wikiLink `'.g:vimwiki_rxWeblink.'`'

" Emoticons: must come after the Textilisms, as later rules take precedence
" over earlier ones. This match is an approximation for the ~70 distinct
syntax match wikiEmoticons /\((.)\|:[()|$@]\|:-[DOPS()\]|$@]\|;)\|:'(\)/

let g:vimwiki_rxTodo = '\(TODO:\|DONE:\|FIXME:\|FIXED:\)'
execute 'syntax match wikiTodo /'. g:vimwiki_rxTodo .'/'

" Load concrete Wiki syntax
execute 'runtime! syntax/vimwiki_'.g:vimwiki_syntax.'.vim'

execute 'syntax match wikiBold /'.g:vimwiki_rxBold.'/'

execute 'syntax match wikiItalic /'.g:vimwiki_rxItalic.'/'

execute 'syntax match wikiCode /'.g:vimwiki_rxCode.'/'

execute 'syntax match wikiDelText /'.g:vimwiki_rxDelText.'/'

execute 'syntax match wikiSuperScript /'.g:vimwiki_rxSuperScript.'/'

execute 'syntax match wikiSubScript /'.g:vimwiki_rxSubScript.'/'

" Aggregate all the regular text highlighting into wikiText
syntax cluster wikiText contains=wikiItalic,wikiBold,wikiCode,wikiDelText,wikiSuperScript,wikiSubScript,wikiWord,wikiEmoticons

" Header levels, 1-6
execute 'syntax match wikiH1 /'.g:vimwiki_rxH1.'/'
execute 'syntax match wikiH2 /'.g:vimwiki_rxH2.'/'
execute 'syntax match wikiH3 /'.g:vimwiki_rxH3.'/'
execute 'syntax match wikiH4 /'.g:vimwiki_rxH4.'/'
execute 'syntax match wikiH5 /'.g:vimwiki_rxH5.'/'
execute 'syntax match wikiH6 /'.g:vimwiki_rxH6.'/'

" <hr>, horizontal rule
execute 'syntax match wikiHR /'.g:vimwiki_rxHR.'/'

" Tables. Each line starts and ends with '||'; each cell is separated by '||'
execute 'syntax match wikiTable /'.g:vimwiki_rxTable.'/'

" Bulleted list items start with whitespace(s), then '*'
" syntax match wikiList           /^\s\+\(\*\|[1-9]\+0*\.\).*$/   contains=@wikiText
" highlight only bullets and digits.
execute 'syntax match wikiList /'.g:vimwiki_rxListBullet.'/'
execute 'syntax match wikiList /'.g:vimwiki_rxListNumber.'/'

" Treat all other lines that start with spaces as PRE-formatted text.
execute 'syntax match wikiPre /'.g:vimwiki_rxPre1.'/'




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

hi def link wikiPre                   PreProc
hi def link wikiLink                  Underlined
hi def link wikiList                  Type
hi def link wikiTable                 PreProc
hi def link wikiEmoticons             Constant
hi def link wikiDelText               Comment
hi def link wikiInsText               Constant
hi def link wikiSuperScript           Constant
hi def link wikiSubScript             Constant
hi def link wikiTodo                  Todo

let b:current_syntax="vimwiki"

syntax\vimwiki_default.vim	[[[1
54
" Vim syntax file
" Language:    Wiki (vimwiki default)
" Author:      Maxim Kim (habamax at gmail dot com)
" Home:        http://code.google.com/p/vimwiki/
" Filenames:   *.wiki
" Last Change: [15.09.2008 - 12:07]
" Version:     0.5

" text: *strong*
let g:vimwiki_rxBold = '\*[^*]\+\*'

" text: _emphasis_
let g:vimwiki_rxItalic = '_[^_]\+_'

" text: `code`
let g:vimwiki_rxCode = '`[^`]\+`'

" text: ~~deleted text~~
let g:vimwiki_rxDelText = '\~\~[^~]\+\~\~'

" text: ^superscript^
let g:vimwiki_rxSuperScript = '\^[^^]\+\^'

" text: ,,subscript,,
let g:vimwiki_rxSubScript = ',,[^,]\+,,'

" Header levels, 1-6
let g:vimwiki_rxH1 = '^!\{1}.*$'
let g:vimwiki_rxH2 = '^!\{2}.*$'
let g:vimwiki_rxH3 = '^!\{3}.*$'
let g:vimwiki_rxH4 = '^!\{4}.*$'
let g:vimwiki_rxH5 = '^!\{5}.*$'
let g:vimwiki_rxH6 = '^!\{6}.*$'

" <hr>, horizontal rule
let g:vimwiki_rxHR = '^----.*$'

" Tables. Each line starts and ends with '||'; each cell is separated by '||'
let g:vimwiki_rxTable = '||'

" Bulleted list items start with whitespace(s), then '*'
" syntax match wikiList           /^\s\+\(\*\|[1-9]\+0*\.\).*$/   contains=@wikiText
" highlight only bullets and digits.
" let g:vimwiki_rxList = '^\s\+\(\*\|#\)'
let g:vimwiki_rxListBullet = '^\s\+\*'
let g:vimwiki_rxListNumber = '^\s\+#'

" Treat all other lines that start with spaces as PRE-formatted text.
let g:vimwiki_rxPre1 = '^\s\+[^[:blank:]*#].*$'

syntax region wikiPre start=/^{{{\s*$/ end=/^}}}\s*$/
syntax sync match wikiPreSync grouphere wikiPre /^{{{\s*$/

" vim:tw=0:
syntax\vimwiki_google.vim	[[[1
53
" Vim syntax file
" Language:    Wiki
" Author:      Maxim Kim (habamax at gmail dot com)
" Home:        http://code.google.com/p/vimwiki/
" Filenames:   *.wiki
" Last Change: [15.09.2008 - 12:07]
" Version:     0.5

" text: *strong*
let g:vimwiki_rxBold = '\*[^*]\+\*'

" text: _emphasis_
let g:vimwiki_rxItalic = '_[^_]\+_'

" text: `code`
let g:vimwiki_rxCode = '`[^`]\+`'

" text: ~~deleted text~~
let g:vimwiki_rxDelText = '\~\~[^~]\+\~\~'

" text: ^superscript^
let g:vimwiki_rxSuperScript = '\^[^^]\+\^'

" text: ,,subscript,,
let g:vimwiki_rxSubScript = ',,[^,]\+,,'

" Header levels, 1-6
let g:vimwiki_rxH1 = '^\s*=\{1}.*=\{1}\s*$'
let g:vimwiki_rxH2 = '^\s*=\{2}.*=\{2}\s*$'
let g:vimwiki_rxH3 = '^\s*=\{3}.*=\{3}\s*$'
let g:vimwiki_rxH4 = '^\s*=\{4}.*=\{4}\s*$'
let g:vimwiki_rxH5 = '^\s*=\{5}.*=\{5}\s*$'
let g:vimwiki_rxH6 = '^\s*=\{6}.*=\{6}\s*$'

" <hr>, horizontal rule
let g:vimwiki_rxHR = '^----.*$'

" Tables. Each line starts and ends with '||'; each cell is separated by '||'
let g:vimwiki_rxTable = '||'

" Bulleted list items start with whitespace(s), then '*'
" syntax match wikiList           /^\s\+\(\*\|[1-9]\+0*\.\).*$/   contains=@wikiText
" highlight only bullets and digits.
let g:vimwiki_rxListBullet = '^\s\+\*'
let g:vimwiki_rxListNumber = '^\s\+#'

" Treat all other lines that start with spaces as PRE-formatted text.
let g:vimwiki_rxPre1 = '^\s\+[^[:blank:]*#].*$'

syntax region wikiPre start=/^{{{\s*$/ end=/^}}}\s*$/
syntax sync match wikiPreSync grouphere wikiPre /^{{{\s*$/

" vim:tw=0:
syntax\vimwiki_media.vim	[[[1
52
" Vim syntax file
" Language:    Wiki (MediaWiki)
" Author:      Maxim Kim (habamax at gmail dot com)
" Home:        http://code.google.com/p/vimwiki/
" Filenames:   *.wiki
" Last Change: [15.09.2008 - 12:07]
" Version:     0.5

" text: '''strong'''
let g:vimwiki_rxBold = "'''[^']\\+'''"

" text: ''emphasis''
let g:vimwiki_rxItalic = "''[^']\\+''"

" text: `code`
let g:vimwiki_rxCode = '`[^`]\+`'

" text: ~~deleted text~~
let g:vimwiki_rxDelText = '\~\~[^~]\+\~\~'

" text: ^superscript^
let g:vimwiki_rxSuperScript = '\^[^^]\+\^'

" text: ,,subscript,,
let g:vimwiki_rxSubScript = ',,[^,]\+,,'

" Header levels, 1-6
let g:vimwiki_rxH1 = '^\s*=\{1}.\+=\{1}\s*$'
let g:vimwiki_rxH2 = '^\s*=\{2}.\+=\{2}\s*$'
let g:vimwiki_rxH3 = '^\s*=\{3}.\+=\{3}\s*$'
let g:vimwiki_rxH4 = '^\s*=\{4}.\+=\{4}\s*$'
let g:vimwiki_rxH5 = '^\s*=\{5}.\+=\{5}\s*$'
let g:vimwiki_rxH6 = '^\s*=\{6}.\+=\{6}\s*$'

" <hr>, horizontal rule
let g:vimwiki_rxHR = '^----.*$'

" Tables. Each line starts and ends with '||'; each cell is separated by '||'
let g:vimwiki_rxTable = '||'

" Bulleted list items start with whitespace(s), then '*'
" highlight only bullets and digits.
let g:vimwiki_rxListBullet = '^\s*\*\+\([^*]*$\)\@='
let g:vimwiki_rxListNumber = '^\s*#\+'

" Treat all other lines that start with spaces as PRE-formatted text.
let g:vimwiki_rxPre1 = '^\s\+[^[:blank:]*#].*$'

syntax region wikiPre start=/^{{{\s*$/ end=/^}}}\s*$/
syntax sync match wikiPreSync grouphere wikiPre /^{{{\s*$/

" vim:tw=0:
