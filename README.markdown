About
-----
smartpairs.vim allows you forget about difficult keys combination like ```vi{``` or ```va"```.
Now you can use only one shortcut for all typical combinations. Even if you've already 
selected something you can easily fix selection by using smartpairs.vim. 

This screenshot describes how it works:

![smartpairs.vim](https://github.com/gorkunov/smartpairs.vim/raw/master/_assets/smartpairs.vim.gif)

Script searches first unpair symbol from the left of the current cursor
position and then runs target command with this symbol.

Available commands
------------------
By default smartpairs.vim focuses on selection command but it also supports other commands: delete/change/yank.

Commands list:

```viml
  vi* -> viv
  va* -> vav
  ci* -> civ
  ca* -> cav
  di* -> div
  da* -> dav
  ya* -> yiv
  ya* -> yav
  Where * is in <, >, ", ', `, (, ), [, ], {, } or t as tag

  NOTE: After v\* commands you also can press v again and script extends selection
  to the next pairs.
```

Installation
------------

    cd ~/.vim/bundle
    git clone https://github.com/gorkunov/smartpairs.vim.git

   

Build status
------------
Yep! We have a lot of tests!
[![Build Status](https://api.travis-ci.org/gorkunov/smartpairs.vim.png)](http://travis-ci.org/gorkunov/smartpairs.vim)
