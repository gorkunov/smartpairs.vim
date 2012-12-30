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

Available commands
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
    
After v\* commands you also can press v again and script extends selection
to the next pairs.

Advanced configuration
----------------------

Build status
------------
Yep! We have a lot of tests! See spec folder!

[![Build Status](https://api.travis-ci.org/gorkunov/smartpairs.vim.png)](http://travis-ci.org/gorkunov/smartpairs.vim)
