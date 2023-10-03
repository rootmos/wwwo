GEN_DEPS = $(shell cat deps.compile)

CC = ocamlc
ifneq (,$(shell command -v gsed 2>/dev/null))
SED = gsed
else
SED = sed
endif

.PHONY: install
install: gen

.PHONY: scripts
scripts: practice.js
	cp "$^" $(TARGET)

define atd
$(1)_t.mli $(1)_t.ml $(1)_j.mli $(1)_j.ml
endef

define strip_versions
$(foreach d,$(1),$(shell echo "$(d)" | $(SED) 's#\(\.[0-9]\+\)\+$$##'))
endef

null :=
space := $(null) #
comma := ,

define packages
$(subst $(space),$(comma),$(call strip_versions,$(1)))
endef

gen: lenient_iso8601.ml \
	$(call atd, sounds) $(call atd, twitch) \
	$(call atd, github) $(call atd, practice) \
	$(call atd, gallery) $(call atd, project) \
	common.ml utils.ml html.ml gen.ml
	ocamlfind $(CC) -linkpkg \
		-package $(call packages,$(GEN_DEPS)) \
		-o $@ $^

%_t.mli %_t.ml %_j.mli %_j.ml: %.atd
	atdgen -t $<
	atdgen -j $<

.PHONY: clean
clean:
	rm -rf gen *.cmi *.cmo *_{j,t}.{ml,mli} .flag.*

.PHONY: deps
deps: .flag.opam-install

.flag.opam-install:
	opam install --yes $(shell cat deps)
	@touch $@
