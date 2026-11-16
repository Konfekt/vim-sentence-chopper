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

let s:latexindent_options = '--modifylinebreaks'
      \ . ' ' . '--cruft=' . s:cruft_folder . s:shell_slash
let s:latexindent_yaml_options = 'modifyLineBreaks:oneSentencePerLine:manipulateSentences: 1'

let s:nul = has('win32') ? 'NUL' : '/dev/null'

"   Remove blanks after punctuation, but
"   recognize phrases inside parentheses, brackets or quotation marks
" - https://en.wikipedia.org/wiki/Quotation_mark#Unicode_code_point_table
" - https://en.wikipedia.org/wiki/Apostrophe#ASCII_encoding

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
unlet s:hyphenated_suffix s:alnum_suffix s:upper_word s:capitalized_word
      \ s:lower_word s:alphanum_word

" The delimiters may be buffer-local (Markdown adds '_*') and the punctuation
" marks may change at any time, so build the pattern per call and cache it.
let s:regex_cache = {}

function! s:regex() abort
  let open = get(b:, 'opening_delimiters', g:opening_delimiters)
  let close = get(b:, 'closing_delimiters', g:closing_delimiters)
  let key = join([open, close, g:punctuation_marks], "\n")
  if !has_key(s:regex_cache, key)
    let open_quote  = '[' . escape(open, '[]-\') . ']' . '{,3}'
    let close_quote = '[' . escape(close, '[]-\') . ']' . '{,3}'
    let punctuation = '[' . g:punctuation_marks . ']'
    " '?' and '!' split after one word. '.' splits only before a capital, so
    " "Fig. 1" and "vs. the" stay, and not after the abbreviations above.
    let s:regex_cache[key] = '%('
          \ . '%(' . open_quote . '|^)?' . s:simple_word
          \ . '%(' . close_quote . punctuation . '|' . punctuation . close_quote . ')'
          \ . '\zs\s+\ze\S'
          \ . '|'
          \ . '%(' . open_quote . '|^)?' . s:dot_word . s:not_abbr
          \ . '%(' . close_quote . '\.+|' . '\.+' . close_quote . ')'
          \ . '\zs\s+\ze' . open_quote . '[[:upper:]]'
          \ . ')'
  endif
  return s:regex_cache[key]
endfunction

function! sentences#chop(...) abort
  let pos = getpos('.')
  normal! m`
  if a:0 == 2
    " visual mode or :ChopSentences
    call s:chop(a:1, a:2)
  else
    " operator
    call s:chop("'[", "']")
  endif
  " The mark follows the cursor line, but is gone if that line was joined.
  if line('``') > 0
    normal! g``
  else
    call cursor(min([pos[1], line('$')]), pos[2])
  endif
endfunction

" A line number from a mark ("'[") or a line positioning command ("12G").
" line('12') is not line 12.
function! s:lnum(pos) abort
  let pos = substitute(a:pos, '\v^(\d+)G$', '\1', '')
  return pos =~# '^\d\+$' ? str2nr(pos) : line(pos)
endfunction

function! s:chop(o, c) abort
  let start = s:lnum(a:o)
  let end = s:lnum(a:c)
  if start < 1 || end < start
    return
  endif
  " Chopping changes the line count; track it to reindent the result.
  let height = line('$')

  if !get(b:, 'latexindent', g:latexindent)
    call s:split(start, end)
  else
    call s:latexindent(start, end)
  endif

  let end = max([start, end + line('$') - height])
  let equalprg = &l:equalprg
  try
    let &l:equalprg = ''
    exe 'silent keepjumps normal! ' . start . 'G=' . end . 'G'
  finally
    let &l:equalprg = equalprg
  endtry
endfunction

function! s:split(start, end) abort
  let end = a:end
  let gdefault = &gdefault
  try
    set gdefault&
    " A newline match runs past the last line. A blank line stops it.
    let guard = end < line('$')
    if guard
      call append(end, '')
    endif
    let height = line('$')
    exe 'silent keepjumps keeppatterns ' . a:start . ',' . end . 'substitute/\v(\S)\s*\n\s*(\S)/\1 \2/geI'
    let end -= height - line('$')
    if guard
      exe 'silent keepjumps ' . (end + 1) . 'delete _'
    endif
    exe 'silent keepjumps keeppatterns ' . a:start . ',' . end . 'substitute/\C\v' . s:regex() . '/\r/geI'
  finally
    let &gdefault = gdefault
  endtry
endfunction

function! s:latexindent(start, end) abort
  if !isdirectory(s:cruft_folder)
    call mkdir(s:cruft_folder, 'p')
  endif
  let formatexpr = &l:formatexpr
  let formatprg = &l:formatprg
  try
    let &l:formatprg = 'latexindent'
          \ . ' ' . s:latexindent_options . ' ' . get(b:, 'latexindent_options', g:latexindent_options)
          \ . ' ' . '--yaml=' . '"' . s:latexindent_yaml_options . ',' . get(b:, 'latexindent_yaml_options', g:latexindent_yaml_options) . '"'
          \ . ' ' . '2>' . s:nul
    let &l:formatexpr = ''
    let changenr = changenr()
    let error = ''
    try
      exe 'silent keepjumps normal! ' . a:start . 'Ggq' . a:end . 'G'
      if v:shell_error > 0
        let error = 'exited with status ' . v:shell_error
      endif
    catch
      let error = 'failed: ' . v:exception
    endtry

    if !empty(error)
      if changenr() != changenr
        silent undo
      endif
      redraw
      echomsg 'Formatprg "' . &l:formatprg . '" ' . error . '.'
    endif
  finally
    if has('win32') | redraw | endif
    let &l:formatprg = formatprg
    let &l:formatexpr = formatexpr
  endtry
endfunction
