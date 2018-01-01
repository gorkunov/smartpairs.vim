"smartpairs.vim - Fantastic Vim selections
"
"Author: Alex Gorkunov <alex.gorkunov@cloudcastlegroup.com>
"Source repository: https://github.com/gorkunov/smartpairs.vim
"
"vim: set tabstop=4 softtabstop=4 shiftwidth=4 expandtab

"avoid installing twice
if exists('g:loaded_smartpairs')
    finish
endif
"check if debugging is turned off
if !exists('g:smartpairs_debug')
    let g:loaded_smartpairs = 1
end

if !exists('g:smartpairs_maxdepth')
    let g:smartpairs_maxdepth = 20
end

"combinate 'i' and 'a' modes in one way
"enabled by default
if !exists('g:smartpairs_uber_mode')
    let g:smartpairs_uber_mode = 1
end

"start selection from word
"disabled by default
if !exists('g:smartpairs_start_from_word')
    let g:smartpairs_start_from_word = 0
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

"Also we use specal markers for several symbols combination:
" '/>' -> 'b'
" '</' -> 'c'

let s:all_targets = keys(s:targets) + values(s:targets)

"deluxe magic: use this to get selected text but keep safe all registers
function! s:GetSelection()
    try
        let cb_save = &clipboard
        set clipboard-=unnamed clipboard-=unnamedplus
        let tmp = @@
        execute "normal! \egv\"\"y"
        return @@
    finally
        let @@ = tmp
        let &clipboard = cb_save
        execute "normal! \egv"
    endtry
endfunction

"stack pairs functions
"push new symbol to stack
function! s:InsertToStack(target, col)
    let s:stops_str = a:target . s:stops_str
    call insert(s:stops, { 'symbol': a:target, 'line': s:line, 'col': a:col })
endfunction

function! s:ReturnToStack(stop)
    let s:stops_str = s:stops_str . a:stop.symbol
    call add(s:stops, a:stop)
endfunction

"remove last symbol from stack
function! s:RemoveLastFromStack()
    let s:stops_str = s:stops_str[:-2]
    call remove(s:stops, -1)
endfunction

"get first unpair symbol from stack
"warning: this function also removes unimportant symbols from stack
function! s:GetFromStack()
    if strchars(s:stops_str) > 0
        let ch = s:stops_str[strchars(s:stops_str) - 1]
        "remove useless symbol from stack (or end of opened tag)
        if ch == '_' || ch == 'e'
            "if this is end of opened tag then save end position to the head of tag
            "It helps us to fix wrong vim selection for some cases
            "see tests #43-#44
            if ch == 'e'
                "first of all we find head of tag 't'
                "it always present in the stask if we have 'e'
                let pos = strchars(s:stops_str) - 2
                while 1
                    let ch = s:stops_str[pos]
                    if ch == 't' | break | endif
                    let pos -= 1
                endwhile
                "then save end position to the head
                "it uses in the ApplyPairs method
                let s:stops[pos]['end_line'] = s:stops[-1].line
                let s:stops[pos]['end_col']  = s:stops[-1].col
            endif
            call s:RemoveLastFromStack()
            let stop = s:GetFromStack()
        else
            let stop = s:stops[-1]
            "reverse symbol converting (see above)
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

"replace matched text to _ e.g.
"((((abc)))) -> ___________
function! s:ReplaceAll(source, regex)
    let result = a:source
    while 1
        let str = substitute(result, a:regex, '\=repeat("_", strchars(submatch(1)))', 'g')
        if str == result
            break
        endif
        let result = str
    endwhile
    return result
endfunction

"replace cursor position to new position
function! s:GoTo(line, col)
    let col = a:col - 1
    if col == 0
      execute "normal! \e" . a:line . "G0"
    else
      execute "normal! \e" . a:line . "G0" . col . "l"
    endif
endfunction

function! s:GetCharByPosition(str, pos)
  let l = strchars(a:str)
  let rest = l - a:pos - 1
  if a:pos < 0 || rest < 0
    return ''
  else
    return substitute(a:str, '^.\{' . a:pos . '}\(.\).\{' . rest . '}', '\1', 'g')
  end
endfunction

"apply select/delete etc. e.g. run di" or va(
function! s:ApplyCommand(type, mod, symbol)
    let status = 1
    try
        execute "normal! \e" . a:type . a:mod . a:symbol
        "fix vim selection for va', va", va`:
        "remove extra spaces from left or right side.
        "check this (  'te_st') put cursor to _ and run va'
        if a:type == 'v' && a:mod == 'a' && index(['"', "'", '`'], a:symbol) > -1
            let selection = s:GetSelection()
            if selection[0] != a:symbol
                execute "normal! \egvof" . a:symbol . "o"
            endif
            if selection[strchars(selection) - 1] != a:symbol
                execute "normal! gvF" . a:symbol
            endif
        endif
    catch
        let status = 0
    endtry
    return status
endfunction

"main function: builds symbol stack and run selection function
function! s:SmartPairs(type, mod, ...)
    if a:0 > 0
        let str = getline(a:1)
        let cur = strchars(str)
    else
        let cur    = virtcol('.') - 1
        let str    = getline('.')
        let s:line = line('.')
        let s:start_line = s:line
        let s:type = a:type
        let s:mod  = a:mod
        "stack with current targets
        let s:stops = []
        let s:stops_str = ''
        let s:history = []

        "drop previous state
        if exists('s:laststop') | unlet s:laststop | endif
        if exists('s:lastselected') | unlet s:lastselected | endif
    endif
    "let str = substitute(str, '.\{1}$', '', 'g')
    "remove all escaped symbols from line
    let str = substitute(str, '\\.', '__', 'g')

    "and now process prepared line 
    while cur > 0
        let cur = cur - 1
        let ch = s:GetCharByPosition(str, cur)
        "skip if current symbol isn't a target
        if index(s:all_targets, ch) < 0
            continue
        endif

        let prev = s:GetCharByPosition(str, cur - 1)
        let next = s:GetCharByPosition(str, cur + 1)
        "skip => (ruby)
        if ch == '>' && cur > 0 && prev == '='
            continue
        endif

        "skip << (ruby)
        if ch == '<' && cur > 0 && (prev == '<' || next == '<')
            continue
        endif

        "workaround for tags <div></div> -> <...> c...>
        "                    <br/> -> <...b
        if ch == '>' && cur > 0 && prev == '/'
            let ch = 'b'
        elseif ch == '<' && next == '/' 
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
        let s:stops_str = s:ReplaceAll(s:stops_str, '\('.left.'[^'.left.']\{-}'.right.'\)')
    endfor
    " relpace matched tags
    " replace all <.../> e.g. <br/> ('b' is '/>' )
    let s:stops_str = s:ReplaceAll(s:stops_str, '\(<.\{-}b\)')
    " replace all opened tags to t___e
    " note: save end of tag as 'e' to fix vim wrong selection 
    let s:stops_str = substitute(s:stops_str, '\(<.\{-}>\)', '\="t".repeat("_", strchars(submatch(1)) - 2)."e"', 'g')
    " (see tests #43-#44)
    " replace all closed tags to r____ ('c' is '</')
    let s:stops_str = substitute(s:stops_str, '\(c.\{-}>\)', '\="r".repeat("_", strchars(submatch(1)) - 1)', 'g')
    " replace all matched tags <...>...</...> e.g. <div>...</div>
    let s:stops_str = s:ReplaceAll(s:stops_str, '\(t[^t]\{-}e[^e]\{-}r\)')
    call s:ApplyPairs()
endfunction

"apply select/delete/change for text between first pair symbol in the stack
function! s:ApplyPairs()
    "get first unpair symbol from stack
    let stop = s:GetFromStack()
    let current_position = { 'line': line('.'), 'col': virtcol('.') }
 
    "if this is opened symbol e.g. (, [, {
    if type(stop) == type({}) && (has_key(s:targets, stop.symbol) || stop.symbol == 't')
        "remove this symbol from stack
        call s:RemoveLastFromStack()
        "save line with this symbol
        let line = getline(stop.line)
        "apply command (select/delete etc)
        call s:GoTo(stop.line, stop.col)
        let status = s:ApplyCommand(s:type, s:mod, stop.symbol)

        "check whether something was changed
        "if we apply select then cursor position should be changed
        "if we apply delete/change then line should be changed
        "
        "But also changes/selection can be wrong. 
        "Currently we found several cases for tags. Apply for those
        "cases special trick: if after changes cursor is placed before
        "end of tag (<div _>) then last operation was wrong
        let ln = line('.')
        let col = virtcol('.')
        if !status || ((stop.symbol != 't' && stop.line == ln && stop.col == col && line == getline('.'))
            \ || (stop.symbol == 't' && (stop.end_line > ln || (stop.end_line == ln && stop.end_col > col)))) "trick for tags
            "undo last change/delete operation
            if s:type == 'c' || s:type == 'd'
                execute "normal! \eu"
            endif
            "replace cursor to the old position
            call s:GoTo(current_position.line, current_position.col)
            "restore last applied selection
            if s:type == 'v' && exists('s:laststop')
                let mod = s:mod
                if g:smartpairs_uber_mode
                    let mod = (mod == 'i') ? 'a' : 'i'
                endif
                call s:ApplyCommand('v', mod, s:laststop.symbol)
            endif
            "and apply operation again (with next pairs in the stack)
            call s:ApplyPairs()
        elseif s:type == 'v'
            "if operation was successful then save state (selection & symbol)
            "this state will be used for NextPairs operation
            let s:laststop = stop
            let s:lastselected = s:GetSelection()
            call add(s:history, { 'mod': s:mod, 'stop': stop })
        endif
    elseif s:line > 1 && s:start_line - s:line < g:smartpairs_maxdepth
        "if we nothing found in the stack 
        "or current symbol is closed e.g. ), ], }
        "then extend stack with line above current line
        let s:line = s:line - 1
        call s:SmartPairs(s:type, s:mod, s:line)
    elseif len(s:stops) > 0
        "if we can't extend stack anymore
        "but we have some symbols in the stack
        "then remove last blocker symbol from stack and
        "run ApplyPairs again
        call s:RemoveLastFromStack()
        call s:ApplyPairs()
    endif
endfunction

"apply next pairs from stack for current selection (extend selection)
"warning: this function is used only for selection mode (virtual)
"this command can be used with flag 'i' or 'a' its work like vi or va
"if no flag is given then previous selection flag is used or flag 'i'
"will be used for new selection 
function! s:NextPairs(...)
    "check flags from params
    if a:0 > 0
        let s:mod = a:1
    endif
    "get current selection
    let selected = s:GetSelection()

    "if we run NextPairs from SmartPairs/NextPairs then run next selection
    if exists('s:lastselected') && s:lastselected == selected
        let stop = s:laststop
        call s:GoTo(stop.line, stop.col)
        "combinate 'a' and 'i' modes 
        if g:smartpairs_uber_mode
            if s:mod == 'i'
                let s:mod = 'a'
                call s:ApplyCommand('v', s:mod, stop.symbol)
                let selected = s:GetSelection()
                if selected != s:lastselected
                    let s:lastselected = selected
                    call add(s:history, { 'mod': s:mod, 'stop': s:laststop })
                endif
            else
                call s:ApplyCommand('v', s:mod, stop.symbol)
                let s:mod = 'i'
                let old_selection = s:lastselected
                call s:ApplyPairs()
                let selected = s:GetSelection()
                if selected == old_selection
                    call s:NextPairs()
                endif
            endif
        else
            call s:ApplyCommand('v', s:mod, stop.symbol)
            call s:ApplyPairs()
        endif
    else
        if g:smartpairs_start_from_word && g:smartpairs_uber_mode && strchars(selected) == 1
            execute "normal! \eviw"
            let selected = s:GetSelection()
            if strchars(selected) > 1
                return
            endif
        endif
        "else run new selection for current line
        let mod = a:0 > 0 ? a:1 : 'i'
        call s:SmartPairs('v', mod)
    endif
endfunction

function! s:Revert()
    let length = len(s:history)
    if length > 1
        let stop = s:GetFromStack()
        let last1 = remove(s:history, -1)
        let last2 = remove(s:history, -1)
        if type(stop) == type({}) && stop == last1.stop
        else
            call s:ReturnToStack(last1.stop)
            if last1.stop == last2.stop
                let s:mod = 'a'
            elseif s:mod == 'a'
                let s:mod = 'i'
                call s:ReturnToStack(last2.stop)
            endif
            let s:laststop = last2.stop
        endif
        let selection = s:GetSelection()
        call s:NextPairs()
        let new_selection = s:GetSelection()
        if selection == new_selection
            call s:Revert()
        endif
    elseif length == 1
        let s:mod = 'i'
        call s:ApplyCommand('v', s:mod, s:history[0]['stop']['symbol'])
    endif
endfunction

function! s:ToggleUberMode()
    let g:smartpairs_uber_mode = !g:smartpairs_uber_mode
endfunction


"define commands for vim (for internal tests)
command! -nargs=1 SmartPairsI call s:SmartPairs(<f-args>, 'i')
command! -nargs=1 SmartPairsA call s:SmartPairs(<f-args>, 'a')
command! NextPairs  call s:NextPairs()
command! NextPairsI call s:NextPairs('i')
command! NextPairsA call s:NextPairs('a')

command! NextPairsToggleUberMode call s:ToggleUberMode()

"keymappings
"mapping for first run (found first pairs run command)
if !exists('g:smartpairs_key')
    let g:smartpairs_key = 'v'
end
for type in ['v', 'd', 'c', 'y']
    for mod in ['i', 'a']
        let cmd = 'nnoremap <silent> ' . type . mod . g:smartpairs_key . '  :<C-U>call <SID>SmartPairs("' . type . '", "' . mod .'")<CR>'
        if type == 'c' 
            let cmd .= 'a'
        endif
        silent exec cmd
    endfor
endfor

"mapping for next pairs (only for selection mode)
if !exists('g:smartpairs_nextpairs_key')
    let g:smartpairs_nextpairs_key = 'v'
end
silent exec 'vnoremap <silent> ' . g:smartpairs_nextpairs_key . '  :<C-U>call <SID>NextPairs()<CR>'

if !exists('g:smartpairs_nextpairs_key_i')
    let g:smartpairs_nextpairs_key_i = 'm'
end
silent exec 'vnoremap <silent> ' . g:smartpairs_nextpairs_key_i . '  :<C-U>call <SID>NextPairs("i")<CR>'

if !exists('g:smartpairs_nextpairs_key_a')
    let g:smartpairs_nextpairs_key_a = 'M'
end
silent exec 'vnoremap <silent> ' . g:smartpairs_nextpairs_key_a . '  :<C-U>call <SID>NextPairs("a")<CR>'

if !exists('g:smartpairs_revert_key')
    let g:smartpairs_revert_key = '<C-V>'
end
silent exec 'vnoremap <silent> ' . g:smartpairs_revert_key . '  :<C-U>call <SID>Revert()<CR>'
