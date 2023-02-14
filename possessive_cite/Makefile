DIFF ?= diff --strip-trailing-cr -u
PANDOC ?= pandoc
PRETTIER ?= npm x prettier --

# Testing the possessive_cite filter uses prettier to standardise the HTML
# output across Pandoc versions. By default, it runs the version of Prettier
# specified in package.json using NPM.

.PHONY: test
test: sample.md possessive_cite.lua
	@$(PANDOC) -C -L possessive_cite.lua -t markdown sample.md \
		| $(DIFF) expected.md -
	@$(PANDOC) -C -L possessive_cite.lua -t latex sample.md \
		| $(DIFF) expected.tex -

.PHONY: test-update
test-update: sample.md possessive_cite.lua
	@$(PANDOC) -C -L possessive_cite.lua -t markdown sample.md \
		> expected.md
	@$(PANDOC) -C -L possessive_cite.lua -t html sample.md \
		| $(PRETTIER) --parser=html \
		> expected.html
	@$(PANDOC) -C -L possessive_cite.lua -t latex sample.md \
		> expected.tex
