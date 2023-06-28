DIFF ?= diff --strip-trailing -u
PANDOC ?= pandoc
PRETTIER ?= npm x prettier --

# Testing the grammar filter uses prettier to standardise the HTML
# output across Pandoc versions. By default, it runs the version of Prettier
# specified in package.json using NPM.

.PHONY: test
test: sample.md grammar.lua
	@$(PANDOC) -L grammar.lua -t markdown sample.md \
		| $(DIFF) expected.md -
	@$(PANDOC) -L grammar.lua -t latex sample.md \
		| $(DIFF) expected.tex -

.PHONY: test-update
test-update: sample.md grammar.lua
	@$(PANDOC) -L grammar.lua -t markdown sample.md \
		> expected.md
	@$(PANDOC) -L grammar.lua -t html sample.md \
		| $(PRETTIER) --parser=html \
		> expected.html
	@$(PANDOC) -L grammar.lua -t latex sample.md \
		> expected.tex
