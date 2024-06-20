function! vimwiki#todo#list()
  let files = vimwiki#vars#get_wikilocal('path') . vimwiki#vars#get_wikilocal('diary_rel_path') . '*.md'

  call setqflist([])

  silent call setqflist([{'text': '# In progress'}], 'a')
  silent execute 'vimgrepadd /\- \[\.\]/ ' . files

  silent call setqflist([{'text': '# To Do'}], 'a')
  silent execute 'vimgrepadd /\- \[ \]/' . files

  copen

  setlocal modifiable

  for i in range(1, line('$'))
    let line = getline(i)
    let line = substitute(line, '^\([^\/]*\/\)*', '', '')
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
