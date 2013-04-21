A Personal Wiki For Vim Plugin
==============================================================================

This is a mirror of http://www.vim.org/scripts/script.php?script_id=2226

Screenshots are available on http://code.google.com/p/vimwiki/ 
There are also zipped vimwiki files there in case you do not like vimball archives.


Prerequisites
==============================================================================

Make sure you have these settings in your vimrc file: 

    set nocompatible
    filetype plugin on
    syntax on

Without them Vimwiki will not work properly.


Intro
==============================================================================
Vimwiki is a personal wiki for Vim -- a number of linked text files that have
their own syntax highlighting.

With vimwiki you can:

 * organize notes and ideas;
 * manage todo-lists;
 * write documentation.

To do a quick start press <Leader>ww (this is usually \ww) to go to your index
wiki file.  By default it is located in: 
    ~/vimwiki/index.wiki

Feed it with the following example:

    = My knowledge base =
        * Tasks -- things to be done _yesterday_!!!
        * Project Gutenberg -- good books are power.
        * Scratchpad -- various temporary stuff.

Place your cursor on 'Tasks' and press Enter to create a link.  Once pressed,
'Tasks' will become '[[Tasks]]' -- a vimwiki link.  Press Enter again to
open it.  Edit the file, save it, and then press Backspace to jump back to your
index.

A vimwiki link can be constructed from more than one word.  Just visually
select the words to be linked and press Enter.  Try it with 'Project
Gutenberg'.  The result should look something like:

    = My knowledge base =
        * [[Tasks]] -- things to be done _yesterday_!!!
        * [[Project Gutenberg]] -- good books are power.
        * Scratchpad -- various temporary stuff.

For the various options see `:h vimwiki-options`.


Basic Markup
==============================================================================
see `:h vimwiki-syntax`

    *bold* -- bold 
    _italic_ -- italic 

    [[wiki link]] -- link with spaces
    [[wiki link|description]] -- link with description

Lists:

    * bullet list item 1
        - bullet list item 2
        - bullet list item 3
            * bullet list item 4
            * bullet list item 5
    * bullet list item 6
    * bullet list item 7
        - bullet list item 8
        - bullet list item 9

    # numbered list item 1
    # numbered list item 2
        # numbered list item 3
        # numbered list item 4

    = Header1 =
    == Header2 ==
    === Header3 ===


Key bindings
==============================================================================
see `:h vimwiki-mappings`

normal mode: 

 * `<Leader>ww` -- Open default wiki index file. 
 * `<Leader>wt` -- Open default wiki index file in a new tab. 
 * `<Leader>ws` -- Select and open wiki index file. 
 * `<Leader>wd` -- Delete wiki file you are in. 
 * `<Leader>wr` -- Rename wiki file you are in. 
 * `<Enter>` -- Folow/Create wiki link 
 * `<Shift-Enter>` -- Split and folow/create wiki link 
 * `<Ctrl-Enter>` -- Vertical split and folow/create wiki link 
 * `<Backspace>` -- Go back to parent(previous) wiki link 
 * `<Tab>` -- Find next wiki link 
 * `<Shift-Tab>` -- Find previous wiki link 


Commands 
============================================================================== 

 * `:Vimwiki2HTML` -- Convert current wiki link to HTML 
 * `:VimwikiAll2HTML` -- Convert all your wiki links to HTML 
 * `:help vimwiki-commands` -- list all commands
 
Install details
============================================================================== 

Using pathogen (http://www.vim.org/scripts/script.php?script_id=2332)

    cd ~/.vim
    mkdir bundle
    cd bundle
    git clone git://github.com/vim-scripts/vimwiki.git

Then launch vim and run `:help vimwiki` to verify it was installed.
