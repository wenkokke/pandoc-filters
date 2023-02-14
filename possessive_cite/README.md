# possessive_cite

A [Pandoc] filter to typeset possessive citations.

This filter renders, _e.g._, this Markdown...

```markdown
We all love @BenjaminHornigold's famous proof. But is it real? No. Probably not.
```

...as follows, using [GitHub Flavoured Markdown]...

---

We all love Hornigold's famous proof. But is it real? No. Probably not.

---

The filter must be run after `--citeproc`, and all citations must be fully resolved.

The filter currently inlines the author name for every target, including LaTeX, which might give inconsistent results when, *e.g.*, Pandoc and natbib disagree on the maximum number of author names to list before using *et al*. It is easy to adapt the code to output a command such as `\citepos`, see [this StackExchange answer](https://tex.stackexchange.com/a/125706):
```latex
\usepackage{natbib}
\usepackage{etoolbox}

\makeatletter

% make numeric styles use name format
\patchcmd{\NAT@test}{\else \NAT@nm}{\else \NAT@nmfmt{\NAT@nm}}{}{}

% define \citepos just like \citet
\DeclareRobustCommand\citepos
  {\begingroup
   % ...except with a different name format
   \let\NAT@nmfmt\NAT@posfmt
   \NAT@swafalse\let\NAT@ctype\z@\NAT@partrue
   \@ifstar{\NAT@fulltrue\NAT@citetp}{\NAT@fullfalse\NAT@citetp}}

\let\NAT@orig@nmfmt\NAT@nmfmt
\def\NAT@posfmt#1{\NAT@orig@nmfmt{#1's}}

\makeatother
```
However, this is not supported by [natbib], and requiring this snippet to be present in the preamble is, unfortunately, quite brittle.

[natbib]: https://www.ctan.org/pkg/natbib
