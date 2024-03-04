scriptencoding utf-8

if g:latexindent && !executable('latexindent')
  echoerr 'sentence-chopper: Please ensure that the path to the folder that contains the latexindent executable is included in the value of the $PATH variable!'
  let g:latexindent = 0
endif

if !exists('g:latexindent_yaml_options')
  let g:latexindent_yaml_options = ''
       \ . 'modifyLineBreaks:items:ItemStartsOnOwnLine: 1' . ','
       \ . 'modifyLineBreaks:environments:'
              \ . 'BeginStartsOnOwnLine: 1' . ';'
              \ . 'BodyStartsOnOwnLine: 1' . ';'
              \ . 'EndStartsOnOwnLine: 1' . ';'
              \ . 'EndFinishesWithLineBreak: 1' . ';'
              \ . 'DBSFinishesWithLineBreak: 1' . ','
       \ . 'modifyLineBreaks:specialBeginEnd:displayMath:'
             \ . 'SpecialBeginStartsOnOwnLine: 1' . ';'
             \ . 'SpecialBodyStartsOnOwnLine: 1' . ';'
             \ . 'SpecialEndStartsOnOwnLine: 1' . ';'
             \ . 'SpecialEndFinishesWithLineBreak: 1' . ','
       \ . 'modifyLineBreaks:specialBeginEnd:displayMathTeX:'
             \ . 'SpecialBeginStartsOnOwnLine: 1' . ';'
             \ . 'SpecialBodyStartsOnOwnLine: 1' . ';'
             \ . 'SpecialEndStartsOnOwnLine: 1' . ';'
             \ . 'SpecialEndFinishesWithLineBreak: 1' . ','
endif
if !exists('g:latexindent_options') | let g:latexindent_options = '' | endif

let s:shell_slash = exists('+shellslash') && !&shellslash ? '\' : '/'
let s:cruft_folder = fnamemodify(tempname(), ':p:h') . s:shell_slash . 'latexindent'
if !isdirectory(s:cruft_folder) | call mkdir(s:cruft_folder, 'p') | endif

let s:latexindent_options = '--modifylinebreaks'
      \ . ' ' . '--cruft=' . s:cruft_folder . s:shell_slash
let s:latexindent_yaml_options = 'modifyLineBreaks:oneSentencePerLine:manipulateSentences: 1'

let s:nul = has('win32') ? 'NUL' : '/dev/null'

function! sentences#chop(...) abort
  normal! m`

  if a:0 == 2
    " visual mode
    let open  = a:1
    let close = a:2
  else
    " normal mode
    let open  = "'["
    let close = "']"
  endif

  call s:chop(open, close)

  normal! g``
endfunction

"   Remove blanks after punctuation, but
"   recognize phrases inside parentheses, brackets or quotation marks
" - https://en.wikipedia.org/wiki/Quotation_mark#Unicode_code_point_table
" - https://en.wikipedia.org/wiki/Apostrophe#ASCII_encoding

let s:open_quote  = '[\[(''"„“«»‚‘‹›]'
let s:close_quote = '[\])''"“”«»‘’‹›]'

let s:hyphenated_suffix = '%([-/''`’][[:upper:]]?[[:lower:]]+)*'.'[''`’]?'
let s:upper_word        = '[[:upper:]]{2,}'.s:hyphenated_suffix
let s:capitalized_word  = '[[:upper:]][[:lower:]]{2,}'.s:hyphenated_suffix
let s:lower_word        = '[[:lower:]]+'.s:hyphenated_suffix

let s:simple_word = '%('.s:upper_word.'|'.s:capitalized_word.'|'.s:lower_word.'|'.'[[:digit:]]+'.')'
let s:dot_word  = '%('.s:upper_word.'|'.s:capitalized_word.'|'.s:lower_word.'|'.'[[:digit:]]{3,}'.')'

let s:punctuation = '['.g:punctuation_marks.']'

" Use striter regex for . than for other punctuation markers such as ,;:? to
" avoid detecting ordinal numbers as end of sentence
let s:regex = '%('.s:open_quote.'|^)?'. '%(' .
      \ s:simple_word.'%('.s:close_quote.'?'.s:punctuation.'|'.s:punctuation.s:close_quote.'{,3}'.')' . '|' .
      \ s:simple_word.s:close_quote.'?'.' '.s:dot_word.'%('.s:close_quote.'{,3}'.'[.]|[.]'.s:close_quote.'?'.')' . ')' .
      \ '\zs\s+\ze\S'

unlet s:open_quote s:close_quote s:hyphenated_suffix s:upper_word
            \ s:capitalized_word s:lower_word s:simple_word s:dot_word

function! s:chop(o,c) abort
  let o = a:o
  let c = a:c

  if !get(b:, 'latexindent', g:latexindent)
    let gdefault = &gdefault
    set gdefault&

    " convert line positioning commands to line ranges
    let o = substitute(o, '\(\d\+\)G$', '\1', '')
    let c = substitute(c, '\(\d\+\)G$', '\1', '')

    let subst = '\v([^\n])\n([^\n])/\1 \2'
    exe 'silent keepjumps keeppatterns ' . o . ',' . c . 'substitute/' . subst . '/geI'
    let subst = '\C\v' . s:regex . '/\r'
    exe 'silent keepjumps keeppatterns ' . o . ',' . c . 'substitute/' . subst . '/geI'

    let &gdefault = gdefault
  else
    try
      let formatexpr = &l:formatexpr
      let formatprg = &l:formatprg

      let &l:formatprg = 'latexindent'
              \ . ' ' . s:latexindent_options . ' ' . get(b:, 'latexindent_options', g:latexindent_options)
              \ . ' ' . '--yaml=' . '"' . s:latexindent_yaml_options . ',' . get(b:, 'latexindent_yaml_options', g:latexindent_yaml_options) . '"'
              \ . ' ' . '2>' . s:nul
      let &l:formatexpr = ''
      exe 'silent keepjumps normal! ' . o . 'gq' . c

      " error handling
      if v:shell_error > 0
        silent undo
        redraw
        echomsg 'Formatprg "' . &l:formatprg . '" exited with status ' . v:shell_error . '.'
      endif
      " end of error handling
    finally
      if has('win32') | redraw | endif
      let &l:formatprg = formatprg
      let &l:formatexpr = formatexpr
    endtry
  endif

  let equalprg = &l:equalprg
  let equalprg = ''
  exe 'silent keepjumps normal! ' . o . '=' . c
  let &l:equalprg = equalprg
endfunction
