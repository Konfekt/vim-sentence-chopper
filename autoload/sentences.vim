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

let s:opening_delimiters = get(b:, 'opening_delimiters', g:opening_delimiters)
let s:open_quote  = '[' . escape(s:opening_delimiters, '[]-\') . ']' . '{,3}'
let s:closing_delimiters = get(b:, 'closing_delimiters', g:closing_delimiters)
let s:close_quote = '[' . escape(s:closing_delimiters, '[]-\') . ']' . '{,3}'

let s:hyphenated_suffix = '%([-/''`’][[:upper:]]?[[:lower:]]+)*'.'[''`’]?'
let s:alnum_suffix      = '%([-/''`’][[:alnum:]]+)*'.'[''`’]?'
let s:upper_word        = '[[:upper:]]{2,}'.s:hyphenated_suffix
let s:capitalized_word  = '[[:upper:]][[:lower:]]{2,}'.s:hyphenated_suffix
let s:lower_word        = '[[:lower:]]+'.s:hyphenated_suffix
let s:alphanum_word     = '[[:alnum:]]*[[:alpha:]][[:alnum:]]*' . s:alnum_suffix

let s:simple_word = '%('
      \ . s:upper_word . '|'
      \ . s:capitalized_word . '|'
      \ . s:lower_word . '|'
      \ . s:alphanum_word . '|'
      \ . '[[:digit:]]+' . ')'
" One token before '.': at least two letters (so "J." / "e.g." stay), or a
" letter plus an apostrophe ("O'Brien"), or 3+ digits (so "1." / "3.14" stay).
let s:dot_word = '%('
      \ . '%([[:alpha:]][[:alnum:]]|[[:alnum:]][[:alpha:]])[[:alnum:]]*' . s:alnum_suffix . '|'
      \ . '[[:alpha:]]%([-/''`’][[:alnum:]]+)+[''`’]?' . '|'
      \ . '[[:digit:]]{3,}' . ')'
" Whole token only: "played." and "Mozart." still end a sentence.
" One lookbehind per length; Vim rejects mixed widths. "Hauptstr." is a suffix.
let s:not_abbr = ''
for s:abbr_group in [
      \ ['Mr', 'Dr', 'Ms', 'St', 'Jr', 'Sr', 'vs', 'cf',
      \  'Ud', 'Av', 'av', 'Pe', 'Pr', 'Me', 'MM', 'Hr', 'Fr', 'Nr', 'nr',
      \  'Bd', 'bd', 'ca', 'Jh', 'Fa', 'Hl', 'Co', 'ff', 'ed', 'SS', 'éd'],
      \ ['Mrs', 'Fig', 'fig', 'Inc', 'Ltd',
      \  'Sra', 'Dra', 'Uds', 'Lic', 'Ing', 'Arq', 'art', 'Art', 'cap', 'vol', 'pag', 'pág',
      \  'Dña', 'núm', 'Sig', 'Avv', 'Rag', 'cfr', 'sez', 'Mme', 'Ste', 'Cie', 'env',
      \  'Frl', 'Abb', 'Abs', 'bzw', 'vgl', 'ggf', 'Mio', 'Mrd', 'Tel', 'tel',
      \  'geb', 'Kap', 'Anm', 'Tab', 'Abt', 'Eng', 'Rev', 'obs', 'Exa',
      \  'med', 'jur', 'nat', 'max', 'min'],
      \ ['Prof', 'Srta', 'Dott', 'Geom', 'Arch', 'Mlle', 'Mmes', 'chap',
      \  'evtl', 'inkl', 'exkl', 'zzgl', 'gest', 'Hrsg', 'Aufl', 'bzgl', 'phil',
      \  'Dipl', 'kath', 'Ltda', 'Exmo', 'Exma', 'Ilmo', 'Ilma', 'págs'],
      \ ['Profa'],
      \ ]
  let s:abbr_parts = []
  for s:abbr in s:abbr_group
    call add(s:abbr_parts, '[^[:alpha:]]' . s:abbr)
    call add(s:abbr_parts, '^' . s:abbr)
  endfor
  let s:not_abbr .= '%(' . join(s:abbr_parts, '|') . ')@<!'
endfor
let s:not_abbr .= '%(Str|str)@<!'
unlet s:abbr_group s:abbr_parts s:abbr

let s:punctuation = '['.g:punctuation_marks.']'

" '?' and '!' split after one word. '.' splits only before a capital, so
" "Fig. 1" and "vs. the" stay, and not after the abbreviations above.
let s:regex = '%('
      \ . '%('.s:open_quote.'|^)?' . s:simple_word
      \ . '%('.s:close_quote.s:punctuation.'|'.s:punctuation.s:close_quote.')'
      \ . '\zs\s+\ze\S'
      \ . '|'
      \ . '%('.s:open_quote.'|^)?' . s:dot_word . s:not_abbr
      \ . '%('.s:close_quote.'\.+|'.'\.+'.s:close_quote.')'
      \ . '\zs\s+\ze' . s:open_quote . '[[:upper:]]'
      \ . ')'

unlet s:open_quote s:close_quote s:opening_delimiters s:closing_delimiters
      \ s:hyphenated_suffix s:alnum_suffix s:upper_word s:capitalized_word
      \ s:lower_word s:simple_word s:dot_word s:not_abbr s:punctuation

function! s:chop(o,c) abort
  let o = a:o
  let c = a:c

  if !get(b:, 'latexindent', g:latexindent)
    let gdefault = &gdefault
    set gdefault&

    " convert line positioning commands to line ranges
    let o = substitute(o, '\(\d\+\)G$', '\1', '')
    let c = substitute(c, '\(\d\+\)G$', '\1', '')

    " line('1') is not line 1; a numeric ChopSentences bound is already a number.
    let start = o =~# '^\d\+$' ? str2nr(o) : line(o)
    let end = c =~# '^\d\+$' ? str2nr(c) : line(c)
    if start >= 1 && end >= start
      " A newline match runs past the last line. A blank line stops it.
      let guard = end < line('$')
      if guard
        call append(end, '')
      endif
      let height = line('$')
      exe 'silent keepjumps keeppatterns ' . start . ',' . end . 'substitute/\v(\S)\s*\n\s*(\S)/\1 \2/geI'
      let end = end - (height - line('$'))
      if guard
        exe 'silent keepjumps ' . (end + 1) . 'delete _'
      endif
      exe 'silent keepjumps keeppatterns ' . start . ',' . end . 'substitute/\C\v' . s:regex . '/\r/geI'
    endif

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
  let &l:equalprg = ''
  exe 'silent keepjumps normal! ' . o . '=' . c
  let &l:equalprg = equalprg
endfunction
