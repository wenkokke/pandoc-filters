DIFF ?= diff --strip-trailing-cr -u
PANDOC ?= pandoc
PRETTIER ?= npm x prettier --

# Testing the embed_pdf filter uses prettier to standardise the HTML
# output across Pandoc versions. By default, it runs the version of Prettier
# specified in package.json using NPM.

.PHONY: test
test: sample.md embed_pdf.lua
	@$(PANDOC) -L embed_pdf.lua -t html sample.md \
		| $(PRETTIER) --parser=html \
		| $(DIFF) expected.html -
	@$(PANDOC) -L embed_pdf.lua -t latex sample.md \
		| $(DIFF) expected.tex -

.PHONY: test-update
test-update: sample.md embed_pdf.lua
	@$(PANDOC) -L embed_pdf.lua -t html sample.md \
		| $(PRETTIER) --parser=html \
		> expected.html
	@$(PANDOC) -L embed_pdf.lua -t latex sample.md \
		-o expected.tex
