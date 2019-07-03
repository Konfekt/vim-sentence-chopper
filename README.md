This Vim plug-in furnishes

- an operator mapping `gw` in normal mode, for example `gwip` operates on a paragraph,
- a mapping `gww` (and `gwgw`) in normal mode that operates on a single line,
- a mapping `gw` that operates on the visual selection, and
- a command `WrapSentences` that operates on given range (equal to the whole buffer if unspecified)

that put each sentence onto a single line.

That is, lines are only broken at punctuation marks `.;:?!` for [better version control of prose](https://news.ycombinator.com/item?id=4642395) such as `markdown`, `tex` or `text` files.

# Usage

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

# Configuration

To change mappings, for example, to use `zy` instead of `gw`, add the lines

```vim
    nmap zy <plug>(WrapSentences)
    xmap zy <plug>(WrapSentences)
```

to your `vimrc`.

# Related

To normalize [Unicode Homoglyphs](https://www.irongeek.com/homoglyph-attack-generator.php), for example, of white spaces and punctuation marks, before wrapping sentences, see the Vim plug-in [vim-unicode-homoglyphs](https://github.com/Konfekt/vim-unicode-homoglyphs) that highlights and normalizes Unicode homoglyphs.

