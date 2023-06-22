# Non regression tests for issue TODO
# -- TODO copy-paste issue description
#
# Syntax: https://github.com/junegunn/vader.vim#syntax-of-vader-file
# Run: bash run_tests.sh -v -t vader -n vim_7.3.429 -f issue_example.vader

Given vimwiki (Empty file):


Execute (Set vimwiki property rxTableSep):
  call SetSyntax('markdown')
  call vimwiki#vars#set_syntaxlocal('rxTableSep', '│' )
  AssertEqual '│', vimwiki#vars#get_syntaxlocal('rxTableSep'), "Conf has been changed"
  

Execute(VimwikiTable):
  VimwikiTable

Expect (Unicode table created):
  
  │   │   │   │   │   │
  │---│---│---│---│---│
  │   │   │   │   │   │


Given vimwiki (Unicode table):
  │ bla bla bla   │   │   │   │   │
  │---│---│---│---│---│
  │   │   │   │   │   │


Execute (Rename file wiki_test.md for table expand):
  file wiki_test.md
  call SetSyntax('markdown')
  call vimwiki#vars#set_syntaxlocal('rxTableSep', '│' )


Do (Expand table):
  :AssertEqual '│', vimwiki#vars#get_syntaxlocal('rxTableSep'), "Conf has been changed"\<Cr>
  A

Expect (Unicode table expanded):
  │ bla bla bla │   │   │   │   │
  │-------------│---│---│---│---│
  │             │   │   │   │   │
