This Vim plug-in furnishes

- an operator mapping `gw` in normal mode, for example `gwip` operates on a paragraph,
- a mapping `gww` (and `gwgw`) in normal mode that operates on a single line,
- a mapping `gw` that operates on the visual selection, and
- a command `ChopSentences` that operates on given range (equal to the whole buffer if unspecified)

that put [each sentence onto a single line](https://sembr.org/).

That is, lines are only broken at punctuation marks `.?!` (customizable by the variable `g:punctuation_marks`) for [better version control of prose](https://news.ycombinator.com/item?id=4642395) in `markdown`, `tex` or other text files.

For best results in `TeX`, ensure that [latexindent](https://github.com/cmhughes/latexindent.pl) is installed and the folder that contains its executable is listed in `$PATH` (respectively in `%PATH%` on Microsoft Windows).
This formatter will also distinguish `TeX` markup from prose to preserve syntactic line breaks.

# Usage

For example, hitting `gwip` on

```
  Hello! How are you? Fine. And you?
```

turns it into

```
  Hello!
  How are you?
  Fine.
  And you?
```

# Configuration

The variable `g:punctuation_marks` defines punctuation marks at which sentences are split up other than `.`;
it is by default set to

```vim
  let g:punctuation_marks = '?!'
```

The global variable `g:latexindent` and its buffer-local analog `b:latexindent` defines whether [latexindent](https://github.com/cmhughes/latexindent.pl) should be used;
by default, if available, `latexindent` is used in TeX (and [pandoc](https://github.com/vim-pandoc/vim-pandoc) files) only.
(That is, `b:latexindent` is enabled in all buffers of these file types.)

The global  variable `g:latexindent_options` (and its buffer-local analog `b:latexindent_options`) defines the command-line options passed to `latexindent` as listed by `latexindent -h`;
the buffer-local variable is undefined and the global variable is by default set to

```vim
  let g:latexindent_options = ''
```

The variable `g:latexindent_yaml_options` (and its buffer-local analog `b:latexindent_yaml_options`) defines the  [documented](http://ctan.uib.no/support/latexindent/documentation/latexindent.pdf) [YAML](https://en.wikipedia.org/wiki/YAML) options passed to `latexindent`;
the buffer-local variable is undefined and the global variable is by default set to

```vim
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
```

For example, to split up sentences also after `;` or `:`  (in addition to `.`), and put every sentence in parentheses onto its proper line, add to your `vimrc`

```vim
let g:latexindent_yaml_options = 'modifyLineBreaks:oneSentencePerLine:sentencesEndWith:'
       \ . 'other: \;|\:' . ';'
       \ . 'modifyLineBreaks:oneSentencePerLine:' . 'sentencesFollow:other: "\)"' . ','
       \ . 'modifyLineBreaks:oneSentencePerLine:' . 'sentencesBeginWith:other: [a-z]'
```

# Mappings

To change mappings, for example, to use `zy` instead of `gw`, add the lines

```vim
    nmap zy <plug>(ChopSentences)
    xmap zy <plug>(ChopSentences)
```

to your `vimrc`.

# Hints

To replace (or delete, or any other operation by Vim) up to the next punctuation mark, say `.` and `,;:!?`, add

```vim
onoremap <silent> . :<c-u>call search('\v\C%(%([\])''"[:space:]-][[:upper:][:lower:]]{2,}\|[[:digit:]]{3,}\|[ivx]{5,}\|[IVX]{5,}\|[\])''"])\zs[.]\|[,;:!?])%(\s+\|[\])''"])\S\|[.,;:!?]\s*$','W')<CR>
```

to your `vimrc`!
Then, for example, hitting `c.` will change and `d.` delete the text up to the next punctuation mark.
Say `c.` turns `That's*it, Sir.`, where `*` stands for the cursor position, into `That's*, Sir.`
This can be thought of as a counterpart to Vim's built-in `C` and `D` commands for prose.

To normalize [Unicode Homoglyphs](https://www.irongeek.com/homoglyph-attack-generator.php), for example, of white spaces and punctuation marks, before chopping sentences, see the Vim plug-in [vim-unicode-homoglyphs](https://github.com/Konfekt/vim-unicode-homoglyphs) that highlights and normalizes Unicode homoglyphs.

