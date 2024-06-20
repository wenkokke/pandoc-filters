DIFF ?= diff --strip-trailing-cr -u
PANDOC ?= pandoc

.PHONY: test
test: sample.md title_case.lua
	@$(PANDOC) -C -L title_case.lua -t markdown sample.md \
		| $(DIFF) expected.md -
	@$(PANDOC) -C -L title_case.lua -t latex sample.md \
		| $(DIFF) expected.tex -

.PHONY: test-update
test-update: sample.md title_case.lua
	@$(PANDOC) -C -L title_case.lua -t markdown sample.md \
		> expected.md
	@$(PANDOC) -C -L title_case.lua -t latex sample.md \
		> expected.tex
