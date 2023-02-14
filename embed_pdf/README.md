![Requires Pandoc ^3.0.1](https://img.shields.io/badge/pandoc-%5E3.0.1-orange)

# embed_pdf

A [Pandoc] filter to typeset embedded PDFs in LaTeX and HTML.

This filter renders, _e.g._, this Markdown...

```markdown
![](sample.pdf){latex:pages="-" latex:addtotoc="{1, section, 1, Sample, sample:theorem}" html:title="The sample from the theorem filter" html:width="640" html:height="480"}
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

To use the filter with LaTeX, you'll need to include a snippet in your preamble to setup theorems, *e.g.*,

```latex
% file: include-in-header.tex
\usepackage{pdfpages}
```
