"vim: set tabstop=4 softtabstop=4 shiftwidth=4 expandtab

"avoid installing twice
"if exists('g:loaded_smartpairs')
    "finish
"endif
"check if debugging is turned off
if !exists('g:smartpairs_debug')
    let g:loaded_smartpairs = 1
end

if !exists('g:smartpairs_maxdepth')
    let g:smartpairs_maxdepth = 20
end

"define all searchable symbols aka *pairs*
let s:targets = { 
            \'<' : '>', 
            \'"' : '"', 
            \"'" : "'", 
            \'`' : '`', 
            \'(' : ')', 
            \'[' : ']', 
            \'{' : '}' }

let s:all_targets = keys(s:targets) + values(s:targets)


function! s:InsertToStack(target, position)
    let s:stops_str = a:target . s:stops_str
    call insert(s:stops, { 'symbol': a:target, 'position': [s:line, a:position] })
endfunction

function! s:RemoveLastFromStack()
    let s:stops_str = s:stops_str[:-2]
    call remove(s:stops, -1)
endfunction

function! s:GetFromStack()
    if strlen(s:stops_str) > 0
        let ch = s:stops_str[strlen(s:stops_str) - 1]
        if ch == "_"
            call s:RemoveLastFromStack()
            let stop = s:GetFromStack()
        else
            let stop = s:stops[-1]
            if ch == 'c'
                let stop.symbol = '<'
            elseif ch == 'b'
                let stop.symbol = '>'
            else
                let stop.symbol = ch
            endif
        endif
    endif
    if exists('stop')
        return stop
    else
        return 0
    end
endfunction

function! s:SmartPairs(type, mod, ...)
    if a:0 > 0
        let str = getline(a:1)
        let cur = len(str)
    else
        let cur    = col('.') - 1
        let str    = getline('.')
        let s:line = line('.')
        let s:start_line = s:line
        let s:type = a:type
        let s:mod  = a:mod
        "stack with current targets
        let s:stops = []
        let s:stops_str = ''
    endif
    let str = str[:cur - 1]
    " remove all escaped symbols from line
    let str = substitute(str, '\\.', '__', 'g')

    " and now process prepared line 
    while cur > 0
        let cur = cur - 1
        let ch = str[cur]
        " skip if current char isn't a target
        if index(s:all_targets, ch) < 0
            continue
        endif

        " workaround for tags <div></div> -> <...> c...>
        "                     <br/> -> <...b
        if ch == '>' && cur > 0 && str[cur - 1] == '/'
            let ch = 'b'
        elseif ch == '<' && str[cur + 1] == '/' 
            let ch = 'c'
        endif
        call s:InsertToStack(ch, cur + 1)
    endwhile
    " replace all matched pairs substring from line e.g: "('')" -> "____"
    " but skip < > because its have complex logic with tags
    for [left, right] in items(s:targets)
        if left == '<'
            continue
        elseif left == '['
            let left = '\['
        endif
        " repeat replacement while result has changes
        while 1
            let str = substitute(s:stops_str, '\('.left.'[^'.left.']\{-}'.right.'\)', '\=repeat("_", strlen(submatch(1)))', 'g')
            if str == s:stops_str
                break
            else
                let s:stops_str = str
            endif
        endwhile
    endfor
    " relpace matched tags
    " replace all <.../> e.g. <br/> ('p' is '/>' )
    while 1
        let str = substitute(s:stops_str, '\(<.\{-}/>\)', '\=repeat("_", strlen(submatch(1)))', 'g')
        if str == s:stops_str
            break
        else
            let s:stops_str = str
        endif
    endwhile
    " replace all opened tags to t____
    let s:stops_str = substitute(s:stops_str, '\(<.\{-}>\)', '\="t".repeat("_", strlen(submatch(1)) - 1)', 'g')
    " replace all closed tags to r____ ('c' is '</')
    let s:stops_str = substitute(s:stops_str, '\(c.\{-}>\)', '\="r".repeat("_", strlen(submatch(1)) - 1)', 'g')
    " replace all matched tags <...>...</...> e.g. <div>...</div>
    while 1
        let str = substitute(s:stops_str, '\(t[^t]\{-}r\)', '\=repeat("_", strlen(submatch(1)))', 'g')
        if str == s:stops_str
            break
        else
            let s:stops_str = str
        endif
    endwhile
    call s:ApplyPairs()
endfunction

function! s:ApplyPairs()
    let stop = s:GetFromStack()
 
    if type(stop) == type({}) && (has_key(s:targets, stop.symbol) || stop.symbol == 't')
        call s:RemoveLastFromStack()
        let prev_position = { 'line': line('.'), 'col': col('.') }
        let line = getline(stop.position[0])
        execute "normal! " . stop.position[0] . "G" . stop.position[1] . "|"
        execute "normal! \e" . s:type . s:mod . stop.symbol
        if  stop.position[0] == line('.') && stop.position[1] == col('.') && line == getline('.')
            execute "normal! \e" . prev_position.line . "G" . prev_position.col . "|"
            call s:ApplyPairs()
        else
            let s:laststop = stop
        endif
    elseif s:line > 1 && s:start_line - s:line < g:smartpairs_maxdepth
        let s:line = s:line - 1
        call s:SmartPairs(s:type, s:mod, s:line)
    elseif len(s:stops) > 0
        call s:RemoveLastFromStack()
        call s:ApplyPairs()
    endif
endfunction

function! s:NextPairs()
    let stop = s:laststop
    execute "normal! " . stop.position[0] . "G" . stop.position[1] . "|"
    execute "normal! \ev" . s:mod . stop.symbol
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
