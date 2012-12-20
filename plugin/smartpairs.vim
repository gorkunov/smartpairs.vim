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

"split to (un)pair symbols
let s:pair_targets = ['<', '{', '[', '(']
let s:unpair_targets = ['"', "'", '`']


function! s:AddToStack(target, position)
    return add(s:stops, { 'symbol': a:target, 'position': [s:line, a:position] })
endfunction

function! s:RemoveLastFromStack()
    call remove(s:stops, -1)
endfunction

function! s:GetSelection() 
    let old_a=@a
    normal! "ay
    let text = @a
    let @a=old_a
    execute "normal! \egv"
    return text
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
    endif
    let str = str[:cur - 1]
    " remove all escaped symbols from line
    let str = substitute(str, '\\.', '__', 'g')
    " replace all closed substring from line e.g: "'foo' 'bar'" -> "_____ _____"
    " apply this only for unpair targets: ' " `
    " because pair targets have complicated logic
    for ch in s:unpair_targets
        let str = substitute(str, '\('.ch.'.\{-}'.ch.'\)', '\=repeat("_", strlen(submatch(1)))', 'g')
    endfor
    " and now process prepared line 
    while cur >= 0
        let cur = cur - 1
        let ch = str[cur]
        " skip if current char isn't a target
        if index(s:all_targets, ch) < 0
            continue
        endif
        " get last found target from stack
        let lastunpair = len(s:stops) > 0 ? s:stops[-1].symbol : ''

        " if current symbol is pair for last found target e.g. [ for ]
        if lastunpair != '' && lastunpair == get(s:targets, ch, '')
            " remove last target from stack
            call s:RemoveLastFromStack()
            " and apply tags workaround
            if ch == '<'
                " closed tag
                if str[cur + 1] == '/' 
                    call s:AddToStack('c', cur + 1)
                else
                    if len(s:stops) && s:stops[-1].symbol == 'c'
                        call s:RemoveLastFromStack()
                    else
                        call s:AddToStack('t', cur + 1)
                    endif
                endif
            endif
        else
            if lastunpair == '<' || lastunpair == '>'
                call s:RemoveLastFromStack()
            endif
            call s:AddToStack(ch, cur + 1)
        endif
    endwhile
    call s:ApplyPairs()
endfunction

let s:sreverted = 0
function! s:ApplyPairs()
    let stop = get(s:stops, 0)
    let line = getline('.')
 
    if type(stop) == type({}) && (has_key(s:targets, stop.symbol) || stop.symbol == 't')
        call remove(s:stops, 0)
        let prev_position = { 'line': line('.'), 'col': col('.') }
        execute "normal! " . stop.position[0] . "G" . stop.position[1] . "|"
        execute "normal! \e" . s:type . s:mod . stop.symbol
        if s:type == 'v'
            let selection = s:GetSelection()
            let s:sreverted = 0
            if strlen(selection) == 1 && selection == stop.symbol
                let s:sreverted = 1
                execute "normal! \e" . prev_position.line . "G" . prev_position.col . "|"
                call s:ApplyPairs()
            endif
        elseif line == getline('.')
            execute "normal! \e" . prev_position.line . "G" . prev_position.col . "|"
            call s:ApplyPairs()
        endif
    elseif s:line > 1 && s:start_line - s:line < g:smartpairs_maxdepth
        let s:line = s:line - 1
        call s:SmartPairs(s:type, s:mod, s:line)
    elseif s:type == 'v' && s:sreverted == 0
        "execute "normal! \egv"
    endif
endfunction

function! s:NextPairs()
    execute "normal! \egv"
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
