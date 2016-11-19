scriptencoding uft-8

function! sentencewrap#format(type, ...) abort
  normal! m`

  if a:0 
    " invoked from Visual mode
    call s:format("'<", "'>")
  else
    " a:type = character- or block-wise range unsupported because neither gq
    " nor gw supports it.
    call s:format("'[", "']")
  endif

  normal! g``
endfunction

function! s:format(o,c) abort
  let o = a:o
  let c = a:c

  let tw=&l:textwidth
  let fo=&l:formatoptions
  setlocal textwidth=999999
  setlocal formatoptions&
  exe 'normal! ' . o . 'gw' . c
  let &l:textwidth=tw
  let &l:formatoptions=fo

  let gdefault = &gdefault
  set gdefault&

  let normalizations = [ [ ';', ';' ], [ ' ', ' ' ] ]
  for n in normalizations
    exe o . ',' . c . 'substitute/' . n[0] . '/' . n[1] . '/geI'
  endfor

  let subst = '\C\v(%(%([^[:digit:][:lower:][:upper:]]|[[:digit:]]{3,}|[[:lower:]]{2,}|[[:upper:]]{2,})[.]|[;:?!])\)?)\s+/\1\r'
  exe o . ',' . c . 'substitute/' . subst . '/geI'

  let &gdefault = gdefault

  exe 'normal! ' . o . '=' . c
endfunction
