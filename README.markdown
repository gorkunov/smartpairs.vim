Build Status
-----
[![Status](https://travis-ci.org/gorkunov/smartpairs.vim.svg?branch=master)](https://travis-ci.org/gorkunov/smartpairs.vim)

About
-----
**smartpairs** allows you to forget about difficult keys combination like ```vi{``` or ```va"```.

Now you can use only one shortcut for all typical combinations. Even if you've already 
selected something you can easily correct selection by using smartpairs. 

Below is a screenshot showing how plugin works:

![smartpairs.vim](https://github.com/gorkunov/smartpairs.vim/raw/master/_assets/smartpairs.vim.gif)

Plugin searches first unpair symbol from the left of the current cursor
position and then runs target command with this symbol. When you press 
```v``` again plugin extends current selection to the next pairs.

Installation
------------
Use [pathogen.vim](https://github.com/tpope/vim-pathogen) for quick plugin installation. 

If you already have pathogen then put smartpairs into ~/.vim/bundle like this:

    cd ~/.vim/bundle
    git clone https://github.com/gorkunov/smartpairs.vim.git

Super fast selection
--------------------
By default smartpairs focuses on fast selection. You can position cursor to any place inside pairs objects 
such as () and just type `vv` and that's all. If you need to extend selection you just type again `v`. 
This is so simple and fast. Smarpairs also supports delete/yank operations see mappings below.
But again most of the time (99%) I use just one combination: `vv`.

Cancel last smartpairs selection
--------------------------------
You can use `Ctrl+Shift+v` keys combination to cancel last selection operation.

Mappings
--------

    vi* -> viv
    va* -> vav
    ci* -> civ
    ca* -> cav
    di* -> div
    da* -> dav
    yi* -> yiv
    ya* -> yav
    Where * is in <, >, ", ', `, (, ), [, ], {, } or t as tag
    
After ```v*``` commands you can press ```v``` again and selection will be extended to 
the next pairs.

Uber Mode (enabled by default)
------------------------------
Uber mode enables combination 'i' and 'a' modes. Let's see how it works:

We have a line (cursor position under _):

    ( 'te_st' )

Without *uber mode* our keys combination converts to:
    
    viv -> vi'
    v   -> vi(

With *uber mode*:
    
    viv -> vi'
    v   -> va'
    v   -> vi(
    v   -> va(

To enable *uber mode* set ```g:smartpairs_uber_mode = 1``` in your vimrc.

Advanced configuration
----------------------
For changing smartpairs keys binding add those lines to your .vimrc file:

```viml
"Key for running smartpairs in all modes (select/delete/change/yank)
"default is 'v'
let g:smartpairs_key = 'v'

"Key for running smartpairs in the selection mode 
"(extend current selection to the next pairs)
"default is 'v'
let g:smartpairs_nextpairs_key = 'v'

"Enable 'uber mode' (see above)
"default is 1
let g:smartpairs_uber_mode = 1

"Start selection from word
"If there is no regions then select word
"default is 0
let g:smartpairs_start_from_word = 1

"Key for running smartpairs in the selection mode
"for extending selection with IN-mod (like vi")
"default is 'm'
let g:smartpairs_nextpairs_key_i = 'm'

"Key for running smartpairs in the selection mode 
"for extending selection with ABOVE-mod (like va")
"default is 'M'
let g:smartpairs_nextpairs_key_a = 'M'

"Keys combination for canceling last smartpais selection
"default is '<C-V>' Ctrl+Shift+v
"under macvim you can use Cmd key e.g. <D-V> -> Cmd+Shift+v
let g:smartpairs_revert_key = '<C-V>'

"Smartpairs works only with 20 lines before cursor position
"but you can changes this limit:
let g:smartpairs_maxdepth = 20
```


License
-------
Smartpairs is released under the [wtfpl](http://sam.zoy.org/wtfpl/COPYING)
