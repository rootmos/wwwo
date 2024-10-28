CURRENT_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

.PHONY: build
build:
	$(MAKE) -C src build

.PHONY: doc
doc: build
	$(MAKE) -C src doc "OCAML_DOC_OUTPUT_DIR=$(CURRENT_DIR)/doc"

DESTDIR ?= /usr
PREFIX ?=
EXE_PREFIX ?= wwwo-

.PHONY: install
install: build
	install -sD "src/gen.exe" "$(DESTDIR)$(PREFIX)/bin/$(EXE_PREFIX)generator"

.PHONY: clean
clean:
	$(MAKE) -C src clean
	rm -rf doc
