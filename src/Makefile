CC = ocamlc
GEN_DEPS = magic-mime base64 yaml omd calendar atdgen

.PHONY: install
install: gen

define atd
$(1)_t.mli $(1)_t.ml $(1)_j.mli $(1)_j.ml
endef

gen: utils.ml lenient_iso8601.ml $(call atd, sounds) $(call atd, github) gen.ml
	ocamlfind $(CC) -linkpkg \
		-package $(shell tr ' ' ',' <<< "$(GEN_DEPS)") \
		-o $@ $^

%_t.mli %_t.ml %_j.mli %_j.ml: %.atd
	atdgen -t $<
	atdgen -j $<

.PHONY: clean
clean:
	rm -rf gen *.cmi *.cmo *_{j,t}.{ml,mli}

.PHONY: deps
deps:
	opam install ocamlfind $(GEN_DEPS)
