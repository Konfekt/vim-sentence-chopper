scriptencoding utf-8

if !exists('g:latexindent')
  let g:latexindent = executable('latexindent')
elseif g:latexindent && !executable('latexindent')
  echoerr 'sentence-chopper: Please ensure that the path to the folder that contains the latexindent executable is included in the value of the $PATH variable!'
  let g:latexindent = 0
endif

if !exists('g:latexindent_yaml_options')
  let g:latexindent_yaml_options = ''
endif
if !exists('g:latexindent_options')
  let g:latexindent_options = ''
endif

let s:cruft_folder = fnamemodify(tempname(), ':p:h')
let s:shell_slash = exists('+shellslash') && !&shellslash ? '\' : '/'

let s:latexindent_options = '-modifylinebreaks'
      \ . ' ' . '-cruft=' . s:cruft_folder . s:shell_slash
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

function! s:chop(o,c) abort
  let o = a:o
  let c = a:c

  if !g:latexindent
    let gdefault = &gdefault
    set gdefault&

    let subst = '\v([^\n])\n([^\n])/\1 \2'
    exe 'silent keeppatterns' . o . ',' . c . 'substitute/' . subst . '/geI'
    " - skip dots after ordinal numbers,
    " - remove blanks after punctuation, but
    " - recognize phrases inside parentheses, braces, brackets or quotation marks
    let subst =
          \ '\C\v(%(%([^[:digit:]IVX]|[\])''"])[.]|[' . g:punctuation_marks . ']))%(\s+|([\])''"]))' 
          \ . '/'
          \ .'\1\2\r'
    exe 'silent keeppatterns' . o . ',' . c . 'substitute/' . subst . '/geI'

    let &gdefault = gdefault
  else
    let formatexpr = &l:formatexpr
    let formatprg = &l:formatprg

    let &l:formatprg = 'latexindent'
            \ . ' ' . s:latexindent_options . ' ' . g:latexindent_options
            \ . ' ' . '-yaml=' . '''' . s:latexindent_yaml_options . ',' . g:latexindent_yaml_options . ''''
            \ . ' ' . '2>' . s:nul
    let &l:formatexpr = ''
    exe 'silent normal! ' . o . 'gq' . c

    " error handling
    if v:shell_error > 0
      silent undo
      redraw
      echomsg 'Formatprg "' . &l:formatprg . '" exited with status ' . v:shell_error . '.'
    endif
    " end of error handling

    let &l:formatprg = formatprg
    let &l:formatexpr = formatexpr
  endif

  let equalprg = &l:equalprg
  let equalprg = ''
  exe 'silent keepjumps normal! ' . o . '=' . c
  let &l:equalprg = equalprg
endfunction
