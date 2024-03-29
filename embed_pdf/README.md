![Requires Pandoc ^3.0.1](https://img.shields.io/badge/pandoc-%5E3.0.1-orange)

# embed_pdf

A [Pandoc] filter to typeset embedded PDFs in LaTeX and HTML.

This filter renders, _e.g._, this Markdown...

```markdown
![](sample.pdf){
  latex:includepdf:pages="-"
  latex:includepdf:addtotoc="{1, section, 1, Sample, sample:theorem}"
  html:attr:title="The sample from the theorem filter"
  html:attr:width="640"
  html:attr:height="480"
}
```

...as the following HTML...

```html
<embed
  src="sample.pdf"
  type="application/pdf"
  title="The sample from the theorem filter"
  width="640"
  height="480"
/>
```

...and the following LaTeX...

```latex
\includepdf[pages=-,addtotoc={1, section, 1, Sample, sample:theorem},]{sample.pdf}
```

To use the filter with LaTeX, you'll need import the [pdfpages] package, *e.g.*, by including a the following snippet in your preamble.

```latex
% file: include-in-header.tex
\usepackage{pdfpages}
```

[pandoc]: https://pandoc.org/
[github flavoured markdown]: https://github.github.com/gfm/
[pdfpages]: https://www.ctan.org/pkg/pdfpages
