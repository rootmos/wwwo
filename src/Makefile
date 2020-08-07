CC = ocamlc
GEN_DEPS = magic-mime base64 yaml omd calendar atdgen camomile

.PHONY: install
install: gen

define atd
$(1)_t.mli $(1)_t.ml $(1)_j.mli $(1)_j.ml
endef

gen: lenient_iso8601.ml \
	$(call atd, sounds) $(call atd, twitch) \
	$(call atd, github) \
	$(call atd, gallery) $(call atd, project) \
	common.ml utils.ml html.ml gen.ml
	ocamlfind $(CC) -linkpkg \
		-package $(shell echo "$(GEN_DEPS)" | tr ' ' ',') \
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
	opam install --yes ocamlfind $(GEN_DEPS)
	@touch $@
