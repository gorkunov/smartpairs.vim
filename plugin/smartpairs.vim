"vim: set tabstop=4 softtabstop=4 shiftwidth=4 expandtab

" Avoid installing twice
"if exists('g:loaded_smartpairs')
    "finish
"endif
"let g:loaded_smartpairs = 1

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

function! s:Placeholder(str)
    let out = ''
    let i = 0
    while i < strlen(a:str)
        let out .= '_'
        let i += 1
    endwhile
    return out
endfunction

function! s:SmartPairs(type, mod, ...)
    let all = keys(s:pairs) + values(s:pairs)
    if a:0 > 0
        let str = getline(a:1)
        let cur = len(str)
    else
        let cur    = col('.') - 1
        let str    = getline('.')
        let s:line = line('.')
        let s:type = a:type
        let s:mod  = a:mod
        let s:stops = []
    endif
    let str = str[:cur - 1]
    let str = substitute(str, '\\.', '__', 'g')
    for ch in ['"', "'", '`']
        let str = substitute(str, '\('.ch.'.\{-}'.ch.'\)', '\=s:Placeholder(submatch(1))', 'g')
    endfor
    while cur >= 0
        let cur = cur - 1
        let ch = str[cur]
        if index(all, ch) < 0
            continue
        endif
        let lastunpair = len(s:stops) > 0 ? s:stops[-1].symbol : ''

        if lastunpair != '' && lastunpair == get(s:pairs, ch, '')
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
            if index(['<', '>'], lastunpair) > -1 && 
                        \ (index(['{', '[', '('], ch) > -1 || (index(['"', "'", '`'], ch) > -1 && s:CountChar(str[:cur - 1], ch) % 2 == 0))

                call remove(s:stops, -1)
            endif
            call add(s:stops, { 'symbol': ch, 'position': [s:line, cur + 1] })
        endif
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
