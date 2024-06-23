function! vimwiki#todo#list()
  let path = vimwiki#vars#get_wikilocal('path')
  let rel_path = substitute(path, '^' . getcwd() . '/', '', '')
  let diary_rel_path = vimwiki#vars#get_wikilocal('diary_rel_path')

  let files = path . diary_rel_path . '*.md'

  call setqflist([])

  silent call setqflist([{'text': '# In progress'}], 'a')
  silent execute 'vimgrepadd /\- \[\.\]/ ' . files

  silent call setqflist([{'text': '# To Do'}], 'a')
  silent execute 'vimgrepadd /\- \[ \]/' . files

  copen

  setlocal modifiable

  for i in range(1, line('$'))
    let line = getline(i)
    let line = substitute(line, '^' . rel_path, '', '')
    let line = substitute(line, '^' . diary_rel_path, 'diary:', '')
    let line = substitute(line, '.md|', '|', '')
    let line = substitute(line, '|\([0-9]\+\) col [0-9-]*|', '|\1|', '')
    let line = substitute(line, '^|| ', '', '')
    call setline(i, line)
  endfor

  setlocal nomodified
  setlocal nomodifiable

  " normal! gg
  nnoremap <buffer> <C-Space> :call vimwiki#todo#toggle()<CR>
endfunction

function! vimwiki#todo#toggle()
  execute ":normal \<C-W>\<CR>"
  execute ":normal \<C-Space>"
  execute ":normal y$"
  wincmd q
  wincmd p
  setlocal modifiable
  execute ":normal ^W\"_Dp"
  setlocal nomodified
  setlocal nomodifiable
endfunction
