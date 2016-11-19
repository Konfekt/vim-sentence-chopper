*Vim-SentenceWrapper*
======

This Vim plug-in furnishes the map `gw` (as operator, for example `gwip`, or on a visual selection) that turns one sentence into one line, breaks it only at punctuation marks `.;:?!` for [better version control of prose](https://news.ycombinator.com/item?id=4642395) such as `markdown`, `tex` or `text` files.

For example, hitting `gwip` on
```
  Hello! How are you? Fine; after all.
```
becomes
```
  Hello!
  How are you?
  Fine;
  after all.
```
