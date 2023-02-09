DIFF ?= diff --strip-trailing-cr -u
PANDOC ?= pandoc

.PHONY: test
test: sample.md theorem.lua
	@$(PANDOC) -L theorem.lua -C -t markdown sample.md \
		| $(DIFF) expected.md -
	@$(PANDOC) -L theorem.lua -C -t latex sample.md \
		| $(DIFF) expected.tex -

.PHONY: test-update
test-update: sample.md theorem.lua
	@$(PANDOC) -L theorem.lua -C -t markdown sample.md -o expected.md
	@$(PANDOC) -L theorem.lua -C -t latex sample.md -o expected.tex
