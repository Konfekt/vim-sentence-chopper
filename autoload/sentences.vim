scriptencoding uft-8

let s:latexindent = executable('latexindent') && g:latexindent

let s:cruft_folder = fnamemodify(tempname(), ':p:h')
let s:shell_slash = exists('+shellslash') && !&shellslash ? '\' : '/'

let s:latexindent_options = '-modifylinebreaks'
      \ . ' ' . '--cruft=' . s:cruft_folder . s:shell_slash
let s:latexindent_yaml_options = 'modifyLineBreaks:oneSentencePerLine:manipulateSentences: 1'

let s:nul = has('win32') ? 'NUL' : '/dev/null'

function! sentences#chop(...) abort
  normal! m`

  if a:0 == 2
    " invoked from Visual mode
    " character- or block-wise range unsupported because
    " neither gq nor gw supports it.
    let open  = a:1
    let close = a:2
  else
    let open  = "'["
    let close = "']"
  endif

  call s:chop(open, close)

  normal! g``
endfunction

function! s:chop(o,c) abort
  let o = a:o
  let c = a:c

  if !s:latexindent
    exe o . ',' . c . 'join'

    let gdefault = &gdefault
    set gdefault&

    let subst =
          \ '\C\v(%(%([^[:digit:]IVX]|[\])''"])[.]|[' . g:punctuation_marks . '])[[:space:]\])''"])' 
          \ . '/'
          \ .'\1\r'
    exe 'silent keeppatterns' . o . ',' . c . 'substitute/' . subst . '/geI'

    let &gdefault = gdefault
  else
    let formatprg = &l:formatprg

    let &l:formatprg = 'latexindent'
            \ . ' ' . s:latexindent_options . ' ' . g:latexindent_options
            \ . ' ' . '--yaml=' . '''' . s:latexindent_yaml_options . ',' . g:latexindent_yaml_options . ''''
            \ . ' ' . '2>' . s:nul
    exe 'silent normal! ' . o . 'gq' . c

    " error handling
    if v:shell_error > 0
      silent undo
      redraw
      echomsg 'Formatprg "' . &l:formatprg . '" exited with status ' . v:shell_error . '.'
    endif
    " end of error handling

    let &l:formatprg = formatprg
  endif

  let equalprg = &l:equalprg
  let equalprg = ''
  exe 'silent keepjumps normal! ' . o . '=' . c
  let &l:equalprg = equalprg
endfunction
