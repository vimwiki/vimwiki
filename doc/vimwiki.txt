*vimwiki.txt*   A Personal Wiki for Vim

             __   __  ___   __   __  _     _  ___   ___   _  ___             ~
            |  | |  ||   | |  |_|  || | _ | ||   | |   | | ||   |            ~
            |  |_|  ||   | |       || || || ||   | |   |_| ||   |            ~
            |       ||   | |       ||       ||   | |      _||   |            ~
            |       ||   | |       ||       ||   | |     |_ |   |            ~
             |     | |   | | ||_|| ||   _   ||   | |    _  ||   |            ~
              |___|  |___| |_|   |_||__| |__||___| |___| |_||___|            ~


                               Version: 2.5

==============================================================================
CONTENTS                                                             *vimwiki*

    1. Intro                         |vimwiki-intro|
    2. Prerequisites                 |vimwiki-prerequisites|
    3. Mappings                      |vimwiki-mappings|
        3.1. Global mappings         |vimwiki-global-mappings|
        3.2. Local mappings          |vimwiki-local-mappings|
        3.3. Text objects            |vimwiki-text-objects|
    4. Commands                      |vimwiki-commands|
        4.1. Global commands         |vimwiki-global-commands|
        4.2. Local commands          |vimwiki-local-commands|
    5. Wiki syntax                   |vimwiki-syntax|
        5.1. Typefaces               |vimwiki-syntax-typefaces|
        5.2. Links                   |vimwiki-syntax-links|
        5.3. Headers                 |vimwiki-syntax-headers|
        5.4. Paragraphs              |vimwiki-syntax-paragraphs|
        5.5. Lists                   |vimwiki-syntax-lists|
        5.6. Tables                  |vimwiki-syntax-tables|
        5.7. Preformatted text       |vimwiki-syntax-preformatted|
        5.8. Mathematical formulae   |vimwiki-syntax-math|
        5.9. Blockquotes             |vimwiki-syntax-blockquotes|
        5.10. Comments               |vimwiki-syntax-comments|
        5.11. Horizontal line        |vimwiki-syntax-hr|
        5.12. Tags                   |vimwiki-syntax-tags|
    6. Folding/Outline               |vimwiki-folding|
    7. Placeholders                  |vimwiki-placeholders|
    8. Lists                         |vimwiki-lists|
    9. Tables                        |vimwiki-tables|
    10. Diary                        |vimwiki-diary|
    11. Anchors                      |vimwiki-anchors|
    12. Options                      |vimwiki-options|
        12.1. Registered Wiki        |vimwiki-register-wiki|
        12.2. Temporary Wiki         |vimwiki-temporary-wiki|
        12.3. Per-Wiki Options       |vimwiki-local-options|
        12.4. Global Options         |vimwiki-global-options|
    13. Getting help                 |vimwiki-help|
    14. Contributing & Bug reports   |vimwiki-contributing|
    15. Development                  |vimwiki-development|
    16. Changelog                    |vimwiki-changelog|
    17. License                      |vimwiki-license|


==============================================================================
1. Intro                                                       *vimwiki-intro*

Vimwiki makes it very easy for you create a personal wiki using the Vim text
editor. A wiki is a collection of text documents linked together and formatted
with wiki or markdown syntax that can be highlighted for readability using
Vim's syntax highlighting feature.

With Vimwiki you can:
    - organize notes and ideas
    - manage todo-lists
    - write documentation
    - maintain a diary
    - export your documents to HTML

Getting started with Vimwiki is easy. Once intalled, simply type `vim` into
your terminal to launch Vim and then type <Leader>ww (the <Leader> key is `\`
by default) to create or open the index wiki file, the "top" page in your
hierarchical collection of wiki pages. By default, this page will be located
at ~/vimwiki/index.wiki.

Now add the following example lines to the document:

= My knowledge base =
    * Tasks -- things to be done _yesterday_!!!
    * Project Gutenberg -- good books are power.
    * Scratchpad -- various temporary stuff.

Next, move your cursor to the word 'Tasks' and press `Enter`. This will create
a Vimwiki link by surrounding 'Tasks' with double square brackets:
'[[Tasks]]'. Pressing `Enter` a second time will generate a new blank buffer
in Vim where you can input your tasks. After you add some tasks and save the
new file, you can hit `Backspace` to jump back to the index document.

A Vimwiki link can contain multiple words by entering Vim's "visual" mode (the
"v" key, by default) and selecting the words to be linked. Once selected,
press `Enter`.

Try this now by selecting 'Project Gutenberg' in visual mode and hitting
`Enter`. The sample text should now look something like this:

= My knowledge base =
    * [[Tasks]] -- things to be done _yesterday_!!!
    * [[Project Gutenberg]] -- good books are power.
    * Scratchpad -- various temporary stuff.

By continuing this way and creating sub pages with links to even more sub
pages, you can create an unlimited number of neatly structured, interconnected
documents to help you organize your notes, documenation, and tasks.

==============================================================================
2. Prerequisites                                       *vimwiki-prerequisites*

Make sure you have these settings in your vimrc file: >
    set nocompatible
    filetype plugin on
    syntax on

Without them Vimwiki will not work properly.


==============================================================================
3. Mappings                                                 *vimwiki-mappings*

There are global and local mappings in Vimwiki.

------------------------------------------------------------------------------
3.1. Global mappings                                 *vimwiki-global-mappings*

Below is a list of all default global key mappings provided by Vimwiki. As
global settings, they work in all vim sessions no matter what filetype you
have open. Vimwiki respects pre-existing global mappings created by you or
other plugins and will not overwrite them.

If a conflict exists between Vimwiki and pre-existing maps or if you wish to
customize these default mappings, you can remap them with: >

         :nmap {map} <Plug>{command}

where
        `{map}` is the new key sequence of your choosing
        `{command}` is the Vimwiki command you are remapping

So, for example, to remap the |:VimwikiIndex| mapping, you'd do something
like: >
        :nmap <Leader>wx <Plug>VimwikiIndex

Note that the recursive version of "map" command is needed to expand the right
hand side to retrieve the <Plug> definition. "noremap" will not work. <Plug> is
required and considered to be part of the command.

You can also place remappings in your vimrc file, without the leading colon, of
course.


                                                          *vimwiki_<Leader>ww*
[count]<Leader>ww
        Open index file of the [count]'s wiki.

        <Leader>ww opens the first wiki from |g:vimwiki_list| if no wiki is
        open. Otherwise the index of the currently active wiki is opened.
        1<Leader>ww opens the first wiki from |g:vimwiki_list|.
        2<Leader>ww opens the second wiki from |g:vimwiki_list|.
        3<Leader>ww opens the third wiki from |g:vimwiki_list|.
        etc.

        Remap command: `<Plug>VimwikiIndex`

See also |:VimwikiIndex|


                                                          *vimwiki_<Leader>wt*
[count]<Leader>wt
        Open index file of the [count]'s wiki in a new tab.

        <Leader>wt tabopens the first wiki from |g:vimwiki_list|.
        1<Leader>wt as above tabopens the first wiki from |g:vimwiki_list|.
        2<Leader>wt tabopens the second wiki from |g:vimwiki_list|.
        3<Leader>wt tabopens the third wiki from |g:vimwiki_list|.
        etc.

        Remap command: `<Plug>VimwikiTabIndex`

See also |:VimwikiTabIndex|

                                                          *vimwiki_<Leader>ws*
<Leader>ws
        List and select available wikis.

        Remap command: `<Plug>VimwikiUISelect`

See also |:VimwikiUISelect|

                                                          *vimwiki_<Leader>wi*
[count]<Leader>wi
        Open diary index file of the [count]'s wiki.

        <Leader>wi opens diary index file of the current wiki.
        1<Leader>wi opens diary index file of the first wiki from
        |g:vimwiki_list|.
        2<Leader>wi opens diary index file of the second wiki from
        |g:vimwiki_list|.
        etc.

        Remap command: `<Plug>VimwikiDiaryIndex`

See also |:VimwikiDiaryIndex|

                                                  *vimwiki_<Leader>w<Leader>w*
[count]<Leader>w<Leader>w
        Open diary wiki-file for today of the [count]'s wiki.

        <Leader>w<Leader>w opens diary wiki-file for today in the current wiki
        1<Leader>w<Leader>w opens diary wiki-file for today in the first wiki
        from |g:vimwiki_list|.
        2<Leader>w<Leader>w opens diary wiki-file for today in the second wiki
        from |g:vimwiki_list|.
        3<Leader>w<Leader>w opens diary wiki-file for today in the third wiki
        from |g:vimwiki_list|.
        etc.

        Remap command: `<Plug>VimwikiMakeDiaryNote`

See also |:VimwikiMakeDiaryNote|


                                                  *vimwiki_<Leader>w<Leader>t*
[count]<Leader>w<Leader>t
        Open diary wiki-file for today of the [count]'s wiki in a new tab.

        <Leader>w<Leader>t tabopens diary wiki-file for today in the current
        wiki
        1<Leader>w<Leader>t tabopens diary wiki-file for today in the
        first wiki from |g:vimwiki_list|.
        2<Leader>w<Leader>t tabopens diary wiki-file for today in the second
        wiki from |g:vimwiki_list|.
        3<Leader>w<Leader>t tabopens diary wiki-file for today in the third
        wiki from |g:vimwiki_list|.
        etc.

        Remap command: `<Plug>VimwikiTabMakeDiaryNote`

See also |:VimwikiTabMakeDiaryNote|


                                                  *vimwiki_<Leader>w<Leader>y*
[count]<Leader>w<Leader>y
        Open diary wiki-file for yesterday of the [count]'s wiki.

        <Leader>w<Leader>y opens diary wiki-file for yesterday in the current
        wiki
        1<Leader>w<Leader>y opens diary wiki-file for yesterday in the first
        wiki from |g:vimwiki_list|.
        2<Leader>w<Leader>y opens diary wiki-file for yesterday in the second
        wiki from |g:vimwiki_list|.
        3<Leader>w<Leader>y opens diary wiki-file for yesterday in the third
        wiki from |g:vimwiki_list|.
        etc.

        Remap command: `<Plug>VimwikiMakeYesterdayDiaryNote`

See also |:VimwikiMakeYesterdayDiaryNote|

                                                  *vimwiki_<Leader>w<Leader>m*
[count]<Leader>w<Leader>m
        Open diary wiki-file for tomorrow of the [count]'s wiki.

        <Leader>w<Leader>m opens diary wiki-file for tomorrow in the current
        wiki
        1<Leader>w<Leader>m opens diary wiki-file for tomorrow in the first
        wiki from |g:vimwiki_list|.
        2<Leader>w<Leader>m opens diary wiki-file for tomorrow in the second
        wiki from |g:vimwiki_list|.
        3<Leader>w<Leader>m opens diary wiki-file for tomorrow in the third
        wiki from |g:vimwiki_list|.
        etc.

        Remap command: `<Plug>VimwikiMakeTomorrowDiaryNote`

See also |:VimwikiMakeTomorrowDiaryNote|

------------------------------------------------------------------------------
3.2. Local mappings                                   *vimwiki-local-mappings*

Below is a listing of all local key mappings provided by Vimwiki. As local
settings, they are available when |FileType| is set to "vimwiki". These
mappings may overwrite pre-existing mappings, but they can be remapped or
disabled (see |g:vimwiki_key_mappings|).

To remap commands that begin with <Plug>, you should do the following:

        :{mode}map {map} <Plug>{command}

For commands that do not begin with <Plug>, do:

        :{mode}noremap {map} {command}

where
        `{mode}` is set to `n` for "normal" mode, `v` for "visual", and `i` for "insert"
        `{map}` is the new key sequence of your choosing
        `{command}` is the Vimwiki command you are remapping

Examples: >
       :nmap <Leader>tl <Plug>VimwikiToggleListItem
       :vmap <Leader>tl <Plug>VimwikiToggleListItem
       :nnoremap glo :VimwikiChangeSymbolTo a)<CR>

The first two lines remap "\tl" to the |:VimwikiToggleListItem| command in both
normal and visual modes. |<Leader>| is set to "\" by default. Use `:echo mapleader`
to determine if it is set to another value. The third map listed
above, which does not contain <Plug>, maps directly to an |Ex| mode command.

Note that |map| is needed for commands beginning with <Plug>. This recursive
version of the "map" command is needed to expand the right hand side to retrieve
the <Plug> definition. "noremap" will not work. <Plug> is required and
considered to be part of the command.

It is recommended that you place your local mappings into a file at
ftplugin/vimwiki.vim within your .vim configuration directory. Create this file
if it doesn't already exist. Or, if you prefer, you can set up a FileType
|autocmd| in your vimrc.

Note: it may be desirable to add `<silent> <buffer>` to mapped commands but
this should only be done if the mappings are placed in ftplugin or in
a Filetype based autocommand. See the Vim help for a description of these
options.

MAP                MODE
                                                          *vimwiki_<Leader>wh*
<Leader>wh         n    Convert current wiki page to HTML.
                        Maps to |:Vimwiki2HTML|
                        Remap command: `<Plug>Vimwiki2HTML`

                                                         *vimwiki_<Leader>whh*
<Leader>whh        n    Convert current wiki page to HTML and open it in the
                        webbrowser.
                        Maps to |:Vimwiki2HTMLBrowse|
                        Remap command: `<Plug>Vimwiki2HTMLBrowse`

                                                  *vimwiki_<Leader>w<Leader>i*
<Leader>w<Leader>i n    Update diary section (delete old, insert new)
                        Only works from the diary index.
                        Maps to |:VimwikiDiaryGenerateLinks|
                        Remap command: `<Plug>VimwikiDiaryGenerateLinks`

                                                                *vimwiki_<CR>*
<CR>               n    Follow/create wiki link (create target wiki page if
                        needed).
                        Maps to |:VimwikiFollowLink|.
                        Remap command: `<Plug>VimwikiFollowLink`

                                                              *vimwiki_<S-CR>*
<S-CR>             n    Split and follow (create target wiki page if needed).
                        May not work in some terminals. Remapping could help.
                        Maps to |:VimwikiSplitLink|.
                        Remap command: `<Plug>VimwikiSplitLink`

                                                              *vimwiki_<C-CR>*
<C-CR>             n    Vertical split and follow (create target wiki page if
                        needed).  May not work in some terminals. Remapping
                        could help.
                        Maps to |:VimwikiVSplitLink|.
                        Remap command: `<Plug>VimwikiVSplitLink`

                                        *vimwiki_<C-S-CR>*    *vimwiki_<D-CR>*
<C-S-CR>, <D-CR>   n    Follow wiki link (create target wiki page if needed),
                        opening in a new tab.
                        May not work in some terminals. Remapping could help.
                        Maps to |:VimwikiTabnewLink|.
                        Remap command: `<Plug>VimwikiTabnewLink`

                                                         *vimwiki_<Backspace>*
<Backspace>        n    Go back to previously visited wiki page.
                        Maps to |:VimwikiGoBackLink|.
                        Remap command: `<Plug>VimwikiGoBackLink`

                                                               *vimwiki_<Tab>*
<Tab>              n    Find next link in the current page.
                        Maps to |:VimwikiNextLink|.
                        Remap command: `<Plug>VimwikiNextLink`

                                                             *vimwiki_<S-Tab>*
<S-Tab>            n    Find previous link in the current page.
                        Maps to |:VimwikiPrevLink|.
                        Remap command: `<Plug>VimwikiPrevLink`

                                                          *vimwiki_<Leader>wn*
<Leader>wn         n    Goto or create new wiki page.
                        Maps to |:VimwikiGoto|.
                        Remap command: `<Plug>VimwikiGoto`

                                                          *vimwiki_<Leader>wd*
<Leader>wd         n    Delete wiki page you are in.
                        Maps to |:VimwikiDeleteFile|.
                        Remap command: `<Plug>VimwikiDeleteFile`

                                                          *vimwiki_<Leader>wr*
<Leader>wr         n    Rename wiki page you are in.
                        Maps to |:VimwikiRenameFile|.
                        Remap command: `<Plug>VimwikiRenameFile`

                                                                   *vimwiki_=*
=                  n    Add header level. Create if needed.
                        There is nothing to indent with '==' command in
                        Vimwiki, so it should be ok to use '=' here.
                        Remap command: `<Plug>VimwikiAddHeaderLevel`

                                                                   *vimwiki_-*
-                  n    Remove header level.
                        Remap command: `<Plug>VimwikiRemoveHeaderLevel`

                                                                  *vimwiki_[[*
[[                 n    Go to the previous header in the buffer.
                        Remap command: `<Plug>VimwikiGoToPrevHeader`

                                                                  *vimwiki_]]*
]]                 n    Go to the next header in the buffer.
                        Remap command: `<Plug>VimwikiGoToNextHeader`

                                                                  *vimwiki_[=*
[=                 n    Go to the previous header which has the same level as
                        the header the cursor is currently under.
                        Remap command: `<Plug>VimwikiGoToPrevSiblingHeader`

                                                                  *vimwiki_]=*
]=                 n    Go to the next header which has the same level as the
                        header the cursor is currently under.
                        Remap command: `<Plug>VimwikiGoToNextSiblingHeader`

                                                    *vimwiki_]u*  *vimwiki_[u*
]u [u              n    Go one level up -- that is, to the parent header of
                        the header the cursor is currently under.
                        Remap command: `<Plug>VimwikiGoToParentHeader`

                                                                   *vimwiki_+*
+                  n v  Create and/or decorate links.  Depending on the
                        context, this command will: convert words into
                        wikilinks; convert raw URLs into wikilinks; and add
                        placeholder description text to wiki- or weblinks that
                        are missing descriptions.  Can be activated in normal
                        mode with the cursor over a word or link, or in visual
                        mode with the selected text.
                        Remap commands:
                        `<Plug>VimwikiNormalizeLink` (normal mode)
                        `<Plug>VimwikiNormalizeLinkVisual` (visual mode)

                                                          *vimwiki_<C-Space>*
<C-Space>         n     Toggle checkbox of a list item on/off.
                        Maps to |:VimwikiToggleListItem|.
                        See |vimwiki-todo-lists|.
                        Remap command: `<Plug>VimwikiToggleListItem`

                                                                *vimwiki_gnt*
gnt               n     Find next unfinished task in the current page.
                        Maps to |:VimwikiNextTask|
                        Remap command: `<Plug>VimwikiNextTask`

                                      *vimwiki_gl<Space>* *vimwiki_gL<Space>*
gl<Space>         n     Remove checkbox from list item.
                        Remap command: `<Plug>VimwikiRemoveSingleCB`
gL<Space>               Remove checkboxes from all sibling list items.
                        Remap command: `<Plug>VimwikiRemoveCBInList`

                                                  *vimwiki_gln* *vimwiki_glp*
gln               n v   Increase the "done" status of a list checkbox, i.e.
                        from [ ] to [.] to [o] etc. See |vimwiki-todo-lists|.
glp                     Decrease the "done" status.
                        Remap command: `<Plug>VimwikiIncrementListItem`

                                                  *vimwiki_gll* *vimwiki_gLl*
gll               n     Increase the level of a list item.
                        Remap commnad: `<Plug>VimwikiIncreaseLvlSingleItem`
gLl                     Increase the level of a list item and all child items.
                        Remap command: `<Plug>VimwikiIncreaseLvlWholeItem`

                                                  *vimwiki_glh* *vimwiki_gLh*
glh               n     Decrease the level of a list item.
                        Remap command: `<Plug>VimwikiDecreaseLvlSingleItem`
gLh                     Decrease the level of a list item and all child items.
                        Remap command: `<Plug>VimwikiDecreaseLvlWholeItem`

                                                  *vimwiki_glr* *vimwiki_gLr*
glr               n     Renumber list items if the cursor is on a numbered
                        list item.
                        Remap command: `<Plug>VimwikiRenumberList`
gLr                     Renumber list items in all numbered lists in the whole
                        file. Also readjust checkboxes.
                        Remap command: `<Plug>VimwikiRenumberAllLists`

                                            *vimwiki_glstar* *vimwiki_gLstar*
gl*               n     Make a list item out of a normal line or change the
                        symbol of the current item to *.
gL*                     Change the symbol of the current list to *.
                        Remap command: `:VimwikiChangeSymbolTo *<CR>`
                        noremap glO :VimwikiChangeSymbolInListTo *<CR>

                                                  *vimwiki_gl#* *vimwiki_gL#*
gl#               n     Make a list item out of a normal line or change the
                        symbol of the current item to #.
gL#                     Change the symbol of the current list to #.
                        Remap command: `:VimwikiChangeSymbolTo #<CR>`
                        Remap command: `:VimwikiChangeSymbolInListTo #<CR>`

                                                  *vimwiki_gl-* *vimwiki_gL-*
gl-               n     Make a list item out of a normal line or change the
                        symbol of the current item to -.
                        Remap command:  `:VimwikiChangeSymbolTo -<CR>`
gL-                     Change the symbol of the current list to -.
                        Remap command: `:VimwikiChangeSymbolInListTo -<CR>`

                                                  *vimwiki_gl1* *vimwiki_gL1*
gl1               n     Make a list item out of a normal line or change the
                        symbol of the current item to 1., the numbering is
                        adjusted according to the surrounding list items.
                        Remap command: `:VimwikiChangeSymbolTo 1.<CR>`
gL1                     Change the symbol of the current list to 1. 2. 3. ...
                        Remap command: `:VimwikiChangeSymbolInListTo 1.<CR>`

                                                  *vimwiki_gla* *vimwiki_gLa*
gla              n      Make a list item out of a normal line or change the
                        symbol of the current item to a), the numbering is
                        adjusted according to the surrounding list items.
                        Remap command: `:VimwikiChangeSymbolTo a)<CR>`
gLa                     Change the symbol of the current list to a) b) c) ...
                        Remap command: `:VimwikiChangeSymbolInListTo a)<CR>`

                                                  *vimwiki_glA* *vimwiki_gLA*
glA              n      Make a list item out of a normal line or change the
                        symbol of the current item to A), the numbering is
                        adjusted according to the surrounding list items.
                        Remap command: `:VimwikiChangeSymbolTo A)<CR>`
gLA                     Change the symbol of the current list to A) B) C) ...
                        Remap command: `:VimwikiChangeSymbolInListTo A)<CR>`

                                                  *vimwiki_gli* *vimwiki_gLi*
gli              n      Make a list item out of a normal line or change the
                        symbol of the current item to i), the numbering is
                        adjusted according to the surrounding list items.
                        Remap command: `:VimwikiChangeSymbolTo i)<CR>`
gLi                     Change the symbol of the current list to
                        i) ii) iii) ...
                        Remap command: `:VimwikiChangeSymbolInListTo i)<CR>`

                                                  *vimwiki_glI* *vimwiki_gLI*
glI              n      Make a list item out of a normal line or change the
                        symbol of the current item to I), the numbering is
                        adjusted according to the surrounding list items.
                        Remap command: `:VimwikiChangeSymbolTo I)<CR>`
gLI                     Change the symbol of the current list to
                        I) II) III) ...
                        Remap command: `:VimwikiChangeSymbolInListTo I)<CR>`

                                                                *vimwiki_glx*
glx              n      Toggle checkbox of a list item disabled/off.
                        Maps to |:VimwikiToggleRejectedListItem|.
                        See |vimwiki-todo-lists|.
                        Remap command: `<Plug>VimwikiToggleRejectedListItem`

                                                 *vimwiki_gqq*  *vimwiki_gww*
gqq              n      Reformats table after making changes.
 or                     Remap command: `<Plug>VimwikiTableAlignQ`
gww                     Remap command: `<Plug>VimwikiTableAlignW`

                                                 *vimwiki_gq1*  *vimwiki_gw1*
gq1              n      Fast format table. The same as the previous, except
 or                     that only a few lines above the current line are
                        tested. If the alignment of the current line differs,
                        then the whole table gets reformatted.
                        Remap command: `<Plug>VimwikiTableAlignQ1`
gw1                     Remap command:`<Plug>VimwikiTableAlignW1`

                                                           *vimwiki_<A-Left>*
<A-Left>         n      Move current table column to the left.
                        See |:VimwikiTableMoveColumnLeft|
                        Remap command: `<Plug>VimwikiTableMoveColumnLeft`

                                                          *vimwiki_<A-Right>*
<A-Right>        n      Move current table column to the right.
                        See |:VimwikiTableMoveColumnRight|
                        Remap command: `<Plug>VimwikiTableMoveColumnRight`

                                                             *vimwiki_<C-Up>*
<C-Up>           n      Open the previous day's diary link if available.
                        See |:VimwikiDiaryPrevDay|
                        Remap command: `<Plug>VimwikiDiaryPrevDay`

                                                           *vimwiki_<C-Down>*
<C-Down>         n      Open the next day's diary link if available.
                        See |:VimwikiDiaryNextDay|
                        Remap command: `<Plug>VimwikiDiaryNextDay`

Mouse mappings                                                *vimwiki_mouse*

These mappings are disabled by default.
See |g:vimwiki_key_mappings| to enable.

<2-LeftMouse>           Follow wiki link (create target wiki page if needed).

<S-2-LeftMouse>         Split and follow wiki link (create target wiki page if
                        needed).

<C-2-LeftMouse>         Vertical split and follow wiki link (create target
                        wiki page if needed).

<RightMouse><LeftMouse> Go back to previous wiki page.

Note: <2-LeftMouse> is just left double click.



TABLE MAPPINGS, INSERT MODE                           *vimwiki-table-mappings*
                                                        *vimwiki_i_<CR>_table*
<CR>                    Go to the table cell beneath the current one, create
                        a new row if on the last one.

                                                       *vimwiki_i_<Tab>_table*
<Tab>                   Go to the next table cell, create a new row if on the
                        last cell.

LIST MAPPINGS, INSERT MODE                             *vimwiki-list-mappings*
                                                              *vimwiki_i_<CR>*
<CR>                    In a list item, insert a new bullet or number in the
                        next line, numbers are incremented.
                        In an empty list item, delete the item symbol. This is
                        useful to end a list, simply press <CR> twice.
                        See |vimwiki-lists| for details and for how to
                        configure the behavior.

                                                            *vimwiki_i_<S-CR>*
<S-CR>                  Does not insert a new list item, useful to create
                        multilined list items. See |vimwiki-lists| for
                        details and for how to configure the behavior. The
                        default map may not work in all terminals and may
                        need to be remapped.

                                                             *vimwiki_i_<C-T>*
<C-T>                   Increase the level of a list item.
                        Remap command: `<Plug>VimwikiIncreaseLvlSingleItem`

                                                             *vimwiki_i_<C-D>*
<C-D>                   Decrease the level of a list item.
                        Remap command: `<Plug>VimwikiDecreaseLvlSingleItem`

                                                       *vimwiki_i_<C-L>_<C-J>*
<C-L><C-J>              Change the symbol of the current list item to the next
                        available. From - to 1. to * to I) to a).
                        Remap command: `<Plug>VimwikiListNextSymbol`

                                                       *vimwiki_i_<C-L>_<C-K>*
<C-L><C-K>              Change the symbol of the current list item to the prev
                        available. From - to a) to I) to * to 1.
                        Remap command: `<Plug>VimwikiListPrevSymbol`

                                                       *vimwiki_i_<C-L>_<C-M>*
<C-L><C-M>              Create/remove a symbol from a list item.
                        Remap command: `<Plug>VimwikiListToggle`


------------------------------------------------------------------------------
3.3. Text objects                                       *vimwiki-text-objects*

ah                      A header including its content up to the next header.
ih                      The content under a header (like 'ah', but excluding
                        the header itself and trailing empty lines).

aH                      A header including all of its subheaders. When [count]
                        is 2, include the parent header, when [count] is 3,
                        the grandparent and so on.
iH                      Like 'aH', but excluding the header itself and
                        trailing empty lines.

Examples:
- type 'cih' to change the content under the current header
- 'daH' deletes an entire header plus its content including the content of all
  of its subheaders
- 'v2aH' selects the parent header of the header the cursor is under plus all
  of the content of all of its subheaders

a\                      A cell in a table.
i\                      An inner cell in a table.
ac                      A column in a table.
ic                      An inner column in a table.

al                      A list item plus its children.
il                      A single list item.

These key mappings can be modified by replacing the default keys: >

  omap ah <Plug>VimwikiTextObjHeader
  vmap ah <Plug>VimwikiTextObjHeaderV
  omap ih <Plug>VimwikiTextObjHeaderContent
  vmap ih <Plug>VimwikiTextObjHeaderContentV
  omap aH <Plug>VimwikiTextObjHeaderSub
  vmap aH <Plug>VimwikiTextObjHeaderSubV
  omap iH <Plug>VimwikiTextObjHeaderSubContent
  vmap iH <Plug>VimwikiTextObjHeaderSubContentV
  omap a\ <Plug>VimwikiTextObjTableCell
  vmap a\ <Plug>VimwikiTextObjTableCellV
  omap i\ <Plug>VimwikiTextObjTableCellInner
  vmap i\ <Plug>VimwikiTextObjTableCellInnerV
  omap ac <Plug>VimwikiTextObjColumn
  vmap ac <Plug>VimwikiTextObjColumnV
  omap ic <Plug>VimwikiTextObjColumnInner
  vmap ic <Plug>VimwikiTextObjColumnInnerV
  omap al <Plug>VimwikiTextObjListChildren
  vmap al <Plug>VimwikiTextObjListChildrenV
  omap il <Plug>VimwikiTextObjListSingle
  vmap il <Plug>VimwikiTextObjListSingleV


==============================================================================
4. Commands                                                 *vimwiki-commands*

------------------------------------------------------------------------------
4.1. Global Commands                                 *vimwiki-global-commands*

*:VimwikiIndex* [count]
    Open index file of the current wiki. If a [count] is given the
    corresponding wiki from |g:vimwiki_list| is opened instead.

*:VimwikiTabIndex* [count]
    Open index file of the current wiki in a new tab. If a [count] is given
    the corresponding wiki from |g:vimwiki_list| is opened instead.

*:VimwikiUISelect*
    Displays a list of registered wikis and opens the index file of the
    selected wiki.

*:VimwikiDiaryIndex* [count]
    Open diary index file of the current wiki. If a [count] is given the
    corresponding wiki from |g:vimwiki_list| is opened instead.

*:VimwikiMakeDiaryNote* [count]
    Open diary wiki-file for today of the current wiki. If a [count] is given
    a diary wiki-file for the corresponding wiki from |g:vimwiki_list| is
    opened instead.

*:VimwikiTabMakeDiaryNote* [count]
    Open diary wiki-file for today of the current wiki in a new tab. If
    a [count] is given a diary wiki-file for the corresponding wiki from
    |g:vimwiki_list| is opened instead.

*:VimwikiMakeYesterdayDiaryNote* [count]
    Open diary wiki-file for yesterday of the current wiki. If a [count] is
    given a diary wiki-file for the corresponding wiki from |g:vimwiki_list|
    is opened instead.

*:VimwikiMakeTomorrowDiaryNote* [count]
    Open diary wiki-file for tomorrow of the current wiki. If a [count] is
    given a diary wiki-file for the corresponding wiki from |g:vimwiki_list|
    is opened instead.

------------------------------------------------------------------------------
4.2. Local commands                                   *vimwiki-local-commands*

These commands are only available (and meaningful) when you are currently in a
Vimwiki file.

*:VimwikiFollowLink*
    Follow wiki link (or create target wiki page if needed).

*:VimwikiGoBackLink*
    Go back to the wiki page you came from.

*:VimwikiSplitLink* [reuse] [move_cursor]
    Split and follow wiki link (create target wiki page if needed).

    If the argument 'reuse' is given and nonzero, the link is opened in a
    possibly existing split window instead of making a new split.

    If 'move_cursor' is given and nonzero, the cursor moves to the window with
    the opened link, otherwise, it stays in the window with the link.

*:VimwikiVSplitLink* [reuse] [move_cursor]
    Vertical split and follow wiki link (create target wiki page if needed).

    If the argument 'reuse' is given and nonzero, the link is opened in a
    possibly existing split window instead of making a new split.

    If 'move_cursor' is given and nonzero, the cursor moves to the window with
    the opened link, otherwise, it stays in the window with the link.

*:VimwikiTabnewLink*
    Follow wiki link in a new tab (create target wiki page if needed).

*:VimwikiNextLink*
    Find next link on the current page.

*:VimwikiPrevLink*
    Find previous link on the current page.

*:VimwikiGoto*
    Goto link provided by an argument. For example: >
        :VimwikiGoto HelloWorld
<    opens/creates HelloWorld wiki page.

    Supports |cmdline-completion| for link name. If name is not specified, a
    prompt will be shown.

*:VimwikiDeleteFile*
    Delete the wiki page you are in.

*:VimwikiRenameFile*
    Rename the wiki page you are in.

*:VimwikiNextTask*
    Jump to the next unfinished task in the current wiki page.

*:Vimwiki2HTML*
    Convert current wiki page to HTML using Vimwiki's own converter or a
    user-supplied script (see |vimwiki-option-custom_wiki2html|).

*:Vimwiki2HTMLBrowse*
    Convert current wiki page to HTML and open it in the webbrowser.

*:VimwikiAll2HTML[!]*
    Convert all wiki pages to HTML.
    Default CSS file (style.css) is created if there is no one.

    By default, only converts wiki pages which have not already been
    converted or have been modified since their last conversion. With !,
    convert all pages, regardless of whether or not they are out-of-date.

*:VimwikiToggleListItem*
    Toggle checkbox of a list item on/off.
    See |vimwiki-todo-lists|.

*:VimwikiToggleRejectedListItem*
    Toggle checkbox of a list item disabled/off.
    See |vimwiki-todo-lists|.

*:VimwikiListChangeLevel* CMD
    Change the nesting level, or symbol, for a single-line list item.
    CMD may be ">>" or "<<" to change the indentation of the item, or
    one of the syntax-specific bullets: "*", "#", "1.", "-".
    See |vimwiki-todo-lists|.

*:VimwikiSearch* /pattern/
*:VWS* /pattern/
    Search for /pattern/ in all files of current wiki.
    To display all matches use |:lopen| command.
    To display next match use |:lnext| command.
    To display previous match use |:lprevious| command.

    Hint: this feature is simply a wrapper around |:lvimgrep|. For a
    complete description of the search pattern format, see |:vimgrep|.
    For example, to perform a case-insensitive search, use >
    :VWS /\cpattern/

*:VimwikiBacklinks*
*:VWB*
    Search for wikilinks to the current wiki page in all files of current
    wiki.
    To display all matches use |:lopen| command.
    To display next match use |:lnext| command.
    To display previous match use |:lprevious| command.


*:VimwikiTable*
    Create a table with 5 cols and 2 rows.

    :VimwikiTable cols rows
    Create a table with the given cols and rows

    :VimwikiTable cols
    Create a table with the given cols and 2 rows


*:VimwikiTableMoveColumnLeft* , *:VimwikiTableMoveColumnRight*
    Move current column to the left or to the right:
    Example: >

    | head1  | head2  | head3  | head4  | head5  |
    |--------|--------|--------|--------|--------|
    | value1 | value2 | value3 | value4 | value5 |


    Cursor is on 'head1'.
    :VimwikiTableMoveColumnRight

    | head2  | head1  | head3  | head4  | head5  |
    |--------|--------|--------|--------|--------|
    | value2 | value1 | value3 | value4 | value5 |

    Cursor is on 'head3'.
    :VimwikiTableMoveColumnLeft

    | head2  | head3  | head1  | head4  | head5  |
    |--------|--------|--------|--------|--------|
    | value2 | value3 | value1 | value4 | value5 |
<

    Commands are mapped to <A-Left> and <A-Right> respectively.


*:VimwikiGenerateLinks* [pattern]
    Insert a list of links to all available wiki files into the current buffer.
    If an optional 'pattern' is given as argument, the files will be searched
    in the wiki root folder according to the 'pattern' as |globpath|

*:VimwikiDiaryGenerateLinks*
    Delete old, insert new diary section into diary index file.

*:VimwikiDiaryNextDay*
    Open next day diary link if available.
    Mapped to <C-Down>.

*:VimwikiDiaryPrevDay*
    Open previous day diary link if available.
    Mapped to <C-Up>.

*:VimwikiTOC*
    Create or update the Table of Contents for the current wiki file.
    See |vimwiki-toc|.

*:VimwikiCheckLinks*
    Search through all wiki files and check if the targets of all wiki links
    and links to external files actually exist.  Check also if all wiki files
    are reachable from the index file.  The results are shown in the quickfix
    window.

*:VimwikiRebuildTags*
    Rebuilds the tags metadata file for all wiki files newer than the metadata
    file.
    Necessary for all tags related commands: |vimwiki-syntax-tags|.

    :VimwikiRebuildTags! does the same for all files.

*:VimwikiSearchTags*
    Searches over the pages in current wiki and finds all locations of a given
    tag.  Supports |cmdline-completion|.

*:VimwikiGenerateTagLinks* tagname1 tagname2 ...
    Creates or updates an overview on all tags of the wiki with links to all
    their instances.  Supports |cmdline-completion|.  If no arguments (tags)
    are specified, outputs all tags.  To make this command work properly, make
    sure the tags have been built (see |vimwiki-build-tags|).


==============================================================================
5. Wiki syntax                                                *vimwiki-syntax*


There are a lot of different wikis out there. Most of them have their own
syntax and Vimwiki is not an exception here.

Vimwiki has evolved its own syntax that closely resembles Google's wiki
markup.  This syntax is described in detail below.

Vimwiki also supports alternative syntaxes, like Markdown and MediaWiki, to
varying degrees; see |vimwiki-option-syntax|.  Static elements like headers,
quotations, and lists are customized in syntax/vimwiki_xxx.vim, where xxx
stands for the chosen syntax.

Interactive elements such as links and Vimwiki commands are supported by
definitions and routines in syntax/vimwiki_xxx_custom.vim and
autoload/vimwiki/xxx_base.vim.  Currently, only Markdown includes this level
of support.

Vimwiki2HTML is currently functional only for the default syntax.

------------------------------------------------------------------------------
5.1. Typefaces                                      *vimwiki-syntax-typefaces*

There are a few typefaces that give you a bit of control over how your text
is decorated: >

  *bold text*
  _italic text_
  _*bold italic text*_
  *_bold italic text _*
  ~~strikeout text~~
  `code (no syntax) text`
  super^script^
  sub,,script,,

For Markdown syntax these variations are used: >

  **bold text** or __bold text__
  *italic text* or _italic text_
  ***bold_italic text*** or ___italic_bold text___

Furthermore, there are a number of words which are highlighted extra flashy:
TODO, DONE, STARTED, FIXME, FIXED, XXX.

When rendered as HTML, code blocks containing only a hash prefixed 6 digit hex
number will be colored as themselves.  For example >
 `#ffe119`
Becomes >
 <code style='background-color:#ffe119;color:black;'>#ffe119</code>

------------------------------------------------------------------------------
5.2. Links                                              *vimwiki-syntax-links*

Wikilinks~

Plain link: >
  [[This is a link]]
With description: >
  [[This is a link source|Description of the link]]

Wiki files don't need to be in the root directory of your wiki, you can put
them in subdirectories as well: >
   [[projects/Important Project 1]]
To jump from that file back to the index file, use this link: >
   [[../index]]
or: >
   [[/index]]
The latter works because wiki links starting with "/" are considered to be
absolute to the wiki root directory, that is, the link [[/index]] always opens
the file /path/to/your/wiki/index.wiki, no matter in which subdirectory you
are currently in.

Links to subdirectories inside the wiki directory are also supported. They
end with a "/": >
  [[a subdirectory/|Other files]]
Use |g:vimwiki_dir_link| to control the behavior when opening directories.

Typing wikilinks can be simplified by using Vim's omni completion (see
|compl-omni|) like so: >
  [[ind<C-X><C-O>
which opens up a popup menu with all the wiki files starting with "ind".

When |vimwiki-option-maxhi| equals 1, a distinct highlighting style is used to
identify wikilinks whose targets are not found.

Interwiki~

If you maintain more than one wiki, you can create interwiki links between
them by adding a numbered prefix "wikiX:" in front of a link: >
  [[wiki1:This is a link]]
or: >
  [[wiki1:This is a link source|Description of the link]]

The number behind "wiki" is in the range 0..N-1 and identifies the destination
wiki in |g:vimwiki_list|.

Named interwiki links are also supported in the format "wn.name:link" >
  [[wn.My Name:This is a link]]
or: >
  [[wn.MyWiki:This is a link source|Description of the link]]

See |vimwiki-option-name| to set a per wiki name.

Diary~

The "diary:" scheme is used to link to diary entries: >
  [[diary:2012-03-05]]

Anchors~

A wikilink, interwiki link or diary link can be followed by a '#' and the name
of an anchor.  When opening a link, the cursor jumps to the anchor. >
  [[Todo List#Tomorrow|Tasks for tomorrow]]

To jump inside the current wiki file you can omit the file: >
  [[#Tomorrow]]

See |vimwiki-anchors| for how to set an anchor.

Raw URLs~

Raw URLs are also supported: >
  https://github.com/vimwiki/vimwiki.git
  mailto:habamax@gmail.com
  ftp://vim.org

External files~

The "file:" and "local:" schemes allow you to directly link to arbitrary
resources using absolute or relative paths: >
  [[file:/home/somebody/a/b/c/music.mp3]]
  [[file:C:/Users/somebody/d/e/f/music.mp3]]
  [[file:~/a/b/c/music.mp3]]
  [[file:../assets/data.csv|Important Data]]
  [[local:C:/Users/somebody/d/e/f/music.mp3]]
  [[file:/home/user/documents/|Link to a directory]]

These links are opened with the system command, i.e. !xdg-open (Linux), !open
(Mac), or !start (Windows).  To customize this behavior, see
|VimwikiLinkHandler|.

In Vim, "file:" and "local:" behave the same, i.e. you can use them with both
relative and absolute links. When converted to HTML, however, "file:" links
will become absolute links, while "local:" links become relative to the HTML
output directory. The latter can be useful if you copy your HTML files to
another computer.
To customize the HTML conversion of links, see |VimwikiLinkConverter|.

Transclusion (Wiki-Include) Links~

Links that use "{{" and "}}" delimiters signify content that is to be
included into the HTML output, rather than referenced via hyperlink.

Wiki-include URLs may use any of the supported schemes, may be absolute or
relative, and need not end with an extension.

The primary purpose for wiki-include links is to include images.

Transclude from a local URL: >
  {{file:../../images/vimwiki_logo.png}}
or from a universal URL: >
  {{http://vimwiki.googlecode.com/hg/images/vimwiki_logo.png}}

Transclude image with alternate text: >
  {{http://vimwiki.googlecode.com/hg/images/vimwiki_logo.png|Vimwiki}}
in HTML: >
  <img src="http://vimwiki.googlecode.com/hg/images/vimwiki_logo.png"
  alt="Vimwiki"/>

Transclude image with alternate text and some style: >
  {{http://.../vimwiki_logo.png|cool stuff|style="width:150px;height:120px;"}}
in HTML: >
  <img src="http://vimwiki.googlecode.com/hg/images/vimwiki_logo.png"
  alt="cool stuff" style="width:150px; height:120px"/>

Transclude image _without_ alternate text and with a CSS class: >
  {{http://.../vimwiki_logo.png||class="center flow blabla"}}
in HTML: >
  <img src="http://vimwiki.googlecode.com/hg/images/vimwiki_logo.png"
  alt="" class="center flow blabla"/>

A trial feature allows you to supply your own handler for wiki-include links.
See |VimwikiWikiIncludeHandler|.

Thumbnail links~
>
Thumbnail links are constructed like this: >
  [[http://someaddr.com/bigpicture.jpg|{{http://someaddr.com/thumbnail.jpg}}]]

in HTML: >
  <a href="http://someaddr.com/ ... /.jpg">
  <img src="http://../thumbnail.jpg /></a>

Markdown Links~

These links are only available for Markdown syntax.  See
http://daringfireball.net/projects/markdown/syntax#link.

Inline link: >
  [Looks like this](URL)

Image link: >
  ![Looks like this](URL)

Reference-style links: >
  a) [Link Name][Id]
  b) [Id][], using the "implicit link name" shortcut

Reference style links must always include two consecutive pairs of
[-brackets, and field entries can not use "[" or "]".


NOTE: (in Vimwiki's current implementation) Reference-style links are a hybrid
of Vimwiki's default "Wikilink" and the tradition reference-style link.

If the Id is defined elsewhere in the source, as per the Markdown standard: >
  [Id]: URL

then the URL is opened with the system default handler.  Otherwise, Vimwiki
treats the reference-style link as a Wikilink, interpreting the Id field as a
wiki page name.

Highlighting of existing links when |vimwiki-option-maxhi| is activated
identifies links whose Id field is not defined, either as a reference-link or
as a wiki page.

To scan the page for new or changed definitions for reference-links, simply
re-open the page ":e<CR>".

------------------------------------------------------------------------------
5.3. Headers                                          *vimwiki-syntax-headers*

= Header level 1 =~
By default all headers are highlighted using |hl-Title| highlight group.

== Header level 2 ==~
You can set up different colors for each header level: >
  :hi VimwikiHeader1 guifg=#FF0000
  :hi VimwikiHeader2 guifg=#00FF00
  :hi VimwikiHeader3 guifg=#0000FF
  :hi VimwikiHeader4 guifg=#FF00FF
  :hi VimwikiHeader5 guifg=#00FFFF
  :hi VimwikiHeader6 guifg=#FFFF00
Set up colors for all 6 header levels or none at all.

=== Header level 3 ===~
==== Header level 4 ====~
===== Header level 5 =====~
====== Header level 6 ======~


You can center your headers in HTML by placing spaces before the first '=':
                     = Centered Header L1 =~


------------------------------------------------------------------------------
5.4. Paragraphs                                    *vimwiki-syntax-paragraphs*

A paragraph is a group of lines starting in column 1 (no indentation).
Paragraphs are separated by a blank line:

This is first paragraph
with two lines.

This is a second paragraph with
two lines.


------------------------------------------------------------------------------
5.5. Lists                                              *vimwiki-syntax-lists*

Unordered lists: >
  - Bulleted list item 1
  - Bulleted list item 2
or: >
  * Bulleted list item 1
  * Bulleted list item 2


Ordered lists: >
  1. Numbered list item 1
  2. Numbered list item 2
  3. Numbered list item 3
or: >
  1) Numbered list item 1
  2) Numbered list item 2
  3) Numbered list item 3
or: >
  a) Numbered list item 1
  b) Numbered list item 2
  c) Numbered list item 3
or: >
  A) Numbered list item 1
  B) Numbered list item 2
  C) Numbered list item 3
or: >
  i) Numbered list item 1
  ii) Numbered list item 2
  iii) Numbered list item 3
or: >
  I) Numbered list item 1
  II) Numbered list item 2
  III) Numbered list item 3
or: >
  # Bulleted list item 1
  # the # become numbers when converted to HTML

Note that a space after the list item symbols (-, *, 1. etc.) is essential.

You can nest and mix the various types: >
  - Bulleted list item 1
  - Bulleted list item 2
    a) Numbered list sub item 1
    b) more ...
      * and more ...
      * ...
    c) Numbered list sub item 3
      1. Numbered list sub sub item 1
      2. Numbered list sub sub item 2
    d) etc.
  - Bulleted list item 3

List items can span multiple lines: >
  * Item 1
    Item 1 continued line.
    Item 1 next continued line.
  * Item 2
    - Sub item 1
      Sub item 1 continued line.
      Sub item 1 next continued line.
    - Sub item 2
    - etc.
    Continuation of Item 2
    Next continuation of Item 2


Definition lists: >
  Term 1:: Definition 1
  Term 2::
  :: Definition 2
  :: Definition 3


------------------------------------------------------------------------------
5.6. Tables                                            *vimwiki-syntax-tables*

Tables are created by entering the content of each cell separated by |
delimiters. You can insert other inline wiki syntax in table cells, including
typeface formatting and links.
For example: >

 | Year | Temperature (low) | Temperature (high) |
 |------|-------------------|--------------------|
 | 1900 | -10               | 25                 |
 | 1910 | -15               | 30                 |
 | 1920 | -10               | 32                 |
 | 1930 | _N/A_             | _N/A_              |
 | 1940 | -2                | 40                 |
>

In HTML the following part >
 | Year | Temperature (low) | Temperature (high) |
 |------|-------------------|--------------------|
>
is highlighted as a table header.

If you indent a table then it will be centered in HTML.

If you put > in a cell, the cell spans the left column.
If you put \/ in a cell, the cell spans the above row.
For example: >

 | a  | b  | c | d |
 | \/ | e  | > | f |
 | \/ | \/ | > | g |
 | h  | >  | > | > |
>

See |vimwiki-tables| for more details on how to manage tables.


------------------------------------------------------------------------------
5.7. Preformatted text                           *vimwiki-syntax-preformatted*

Use {{{ and }}} to define a block of preformatted text:
{{{ >
  Tyger! Tyger! burning bright
   In the forests of the night,
    What immortal hand or eye
     Could frame thy fearful symmetry?
  In what distant deeps or skies
   Burnt the fire of thine eyes?
    On what wings dare he aspire?
     What the hand dare sieze the fire?
}}}


You can add optional information after the {{{: >
{{{class="brush: python" >
 def hello(world):
     for x in range(10):
         print("Hello {0} number {1}".format(world, x))
}}}

Result of HTML export: >
 <pre class="brush: python">
 def hello(world):
     for x in range(10):
         print("Hello {0} number {1}".format(world, x))
 </pre>

This might be useful for coloring program code with external JS tools
such as Google's syntax highlighter.

You can setup Vimwiki to highlight code snippets in preformatted text.
See |vimwiki-option-nested_syntaxes| and
|vimwiki-option-automatic_nested_syntaxes|.


------------------------------------------------------------------------------
5.8. Mathematical formulae                              *vimwiki-syntax-math*

Mathematical formulae are highlighted, and can be rendered in HTML using the
powerful open source display engine MathJax (http://www.mathjax.org/).

There are three supported syntaxes, which are inline, block display and
block environment.

Inline math is for short formulae within text. It is enclosed by single
dollar signs, e.g.:
 $ \sum_i a_i^2 = 1 $

Block display creates a centered formula with some spacing before and after
it. It must start with a line including only {{$, then an arbitrary number
of mathematical text are allowed, and it must end with a line including only
}}$.
E.g.:
 {{$
 \sum_i a_i^2
 =
 1
 }}$

Note: no matter how many lines are used in the text file, the HTML will
compress it to one line only.

Block environment is similar to block display, but is able to use specific
LaTeX environments, such as 'align'. The syntax is the same as for block
display, except for the first line which is {{$%environment%.
E.g.:
 {{$%align%
 \sum_i a_i^2 &= 1 + 1 \\
 &= 2.
 }}$

Similar compression rules for the HTML page hold (as MathJax interprets the
LaTeX code).

Note: the highlighting in Vim is automatic. For the rendering in HTML, you
have two alternative options:

1. installing MathJax locally (Recommended: faster, no internet required).
Choose a folder on your hard drive and save MathJax in it. Then add to your
HTML template the following line:

<script type="text/javascript" src="<mathjax_folder>/es5/tex-chtml.js?config=TeX-AMS-MML_HTMLorMML"></script>

where <mathjax_folder> is the folder on your HD, as a relative path to the
template folder. For instance, a sensible folder structure could be:

- wiki
  - text
  - html
  - templates
  - mathjax

In this case, <mathjax_folder> would be "../mathjax" (without quotes).

2. Loading MathJax from a CDN-server (needs internet connection).
Add to your HTML template the following lines:

<script src="https://polyfill.io/v3/polyfill.min.js?features=es6"></script>
<script id="MathJax-script" async src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js"></script>


------------------------------------------------------------------------------
5.9. Blockquotes                                  *vimwiki-syntax-blockquotes*

Text which starts with 4 or more spaces is a blockquote.

    This would be a blockquote in Vimwiki. It is not highlighted in Vim but
    could be styled by CSS in HTML. Blockquotes are usually used to quote a
    long piece of text from another source.


------------------------------------------------------------------------------
5.10. Comments                                       *vimwiki-syntax-comments*

A line that starts with %% is a comment.
E.g.: >
 %% this text would not be in HTML
<

------------------------------------------------------------------------------
5.11. Horizontal line                                      *vimwiki-syntax-hr*

4 or more dashes at the start of the line is a horizontal line (<hr />): >
 ----
<

------------------------------------------------------------------------------
5.12. Tags                                               *vimwiki-syntax-tags*

You can tag a wiki file, a header or an arbitrary place in a wiki file. Then,
you can use Vim's built-in tag search functionality (see |tagsrch.txt|) or
Vimwiki's tag related commands to quickly jump to all occurrences of the tag.

A tag is a sequence of non-space characters between two colons: >
        :tag-example:
<
It is allowed to concatenate multiple tags in one line: >
        :tag-one:tag-two:
<
If placed in the first two lines of a file, the whole file is tagged.  If
placed under a header, within the 2 lines below it, the header is then tagged
with this tag, and the tag search commands will jump to this specific header.
Otherwise, the tag stands of its own and the search command jumps directly to
it.

Typing tags can be simplified by using Vim's omni completion (see
|compl-omni|) like so: >
  :ind<C-X><C-O>
which opens up a popup menu with all tags defined in the wiki starting with
"ind".

Tags are also treated as |vimwiki-anchors| (similar to bold text).

                                                          *vimwiki-build-tags*
Note that the tag search/jump/completion commands need certain metadata saved
in the wiki folder.  This metadata file can be manually updated by running
|:VimwikiRebuildTags|.  When the option |vimwiki-option-auto_tags| is enabled,
the tags metadata will be auto-updated on each page save.


Tags-related commands and options:
   * |:VimwikiRebuildTags|
   * |:VimwikiGenerateTagLinks|
   * |:VimwikiSearchTags|
   * |vimwiki-option-auto_tags|


==============================================================================
6. Folding/Outline                                           *vimwiki-folding*

Vimwiki allows you to use Vim's folding methods and options so you can fold
your outline to make it less distracting and easier to navigate. You can use
Vimwiki's built-in folding methods or supply custom methods for folding.  You
control how folds behave with by setting the |g:vimwiki_folding| variable to
the desired value in your configuration file: >

  let g:vimwiki_folding = 'value'

Here's an example of how folds work with |g:vimwiki_folding| set to 'list':

= My current task =
* [ ] Do stuff 1
  * [ ] Do substuff 1.1
  * [ ] Do substuff 1.2
    * [ ] Do substuff 1.2.1
    * [ ] Do substuff 1.2.2
  * [ ] Do substuff 1.3
* [ ] Do stuff 2
* [ ] Do stuff 3

Hit |zM| :
= My current task =
* [ ] Do stuff 1 [6] --------------------------------------~
* [ ] Do stuff 2
* [ ] Do stuff 3

Hit |zr| :
= My current task =
* [ ] Do stuff 1
  * [ ] Do substuff 1.1
  * [ ] Do substuff 1.2 [3] -------------------------------~
  * [ ] Do substuff 1.3
* [ ] Do stuff 2
* [ ] Do stuff 3

Hit |zr| one more time :
= My current task =
* [ ] Do stuff 1
  * [ ] Do substuff 1.1
  * [ ] Do substuff 1.2
    * [ ] Do substuff 1.2.1
    * [ ] Do substuff 1.2.2
  * [ ] Do substuff 1.3
* [ ] Do stuff 2
* [ ] Do stuff 3

Note: If you use the default Vimwiki syntax, folding on list items will work
properly only if all of them are indented using the current 'shiftwidth'.
For Markdown and MediaWiki syntax, * or # should be in the first column.

For maximum control over folds, set |g:vimwiki_folding| to 'custom' so you can
allow other plugins or your vim configuration file to control how folding is
performed. For example, let's say you are using markdown syntax and prefer to
fold so that the last blank line before a header is not folded, you can add
this function to your configuration file: >

  function! VimwikiFoldLevelCustom(lnum)
    let pounds = strlen(matchstr(getline(a:lnum), '^#\+'))
    if (pounds)
      return '>' . pounds  " start a fold level
    endif
    if getline(a:lnum) =~? '\v^\s*$'
      if (strlen(matchstr(getline(a:lnum + 1), '^#\+')))
        return '-1' " don't fold last blank line before header
      endif
    endif
    return '=' " return previous fold level
  endfunction

Note that you will also need to add the following vim options to your configuration: >

  augroup VimrcAuGroup
    autocmd!
    autocmd FileType vimwiki setlocal foldmethod=expr |
      \ setlocal foldenable | set foldexpr=VimwikiFoldLevelCustom(v:lnum)
  augroup END

See the |g:vimwiki_folding| documentation for more details.

==============================================================================
7. Placeholders                                         *vimwiki-placeholders*

------------------------------------------------------------------------------
%title Title of the page                                       *vimwiki-title*

When you htmlize your wiki page, the default title is the filename of the
page. Place >

%title My books

into your wiki page if you want another title.


------------------------------------------------------------------------------
%nohtml                                                       *vimwiki-nohtml*

If you do not want a wiki page to be converted to HTML, place:

%nohtml

into it.


------------------------------------------------------------------------------
%template                                                   *vimwiki-template*

To apply a concrete HTML template to a wiki page, place:

%template name

into it.

See |vimwiki-option-template_path| for details.

------------------------------------------------------------------------------
%date                                                           *vimwiki-date*

The date of the wiki page. The value can be used in the HTML template, see
|vimwiki-option-template_path| for details.

%date 2017-07-08
%date

If you omit the date after the placeholder, the date of the HTML conversion is
used.


==============================================================================
8. Lists                                                       *vimwiki-lists*

While writing lists, the keys <CR>, o and O insert new bullets or numbers as
you would expect it. A new bullet/number is inserted if and only if the cursor
is in a list item. If you use hard line wraps within your lists then you will
need to remap `<CR>` to `VimwikiReturn 3 5`, use <S-CR>, or press <CR> and
<C-L><C-M>.

Note that the mapping <S-CR> is not available in all terminals.

Furthermore, <CR> and <S-CR> behave differently when the cursor is behind an
empty list item. See the table below.

To customize the behavior you should use an autocmd or place the mappings in
`~/.vim/after/ftplugin/vimwiki.vim`. This is necessary to avoid an error that
the command `VimwikiReturn` doesn't exist when editing non Vimwiki files.: >

  autocmd FileType vimwiki inoremap <silent><buffer> <CR>
              \ <C-]><Esc>:VimwikiReturn 3 5<CR>
  autocmd FileType vimwiki inoremap <silent><buffer> <S-CR>
              \ <Esc>:VimwikiReturn 2 2<CR>

Note: Prefixing the mapping with `<C-]>` expands iabbrev definitions and
requires Vim > 7.3.489.

The first argument of the command :VimwikiReturn is a number that specifies
when to insert a new bullet/number and when not, depending on whether the
cursor is in a list item or in a normal line: >

 Number │     Before     │    After
 ======================================
    1   │ 1. item|       │ 1. item
        │                │ 2. |
        │––––––––––––––––––––––––––––––       ← default for <CR>
        │ 1. item        │ 1. item
        │    continue|   │    continue
        │                │    |
 ======================================
    2   │ 1. item|       │ 1. item
        │                │    |
        │––––––––––––––––––––––––––––––       ← default for <S-CR>
        │ 1. item        │ 1. item
        │    continue|   │    continue
        │                │ 2. |
 ======================================
    3   │ 1. item|       │ 1. item
        │                │ 2. |
        │––––––––––––––––––––––––––––––
        │ 1. item        │ 1. item
        │    continue|   │    continue
        │                │ 2. |
 ======================================
    4   │ 1. item|       │ 1. item
        │                │    |
        │––––––––––––––––––––––––––––––
        │ 1. item        │ 1. item
        │    continue|   │    continue
        │                │    |
<

The second argument is a number that specifies what should happen when you
press <CR> or <S-CR> behind an empty list item. There are no less than five
possibilities:
>
 Number │     Before     │    After
 ======================================
    1   │ 1. |           │ 1.
        │                │ 2. |
 ======================================
    2   │ 1. |           │                    ← default for <S-CR>
        │                │ 1. |
 ======================================
    3   │ 1. |           │ |
        │                │
 ======================================
    4   │ 1. |           │
        │                │ |
 ======================================
    5   │     1. |       │ 1. |
        │                │
        │––––––––––––––––––––––––––––––       ← default for <CR>
        │ 1. |           │ |
        │                │
<


                                                   *vimwiki-list-manipulation*
The level of a list item is determined by its indentation (default and
Markdown syntax) or by the number of list symbols (MediaWiki syntax).

Use gll and glh in normal mode to increase or decrease the level of a list
item. The symbols are adjusted automatically to the list items around it.
Use gLl and gLh to increase or decrease the level of a list item plus all
list items of lower level below it, that is, all child items.

Use <C-T> and <C-D> to change the level of a list item in insert mode.

See |vimwiki_gll|, |vimwiki_gLl|, |vimwiki_glh|, |vimwiki_gLh|,
|vimwiki_i_<C-T>|, |vimwiki_i_<C-D>|


Use gl followed by the desired symbol to change the symbol of a list item or
create one. Type gL and the symbol to change all items of the current list.
For default syntax, the following types are available: >
    - hyphen
    * asterisk
    # hash
    1. number with period
    1) number with parenthesis
    a) lower-case letter with parenthesis
    A) upper-case letter with parenthesis
    i) lower-case Roman numerals with parenthesis
    I) upper-case Roman numerals with parenthesis

Markdown syntax has the following types: >
    - hyphen
    * asterisk
    + plus
    1. number with period

MediaWiki syntax only has: >
    * asterisk
    # hash

In insert mode, use the keys <C-L><C-J> and <C-L><C-K> to switch between
symbols. For convenience, only the commonly used symbols can be reached
through these keys for default syntax.

Note that such a list: a) b) c) … only goes up to zz), to avoid confusion with
normal text followed by a parenthesis.
Roman numerals go up to MMMM) and numbers up to 2147483647. or
9223372036854775807. depending if your Vim is 32 or 64 bit.

Also, note that you can, of course, mix different list symbols in one list, but
if you have the strange idea of putting a list with Roman numerals right after
a list using letters or vice versa, Vimwiki will get confused because it
cannot distinguish which is which (at least if the types are both upper case
or both lower case).

See |vimwiki_glstar|, |vimwiki_gl#| |vimwiki_gl-|, |vimwiki_gl-|,
|vimwiki_gl1|, |vimwiki_gla|, |vimwiki_glA|, |vimwiki_gli|, |vimwiki_glI|


Use glr and gLr if the numbers of a numbered list are mixed up. See
|vimwiki_glr| and |vimwiki_gLr|.


------------------------------------------------------------------------------
Todo lists                                                *vimwiki-todo-lists*

You can have todo lists -- lists of items you can check/uncheck.

Consider the following example: >
 = Toggleable list of todo items =
   * [X] Toggle list item on/off.
     * [X] Simple toggling between [ ] and [X].
     * [X] All list's subitems should be toggled on/off appropriately.
     * [X] Toggle child subitems only if current line is list item
     * [X] Parent list item should be toggled depending on its child items.
   * [X] Make numbered list items toggleable too
   * [X] Add highlighting to list item boxes
   * [X] Add [ ] to the next list item created with o, O and <CR>.

Pressing <C-Space> on the first list item will toggle it and all of its child
items: >
 = Toggleable list of todo items =
   * [ ] Toggle list item on/off.
     * [ ] Simple toggling between [ ] and [X].
     * [ ] All of a list's subitems should be toggled on/off appropriately.
     * [ ] Toggle child subitems only if the current line is a list item.
     * [ ] Parent list item should be toggled depending on their child items.
   * [X] Make numbered list items toggleable too.
   * [X] Add highlighting to list item boxes.
   * [X] Add [ ] to the next list item created using o, O or <CR>.

Pressing <C-Space> on the third list item will toggle it and adjust all of its
parent items: >
 = Toggleable list of todo items =
   * [.] Toggle list item on/off.
     * [ ] Simple toggling between [ ] and [X].
     * [X] All of a list's subitems should be toggled on/off appropriately.
     * [ ] Toggle child subitems only if current line is list item.
     * [ ] Parent list item should be toggled depending on its child items.
   * [ ] Make numbered list items toggleable too.
   * [ ] Add highlighting to list item boxes.
   * [ ] Add [ ] to the next list item created using o, O or <CR>.

Parent items should change when their child items change. If not, use
|vimwiki_glr|. The symbol between [ ] depends on the percentage of toggled
child items (see also |g:vimwiki_listsyms|): >
    [ ] -- 0%
    [.] -- 1-33%
    [o] -- 34-66%
    [O] -- 67-99%
    [X] -- 100%

You can use |vimwiki_gln| and |vimwiki_glp| to change the "done" status of a
checkbox without a childitem.

It is possible to toggle several list items using visual mode. But note that
instead of toggling every item individually, all items get checked if the
first item was unchecked and all items get unchecked if the first item was
checked.

Use gl<Space> (see |vimwiki_gl<Space>|) to remove a single checkbox and
gL<Space> (see |vimwiki_gL<Space>|) to remove all checkboxes of the list the
cursor is in.

You can mark an item as rejected ("won't do") with
|vimwiki_glx|. A rejected item will not influence the status of its parents.


==============================================================================
9. Tables                                                     *vimwiki-tables*

Use the  :VimwikiTable command to create a default table with 5 columns and 2
rows: >

 |   |   |   |   |   |
 |---|---|---|---|---|
 |   |   |   |   |   |
<

Tables are auto-formattable. Let's add some text into first cell: >

 | First Name  |   |   |   |   |
 |---|---|---|---|---|
 |   |   |   |   |   |
<

Whenever you press <TAB>, <CR> or leave Insert mode, the table is formatted: >

 | First Name |   |   |   |   |
 |------------|---|---|---|---|
 |            |   |   |   |   |
<

You can easily create nice-looking text tables, just press <TAB> and enter new
values: >

 | First Name | Last Name  | Age | City     | e-mail               |
 |------------|------------|-----|----------|----------------------|
 | Vladislav  | Pokrishkin | 31  | Moscow   | vlad_pok@smail.com   |
 | James      | Esfandiary | 27  | Istanbul | esfandiary@tmail.com |
<

To indent table indent the first row. Then format it with 'gqq'.

You can specify the type of horizontal alignment for columns in the separator
using the ':' character. The default is left-align.  >

 | Date       |  Item  |   Price |
 |------------|:------:|--------:|
 | yest       | Coffee |  $15.00 |
 | 2017-02-13 |  Tea   |   $2.10 |
 | 2017-03-14 |  Cake  | $143.12 |
<

==============================================================================
10. Diary                                                      *vimwiki-diary*

The diary helps you make daily notes. You can easily add information into
Vimwiki that should be sorted out later. Just hit <Leader>w<Leader>w to create
a new note for today with a name based on the current date.

To generate the diary section with all available links one can use
|:VimwikiDiaryGenerateLinks| or <Leader>w<Leader>i .

Note: it works only for diary index file.

Example of diary section: >
    = Diary =

    == 2011 ==

    === December ===
        * [[2011-12-09]]
        * [[2011-12-08]]


See |g:vimwiki_diary_months| if you would like to rename months.


------------------------------------------------------------------------------
Calendar integration                                        *vimwiki-calendar*

If you have Calendar.vim installed you can use it to create diary notes.
Just open calendar with :Calendar and tap <Enter> on the date. A wiki file
will be created in the default wiki's diary.

Get it from http://www.vim.org/scripts/script.php?script_id=52

See |g:vimwiki_use_calendar| option to turn it off/on.


------------------------------------------------------------------------------
Markdown export

If you use markdown as the syntax for your wiki, there is a rubygem available
at https://github.com/patrickdavey/vimwiki_markdown which you can use to
convert the wiki markdown files into html.

Also, See |vimwiki-option-html_filename_parameterization| for supporting
functionality.

==============================================================================
11. Anchors                                                  *vimwiki-anchors*

Every header, tag, and bold text can be used as an anchor.  To jump to it, use
a wikilink of the form >
  [[file#anchor]]

For example, consider the following file "Todo.wiki": >
  = My tasks =
  :todo-lists:
  == Home ==
    - [ ] bathe my dog
  == Work ==
    - [ ] beg for *pay rise*
  == Knitting club ==
  === Knitting projects ===
    - [ ] a *funny pig*
    - [ ] a *scary dog*

Then, to jump from your index.wiki directly to your knitting projects, use: >
  [[Todo#Knitting projects]]

Or, to jump to an individual project, use this link: >
  [[Todo#funny pig]]

Or, to jump to a tag, use this link: >
  [[Todo#todo-lists]]

If there are multiple instances of an anchor, you can use the long form which
consists of the complete header hierarchy, separated by '#': >
 [[Todo#My tasks#Knitting club#Knitting projects#scary dog]]

If you don't feel like typing the whole stuff, type just [[Todo# and then
|i_CTRL-X_CTRL-O| to start the omni completion of anchors.

For jumping inside a single file, you can omit the file in the link: >
  [[#pay rise]]


------------------------------------------------------------------------------
Table of Contents                    *vimwiki-toc* *vimwiki-table-of-contents*

You can create a "table of contents" at the top of your wiki file.
The commando |:VimwikiTOC| creates the magic header >
  = Contents =
in the current file and below it a list of all the headers in this file as
links, so you can directly jump to specific parts of the file.

For the indentation of the list, the value of |vimwiki-option-list_margin| is
used.

If you don't want the TOC to sit in the very first line, e.g. because you have
a modeline there, put the magic header in the second or third line and run
:VimwikiTOC to update the TOC.

If English is not your preferred language, set the option
|g:vimwiki_toc_header| to your favorite translation.

If you want to keep the TOC up to date automatically, use the option
|vimwiki-option-auto_toc|.


------------------------------------------------------------------------------
Tagbar integration                                            *vimwiki-tagbar*

As an alternative to the Table of Contents, you can use the Tagbar plugin
(http://majutsushi.github.io/tagbar/) to show the headers of your wiki files
in a side pane.
Download the Python script from
https://raw.githubusercontent.com/vimwiki/utils/master/vwtags.py and follow
the instructions in it.


==============================================================================
12. Options                                                  *vimwiki-options*

There are global options and local (per-wiki) options available to tune
Vimwiki.

Global options are configured via global variables.  For a complete list of
them, see |vimwiki-global-options|.

Local options for multiple independent wikis are stored in a single global
variable |g:vimwiki_list|.  The per-wiki options can be registered in advance,
as described in |vimwiki-register-wiki|, or may be registered on the fly as
described in |vimwiki-temporary-wiki|.  For a list of per-wiki options, see
|vimwiki-local-options|.

A note for Vim power users:
If you have an elaborated Vim setup, where you e.g. load plugins
conditionally, make sure the settings are set before Vimwiki loads (that is,
before plugin/vimwiki.vim is sourced). If this is not possible, try this
command after the Vimwiki settings are (re-) set: >
  :call vimwiki#vars#init()

------------------------------------------------------------------------------
12.1 Registered Wiki                  *g:vimwiki_list* *vimwiki-register-wiki*

One or more wikis can be registered using the |g:vimwiki_list| variable.

Each item in |g:vimwiki_list| is a |Dictionary| that holds all customizations
available for a distinct wiki. The options dictionary has the form: >
  {'option1': 'value1', 'option2': 'value2', ...}

Consider the following: >
  let g:vimwiki_list = [{'path': '~/my_site/', 'path_html': '~/public_html/'}]

This defines one wiki located at ~/my_site/. When converted to HTML, the
produced HTML files go to ~/public_html/ .

Another example: >
  let g:vimwiki_list = [{'path': '~/my_site/', 'path_html': '~/public_html/'},
            \ {'path': '~/my_docs/', 'ext': '.mdox'}]

defines two wikis: the first as before, and the second one located in
~/my_docs/, with files that have the .mdox extension.

An empty |Dictionary| in g:vimwiki_list is the wiki with default options: >
  let g:vimwiki_list = [{},
            \ {'path': '~/my_docs/', 'ext': '.mdox'}]

For clarity, in your .vimrc file you can define wiki options using separate
|Dictionary| variables and subsequently compose them into |g:vimwiki_list|. >
    let wiki_1 = {}
    let wiki_1.path = '~/my_docs/'
    let wiki_1.html_template = '~/public_html/template.tpl'
    let wiki_1.nested_syntaxes = {'python': 'python', 'c++': 'cpp'}

    let wiki_2 = {}
    let wiki_2.path = '~/project_docs/'
    let wiki_2.index = 'main'

    let g:vimwiki_list = [wiki_1, wiki_2]
<


------------------------------------------------------------------------------
12.2 Temporary Wiki                                   *vimwiki-temporary-wiki*


The creation of temporary wikis allows you to create a wiki on the fly.

If a file with a registered wiki extension (see |vimwiki-register-extension|)
is opened in a directory that: 1) is not listed in |g:vimwiki_list|, and 2) is
not a subdirectory of any such directory, then a temporary wiki is created and
appended to the list of configured wikis in |g:vimwiki_list|.

In addition to Vimwiki's editing functionality, the temporary wiki enables: 1)
wiki-linking to other files in the same subtree, 2) highlighting of existing
wiki pages when |vimwiki-option-maxhi| is activated, and 3) HTML generation to
|vimwiki-option-path_html|.

Temporary wikis are configured using default |vimwiki-local-options|, except
for the path, extension, and syntax options.  The path and extension are set
using the file's location and extension.  The syntax is set to Vimwiki's
default unless another syntax is registered via |vimwiki-register-extension|.

Use |g:vimwiki_global_ext| to turn off creation of temporary wikis.

NOTE: Vimwiki assumes that the locations of distinct wikis do not overlap.


------------------------------------------------------------------------------
12.3 Per-Wiki Options                                  *vimwiki-local-options*


*vimwiki-option-path*
------------------------------------------------------------------------------
Key             Default value~
path            ~/vimwiki/

Description~
Wiki files location: >
  let g:vimwiki_list = [{'path': '~/my_site/'}]
<

*vimwiki-option-path_html*
------------------------------------------------------------------------------
Key             Default value~
path_html       ''

Description~
Location of HTML files converted from wiki files: >
  let g:vimwiki_list = [{'path': '~/my_site/',
                       \ 'path_html': '~/html_site/'}]

If path_html is an empty string, the location is derived from
|vimwiki-option-path| by adding '_html'; i.e. for: >
  let g:vimwiki_list = [{'path': '~/okidoki/'}]

path_html will be set to '~/okidoki_html/'.


*vimwiki-option-name*
------------------------------------------------------------------------------
Key             Default value~
name            ''

Description~
A name that can be used to create interwiki links: >
  let g:vimwiki_list = [{'path': '~/my_site/',
                       \ 'name': 'My Wiki'}]

Valid names can contain letters, numbers, spaces, underscores, and dashes.
If duplicate names are used the interwiki link will jump to the first wiki
with a matching name in |g:vimwiki_list|.

The assigned wiki name will also be shown in the menu entries in GVim.
See the option |g:vimwiki_menu|.


*vimwiki-option-auto_export*
------------------------------------------------------------------------------
Key             Default value     Values~
auto_export     0                 0, 1

Description~
Set this option to 1 to automatically generate the HTML file when the
corresponding wiki page is saved: >
  let g:vimwiki_list = [{'path': '~/my_site/', 'auto_export': 1}]

This will keep your HTML files up to date.


*vimwiki-option-auto_toc*
------------------------------------------------------------------------------
Key             Default value     Values~
auto_toc        0                 0, 1

Description~
Set this option to 1 to automatically update the table of contents when the
current wiki page is saved: >
  let g:vimwiki_list = [{'path': '~/my_site/', 'auto_toc': 1}]


*vimwiki-option-index*
------------------------------------------------------------------------------
Key             Default value~
index           index

Description~
Name of wiki index file: >
  let g:vimwiki_list = [{'path': '~/my_site/', 'index': 'main'}]

NOTE: Do not include the extension.


*vimwiki-option-ext*
------------------------------------------------------------------------------
Key             Default value~
ext             .wiki

Description~
Extension of wiki files: >
  let g:vimwiki_list = [{'path': '~/my_site/',
                       \ 'index': 'main', 'ext': '.document'}]

<
*vimwiki-option-syntax*
------------------------------------------------------------------------------
Key             Default value     Values~
syntax          default           default, markdown, or media

Description~
Wiki syntax.  You can use different markup languages (currently: Vimwiki's
default, Markdown, and MediaWiki), but only Vimwiki's default markup will be
converted to HTML at the moment.

To use Markdown's wiki markup: >
  let g:vimwiki_list = [{'path': '~/my_site/',
                       \ 'syntax': 'markdown', 'ext': '.md'}]

*vimwiki-option-links_space_char*
------------------------------------------------------------------------------
Key                 Default value~
links_space_char    ' '

Description~
Set the character (or string) used to replace spaces when creating a link. For
example, setting '_' would transform the string 'my link' into [[my_link]] and
the created file would be my_link.wiki. The default behavior does not replace
spaces.

To set the space replacement character: >
  let g:vimwiki_list = [{'path': '~/my_site/',
                       \ 'links_space_char': '_'}]
<

*vimwiki-option-template_path*
------------------------------------------------------------------------------
Key                 Default value~
template_path       ~/vimwiki/templates/

Description~
Setup path for HTML templates: >
  let g:vimwiki_list = [{'path': '~/my_site/',
          \ 'template_path': '~/public_html/templates/',
          \ 'template_default': 'def_template',
          \ 'template_ext': '.html'}]

There could be a bunch of templates: >
    def_template.html
    index.html
    bio.html
    person.html
etc.

Each template could look like: >
    <html>
    <head>
        <link rel="Stylesheet" type="text/css" href="%root_path%style.css" />
        <title>%title%</title>
        <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    </head>
    <body>
        <div class="content">
        %content%
        </div>
        <p><small>Page created on %date%</small></p>
    </body>
    </html>

where
  `%title%` is replaced by a wiki page name or by a |vimwiki-title|
  `%date%` is replaced with the current date or by |vimwiki-date|
  `%root_path%` is replaced by a count of ../ for pages buried in subdirs:
    if you have wikilink [[dir1/dir2/dir3/my page in a subdir]] then
    `%root_path%` is replaced by '../../../'.
  `%wiki_path%` Path to current wiki-file.` The file path to the current wiki
    file. For example, if you are on page a/b.wiki %wiki-path% contains
    "a/b.wiki". Mostly useful if you want to link the to raw wiki page from
    the rendered version.

  `%content%` is replaced by a wiki file content.


The default template will be applied to all wiki pages unless a page specifies
a template. Consider you have wiki page named 'Maxim.wiki' and you want apply
'person.html' template to it. Just add: >
 %template person
to that page.


*vimwiki-option-template_default*
------------------------------------------------------------------------------
Key                 Default value~
template_default    default

Description~
Setup default template name (without extension).

See |vimwiki-option-template_path| for details.


*vimwiki-option-template_ext*
------------------------------------------------------------------------------
Key                 Default value~
template_ext        .tpl

Description~
Setup template filename extension.

See |vimwiki-option-template_path| for details.


*vimwiki-option-css_name*
------------------------------------------------------------------------------
Key             Default value~
css_name        style.css

Description~
Setup CSS file name: >
  let g:vimwiki_list = [{'path': '~/my_pages/',
          \ 'css_name': 'main.css'}]
<
or even >
  let g:vimwiki_list = [{'path': '~/my_pages/',
          \ 'css_name': 'css/main.css'}]
<
Vimwiki comes with a default CSS file "style.css".


*vimwiki-option-maxhi*
------------------------------------------------------------------------------
Key             Default value     Values~
maxhi           0                 0, 1

Description~
If on, wiki links to non-existent wiki files are highlighted.  However, it can
be quite slow.  If you still want it, set maxhi to 1: >
  let g:vimwiki_list = [{'path': '~/my_site/', 'maxhi': 1}]


*vimwiki-option-nested_syntaxes*
------------------------------------------------------------------------------
Key             Default value     Values~
nested_syntaxes {}                pairs of highlight keyword and Vim filetype

Description~
You can configure preformatted text to be highlighted with any syntax
available for Vim.
For example the following setup in your vimrc: >
  let wiki = {}
  let wiki.path = '~/my_wiki/'
  let wiki.nested_syntaxes = {'python': 'python', 'c++': 'cpp'}
  let g:vimwiki_list = [wiki]

would give you Python and C++ highlighting in: >
 {{{class="brush: python"
 for i in range(1, 5):
     print(i)
 }}}

 {{{class="brush: c++"
 #include "helloworld.h"
 int helloworld()
 {
    printf("hello world");
 }
 }}}

or in: >
 {{{c++
 #include "helloworld.h"
 int helloworld()
 {
    printf("hello world");
 }
 }}}

 {{{python
 for i in range(1, 5):
     print(i)
 }}}


*vimwiki-option-automatic_nested_syntaxes*
------------------------------------------------------------------------------
Key                        Default value~
automatic_nested_syntaxes  1

Description~
If set, the nested syntaxes (|vimwiki-option-nested_syntaxes|) are
automatically derived when opening a buffer.
Just write your preformatted text in your file like this >
 {{{xxx
 my preformatted text
 }}}

where xxx is a filetype which is known to Vim. For example, for C++
highlighting, use "cpp" (not "c++"). For a list of known filetypes, type
":setf " and hit Ctrl+d.

Note that you may have to reload the file (|:edit|) to see the highlight.

Since every file is scanned for the markers of preformatted text when it is
opened, it can be slow when you have huge files. In this case, set this option
to 0.


*vimwiki-option-diary_rel_path*
------------------------------------------------------------------------------
Key             Default value~
diary_rel_path  diary/

Description~
The path to the diary wiki files, relative to |vimwiki-option-path|.


*vimwiki-option-diary_index*
------------------------------------------------------------------------------
Key             Default value~
diary_index     diary

Description~
Name of wiki-file that holds all links to dated wiki files.


*vimwiki-option-diary_header*
------------------------------------------------------------------------------
Key             Default value~
diary_header    Diary

Description~
Name of the header in |vimwiki-option-diary_index| where links to dated
wiki-files are located.


*vimwiki-option-diary_sort*
------------------------------------------------------------------------------
Key             Default value   Values~
diary_sort      desc            desc, asc

Description~
Sort links in a diary index page.


*vimwiki-option-diary_caption_level*
------------------------------------------------------------------------------
Key                   Default value~
diary_caption_level   0

Description~
Controls the presence of captions in the diary index linking to headers within
the diary pages.

Possible values:
-1:  No headers are read from the diary page.
 0:  The first header from the diary page is used as the caption.
       There are no sub-captions.
 1:  Captions are created for headers of level 1 in the diary page.
 2:  Captions are created for headers up to level 2 in the diary page.
 etc.

When the value is >= 1, the primary caption of each diary page is set to the
first header read from that page if it is the unique lowest-level header.

*vimwiki-option-custom_wiki2html*
------------------------------------------------------------------------------
Key               Default value~
custom_wiki2html  ''

Description~
The full path to a user-provided script that converts a wiki page to HTML.
Vimwiki calls the provided |vimwiki-option-custom_wiki2html| script from the
command-line, using |:!| invocation.

The following arguments, in this order, are passed to the script:

1. force : [0/1] overwrite an existing file
2. syntax : the syntax chosen for this wiki
3. extension : the file extension for this wiki
4. output_dir : the full path of the output directory
5. input_file : the full path of the wiki page
6. css_file : the full path of the css file for this wiki
7. template_path : the full path to the wiki's templates
8. template_default : the default template name
9. template_ext : the extension of template files
10. root_path : a count of ../ for pages buried in subdirs
    For example, if you have wikilink [[dir1/dir2/dir3/my page in a subdir]]
    then this argument is '../../../'.
11. custom_args : custom arguments that will be passed to the conversion
    (can be defined in g:vimwiki_list as 'custom_wiki2html_args' parameter,
    see |vimwiki-option-custom_wiki2html_args|)
    script.

Options 7-11 are experimental and may change in the future.  If any of these
parameters is empty, a hyphen "-" is passed to the script in its place.

For an example and further instructions, refer to the following script:

  $VIMHOME/autoload/vimwiki/customwiki2html.sh

An alternative converter was developed by Jason6Anderson, and can
be located at https://github.com/vimwiki-backup/vimwiki/issues/384

To use the internal wiki2html converter, use an empty string (the default).


*vimwiki-option-custom_wiki2html_args*
-----------------------------------------------------------------------------
Key                     Default value~
custom_wiki2html_args   ''

Description~
If a custom script is called with |vimwiki-option-custom_wiki2html|, additional
parameters can be passed using this option: >
  let g:vimwiki_list = [{'path': '~/path/', 'custom_wiki2html_args': 'stuff'}]


*vimwiki-option-list_margin*
------------------------------------------------------------------------------
Key               Default value~
list_margin       -1 (0 for markdown)

Description~
Width of left-hand margin for lists.  When negative, the current 'shiftwidth'
is used.  This affects the appearance of the generated links (see
|:VimwikiGenerateLinks|), the Table of contents (|vimwiki-toc|) and the
behavior of the list manipulation commands |:VimwikiListChangeLevel| and the
local mappings |vimwiki_glstar|, |vimwiki_gl#| |vimwiki_gl-|, |vimwiki_gl-|,
|vimwiki_gl1|, |vimwiki_gla|, |vimwiki_glA|, |vimwiki_gli|, |vimwiki_glI| and
|vimwiki_i_<C-L>_<C-M>|.

Note: if you use Markdown or MediaWiki syntax, you probably would like to set
this option to 0, because every indented line is considered verbatim text.


*vimwiki-option-auto_tags*
------------------------------------------------------------------------------
Key             Default value     Values~
auto_tags       0                 0, 1

Description~
Set this option to 1 to automatically update the tags metadata when the
current wiki page is saved: >
  let g:vimwiki_list = [{'path': '~/my_site/', 'auto_tags': 1}]


*vimwiki-option-auto_diary_index*
------------------------------------------------------------------------------
Key               Default value     Values~
auto_diary_index  0                 0, 1

Description~
Set this option to 1 to automatically update the diary index when opened.
See |:VimwikiDiaryGenerateLinks|:  >
  let g:vimwiki_list = [{'path': '~/my_site/', 'auto_diary_index': 1}]


*vimwiki-option-auto_generate_links*
------------------------------------------------------------------------------
Key                  Default value     Values~
auto_generate_links  0                 0, 1

Description~
Set this option to 1 to automatically update generated links when the
current wiki page is saved: >
  let g:vimwiki_list = [{'path': '~/my_site/', 'auto_generate_links': 1}]


*vimwiki-option-auto_generate_tags*
------------------------------------------------------------------------------
Key                 Default value     Values~
auto_generate_tags  0                 0, 1

Description~
Set this option to 1 to automatically update generated tags when the
current wiki page is saved: >
  let g:vimwiki_list = [{'path': '~/my_site/', 'auto_generate_tags': 1}]


*vimwiki-option-exclude_files*
------------------------------------------------------------------------------
Key             Default value     Values~
exclude_files   []                list of file patterns to exclude

Description~
Set this option to a list of file patterns to exclude when checking or
generating links: >
  let g:vimwiki_list = [{'path': '~/my_site/', 'exclude_files': ['**/README.md']}]


*vimwiki-option-html_filename_parameterization*
------------------------------------------------------------------------------
Key                             Default value     Values~
html_filename_parameterization  0                 0, 1

Description~
This setting is for integration with the vimwiki_markdown gem. If this is set
to 1 it alters the check for generated html filenames to match what
vimwiki_markdown generates. This means that it prevents unnecessary
regeneration of HTML files.

This setting also turns off the automatic deletion of files
in the site_html directory which don't match existing wiki files.


------------------------------------------------------------------------------
12.4 Global Options                                   *vimwiki-global-options*


Global options are configured using the following pattern: >

    let g:option_name = option_value


------------------------------------------------------------------------------
*g:vimwiki_hl_headers*

Highlight headers with =Reddish=, ==Greenish==, ===Blueish=== colors.

Value           Description~
1               Use VimwikiHeader1 - VimwikiHeader6 group colors to highlight
                different header levels.
0               Use |hl-Title| color for headers.
Default: 0


------------------------------------------------------------------------------
*g:vimwiki_hl_cb_checked*

Highlight checked list items with a special color:

  * [X] the whole line can be highlighted with the option set to 1.
    * this line is highlighted as well with the option set to 2
  * [ ] this line is never highlighted

Value           Description~
0               Don't highlight anything.
1               Highlight only the first line of a checked [X] list item.
2               Highlight a complete checked list item and all its child items.

Default: 0

The |group-name| "Comment" is used for highlighting.

Note: Option 2 does not work perfectly.  Specifically, it might break if the
list item contains preformatted text or if you mix tabs and spaces for
indenting.  Also, indented headers can be highlighted erroneously.
Furthermore, if your list is long, Vim's highlight can break. To solve this,
consider putting >
 au BufEnter *.wiki :syntax sync fromstart
in your .vimrc

------------------------------------------------------------------------------
*g:vimwiki_global_ext*

Control the creation of |vimwiki-temporary-wiki|s.

If a file with a registered extension (see |vimwiki-register-extension|) is
opened in a directory that is: 1) not listed in |g:vimwiki_list|, and 2) not a
subdirectory of any such directory, then:

Value           Description~
1               make temporary wiki and append it to |g:vimwiki_list|.
0               don't make temporary wiki in that dir.

If your preferred wiki extension is .txt then you can >
    let g:vimwiki_global_ext = 0
to restrict Vimwiki's operation to only those paths listed in g:vimwiki_list.
Other text files wouldn't be treated as wiki pages.

Default: 1


------------------------------------------------------------------------------
*g:vimwiki_ext2syntax* *vimwiki-register-extension*

A many-to-one mapping between file extensions and syntaxes whose purpose is to
register the extensions with Vimwiki.

E.g.: >
  let g:vimwiki_ext2syntax = {'.md': 'markdown',
                  \ '.mkd': 'markdown',
                  \ '.wiki': 'media'}

An extension that is registered with Vimwiki can trigger creation of
a |vimwiki-temporary-wiki|. File extensions used in |g:vimwiki_list| are
automatically registered with Vimwiki using the default syntax. Extensions
mapped with this option will instead use the mapped syntax.

Default: >
    {'.md': 'markdown', '.mkdn': 'markdown',
    \  '.mdwn': 'markdown', '.mdown': 'markdown',
    \  '.markdown': 'markdown', '.mw': 'media'}},

Note: setting this option will overwrite the default values so include them if
desired.

------------------------------------------------------------------------------
*g:vimwiki_menu*

Create a menu in the menu bar of GVim, where you can open the available wikis.
If the wiki has an assigned name (see |vimwiki-option-name|), the menu entry
will match the name. Otherwise, the final folder of |vimwiki-option-path| will
be used for the name. If there are duplicate entries the index number from
|g:vimwiki_list| will be appended to the name.

Value              Description~
''                 No menu
'Vimwiki'          Top level menu "Vimwiki"
'Plugin.Vimwiki'   "Vimwiki" submenu of top level menu "Plugin"
etc.

Default: 'Vimwiki'


------------------------------------------------------------------------------
*g:vimwiki_listsyms*

String of at least two symbols to show the progression of todo list items.
Default value is ' .oOX'.

The first char is for 0% done items.
The last is for 100% done items.

You can set it to some more fancy symbols like this:
>
   let g:vimwiki_listsyms = '✗○◐●✓'


------------------------------------------------------------------------------
*g:vimwiki_listsym_rejected*

Character that is used to show that an item of a todo list will not be done.
Default value is '-'.

The character used here must not be part of |g:vimwiki_listsyms|.

You can set it to a more fancy symbol like this:
>
   let g:vimwiki_listsym_rejected = '✗'


------------------------------------------------------------------------------
*g:vimwiki_folding*

Enable/disable Vimwiki's folding (outline) functionality. Folding in Vimwiki
can use either the 'expr' or the 'syntax' |foldmethod| of Vim.

Value           Description~
''              Disable folding
'expr'          Folding based on expression (folds sections and code blocks)
'syntax'        Folding based on syntax (folds sections; slower than 'expr')
'list'          Folding based on expression (folds list subitems; much slower)
'custom'        Allow folding options to be set by another plugin or a vim
                configuration file

Default: ''

Limitations:
  - Opening very large files may be slow when folding is enabled.
  - 'list' folding is particularly slow with larger files.
  - 'list' is intended to work with lists nicely indented with 'shiftwidth'.
  - 'syntax' is only available for the default syntax so far.

The options above can be suffixed with ':quick' (e.g.: 'expr:quick') in order
to use some workarounds to make folds work faster.

------------------------------------------------------------------------------
*g:vimwiki_list_ignore_newline*

This is HTML related.
Convert newlines to <br />s in multiline list items.

Value           Description~
0               Newlines in a list item are converted to <br />s.
1               Ignore newlines.

Default: 1


------------------------------------------------------------------------------
*g:vimwiki_text_ignore_newline*

This is HTML related.
Convert newlines to <br />s in text.

Value           Description~
0               Newlines in text are converted to <br />s.
1               Ignore newlines.

Default: 1


------------------------------------------------------------------------------
*g:vimwiki_use_calendar*

Create new or open existing diary wiki-file for the date selected in Calendar.
See |vimwiki-calendar|.

Value           Description~
0               Do not use calendar.
1               Use calendar.

Default: 1


------------------------------------------------------------------------------
*g:vimwiki_create_link*

Create target wiki page if it does not exist. See |:VimwikiFollowLink|.

Value           Description~
0               Do not create target wiki page.
1               Create target wiki page.

Default: 1


------------------------------------------------------------------------------
*g:vimwiki_markdown_link_ext*

Append wiki file extension to links in Markdown. This is needed for
compatibility with other Markdown tools.

Value           Description~
0               Do not append wiki file extension.
1               Append wiki file extension.

Default: 0


------------------------------------------------------------------------------
*VimwikiLinkHandler*

A customizable link handler can be defined to override Vimwiki's behavior when
opening links.  Each recognized link, whether it is a wikilink, wiki-include
link or a weblink, is first passed to |VimwikiLinkHandler| to see if it can be
handled. The return value 1 indicates success.

If the link is not handled successfully, the behavior of Vimwiki depends on
the scheme.  "wiki:", "diary:" or schemeless links are opened in Vim.  "file:"
and "local:" links are opened with a system default handler.

You can redefine the VimwikiLinkHandler function in your .vimrc to do
something else: >

  function! VimwikiLinkHandler(link)
    try
      let browser = 'C:\Program Files\Firefox\firefox.exe'
      execute '!start "'.browser.'" ' . a:link
      return 1
    catch
      echo "This can happen for a variety of reasons ..."
    endtry
    return 0
  endfunction

A second example handles a new scheme, "vfile:", which behaves similar to
"file:", but the files are always opened with Vim in a new tab: >

  function! VimwikiLinkHandler(link)
    " Use Vim to open external files with the 'vfile:' scheme.  E.g.:
    "   1) [[vfile:~/Code/PythonProject/abc123.py]]
    "   2) [[vfile:./|Wiki Home]]
    let link = a:link
    if link =~# '^vfile:'
      let link = link[1:]
    else
      return 0
    endif
    let link_infos = vimwiki#base#resolve_link(link)
    if link_infos.filename == ''
      echomsg 'Vimwiki Error: Unable to resolve link!'
      return 0
    else
      exe 'tabnew ' . fnameescape(link_infos.filename)
      return 1
    endif
  endfunction

------------------------------------------------------------------------------
*VimwikiLinkConverter*

This function can be overridden in your .vimrc to specify what a link looks
like when converted to HTML.  The parameters of the function are:
        - the link as a string
        - the full path to the wiki file where the link is in
        - the full path to the output HTML file
It should return the HTML link if successful or an empty string '' otherwise.

This example changes how relative links to external files using the "local:"
scheme look like in HTML.  Per default, they would become links relative to
the HTML output directory.  This function converts them to links relative to
the wiki file, i.e. a link [[local:../document.pdf]] becomes
<a href="../document.pdf">. Also, this function will copy document.pdf to the
right place. >

  function! VimwikiLinkConverter(link, source_wiki_file, target_html_file)
    if a:link =~# '^local:'
      let link_infos = vimwiki#base#resolve_link(a:link)
      let html_link = vimwiki#path#relpath(
                \ fnamemodify(a:source_wiki_file, ':h'), link_infos.filename)
      let relative_link =
                \ fnamemodify(a:target_html_file, ':h') . '/' . html_link
      call system('cp ' . fnameescape(link_infos.filename) .
                \ ' ' . fnameescape(relative_link))
      return html_link
    endif
    return ''
  endfunction

------------------------------------------------------------------------------
*VimwikiWikiIncludeHandler*

Vimwiki includes the content of a wiki-include URL as an image by default.

A trial feature allows you to supply your own handler for wiki-include links.
The handler should return the empty string when it does not recognize or
cannot otherwise convert the link.  A customized handler might look like this: >

  " Convert {{URL|#|ID}} -> URL#ID
  function! VimwikiWikiIncludeHandler(value)
    let str = a:value

    " complete URL
    let url_0 = matchstr(str, g:vimwiki_rxWikiInclMatchUrl)
    " URL parts
    let link_infos = vimwiki#base#resolve_link(url_0)
    let arg1 = matchstr(str, VimwikiWikiInclMatchArg(1))
    let arg2 = matchstr(str, VimwikiWikiInclMatchArg(2))

    if arg1 =~ '#'
      return link_infos.filename.'#'.arg2
    endif

    " Return the empty string when unable to process link
    return ''
  endfunction
<

------------------------------------------------------------------------------
*g:vimwiki_table_auto_fmt*

Enable/disable table auto formatting after leaving INSERT mode.

Value           Description~
0               Disable table auto formatting.
1               Enable table auto formatting.

Default: 1


------------------------------------------------------------------------------
*g:vimwiki_table_reduce_last_col*

If set, the last column separator will not be expanded to fill the cell.  When
`:set wrap` this option improves how a table is displayed, particularly on
small screens.  If |g:vimwiki_table_auto_fmt| is set to 0, this option has no
effect.

Value           Description~
0               Enable table auto formating for all columns.
1               Disable table auto formating for the last column.

Default: 0


------------------------------------------------------------------------------
*g:vimwiki_w32_dir_enc*

Convert directory name from current 'encoding' into 'g:vimwiki_w32_dir_enc'
before it is created.

If you have 'enc=utf-8' and set up >
    let g:vimwiki_w32_dir_enc = 'cp1251'
<
then following the next link with <CR>: >
    [[привет/мир]]
>
would convert utf-8 'привет' to cp1251 and create directory with that name.

Default: ''


------------------------------------------------------------------------------
*g:vimwiki_CJK_length*

Use a special method to calculate the correct length of the strings with
double-wide characters (to align table cells properly).

Value           Description~
0               Do not use it.
1               Use it.

Default: 0

Note: Vim 7.3 has a new function |strdisplaywidth()|, so for users of an up to
date Vim, this option is obsolete.


------------------------------------------------------------------------------
*g:vimwiki_dir_link*

This option is about what to do with links to directories, like
[[directory/]], [[papers/]], etc.

Value           Description~
''              Open 'directory/' using the standard netrw plugin.
'index'         Open 'directory/index.wiki', create if needed.
'main'          Open 'directory/main.wiki', create if needed.
etc.

Default: '' (empty string)


------------------------------------------------------------------------------
*g:vimwiki_html_header_numbering*

Set this option if you want headers to be auto-numbered in HTML.

E.g.: >
    1 Header1
    1.1 Header2
    1.2 Header2
    1.2.1 Header3
    1.2.2 Header3
    1.3 Header2
    2 Header1
    3 Header1
etc.

Value           Description~
0               Header numbering is off.
1               Header numbering is on. Headers are numbered starting from
                header level 1.
2               Header numbering is on. Headers are numbered starting from
                header level 2.
etc.

Example when g:vimwiki_html_header_numbering = 2: >
    Header1
    1 Header2
    2 Header2
    2.1 Header3
    2.1.1 Header4
    2.1.2 Header4
    2.2 Header3
    3 Header2
    4 Header2
etc.

Default: 0


------------------------------------------------------------------------------
*g:vimwiki_html_header_numbering_sym*

Ending symbol for |g:vimwiki_html_header_numbering|.

Value           Description~
'.'             Dot will be added after a header's number.
')'             Closing bracket will be added after a header's number.
etc.

With
    let g:vimwiki_html_header_numbering_sym = '.'
headers would look like: >
    1. Header1
    1.1. Header2
    1.2. Header2
    1.2.1. Header3
    1.2.2. Header3
    1.3. Header2
    2. Header1
    3. Header1


Default: '' (empty)


------------------------------------------------------------------------------
*g:vimwiki_valid_html_tags*

Case-insensitive comma separated list of HTML tags that can be used in
Vimwiki.  When converting to HTML, these tags are left as they are, while
every other tag is escaped.

Default: 'b,i,s,u,sub,sup,kbd,br,hr'


------------------------------------------------------------------------------
*g:vimwiki_user_htmls*

Comma-separated list of HTML files that have no corresponding wiki files and
should not be deleted after |:VimwikiAll2HTML|.

Default: ''

Example:
Consider you have 404.html and search.html in your Vimwiki 'path_html'.
With: >
    let g:vimwiki_user_htmls = '404.html,search.html'
they would not be deleted after |:VimwikiAll2HTML|.


------------------------------------------------------------------------------
*g:vimwiki_conceallevel*

In Vim 7.3 'conceallevel' is local to the current window, thus if you open a
Vimwiki buffer in a new tab or window, it would be set to the default value.

Vimwiki sets 'conceallevel' to g:vimwiki_conceallevel every time a Vimwiki
buffer is entered.

With default settings, Vimwiki conceals one-character markers, shortens long
URLs and hides markers and URL for links that have a description.

Default: 2


------------------------------------------------------------------------------
*g:vimwiki_conceal_onechar_markers*

Control the concealment of one-character markers.

Setting 'conceal_onechar_markers' to 0 will show the markers, overriding
whatever value is set in |g:vimwiki_conceallevel|

Default: 1


------------------------------------------------------------------------------
*g:vimwiki_conceal_pre*

Conceal preformatted text markers. For example,
>
    {{{python
    def say_hello():
        print("Hello, world!")
    }}}
>
would appear as simply
>
    def say_hello():
        print("Hello, world!")
>
in your wiki file.

Default: 0


------------------------------------------------------------------------------
*g:vimwiki_autowriteall*

Automatically save a modified wiki buffer when switching wiki pages. Has the
same effect as setting the Vim option 'autowriteall', but it works for wiki
files only, while the Vim option is global.
Hint: if you're just annoyed that you have to save files manually to switch
wiki pages, consider setting the Vim option 'hidden' which makes that modified
files don't need to be saved.

Value           Description~
0               autowriteall is off
1               autowriteall is on

Default: 1


------------------------------------------------------------------------------
*g:vimwiki_url_maxsave*

Setting the value of |g:vimwiki_url_maxsave| to 0 will prevent any link
shortening: you will see the full URL in all types of links, with no parts
being concealed. This option does not affect the concealing of wiki elements
such as bold, italic, wikilinks, etc.

When positive, the value determines the maximum number of characters that
are retained at the end after concealing the middle part of a long URL.
It could be less: in case one of the characters /,#,? is found near the end,
the URL will be concealed up to the last occurrence of that character.

Note:
  * The conceal feature works only with Vim >= 7.3.
  * When using the default |wrap| option of Vim, the effect of concealed links
    is not always pleasing, because the visible text on longer lines with
    a lot of concealed parts may appear to be strangely broken across several
    lines. This is a limitation of Vim's |conceal| feature.
  * Many color schemes do not define an unobtrusive color for the Conceal
    highlight group - this might be quite noticeable on shortened URLs.


Default: 15


------------------------------------------------------------------------------
*g:vimwiki_diary_months*

It is a |Dictionary| with the numbers of months and corresponding names. Diary
uses it.

Redefine it in your .vimrc to get localized months in your diary:
let g:vimwiki_diary_months = {
      \ 1: 'Январь', 2: 'Февраль', 3: 'Март',
      \ 4: 'Апрель', 5: 'Май', 6: 'Июнь',
      \ 7: 'Июль', 8: 'Август', 9: 'Сентябрь',
      \ 10: 'Октябрь', 11: 'Ноябрь', 12: 'Декабрь'
      \ }

Default:
let g:vimwiki_diary_months = {
      \ 1: 'January', 2: 'February', 3: 'March',
      \ 4: 'April', 5: 'May', 6: 'June',
      \ 7: 'July', 8: 'August', 9: 'September',
      \ 10: 'October', 11: 'November', 12: 'December'
      \ }


------------------------------------------------------------------------------
*g:vimwiki_toc_header*

A string with the magic header that tells Vimwiki where the Table of Contents
(see |vimwiki-toc|) is located in a file. You can change it to the
appropriate word in your mother tongue like this: >
  let g:vimwiki_toc_header = 'Inhalt'

The default is 'Contents'.


------------------------------------------------------------------------------
*g:vimwiki_toc_header_level*

The header level of the Table of Contents (see |vimwiki-toc|). Valid values
are from 1 to 6.

The default is 1.


------------------------------------------------------------------------------
*g:vimwiki_toc_link_format*

The format of the links in the Table of Contents (see |vimwiki-toc|).


Value           Description~
0               Extended: The link contains the description and URL. URL
                references all levels.
1               Brief: The link contains only the URL. URL references only
                the immediate level.

Default: 0


------------------------------------------------------------------------------
*g:vimwiki_map_prefix*

A string which specifies the prefix for all global mappings (and some local
ones).  Use it to avoid conflicts with other plugins.  Note that it must be
defined before the plugin loads.  >
  let g:vimwiki_map_prefix = '<Leader>e'

The default is '<Leader>w'.


------------------------------------------------------------------------------
*g:vimwiki_auto_chdir*

When set to 1, enables auto-cd feature. Whenever Vimwiki page is opened,
Vimwiki performs an |:lcd| to the root Vimwiki folder of the page's wiki.


Value           Description~
0               Do not change directory.
1               Change directory to root Vimwiki folder on opening page.

Default: 0


------------------------------------------------------------------------------
*g:vimwiki_links_header*

A string with the magic header that tells Vimwiki where the generated links
are located in a file. You can change it to the appropriate word in your
mother tongue like this: >
  let g:vimwiki_links_header = 'Generierte Links'

The default is 'Generated Links'.


------------------------------------------------------------------------------
*g:vimwiki_links_header_level*

The header level of generated links. Valid values are from 1 to 6.

The default is 1.


------------------------------------------------------------------------------
*g:vimwiki_tags_header*

A string with the magic header that tells Vimwiki where the generated tags
are located in a file. You can change it to the appropriate word in your
mother tongue like this: >
  let g:vimwiki_tags_header = 'Generierte Stichworte'

The default is 'Generated Tags'.


------------------------------------------------------------------------------
*g:vimwiki_tags_header_level*

The header level of generated tags. Valid values are from 1 to 5.

The default is 1.


------------------------------------------------------------------------------
*g:vimwiki_markdown_header_style*

The number of newlines to be inserted after a header is generated. Valid
values are from 0 to 2.

The default is 1.


------------------------------------------------------------------------------
*g:vimwiki_auto_header*

Set this option to 1 to automatically generate a level 1 header when creating
a new wiki page. This option is disabled for the wiki index and the diary
index. Spaces replaced with |vimwiki-option-links_space_char| are reverted
back to spaces in the generated header, which will match the filename
except for the characters that were reverted to spaces.

For example, with `links_space_char` set to `'_'` creating a link from the text
`foo bar link` would result in `[[foo_bar_link]]` and the file
`foo_bar_link.wiki`. The generated header would be `= foo bar link =`

The default is 0.


------------------------------------------------------------------------------
*g:vimwiki_key_mappings*

A dictionary that is used to enable/disable various key mapping groups. To
disable a specific group set the value for the associated key to 0.
For example: >

  let g:vimwiki_key_mappings =
    \ {
    \ 'headers': 0,
    \ 'text_objs': 0,
    \ }

To disable ALL Vimwiki key mappings use: >

    let g:vimwiki_key_mappings = { 'all_maps': 0, }

The valid key groups and their associated mappings are shown below.

`all_maps`:
  Used to disable all Vimwiki key mappings.
`global`:
  |vimwiki-global-mappings| that are defined when Vim starts.
`headers`:
  Mappings for header navigation and manipulation:
  |vimwiki_=|, |vimwiki_-|, |vimwiki_[[|, |vimwiki_]]|, |vimwiki_[=|
  |vimwiki_]=|, |vimwiki_]u| , |vimwiki_[u|
`text_objs`:
  |vimwiki-text-objects| mappings.
`table_format`:
  Mappings used for table formatting.
  |vimwiki_gqq|, |vimwiki_gww|, |vimwiki_gq1|, |vimwiki_gw1|
  |vimwiki_<A-Left>|, |vimwiki_<A-Right>|
`table_mappings`:
    Table mappings for insert mode.
    |vimwiki_<Tab>|, |vimwiki_<S-Tab>|
`lists`:
    Mappings for list manipulation.
    |vimwiki_<C-Space>|, |vimwiki_gl<Space>|, |vimwiki_gL<Space>| |vimwiki_gln|, |vimwiki_glp|
    |vimwiki_gll|, |vimwiki_gLl|, |vimwiki_glh|, |vimwiki_gLh|, |vimwiki_glr|, |vimwiki_gLr|
    |vimwiki_glsar|, |vimwiki_gLstar|, |vimwiki_gl#|, |vimwiki_gL#|, |vimwiki_gl-|, |vimwiki_gL-|
    |vimwiki_gl1|, |vimwiki_gL1|, |vimwiki_gla|, |vimwiki_gLa|, |vimwiki_glA|, |vimwiki_gLA|
    |vimwiki_gli|, |vimwiki_gLi|, |vimwiki_glI|, |vimwiki_gLI|, |vimwiki_glx|
`links`:
    Mappings for link creation and navigation.
    |vimwiki_<Leader>w<Leader>i|, |vimwiki_<CR>|, |vimwiki_<S-CR>|, |vimwiki_<C-CR>|
    |vimwiki_<C-S-CR>|, |vimwiki_<D-CR>|, |vimwiki_<Backspace>|, |vimwiki_<Tab>|
    |vimwiki_<S-Tab>|, |vimwiki_<Leader>wd|, |vimwiki_<Leader>wr|, |vimwiki_<C-Down>|
    |vimwiki_<C-Up>|, |vimwiki_+|, |vimwiki_<Backspace>|
`html`:
    Mappings for HTML generation.
    |vimwiki_<Leader>wh|, |vimwiki_<Leader>whh|
`mouse`:
    Mouse mappings, see |vimwiki_mouse|. This option is disabled by default.

The default is to enable all key mappings except the mouse: >
  let g:vimwiki_key_mappings =
    \ {
    \   'all_maps': 1,
    \   'global': 1,
    \   'headers': 1,
    \   'text_objs': 1,
    \   'table_format': 1,
    \   'table_mappings': 1,
    \   'lists': 1,
    \   'links': 1,
    \   'html': 1,
    \   'mouse': 0,
    \ }


------------------------------------------------------------------------------
*g:vimwiki_filetypes*

A list of additional fileypes that should be registered to vimwiki files: >

  let g:vimwiki_filetypes = ['markdown', 'pandoc']

Would result in the filetype being set to `vimwiki.markdown.pandoc`. This can
be used to enable third party plugins such as custom folding. WARNING: this
option can allow other plugins to overwrite vimwiki settings and operation so
take care when using it. Any plugin that uses a set filetype will be enabled.

The default is `[ ]`

==============================================================================
13. Getting help                                                *vimwiki-help*

For questions, discussions, praise or rants there is a mailing list:
https://groups.google.com/forum/#!forum/vimwiki

Also, there is the IRC channel #vimwiki on Freenode which can be accessed via
webchat: https://webchat.freenode.net/?channels=#vimwiki

==============================================================================
14. Contributing & Bug reports                          *vimwiki-contributing*

Your help in making Vimwiki better is really appreciated!
Any help, whether it is a spelling correction or a code snippet to patch --
everything is welcomed.

See CONTRIBUTING.md for info about how to file bugs etc.

==============================================================================
15. Development                                          *vimwiki-development*

Homepage: http://vimwiki.github.io/
Github: https://github.com/vimwiki/vimwiki/
Vim plugins: http://www.vim.org/scripts/script.php?script_id=2226
Old homepage: http://code.google.com/p/vimwiki/

Contributors and their Github usernames in roughly chronological order:

    - Maxim Kim (@habamax) <habamax@gmail.com> as original author
    - the people here: http://code.google.com/p/vimwiki/people/list
    - Stuart Andrews (@tub78)
    - Tomas Pospichal
    - Daniel Schemala (@EinfachToll) as current maintainer
    - Larry Hynes (@larryhynes)
    - Hector Arciga (@harciga)
    - Alexey Radkov (@lyokha)
    - Aaron Franks (@af)
    - Dan Bernier (@danbernier)
    - Carl Helmertz (@chelmertz)
    - Karl Yngve Lervåg (@lervag)
    - Patrick Davey (@patrickdavey)
    - Ivan Tishchenko (@t7ko)
    - 修昊 (@Svtter)
    - Marcelo D Montu (@mMontu)
    - John Kaul
    - Hongbo Liu (@hiberabyss)
    - @Tomsod
    - @wangzq
    - Jinzhou Zhang (@lotabout)
    - Michael Riley (@optik-aper)
    - Irfan Sharif (@irfansharif)
    - John Conroy (@jconroy77)
    - Christian Rondeau (@christianrondeau)
    - Alex Thorne (@thornecc)
    - Shafqat Bhuiyan (@priomsrb)
    - Bradley Cicenas (@bcicen)
    - Michael Thessel (@MichaelThessel)
    - Michael F. Schönitzer (@nudin)
    - @sqlwwx
    - Guilherme Salazar (@salazar)
    - Daniel Trnka (@trnila)
    - Yuchen Pei (@ycpei)
    - @maqiv
    - Dawid Ciężarkiewicz (@dpc)
    - Drew Hays (@Dru89)
    - Daniel Etrata (@danetrata)
    - Keith Haber (@kjhaber)
    - @beuerle
    - Silvio Ricardo Cordeiro (@silvioricardoc)
    - @blyoa
    - Jonathan McElroy (@jonathanmcelroy)
    - @PetrusZ
    - Brian Gianforcaro (@bgianfo)
    - Ben Burrill (@benburrill)
    - Zhuang Ma (@mzlogin)
    - Huy Le (@huynle)
    - Nick Borden (@hcwndbyw)
    - John Campbell (@johnmarcampbell)
    - Petrus (@PetrusZ)
    - Steven Stallion (@sstallion)
    - Daniel Quomsieh (@DQuomsieh)
    - Fredrik Arnerup (@farnerup)
    - CUI Hao (@cuihaoleo)
    - Benjamin Brandtner (@BenjaminBrandtner)
    - @sreejith994
    - Raphael Feng (@raphaelfeng)
    - Kasper Socha (@fte10kso)
    - Nicolas Brailovsky (@nicolasbrailo)
    - @BenMcH
    - Stefan Huber (@shuber2)
    - Hugo Hörnquist (@HugoNikanor)
    - Rane Brown (@ranebrown)
    - Patrik Willard (@padowi)
    - Steve Dondley (@sdondley)
    - Alexander Gude (@agude)
    - Jonny Bylsma (@jbylsma)
    - Shaedil (@Shaedil)
    - Robin Lowe (@defau1t)
    - Abhinav Gupta (@abhinav)
    - Dave Gauer (@ratfactor)
    - Martin Tourneboeuf (@tinmarino)
    - Mauro Morales (@mauromorales)
    - Valtteri Vallius (@kaphula)
    - Patrick Stockwell (@patstockwell)
    - Henry Qin (@hq6)
    - Hugo Hörnquist
    - Greg Anders
    - Steven Schmeiser
    - Monkin (@monkinco)
    - @AresMegaGlobal
    - Cesar Tessarin (@tessarin)
    - Clément Bœsch (@ubitux)
    - Dave Gauer
    - Eric Langlois (@edlanglois)
    - James Moriarty
    - Lionel Flandrin (@simias)
    - Michael Brauweiler (@rattletat)
    - Michal Cizmazia (@cizmazia)
    - Samir Benmendil (@Ram-Z)
    - Stefan Lehmann (@stevesteve)
    - @graywolf
    - flex (@bratekarate)

==============================================================================
16. Changelog                                              *vimwiki-changelog*


Issue numbers starting with '#' are issues from
https://github.com/vimwiki/vimwiki/issues/, all others from
http://code.google.com/p/vimwiki/issues/list. They may be accessible from
https://github.com/vimwiki-backup/vimwiki/issues.


2.5 (2020-05-26)~

New:~
    * PR #787: |:VimwikiRenameFile| works for all directories: even
      wiki_root/diary/2019-12-11.md if current file is wiki_root/dir1/file.md.
    * Issue #764: fenced code blocks are properly supported for markdown
      syntax i.e. more than 3 backticks, adds tilde support.
    * PR #785: |:VimwikiGoto| completion works with part of filename and
      nested directories
    * Add test framework (vader, vint, vim-testbed)
    * Issue #769: Set default values for |g:vimwiki_ext2syntax|.
    * PR #735: Make list-toggling work properly even when code blocks are
      embedded within the list in Markdown mode.
    * PR #711: Allow forcing VimwikiAll2HTML with !
    * PR #702: Make remapping documentation more accessible to newer vim users
    * PR #673: Add :VimwikiGoto key mapping.
    * PR #689: Allow |vimwiki-option-diary_rel_path| to be an empty string.
    * PR #683: Improve layout and format of key binding documentation in
      README and include note about key bindings that may not work.
    * PR #681: Prevent sticky type checking errors for old vim versions.
    * PR #686: New option |g:vimwiki_key_mappings| that allow key mappings to
      be enabled/disabled by groups. Key mappings are also no longer
      overwritten if they are already defined.
    * PR #675: Add option |vimwiki-option-name| to assign a per wiki name.
    * PR #661: Add option |g:vimwiki_auto_header| to automatically generate
      a level 1 header for new wiki pages.
    * PR #665: Integration with vimwiki_markdown gem
      https://github.com/patrickdavey/vimwiki_markdown
      This provides the |vimwiki-option-html_filename_parameterization|
      which alters the filenames vimiwiki checks against when running the
      html conversion. It also disables the deleting of html files which
      no longer match against a wiki file.
    * PR #663: New option |g:vimwiki_conceal_onechar_markers| to control
      whether to show or hide single-character format markers.
    * PR #636: Wiki local option |vimwiki-option-exclude_files| which is
      a list of patterns to exclude when checking or generating links.
    * PR #644: Key mapping gnt to jump to the next open task.
    * PR #643: Option |g:vimwiki_toc_link_format| to change how links are
      formatted in the TOC.
    * PR #641: Option |g:vimwiki_conceal_code_blocks| to conceal preformatted
      text markers.
    * PR #634: New options |g:vimwiki_links_header| and
      |g:vimwiki_tags_header| to customize the title string of generated
      sections. New option |g:vimwiki_links_header_level| and
      |g:vimwiki_tags_header_level| which allow the header level (1-6) of the
      generated links to be set. New option |g:vimwiki_markdown_header_style|
      which specifies the nuber of newlines after the created header for
      generated sections.
    * PR #635: Wiki local options |vimwiki-option-auto_generate_links| and
      |vimwiki-option-auto_generate_tags|.
    * Wiki local option |vimwiki-option-links_space_char| to replace spaces
      with a different character when creating a link.
    * Allow increase/decrease header level to take a count.
    * PR #637: Option |g:vimwiki_table_reduce_last_col| to not autoformat last
      column of a table.
    * PR #629: New option |g:vimwiki_toc_header_level| to set the desired
      header level for the TOC.
    * PR #616: Hex color codes are colored in HTML output.
    * PR #573: Add HTML template variable %wiki_path% which outputs the path
      of the current file being converted to HTML.
    * PR #529: Option |g:vimwiki_markdown_link_ext| to include the extension
      .md in generated links.
    * PR #528: Add option |g:vimwiki_create_link| to prevent link creation
      with <CR>.
    * PR #498: Option |vimwiki-option-diary_caption_level| which adds captions
      to the diary index based on headers.
    * PR #377: Add horizontal alignment to tables.
    * PR #202: Don't override or display errors for existing keymappings.
    * PR #47: Optimize table formatting for large tables.
    * PR #857: Make default template responsive
    * PR #879: Generate links when diary & wiki dir are the same

Changed:~
    * Issue #796: Rename |:VimwikiGenerateTags| to |:VimwikiGenerateTagLinks|
    * Issue #638: Rename |:VimwikiDeleteLink| to |:VimwikiDeleteFile|
    * Issue #638: Rename |:VimwikiRenameLink| to |:VimwikiRenameFile|
    * For all three above the old commands still works but is deprecated and
    * will be removed in later versions.
    * Set default |vimwiki-option-list_margin| = 0 for markdown syntax.
    * Modify horizontal rule (thematic-breaks) syntax for markdown.

Removed:~
    * PR #698: Remove awa check triggering silent file edits.
    * Options g:vimwiki_use_mouse and g:vimwiki_table_mappings. These are
      still present in the code for backwards compatibility but have been
      removed from the documentation and will be fully removed at a later
      point.

Fixed:~
    * Issue #90: |:VimwikiRenameFile| doesn't update links in diary.
    * Issue #790: Allow tags before a header with markdown syntax.
    * Issue #779: Vimwiki tags file meets ctags standard.
    * Issue #781: Compatablity fixes for older versions of Vim.
    * Issue #691: Allow |:VimwikiGoBackLink| to go back multiple times.
    * Update MathJax CDN loading instructions.
    * Issue #212: Don't treat comment characters within code blocks as
      headers.
    * Issue #420: Add error handling to |:VimwikiSearch|
    * PR #744: Fix typo in vimwiki_list_manipulation
    * Issue #715: s:clean_url is compatible with vim pre 7.4.1546 (sticky type
      checking)
    * Issue #729: Normalize links uses relative paths in diary pages for
      Markdown syntax. This previously only worked for the default syntax.
    * Disable spell check in code and math inline/blocks.
    * Properly handle markdown image links `![]()`
    * Issue #415: Expand iabbrev entries on <CR>.
    * Issue #619: allow escaped characters in markdown links.
    * Issue #240: Fix regex pattern for markdown '[]()' links
    * Issue #685: Error message for invalid user options fixed.
    * Issue #481: Allow surrounding URLs with '<' '>'
    * Issue #237: |:VimwikiRenameFile| now works for Markdown syntax
    * Issue #612: GVim menu displayed duplicate names.
    * Issue #456: Omnicompletion of wikilinks under Windows. Note: this should
      be considered a temporary fix until #478 is closed.
    * Issue #654: Fix |:VimwikiShowVersion| command.
    * PR #634: Removed extra newlines that were inserted before/after
      generated links.
    * Issue #543: Allow commands related to opening index files or diary pages
      to take a count, modify keymapping behavior, and fix discrepancies in
      the documentation.
    * Issue #539: The option |g:vimwiki_url_maxsave| now only affects raw
      URLs (wiki links are excluded).
    * Issue #438: Fix creation of visually selected links on diary pages.
    * Issue #404: Don't conceal strikethrough character in tables.
    * Issue #318: Markdown syntax bold, italic, and italic/bold are now
      rendered correctly.
    * Issue #835: Pressing enter on the dash of a markdown list causes an error.
    * Issue #876: E684: list index out of range: 0, when creating a link containing a `.`.
    * Issue #803: |:VimwikiGenerateLinks| for subdirectory only
    * Issue #776: Command [count]o can't repeat in vimwiki


2.4.1 (2019-02-20)~
Fixed:
    * Fix VimwikiShowVersion function.
    * strikethrough `~` characters were not hidden within tables
    * Update and format README.md and update screen shots

2.4 (2019-03-24)~

New:~
    * Add the option |g:vimwiki_text_ignore_newline|.
    * |g:vimwiki_listsyms| can have fewer or more than 5 symbols.
    * glx on a list item marks a checkbox as won't do, see |vimwiki_glx|.
    * Add the option |g:vimwiki_listsym_rejected| to set the character used
      for won't-do list items.
    * gln and glp change the "done" status of a checkbox, see |vimwiki_gln|.
    * |:VimwikiSplitLink| and |:VimwikiVSplitLink| can now reuse an existing
      split window and not move the cursor.
    * Add 'aH' and 'iH' text objects, see |vimwiki-text-objects|.
    * Add the keys |vimwiki_[[|, |vimwiki_]]|, |vimwiki_[=|, |vimwiki_]=| and
      |vimwiki_]u| for navigating between headers.
    * Add the command |:VimwikiMakeTomorrowDiaryNote|.
    * |g:vimwiki_folding| has a new option 'custom'.
    * Add the ':quick' option for faster folding, see |g:vimwiki_folding|.
    * Add the %date placeholder, see |vimwiki-date|.
    * Add the option |vimwiki-option-custom_wiki2html_args|.
    * Add support for HTML-style comments when using markdown syntax.
    * Made headings link to themselves in HTML output.
    * Add |:VimwikiShowVersion| to check the version

Removed:~
    * Remove the undocumented and buggy command :VimwikiReadLocalOptions
      which allowed to store Vimwiki related settings in a local file.
    * Remove the undocumented command :VimwikiPrintWikiState.
    * For complicated reasons, Vimwiki doesn't clean up its settings anymore
      if you change the filetype of a wiki buffer.

Fixed:~
    * Make |vimwiki-option-automatic_nested_syntaxes| work also for markdown.
    * Issue #236: Highlight math blocks as TeX math, not TeX.
    * Issue #264: Don't overwrite mappings to i_<CR> from other plugins.
    * Fix an error where <BS> sometimes didn't work under Windows.
    * Issue #302: |:VimwikiDiaryGenerateLinks| had issues with markdown.
    * Issue #445: Better handling of |'autowriteall'| and |'hidden'|.
    * Improve 'ah' and 'ih' text objects, see |vimwiki-text-objects|.
    * Allow opening of links using Powershell.
    * Allow any visual mode to be used with |vimwiki_+|.
    * Markdown syntax for |vimwiki-toc| is used, when appropriate.
    * Wikis can now be in subfolders of other wikis.
    * Issue #482: |:VimwikiMakeDiaryNote| now uses the diary of the current wiki.
    * Opening the diary and wikis from the menu works correctly now.
    * Issue #497: Make |:VimwikiMakeDiaryNote| work outside a wiki buffer.
    * Use markdown syntax in the diary when appropriate.
    * Improve handling of errors on opening files.
    * Update links when renaming a page with |:VimwikiRenameLink|.
    * Fix losing the highlighting in various situations.
    * Improved link normalisation.
    * Various other minor fixes.


2.3 (2016-03-31)~

New:~
    * Add |:VimwikiMakeYesterdayDiaryNote| command
    * Issue #128: add option |vimwiki-option-automatic_nested_syntaxes|
    * Issue #192: Sort links in the list generated by |:VimwikiGenerateTags|

Fixed:~
    * Issue #176: Fix issue when the wiki path contains spaces
    * Also look for tags in wiki files in subdirectories
    * Locate the .tags file correctly on Windows
    * Issue #183: Fix HTML conversion of headers containing links
    * Issue #64: create correct Markdown links when pressing CR on a word
    * Issue #191: ignore headers inside preformatted text when creating the TOC
    * Create the standard CSS file also if only one file is converted to HTML
    * Fix #188: |vimwiki_+| on a raw url surrounds it with brackets
    * various minor fixes


2.2.1 (2015-12-10)~

Removed:~
    * Removed the option g:vimwiki_debug, which probably nobody used. If you
      want it back, file an issue at Github.

Fixed:~
    * Issue #175: Don't do random things when the user has remapped the z key
    * Don't ask for confirmation when following a URL in MacOS
    * Always jump to the first occurrence of a tag in a file
    * Don't move the cursor when updating the TOC
    * Fix some issues with the TOC when folding is enabled


2.2 (2015-11-25)~

New:~
    * Support for anchors, see |vimwiki-anchors|
        * in this context, add support for TOC, see |vimwiki-toc|
        * add omni completion of wiki links (files and anchors)
        * new local option |vimwiki-option-auto_toc|
        * new global option |g:vimwiki_toc_header|
    * Support for tags, see |vimwiki-syntax-tags|
    * List editing capabilities, see |vimwiki-lists|:
        * support for auto incrementing numbered lists
        * more key maps for list manipulation, see |vimwiki-list-manipulation|
        * improved automatic adjustment of checkboxes
        * text objects for list items, see |vimwiki-text-objects|
    * New command |:VimwikiCheckLinks| to check for broken links
    * New global option |g:vimwiki_auto_chdir|
    * New global option |g:vimwiki_map_prefix|
    * Support for wiki links absolute to the wiki root
    * Added the |VimwikiLinkConverter| function
    * Issue #24: Basic support for remote directories via netrw
    * Issue #50: in HTML, tables can now be embedded in lists
    * When converting to HTML, show a message with the output directory
    * Add auto completion for |:VimwikiGoto|
    * Add Chinese Readme file

Changed:~
    * Wiki files must not contain # anymore, because # is used to separate the
      file from an anchor in a link.
    * replace the function vimwiki#base#resolve_scheme() by
      vimwiki#base#resolve_link() (relevant if you have a custom
      |VimwikiLinkHandler| which used this function)
    * The semantic of "file:" and "local:" links changed slightly, see
      |vimwiki-syntax-links| for what they mean now
    * The meaning of a link like [[/some/directory/]] changed. It used to be
      a link to the actual directory /some/directory/, now it's relative to
      the root of the current wiki. Use [[file:/some/directory/]] for the old
      behavior.

Removed:~
    * the %toc placeholder is now useless, use |vimwiki-toc| instead
    * the global option g:vimwiki_auto_checkbox is now useless and removed

Fixed:~
    * Issue 415: Disable folding if g:vimwiki_folding is set to ''
    * Fix slowdown in Vim 7.4
    * Issue #12: Separate diaries from different wikis
    * Issue #13: Fix :VimwikiRenameLink on links containing a dot
    * Always jump to previous link on <S-Tab>, not to beginning of link
    * Issue #27: Fix <CR> on a visual selection sometimes not working
    * |VimwikiBackLinks| now recognizes much more valid links
    * Issue 424: make external links with #, % work under Linux
    * Issue #39: don't htmlize stuff inside pre tags
    * Issue #44: faster formatting of large tables
    * Issue #52: Recognize markdown links when renaming wiki file
    * Issue #54: Disable 'shellslash' on Windows to avoid problems
    * Issue #81: Don't get stuck when converting a read-only file
    * Issue #66: Better normalizing of links in diary
    * Fix the menu in GVim, which was sometimes not shown correctly
    * |VimwikiGenerateLinks| now also generates links for subdirectories
    * Issue #93: Don't process placeholders inside preformatted text
    * Issue #102: Add default values to some options like the doc says
    * Issue #144: Fix bug with folds shortening on multibyte characters
    * Issue #158: Detect the OS correctly
    * |VimwikiGenerateLinks| now replaces a potentially existing old list
    * Fix uneven indentation of list items with checkboxes in HTML
    * Various small fixes
    * Corrected website links in documentation. code.google is dead, long live
      Github!

2.1~

    * Concealing of links can be turned off - set |g:vimwiki_url_maxsave| to 0.
      The option g:vimwiki_url_mingain was removed
    * |g:vimwiki_folding| also accepts value 'list'; with 'expr' both sections
      and code blocks folded, g:vimwiki_fold_lists option was removed
    * Issue 261: Syntax folding is back. |g:vimwiki_folding| values are
      changed to '', 'expr', 'syntax'.
    * Issue 372: Ignore case in g:vimwiki_valid_html_tags
    * Issue 374: Make autowriteall local to vimwiki. It is not 100% local
      though.
    * Issue 384: Custom_wiki2html script now receives templating arguments
    * Issue 393: Custom_wiki2html script path can contain tilde character
    * Issue 392: Custom_wiki2html arguments are quoted, e.g names with spaces
    * Various small bug fixes.

2.0.1 'stu'~

    * Follow (i.e. open target of) markdown reference-style links.
    * Bug fixes.


2.0 'stu'~

This release is partly incompatible with previous.

Summary ~

    * Quick page-link creation.
    * Redesign of link syntaxes (!)
        * No more CamelCase links. Check the ways to convert them
          https://groups.google.com/forum/?fromgroups#!topic/vimwiki/NdS9OBG2dys
        * No more [[link][desc]] links.
        * No more [http://link description] links.
        * No more plain image links. Use transclusions.
        * No more image links identified by extension. Use transclusions.
    * Interwiki links
    * More link schemes
    * Transclusions
    * Normalize link command. See |vimwiki_+|.
    * Improved diary organization and generation. See |vimwiki-diary|.
    * List manipulation. See |vimwiki-list-manipulation|.
    * Markdown support.
    * Mathjax support. See |vimwiki-syntax-math|.
    * Improved handling of special characters and punctuation in filenames and
      urls.
    * Back links command: list links referring to the current page.
    * Highlighting nonexisted links are off by default.
    * Table syntax change. Row separator uses | instead of +.
    * Fold multilined list items.
    * Custom wiki to HTML converters. See |vimwiki-option-custom_wiki2html|.
    * Conceal long weblinks. See g:vimwiki_url_mingain.
    * Option to disable table mappings. See |g:vimwiki_table_mappings|.

For detailed information see issues list on
http://code.google.com/p/vimwiki/issues/list


1.2~
    * Issue 70: Table spanning cell support.
    * Issue 72: Do not convert again for unchanged file. |:VimwikiAll2HTML|
      converts only changed wiki files.
    * Issue 117: |:VimwikiDiaryIndex| command that opens diary index wiki page.
    * Issue 120: Links in headers are not highlighted in vimwiki but are
      highlighted in HTML.
    * Issue 138: Added possibility to remap table-column move bindings. See
      |:VimwikiTableMoveColumnLeft| and |:VimwikiTableMoveColumnRight|
      commands. For remap instructions see |vimwiki_<A-Left>|
      and |vimwiki_<A-Right>|.
    * Issue 125: Problem with 'o' command given while at the of the file.
    * Issue 131: FileType is not set up when GUIEnter autocommand is used in
      vimrc. Use 'nested' in 'au GUIEnter * nested VimwikiIndex'
    * Issue 132: Link to perl (or any non-wiki) file in vimwiki subdirectory
      doesn't work as intended.
    * Issue 135: %title and %toc used together cause TOC to appear in an
      unexpected place in HTML.
    * Issue 139: |:VimwikiTabnewLink| command is added.
    * Fix of g:vimwiki_stripsym = '' (i.e. an empty string) -- it removes bad
      symbols from filenames.
    * Issue 145: With modeline 'set ft=vimwiki' links are not correctly
      highlighted when open wiki files.
    * Issue 146: Filetype difficulty with ".txt" as a vimwiki extension.
    * Issue 148: There are no mailto links.
    * Issue 151: Use location list instead of quickfix list for |:VimwikiSearch|
      command result. Use :lopen instead of :copen, :lnext instead of :cnext
      etc.
    * Issue 152: Add the list of HTML files that would not be deleted after
      |:VimwikiAll2HTML|.
    * Issue 153: Delete HTML files that has no corresponding wiki ones with
      |:VimwikiAll2HTML|.
    * Issue 156: Add multiple HTML templates. See
      |vimwiki-option-template_path|. Options html_header and html_footer are
      no longer exist.
    * Issue 173: When virtualedit=all option is enabled the 'o' command behave
      strange.
    * Issue 178: Problem with alike wikie's paths.
    * Issue 182: Browser command does not quote url.
    * Issue 183: Spelling error highlighting is not possible with nested
      syntaxes.
    * Issue 184: Wrong foldlevel in some cases.
    * Issue 195: Page renaming issue.
    * Issue 196: vim: modeline bug -- syn=vim doesn't work.
    * Issue 199: Generated HTML for sublists is invalid.
    * Issue 200: Generated HTML for todo lists does not show completion status
      the fix relies on CSS, thus your old stylesheets need to be updated!;
      may not work in obsolete browsers or font-deficient systems.
    * Issue 205: Block code: highlighting differs from processing. Inline code
      block {{{ ... }}} is removed. Use `...` instead.
    * Issue 208: Default highlight colors are problematic in many
      colorschemes. Headers are highlighted as |hl-Title| by default, use
      |g:vimwiki_hl_headers| to restore previous default Red, Green, Blue or
      custom header colors. Some other changes in highlighting.
    * Issue 209: Wild comments slow down html generation. Comments are
      changed, use %% to comment out entire line.
    * Issue 210: HTML: para enclose header.
    * Issue 214: External links containing Chinese characters get trimmed.
    * Issue 218: Command to generate HTML file and open it in webbrowser. See
      |:Vimwiki2HTMLBrowse|(bind to <Leader>whh)
    * NEW: Added <Leader>wh mapping to call |:Vimwiki2HTML|


...

39 releases

...

0.1~
    * First public version.

==============================================================================
17. License                                                  *vimwiki-license*

The MIT License
http://www.opensource.org/licenses/mit-license.php

Copyright (c) 2008-2010 Maxim Kim
              2013-2017 Daniel Schemala

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.



 vim:tw=78:ts=8:ft=help
