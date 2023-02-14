DIFF ?= diff --strip-trailing-cr -u
PANDOC ?= pandoc

.PHONY: test
test: sample.md theorem.lua
	@$(PANDOC) -C -L theorem.lua -t markdown sample.md \
		| $(DIFF) expected.md -
	@$(PANDOC) -C -L theorem.lua --natbib -t latex sample.md \
		| $(DIFF) expected.tex -

.PHONY: test-update
test-update: sample.md theorem.lua
	@$(PANDOC) -C -L theorem.lua -t markdown sample.md \
		> expected.md
	@$(PANDOC) -C -L theorem.lua --natbib -t latex sample.md \
		> expected.tex
