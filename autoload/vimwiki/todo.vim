function! vimwiki#todo#list()
  "let files = vimwiki#base#find_files(-1,0)
  let files = vimwiki#diary#get_diary_files()

  call setqflist([])

  silent call setqflist([{'text': '# In progress'}], 'a')
  for f in files
    let d = split(split(f, '/')[-1], '\.')[0]
    silent call setqflist([{'text': '# ' . d, 'filename': f}], 'a')
    silent execute 'vimgrepadd /\- \[\.\]/' . f
  endfor

  silent call setqflist([{'text': '# To Do'}], 'a')
  for f in files
    let d = split(split(f, '/')[-1], '\.')[0]

    silent call setqflist([{'text': '## ' . d, '\.')[0], 'filename': f}], 'a')
    silent execute 'vimgrepadd /\- \[\.\]/' . f
  endfor

  copen

  setlocal modifiable

  for i in range(1, line('$'))
    let l:line = getline(i)
    let l:line = substitute(l:line, '^[^|]*', '', '')
    let l:line = substitute(l:line, '^|| ', '', '')
    let l:line = substitute(l:line, '^|[^|]*|', '', '')
    call setline(i, l:line)
  endfor

  setlocal nomodified
  setlocal nomodifiable

  normal! gg
endfunction
