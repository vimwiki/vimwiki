set runtimepath+=/tmp/vader_wiki/home/vimtest/vim,$VIM/vimfiles,$VIMRUNTIME,$VIM/vimfiles/after,/tmp/vader_wiki/home/vimtest/vim/after
execute 'set rtp+='.join(filter(split(expand('/tmp/vader_wiki/home/vimtest/plugins/*')), 'isdirectory(v:val)'), ',')
set runtimepath+=/tmp/vader_wiki/testplugin
