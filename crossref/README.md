![Requires Pandoc ^3.0.1](https://img.shields.io/badge/pandoc-%5E3.0.1-orange)

# crossref

A [Pandoc] filter to typeset cross-references.

This filter renders, _e.g._, this Markdown...

```markdown
# Cross-references? Who needs 'em. {#me}

```{#snippet}
Is this code? Not really.
```

But would you look at @snippet?

I love @me.
```

...as follows, using [GitHub Flavoured Markdown]...

---

# Cross-references? Who needs 'em. {#me}

``` {#snippet}
Is this code? Not really.
```

But would you look at [CodeBlock 1](#snippet)?

I love [Section 1](#me).

But what's this? I'm referencing @BenjaminHornigold? AGAIN?!

---

The filter must be run _before_ `--citeproc`, because it uses the same syntax and citeproc will issue warnings on unresolved citations.


[pandoc]: https://pandoc.org/
[github flavoured markdown]: https://github.github.com/gfm/
