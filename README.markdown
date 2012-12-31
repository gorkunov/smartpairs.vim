About
-----
**smartpairs** allows you forget about difficult keys combination like ```vi{``` or ```va"```.

Now you can use only one shortcut for all typical combinations. Even if you've already 
selected something you can easily fix selection by using smartpairs. 

Below is a screenshot showing how plugin works:

![smartpairs.vim](https://github.com/gorkunov/smartpairs.vim/raw/master/_assets/smartpairs.vim.gif)

Plugin searches first unpair symbol from the left of the current cursor
position and then runs target command with this symbol. When you press 
```v``` again plugin extend current selection by next pairs.

Installation
------------
Use [pathogen.vim](https://github.com/tpope/vim-pathogen) for quick plugin installation. 

If you already have pathogen then put smartpairs into ~/.vim/bundle like this:

    cd ~/.vim/bundle
    git clone https://github.com/gorkunov/smartpairs.vim.git

Mappings
------------------
By default smartpairs focuses on selection command but it also supports delete/change/yank.

Commands list:

    vi* -> viv
    va* -> vav
    ci* -> civ
    ca* -> cav
    di* -> div
    da* -> dav
    ya* -> yiv
    ya* -> yav
    Where * is in <, >, ", ', `, (, ), [, ], {, } or t as tag
    
After v\* commands you can press v again and selection will be extended to 
the next pairs.

Advanced configuration
----------------------
For changing smartpairs keys binding add those lines to your .vimrc file:

```viml
"Key for running smartpairs in all modes (select/delete/change/yank)
"default is 'v'
let g:smartpairs_key = 'v'

"Key for running smartpairs in the selection mode 
"(extend current selection to the next pair)
"default is 'v'
let g:smartpairs_nextpairs_key = 'v'

"Key for running smartpairs in the selection mode
"for extending selection with IN-mod (like vi")
"default is 'z'
let g:smartpairs_nextpairs_key_i = 'z'

"Key for running smartpairs in the selection mode 
"for extending selection with ABOVE-mod (like va")
"default is 'Z'
let g:smartpairs_nextpairs_key_a = 'Z'

"Smartpairs looks only 20 lines before cursor position
"but you can changes this limit:
let g:smartpairs_maxdepth = 20
```

Build status
------------
Yep! We have a lot of tests! See spec folder!

[![Build Status](https://api.travis-ci.org/gorkunov/smartpairs.vim.png)](http://travis-ci.org/gorkunov/smartpairs.vim)

License
-------
Smartpairs is released under the [wtfpl](http://sam.zoy.org/wtfpl/COPYING)
