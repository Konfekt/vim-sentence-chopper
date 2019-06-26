" augroup epnSentenceWrap
"   autocmd!
"   if exists('##OptionSet')
"     autocmd OptionSet spell if &l:spell | call s:mappings() | endif
"   endif
"   autocmd BufWinEnter  *    if &l:spell | call s:mappings() | endif
" augroup end

onoremap <SID>(underline) _

" function! s:mappings() abort
  silent! nnoremap <unique><silent> gw :<C-U>set opfunc=sentencewrap#format<CR>g@
  silent! xnoremap <unique><silent> gw :<C-U>call sentencewrap#format(visualmode(), 1)<CR>

  silent! nmap <unique><expr> gww  'gw' . v:count1 . '<SID>(underline)'
  silent! nmap <unique>       gwgw gww
" endfunction
