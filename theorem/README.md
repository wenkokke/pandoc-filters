![Requires Pandoc ^2.17](https://img.shields.io/badge/pandoc-%5E2.17-orange)

# theorem

A [Pandoc] filter to typeset theorems. For the LaTeX target, the filter generates [amsthm] environments. Otherwise, the filter typesets the theorems manually.

This filter renders, _e.g._, this Markdown...

```markdown
Theorem (Pirate ipsum).
: Cog pinnace broadside crack Jennys tea cup scourge of the seven seas
knave me Arr yardarm Davy Jones' Locker. Fore league cutlass shrouds six
pounders gun bilge rat lookout code of conduct pillage.
```

...as follows, using [GitHub Flavoured Markdown]...

---

<div id="theorem-pirate-ipsum" class="theorem">

**Theorem 1** (Pirate ipsum).

Cog pinnace broadside crack Jennys tea cup scourge of the seven seas
knave me Arr yardarm Davy Jones’ Locker. Fore league cutlass shrouds six
pounders gun bilge rat lookout code of conduct pillage.

</div>

---

...or as the following LaTeX...

```latex
\begin{theorem}[Pirate ipsum]

Cog pinnace broadside crack Jennys tea cup scourge of the seven seas
knave me Arr yardarm Davy Jones' Locker. Fore league cutlass shrouds six
pounders gun bilge rat lookout code of conduct pillage.

\end{theorem}
```

For non-LaTeX backends, the filter automatically numbers each theorem environment—using separate counters for theorems, lemmas, _etc_—and inserts a unique identifier for each theorem.

If you want the filter to insert a specific number, simply use it in the input syntax. For instance, the filter renders this Markdown...

```markdown
Theorem 3.1.5 (Pirate ipsum by @BenjaminHornigold).
: Crow's nest marooned Yellow Jack cutlass code of conduct rope's end
belay mizzenmast Spanish Main yard. Carouser broadside cog careen tender
wherry provost Arr red ensign chase guns. Strike colors furl man-of-war
keelhaul smartly dead men tell no tales red ensign crow's nest walk the
plank long clothes.
```

...as follows, using [GitHub Flavoured Markdown]...

---

<div id="theorem-pirate-ipsum-by--benjaminhornigold" class="theorem">

**Theorem 3.1.5** (Pirate ipsum by Hornigold (1680)).

Crow’s nest marooned Yellow Jack cutlass code of conduct rope’s end
belay mizzenmast Spanish Main yard. Carouser broadside cog careen tender
wherry provost Arr red ensign chase guns. Strike colors furl man-of-war
keelhaul smartly dead men tell no tales red ensign crow’s nest walk the
plank long clothes.

</div>

---

...or as the following LaTeX...

```latex
{
  \renewcommand{\thetheorem}{3.1.5}
  \begin{theorem}[Pirate ipsum by \citet{BenjaminHornigold}]

  Crow's nest marooned Yellow Jack cutlass code of conduct rope's end
  belay mizzenmast Spanish Main yard. Carouser broadside cog careen tender
  wherry provost Arr red ensign chase guns. Strike colors furl man-of-war
  keelhaul smartly dead men tell no tales red ensign crow's nest walk the
  plank long clothes.

  \end{theorem}
  \addtocounter{theorem}{-1}
}
```

The filter supports the following theorem keywords:

| Keyword      | LaTeX environment |
| ------------ | ----------------- |
| `Assumption` | `assumption`      |
| `Claim`      | `claim`           |
| `Definition` | `definition`      |
| `Example`    | `example`         |
| `Lemma`      | `lemma`           |
| `Proof`      | `proof`           |
| `Theorem`    | `theorem`         |



To use the filter with LaTeX, you'll need to setup [amsthm]-compatible theorems, *e.g.*, by include the following snippet in your preamble.

```latex
% file: include-in-header.tex
\usepackage{amsthm}
\newtheorem{assumption}{Assumption}
\newtheorem{claim}{Claim}
\newtheorem{definition}{Definition}
\newtheorem{example}{Example}
\newtheorem{lemma}{Lemma}
% proof is defined by amsthm
\newtheorem{theorem}{Theorem}
```

---

This filter was inspired by [@sliminality]'s [pandoc-theorem] filter.

[pandoc]: https://pandoc.org/
[github flavoured markdown]: https://github.github.com/gfm/
[definition lists]: https://pandoc.org/MANUAL.html#definition-lists
[amsthm]: https://www.ctan.org/pkg/amsthm
[@sliminality]: https://github.com/sliminality
[pandoc-theorem]: https://github.com/sliminality/pandoc-theorem
