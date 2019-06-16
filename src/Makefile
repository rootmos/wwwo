CC = ocamlc
GEN_DEPS = magic-mime base64 yaml omd calendar atdgen

.PHONY: install
install: gen

gen: utils.ml lenient_iso8601.ml sounds_t.mli sounds_t.ml sounds_j.mli sounds_j.ml gen.ml
	ocamlfind $(CC) -linkpkg \
		-package $(shell tr ' ' ',' <<< "$(GEN_DEPS)") \
		-o $@ $^

sounds_t.mli sounds_t.ml sounds_j.mli sounds_j.ml: sounds.atd
	atdgen -t $<
	atdgen -j $<

.PHONY: clean
clean:
	rm -rf gen *.cmi *.cmo sounds_*.ml

.PHONY: deps
deps:
	opam install ocamlfind $(GEN_DEPS)
