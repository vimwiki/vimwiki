function! vimwiki#todo#grep()
  "let l:path = vimwiki#vars#get_wikilocal('path')
  let l:diary_files = vimwiki#diary#get_diary_files()
  "let l:files = vimwiki#base#find_files(-1,0)

  call setqflist([])

  for f in l:diary_files

    silent call setqflist([{'text': '# ' . split(split(f, '/')[-1], '\.')[0], 'filename': f}], 'a')

    silent execute 'vimgrepadd /\- \[ \]/' . f
  endfor

  copen

  set modifiable

  for i in range(1, line('$'))
    let l:line = getline(i)
    let l:line = substitute(l:line, '^[^|]*', '', '')
    let l:line = substitute(l:line, '^|| ', '', '')
    let l:line = substitute(l:line, '^|[^|]*|', '', '')

    call setline(i, l:line)
  endfor

  set nomodified
  set nomodifiable

  normal! gg
endfunction
