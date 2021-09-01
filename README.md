![VimWiki: A Personal Wiki For Vim](doc/splash.png)

[中文](README-cn.md)

- [Intro](#introduction)
- [Screenshots](#screenshots)
- [Installation](#installation)
    - [Prerequisites](#prerequisites)
    - [VIM Packages](#installation-using-vim-packages-since-vim-741528)
    - [Pathogen](#installation-using-pathogen)
    - [Vim-Plug](#installation-using-vim-plug)
    - [Vundle](#installation-using-vundle)
- [Basic Markup](#basic-markup)
    - [Lists](#lists)
- [Key Bindings](#key-bindings)
- [Commands](#commands)
- [Changing Wiki Syntax](#changing-wiki-syntax)
- [Getting Help](#getting-help)
- [Helping VimWiki](#helping-vimwiki)
- [Wiki](https://github.com/vimwiki/vimwiki/wiki)
- [License](#license)

----

## Introduction

VimWiki is a personal wiki for Vim -- a number of linked text files that have
their own syntax highlighting. See the [VimWiki Wiki](https://vimwiki.github.io/vimwikiwiki/)
for an example website built with VimWiki!

For the latest features and fixes checkout the [dev branch](https://github.com/vimwiki/vimwiki/tree/dev).
If you are interested in contributing see [this section](#helping-vimwiki).

With VimWiki, you can:

- Organize notes and ideas
- Manage to-do lists
- Write documentation
- Maintain a diary
- Export everything to HTML

To do a quick start, press `<Leader>ww` (default is `\ww`) to go to your index
wiki file. By default, it is located in `~/vimwiki/index.wiki`. See `:h vimwiki_list`
for registering a different path/wiki.

Feed it with the following example:

```text
= My knowledge base =
    * Tasks -- things to be done _yesterday_!!!
    * Project Gutenberg -- good books are power.
    * Scratchpad -- various temporary stuff.
```

Place your cursor on `Tasks` and press Enter to create a link. Once pressed,
`Tasks` will become `[[Tasks]]` -- a VimWiki link. Press Enter again to
open it. Edit the file, save it, and then press Backspace to jump back to your
index.

A VimWiki link can be constructed from more than one word. Just visually
select the words to be linked and press Enter. Try it, with `Project Gutenberg`.
The result should look something like:

```text
= My knowledge base =
    * [[Tasks]] -- things to be done _yesterday_!!!
    * [[Project Gutenberg]] -- good books are power.
    * Scratchpad -- various temporary stuff.
```

## Screenshots

![Lists View](doc/lists.png)
![Entries View](doc/entries.png)
![Todos View](doc/todos.png)
![Wiki View](doc/wiki.png)

## Installation

VimWiki has been tested on **Vim >= 7.3**. It will likely work on older
versions but will not be officially supported.

### Prerequisites

Make sure you have these settings in your vimrc file:

```vim
set nocompatible
filetype plugin on
syntax on
```

Without them, VimWiki will not work properly.

#### Installation using [Vim packages](http://vimhelp.appspot.com/repeat.txt.html#packages) (since Vim 7.4.1528)

```sh

git clone https://github.com/vimwiki/vimwiki.git ~/.vim/pack/plugins/start/vimwiki

# to generate documentation i.e. ':h vimwiki'
vim -c 'helptags ~/.vim/pack/plugins/start/vimwiki/doc' -c quit

```

Notes:

- See `:h helptags` for issues with installing the documentation.
- For general information on vim packages see `:h packages`.

#### Installation using [Pathogen](https://github.com/tpope/vim-pathogen)

```sh

cd ~/.vim
mkdir bundle
cd bundle
git clone https://github.com/vimwiki/vimwiki.git

```

#### Installation using [Vim-Plug](https://github.com/junegunn/vim-plug)

Add the following to the plugin-configuration in your vimrc:

```vim

Plug 'vimwiki/vimwiki'

```

Then run `:PlugInstall`.

#### Installation using [Vundle](https://github.com/VundleVim/Vundle.vim)

Add `Plugin 'vimwiki/vimwiki'` to your vimrc file and run:

```sh

vim +PluginInstall +qall

```

#### Manual Install

Download the [zip archive](https://github.com/vimwiki/vimwiki/archive/master.zip)
and extract it in `~/.vim/bundle/`

Then launch Vim, run `:Helptags` and then `:help vimwiki` to verify it was
installed.

## Basic Markup

```text
= Header1 =
== Header2 ==
=== Header3 ===


*bold* -- bold text
_italic_ -- italic text

[[wiki link]] -- wiki link
[[wiki link|description]] -- wiki link with description
```

### Lists

```text
* bullet list item 1
    - bullet list item 2
    - bullet list item 3
        * bullet list item 4
        * bullet list item 5
* bullet list item 6
* bullet list item 7
    - bullet list item 8
    - bullet list item 9

1. numbered list item 1
2. numbered list item 2
    a) numbered list item 3
    b) numbered list item 4
```

For other syntax elements, see `:h vimwiki-syntax`

## Key bindings

### Normal mode

**Note:** your terminal may prevent capturing some of the default bindings
listed below. See `:h vimwiki-local-mappings` for suggestions for alternative
bindings if you encounter a problem.

#### Basic key bindings

- `<Leader>ww` -- Open default wiki index file.
- `<Leader>wt` -- Open default wiki index file in a new tab.
- `<Leader>ws` -- Select and open wiki index file.
- `<Leader>wd` -- Delete wiki file you are in.
- `<Leader>wr` -- Rename wiki file you are in.
- `<Enter>` -- Follow/Create wiki link.
- `<Shift-Enter>` -- Split and follow/create wiki link.
- `<Ctrl-Enter>` -- Vertical split and follow/create wiki link.
- `<Backspace>` -- Go back to parent(previous) wiki link.
- `<Tab>` -- Find next wiki link.
- `<Shift-Tab>` -- Find previous wiki link.

#### Advanced key bindings

Refer to the complete documentation at `:h vimwiki-mappings` to see many
more bindings.

## Commands

- `:Vimwiki2HTML` -- Convert current wiki link to HTML.
- `:VimwikiAll2HTML` -- Convert all your wiki links to HTML.
- `:help vimwiki-commands` -- List all commands.
- `:help vimwiki` -- General vimwiki help docs.

## Changing Wiki Syntax

VimWiki currently ships with 3 syntaxes: VimWiki (default), Markdown
(markdown), and MediaWiki (media).

**NOTE:** Only the default syntax ships with a built-in HTML converter. For
Markdown or MediaWiki see `:h vimwiki-option-custom_wiki2html`. Some examples
and 3rd party tools are available [here](https://vimwiki.github.io/vimwikiwiki/Related%20Tools.html#Related%20Tools-External%20Tools).

If you would prefer to use either Markdown or MediaWiki syntaxes, set the
following option in your `.vimrc`:

```vim

let g:vimwiki_list = [{'path': '~/vimwiki/',
                      \ 'syntax': 'markdown', 'ext': '.md'}]

```

This option will treat all markdown files in your system as part of vimwiki (check `set filetype?`). Add
```vim
let g:vimwiki_global_ext = 0
```
to your `.vimrc` to restrict Vimwiki's operation to only those paths listed in `g:vimwiki_list`.
Other markdown files wouldn't be treated as wiki pages.
See [g:vimwiki_global_ext](https://github.com/vimwiki/vimwiki/blob/619f04f89861c58e5a6415a4f83847752928252d/doc/vimwiki.txt#L2631).

## Getting help

[GitHub issues](https://github.com/vimwiki/vimwiki/issues) are the primary
method for raising bug reports or feature requests.

Additional resources:

  - The IRC channel [#vimwiki](ircs://irc.libera.chat:6697/vimwiki) on irc.libera.chat
    - [Connect via webchat](https://web.libera.chat/?channels=#vimwiki)
    - Connect via Matrix/Element: [#vimwiki:libera.chat](https://matrix.to/#/#vimwiki:libera.chat)
  - Post to the [mailing list](https://groups.google.com/forum/#!forum/vimwiki).

## Helping VimWiki

VimWiki has a lot of users but only very few recurring developers or people
helping the community. Your help is therefore appreciated. Everyone can help!
See [#625](https://github.com/vimwiki/vimwiki/issues/625) for information on how you can help.

Also, take a look at [CONTRIBUTING.md](https://github.com/vimwiki/vimwiki/blob/master/CONTRIBUTING.md) and [design_notes.md](doc/design_notes.md)

----

## License

MIT License

Copyright (c) 2008-2010 Maxim Kim
              2013-2017 Daniel Schemala

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
