augroup epnSentenceWrap
  autocmd!
  if exists('##OptionSet')
    autocmd OptionSet spell if &l:spell | call s:mappings() | endif
  endif
  autocmd BufWinEnter  *    if &l:spell | call s:mappings() | endif
augroup end

onoremap <SID>(underline) _

function! s:mappings() abort
  nnoremap <buffer><silent> gw :<C-U>set opfunc=sentencewrap#format<CR>g@
  xnoremap <buffer><silent> gw :<C-U>call sentencewrap#format(visualmode(), 1)<CR>

  nmap <buffer><expr> gww  'gw' . v:count1 . '<SID>(underline)'
  nmap <buffer>       gwgw gww
endfunction
