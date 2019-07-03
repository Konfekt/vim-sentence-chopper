scriptencoding uft-8

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

  let tw=&l:textwidth
  let fo=&l:formatoptions
  setlocal textwidth=999999
  setlocal formatoptions&

  exe 'normal! ' . o . 'gw' . c

  let &l:textwidth=tw
  let &l:formatoptions=fo

  let gdefault = &gdefault
  set gdefault&

  let subst = '\C\v(%(%([^[:digit:][:lower:][:upper:]]|[[:digit:]]{3,}|[[:lower:]]{2,}|[[:upper:]]{2,})[.]|[;:?!])\)?)\s+/\1\r'
  exe o . ',' . c . 'substitute/' . subst . '/geI'

  let &gdefault = gdefault

  exe 'normal! ' . o . '=' . c
endfunction
