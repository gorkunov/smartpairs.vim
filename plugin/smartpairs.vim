" About:
"
"  How often do you forget which keys you should use to select/modify strings
"  in the ' or " or in other pairs? I often use viw/ciw instead of vi'/vi" for
"  the first time because it easier for my fingers (but after that I remember
"  about vi'). This script allows you always use the same shortcut for all
"  cases. When you want to select string in the ' use viv. Do you want to
"  select all in the '()'? Use viv. All in the '[]'? Use viv.
"
" How it works:
"
"  Script searches first unpair symbol from the left of the current cursor
"  position and than runs target command with this symbol. You can use i or a
"  modifiers for commands too.
"
" Available commands:
"
"  vi* -> viv
"  va* -> vav
"  ci* -> civ
"  ca* -> cav
"  di* -> div
"  da* -> dav
"  ya* -> yiv
"  ya* -> yav
"  Where * is in <, >, ", ', `, (, ), [, ], {, } or t as tag
"
"  NOTE: After v* commands you also can press v again and script extends selection
"  to the next pairs.
"   
" Author: @gorkunov (alex.g@cloudcastlegroup.com)
"
"
let s:pairs = { '<' : '>', '"': '"', "'": "'", '`': '`', '(': ')', '[': ']', '{': '}' }
function! s:CountChar(str, char)
    let charcount = 0
    let pos = 0
    while pos < len(a:str)
        if a:str[pos] == a:char
            let charcount = charcount + 1
        endif
        let pos = pos + 1
    endwhile
    return charcount
endfunction

function! s:SmartPairs(type, mod, ...)
    let all = keys(s:pairs) + values(s:pairs)
    if a:0 > 0
        let str = getline(a:1)
        let cur = len(str)
    else
        let str    = getline('.')
        let cur    = col('.') - 1
        let s:line = line('.')
        let s:type = a:type
        let s:mod  = a:mod
        let s:stops = []
    endif
    let str = substitute(str, '\\.', '__', 'g')
    while cur >= 0
        let cur = cur - 1
        let ch = str[cur]
        if index(all, ch) < 0
            continue
        endif

        if len(s:stops) && get(s:pairs, ch, '') == s:stops[-1].symbol
            if index(['"', "'", '`'], ch) < 0
                call remove(s:stops, -1)
            else
                if s:CountChar(str[:cur - 1], ch) % 2 == 0
                    call remove(s:stops, -1)
                else
                    call add(s:stops, { 'symbol': ch, 'position': [s:line, cur + 1] })
                endif
            endif
            " tags workaround
            if ch == '<'
                " closed tag
                if str[cur + 1] == '/' 
                    call add(s:stops, { 'symbol': 'c', 'position': [s:line, cur + 1] })
                else
                    if len(s:stops) && s:stops[-1].symbol == 'c'
                        call remove(s:stops, -1)
                    else
                        call add(s:stops, { 'symbol': 't', 'position': [s:line, cur + 1] })
                    endif
                endif
            endif
        else
            call add(s:stops, { 'symbol': ch, 'position': [s:line, cur + 1] })
        endif
        "echo s:stops
    endwhile
    call s:ApplyPairs()
endfunction

function! s:ApplyPairs()
    let stop = get(s:stops, 0)

    if type(stop) == type({}) && (has_key(s:pairs, stop.symbol) || stop.symbol == 't')
        call remove(s:stops, 0)
        execute "normal! " . stop.position[0] . "G" . stop.position[1] . "|"
        execute "normal! \e" . s:type . s:mod . stop.symbol
    elseif s:line > 1
        let s:line = s:line - 1
        call s:SmartPairs(s:type, s:mod, s:line)
    else
        execute "normal! \egv"
    endif
endfunction

function! s:NextPairs()
    call s:ApplyPairs()
endfunction

command! -nargs=1 SmartPairsI call s:SmartPairs(<f-args>, 'i')
command! -nargs=1 SmartPairsA call s:SmartPairs(<f-args>, 'a')
command! NextPairs call s:NextPairs()

nnoremap <silent> viv :call <SID>SmartPairs('v', 'i')<CR>
nnoremap <silent> vav :call <SID>SmartPairs('v', 'a')<CR>
nnoremap <silent> div :call <SID>SmartPairs('d', 'i')<CR>
nnoremap <silent> dav :call <SID>SmartPairs('d', 'a')<CR>
nnoremap <silent> civ :call <SID>SmartPairs('c', 'i')<CR>a
nnoremap <silent> cav :call <SID>SmartPairs('c', 'a')<CR>a
nnoremap <silent> yiv :call <SID>SmartPairs('y', 'i')<CR>
nnoremap <silent> yav :call <SID>SmartPairs('y', 'a')<CR>
vnoremap <silent> v   :call <SID>NextPairs()<CR>
