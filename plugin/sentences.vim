scriptencoding utf-8

" LICENCE PUBLIQUE RIEN À BRANLER
" Version 1, Mars 2009
"
" Copyright (C) 2009 Sam Hocevar
" 14 rue de Plaisance, 75014 Paris, France
"
" La copie et la distribution de copies exactes de cette licence sont
" autorisées, et toute modification est permise à condition de changer
" le nom de la licence.
"
" CONDITIONS DE COPIE, DISTRIBUTON ET MODIFICATION
" DE LA LICENCE PUBLIQUE RIEN À BRANLER
"
" 0. Faites ce que vous voulez, j’en ai RIEN À BRANLER.

if exists('g:loaded_sentences') || &cp
  finish
endif
let g:loaded_sentences = 1

let s:keepcpo         = &cpo
set cpo&vim

" ------------------------------------------------------------------------------
command! -range=% -bar WrapSentences call sentences#wrap(<line1>, <line2>)

nnoremap <silent> <plug>(WrapSentences) :<C-U>set  opfunc=sentences#wrap<CR>g@
xnoremap <silent> <plug>(WrapSentences) :<C-U>call sentences#wrap("'<", "'>")<CR>

if !hasmapto('<Plug>(WrapSentences)', 'n')
  silent! nmap <unique> gw <plug>(WrapSentences)
endif
if !hasmapto('<Plug>(WrapSentences)', 'x')
  silent! xmap <unique> gw <plug>(WrapSentences)
endif

if hasmapto('gw', 'n')
  onoremap     <SID>(underline) _
  silent! nmap <unique><expr> gww  'gw' . v:count1 . '<SID>(underline)'
  silent! nmap <unique>       gwgw gww
endif

" ------------------------------------------------------------------------------
let &cpo= s:keepcpo
unlet s:keepcpo
