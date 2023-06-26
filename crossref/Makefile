DIFF ?= diff --strip-trailing -u
PANDOC ?= pandoc
PRETTIER ?= npm x prettier --

# Testing the crossref filter uses prettier to standardise the HTML
# output across Pandoc versions. By default, it runs the version of Prettier
# specified in package.json using NPM.

.PHONY: test
test: sample.md crossref.lua
	@$(PANDOC) --top-level-division=section -L crossref.lua -C -t markdown sample.md \
		| $(DIFF) expected.md -
	@$(PANDOC) --top-level-division=section -L crossref.lua -C -t latex sample.md \
		| $(DIFF) expected.tex -

.PHONY: test-update
test-update: sample.md crossref.lua
	@$(PANDOC) --top-level-division=section -L crossref.lua -C -t markdown sample.md \
		> expected.md
	@$(PANDOC) --top-level-division=section -L crossref.lua -C -t html sample.md \
		| $(PRETTIER) --parser=html \
		> expected.html
	@$(PANDOC) --top-level-division=section -L crossref.lua -C -t latex sample.md \
		> expected.tex
