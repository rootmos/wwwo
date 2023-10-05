.PHONY: build
build:
	$(MAKE) -C src build

DESTDIR ?= /usr
PREFIX ?=
EXE_PREFIX ?= wwwo-

.PHONY: install
install: build
	install -sD "src/gen.exe" "$(DESTDIR)$(PREFIX)/bin/$(EXE_PREFIX)generator"

.PHONY: clean
clean:
	$(MAKE) -C src clean
