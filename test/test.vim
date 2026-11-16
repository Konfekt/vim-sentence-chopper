" Headless tests: vim -Nu NONE -es -S test/test.vim (or nvim --headless).
" Writes test/results.txt and exits non-zero on failure.
" vint: -ProhibitCommandRelyOnUser (mappings are exercised on purpose)
scriptencoding utf-8
let s:root = fnamemodify(expand('<sfile>:p'), ':h:h')
let &runtimepath = s:root . ',' . &runtimepath
filetype on
runtime plugin/sentences.vim

function! s:reset(lines) abort
  silent! bwipeout!
  enew!
  setlocal indentexpr= equalprg=
  call setline(1, a:lines)
  " Start a new undo block, as typing would.
  let &undolevels = &undolevels
endfunction

function! Test_basic() abort
  call s:reset(['Hello! How are you? I''m Fine. And you?'])
  ChopSentences
  call assert_equal(['Hello!', 'How are you?', 'I''m Fine.', 'And you?'], getline(1, '$'))
endfunction

function! Test_joins_and_keeps_abbreviations() abort
  call s:reset(['See Fig. 1 and Dr. Who', 'played. Then e.g. Mozart. End.', '', 'Next.'])
  1,2ChopSentences
  call assert_equal(['See Fig. 1 and Dr. Who played.', 'Then e.g. Mozart.', 'End.', '', 'Next.'], getline(1, '$'))
endfunction

function! Test_operator_and_line_mapping() abort
  call s:reset(['One. Two. Three.', 'Four. Five.', 'Six. Seven.'])
  normal 2Ggbb
  call assert_equal(['One. Two. Three.', 'Four.', 'Five.', 'Six. Seven.'], getline(1, '$'))
  call s:reset(['One. Two.', 'Three. Four.', '', 'Five. Six.'])
  normal 1Ggbip
  call assert_equal(['One.', 'Two.', 'Three.', 'Four.', '', 'Five. Six.'], getline(1, '$'))
  call s:reset(['One. Two.', 'Three. Four.', 'Five. Six.'])
  normal 1G2gbb
  call assert_equal(['One.', 'Two.', 'Three.', 'Four.', 'Five. Six.'], getline(1, '$'))
endfunction

function! Test_visual_mapping() abort
  call s:reset(['One. Two.', 'Three. Four.', 'Five. Six.'])
  normal 2GVgb
  call assert_equal(['One. Two.', 'Three.', 'Four.', 'Five. Six.'], getline(1, '$'))
endfunction

" Every resulting line is reindented, not just the original range.
function! Test_reindent_command_range() abort
  call s:reset(['One. Two. Three.', 'Four.'])
  setlocal indentexpr=4
  1ChopSentences
  call assert_equal(['    One.', '    Two.', '    Three.', 'Four.'], getline(1, '$'))
endfunction

function! Test_reindent_visual() abort
  call s:reset(['One. Two. Three.', 'Four.'])
  setlocal indentexpr=4
  normal 1GVgb
  call assert_equal(['    One.', '    Two.', '    Three.', 'Four.'], getline(1, '$'))
endfunction

function! Test_reindent_operator() abort
  call s:reset(['One. Two. Three.', 'Four.'])
  setlocal indentexpr=4
  normal 1Ggbb
  call assert_equal(['    One.', '    Two.', '    Three.', 'Four.'], getline(1, '$'))
endfunction

" Markdown adds '*' and '_' to the delimiters of its buffers, even when the
" plugin was first used in another buffer.
function! Test_markdown_delimiters_after_text_buffer() abort
  call s:reset(['A *b.* C.'])
  ChopSentences
  call assert_equal(['A *b.* C.'], getline(1, '$'))
  call s:reset(['This is *bold.* Next one.'])
  setfiletype markdown
  ChopSentences
  call assert_equal(['This is *bold.*', 'Next one.'], getline(1, '$'))
  call s:reset(['A *b.* C.'])
  ChopSentences
  call assert_equal(['A *b.* C.'], getline(1, '$'))
endfunction

function! Test_punctuation_marks_change() abort
  call s:reset(['One; two'])
  ChopSentences
  call assert_equal(['One; two'], getline(1, '$'))
  let saved = g:punctuation_marks
  let g:punctuation_marks = '?!;'
  try
    call s:reset(['One; two'])
    ChopSentences
    call assert_equal(['One;', 'two'], getline(1, '$'))
  finally
    let g:punctuation_marks = saved
  endtry
endfunction

function! Test_options_and_cursor_restored() abort
  call s:reset(['One. Two.', 'Three.'])
  set gdefault
  setlocal equalprg=cat
  call cursor(2, 3)
  ChopSentences
  call assert_true(&gdefault)
  call assert_equal('cat', &l:equalprg)
  call assert_equal([2, 3], [line('.'), col('.')])
  set gdefault&
endfunction

function! Test_latexindent() abort
  let saved = $PATH
  let $PATH = s:root . '/test/bin:' . $PATH
  try
    call s:reset(['One. Two.', 'Three. Four.'])
    let b:latexindent = 1
    setlocal formatprg=keep
    ChopSentences
    call assert_equal(['One.', 'Two.', 'Three.', 'Four.'], getline(1, '$'))
    call assert_equal('keep', &l:formatprg)

    call s:reset(['One. Two.'])
    let b:latexindent = 1
    let $FAKE_LATEXINDENT_FAIL = 1
    silent ChopSentences
    call assert_equal(['One. Two.'], getline(1, '$'))
  finally
    let $PATH = saved
    let $FAKE_LATEXINDENT_FAIL = ''
  endtry
endfunction

" Characters special inside a collection are taken literally.
function! Test_punctuation_marks_special_characters() abort
  let saved = g:punctuation_marks
  let g:punctuation_marks = '?-!'
  try
    call s:reset(['One - two? Three'])
    ChopSentences
    call assert_equal(['One - two?', 'Three'], getline(1, '$'))
  finally
    let g:punctuation_marks = saved
  endtry
endfunction

" latexindent wanted but missing: fall back to the built-in splitting.
function! Test_latexindent_missing_falls_back() abort
  let saved = $PATH
  let $PATH = s:root . '/test/empty-path-dir'
  try
    call s:reset(['One. Two.'])
    let b:latexindent = 1
    let msg = execute('ChopSentences')
    call assert_equal(['One.', 'Two.'], getline(1, '$'))
    call assert_match('latexindent not found', msg)
  finally
    let $PATH = saved
  endtry
endfunction

let s:results = []
let s:failed = 0
for s:test in sort(filter(split(execute('function /^Test_'), "\n"), 'v:val =~# ''^function Test_'''))
  let s:name = matchstr(s:test, 'Test_\w\+')
  let v:errors = []
  try
    call call(s:name, [])
  catch
    call add(v:errors, v:exception . ' @ ' . v:throwpoint)
  endtry
  if empty(v:errors)
    call add(s:results, 'ok   ' . s:name)
  else
    let s:failed += 1
    call add(s:results, 'FAIL ' . s:name)
    call extend(s:results, map(copy(v:errors), '''     '' . v:val'))
  endif
endfor
call add(s:results, s:failed ? s:failed . ' failed' : 'all passed')
call writefile(s:results, s:root . '/test/results.txt')
execute s:failed ? 'cquit!' : 'qall!'
