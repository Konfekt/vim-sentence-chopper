*Vim-SentenceWrapper*
======

This Vim plug-in furnishes the map `gw` as an operator in normal mode, for example `gwip` will format a paragraph, and in visual mode that first normalizes [Unicode Homoglyphs](https://www.irongeek.com/homoglyph-attack-generator.php) and then puts each sentence onto a single line.
That is, lines are only broken at punctuation marks `.;:?!` for [better version control of prose](https://news.ycombinator.com/item?id=4642395) such as `markdown`, `tex` or `text` files.

For example, hitting `gwip` on
```
  Hello! How are you? Fine; after all.
```
turns it into
```
  Hello!
  How are you?
  Fine;
  after all.
```
