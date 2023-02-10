DIFF ?= diff --strip-trailing-cr -u
PANDOC ?= pandoc

.PHONY: test
test: sample.md possessive_cite.lua
	@$(PANDOC) -C -L possessive_cite.lua -t markdown sample.md \
		| $(DIFF) expected.md -
	@$(PANDOC) -C -L possessive_cite.lua -t latex sample.md \
		| $(DIFF) expected.tex -

.PHONY: test-update
test-update: sample.md possessive_cite.lua
	@$(PANDOC) -C -L possessive_cite.lua -t markdown sample.md -o expected.md
	@$(PANDOC) -C -L possessive_cite.lua -t latex sample.md -o expected.tex
