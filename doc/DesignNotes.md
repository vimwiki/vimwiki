# Design Notes

This file is meant to document design decisions and algorithms inside vimwiki
which are too large for code comments, and not necessarily interesting to
users. Please create a new section to document each behavior.

## Formatting tables

In vimwiki, formatting tables occurs dynamically, when navigating between cells
and adding new rows in a table in the Insert mode, or statically, when pressing
`gqq` or `gqw` (which are mappings for commands `VimwikiTableAlignQ` and
`VimwikiTableAlignW` respectively) in the Normal mode. It also triggers when
leaving Insert mode, provided variable `g:vimwiki_table_auto_fmt` is set. In
this section, the original and the newer optimized algorithms of table
formatting will be described and compared.

### The older table formatting algorithm and why this is not optimal

Let's consider a simple example. Open a new file, say _tmp.wiki_, and create a
new table with command `VimwikiTable`. This should create a blank table.

```
|   |   |   |   |   |
|---|---|---|---|---|
|   |   |   |   |   |
```

Let's put the cursor in the first header column of the table, enter the Insert
mode and type a name, say _Col1_. Then press _Tab_: the cursor will move to the
second column of the header and the table will get aligned (in the context of
the table formatting story, words _aligned_ and _formatted_ are considered as
synonyms). Now the table looks as in the following snippet.

```
| Col1 |   |   |   |   |
|------|---|---|---|---|
|      |   |   |   |   |
```

Then, when moving cursor to the first data row (i.e. to the third line of the
table below the separator line) and typing anything here and there while
navigating using _Tab_ or _Enter_ (pressing this creates a new row below the
current row), the table shall keep formatting. Below is a result of such a
random edit.

```
| Col1 |       |   |       |          |
|------|-------|---|-------|----------|
|      | Data1 |   | Data2 |          |
|      |       |   |       | New data |
```

The lowest row gets aligned when leaving the Insert mode. Let's copy _Data1_
(using `viwy` or another keystroke) and paste it (using `p`) in the second data
row of the first column. Now the table looks mis-aligned (as we did not enter
the Insert mode).

```
| Col1 |       |   |       |          |
|------|-------|---|-------|----------|
|      | Data1 |   | Data2 |          |
| Data1     |       |   |       | New data |
```

This is not a big problem though, because we can put the cursor at _any_ place
in the table and press `gqq`: the table will get aligned.

```
| Col1  |       |   |       |          |
|-------|-------|---|-------|----------|
|       | Data1 |   | Data2 |          |
| Data1 |       |   |       | New data |
```

Now let's make real problems! Move the cursor to the lowest row and copy it
with `yy`. Then 500-fold paste it with `500p`. Now the table very long. Move
the cursor to the lowest row (by pressing `G`), enter the Insert mode, and try
a new random editing session by typing anything in cells with _Tab_ and _Enter_
navigation interleaves. The editing got painfully slow, did not?

The reason of the slowing down is the older table formatting algorithm. Every
time _Tab_ or _Enter_ get pressed down, all rows in the table get visited to
calculate a new alignment. Moreover, by design it may happen even more than
once per one press!

```vim
function! s:kbd_create_new_row(cols, goto_first)
  let cmd = "\<ESC>o".s:create_empty_row(a:cols)
  let cmd .= "\<ESC>:call vimwiki#tbl#format(line('.'))\<CR>"
  let cmd .= "\<ESC>0"
  if a:goto_first
    let cmd .= ":call search('\\(".s:rxSep()."\\)\\zs', 'c', line('.'))\<CR>"
  else
    let cmd .= (col('.')-1)."l"
    let cmd .= ":call search('\\(".s:rxSep()."\\)\\zs', 'bc', line('.'))\<CR>"
  endif
  let cmd .= "a"

  return cmd
endfunction
```

Function `s:kbd_create_new_row()` is called when _Tab_ or _Enter_ get pressed.
Formatting of the whole table happens in function `vimwiki#tbl#format()`. But
remember that leaving the Insert mode triggers re-formatting of a table when
variable `g:vimwiki_table_auto_fmt` is set. This means that formatting of the
whole table is called on all those multiple interleaves between the Insert and
the Normal mode in `s:kbd_create_new_row` (notice `\<ESC>`, `o`, etc.).

### The newer table formating algorithm

The newer algorithm was introduced to struggle against performance issues when
formatting large tables.

Let's take the table from the previous example in an intermediate state.

```
| Col1 |       |   |       |          |
|------|-------|---|-------|----------|
|      | Data1 |   | Data2 |          |
| Data1     |       |   |       | New data |
```

Then move the cursor to the first data row, copy it with `yy`, go down to the
mis-aligned line, and press `5p`. Now we have a slightly bigger mis-aligned
table.

```
| Col1 |       |   |       |          |
|------|-------|---|-------|----------|
|      | Data1 |   | Data2 |          |
| Data1     |       |   |       | New data |
|      | Data1 |   | Data2 |          |
|      | Data1 |   | Data2 |          |
|      | Data1 |   | Data2 |          |
|      | Data1 |   | Data2 |          |
|      | Data1 |   | Data2 |          |
```

Go down to the lowest, the 7th, data row and press `gq1`. Nothing happened.
Let's go to the second or the third data row and press `gq1` once again. Now
the table gets aligned. Let's undo formatting with `u`, go to the fourth row,
and press `gq1`. Now the table should look like in the following snippet.

```
| Col1 |       |   |       |          |
|------|-------|---|-------|----------|
|      | Data1 |   | Data2 |          |
| Data1     |       |   |       | New data |
|           | Data1 |   | Data2 |          |
|           | Data1 |   | Data2 |          |
|      | Data1 |   | Data2 |          |
|      | Data1 |   | Data2 |          |
|      | Data1 |   | Data2 |          |
```

What a peculiar command! Does using it make any sense? Not much, honestly.
Except it shows how the newer optimized table formatting algorithm works in the
Insert mode.

Indeed, the newer table formatting algorithm introduces a _viewport_ on a table.
Now, when pressing _Tab_ or _Enter_ in the Insert mode, only a small part of
rows are checked for possible formatting: two rows above the current line and
the current line itself (the latter gets preliminary shrunk with function
`s:fmt_row()`). If all three lines in the viewport are of the same length, then
nothing happens (case 1 in the example). If the second or the shrunk current
line is longer then the topmost line in the viewport, then the algorithm falls
back to the older formatting algorithm and the whole table gets aligned
(case 2). If the topmost line in the viewport is longer than the second
and the shrunk current line, then the two lowest lines get aligned according to
the topmost line (case 3).

Performance of the newer formatting algorithm should not depend on the height
of the table. The newer algorithm should also be consistent with respect to
user editing experience. Indeed, as soon as a table should normally be edited
row by row from the top to the bottom, dynamic formatting should be both fast
(watching only three rows in a table, re-formatting only when the shrunk
current row gets longer than any of the two rows above) and eager (a table
should look formatted on every press on _Tab_ and _Enter_). However, the newer
algorithm differs from the older algorithm when starting editing a mis-aligned
table in an area where mis-aligned rows do not get into the viewport: in this
case the newer algorithm will format the table partly (in the rows of the
viewport) until one of the being edited cells grows in length to a value big
enough to trigger the older algorithm and the whole table gets aligned. When
partial formatting is not desirable, the whole table can be formatted by
pressing `gqq` in the Normal mode.
