CURRENT_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
ROOT := $(realpath $(CURRENT_DIR)/..)
BIN := $(ROOT)/bin
BUILDML := $(BIN)/buildml
INCLUDE := $(BIN)/include
GENERATOR := $(ROOT)/generator

README.md: README.in.md hello.pretty.html html.mli
	$(INCLUDE) $< $@

hello.pretty.html: hello.html
	tidy --indent yes --tidy-mark no -quiet -output $@ $<

hello.html: hello.ml
	$(BUILDML) -C $(GENERATOR) -m build
	$(GENERATOR)/src/hello.exe

.PHONY: clean
clean:
	rm -f *.html
