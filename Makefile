CC = ocamlc
DEPS = magic-mime base64 yaml omd yojson

export LOCAL

upload: clean validate
	scp index.html www.rootmos.io:o/

validate: index.html
	tidy -quiet -errors --doctype=html5 $^

index.html: main
	@./$^

main: Main.ml
	ocamlfind $(CC) -linkpkg \
		-package $(shell tr ' ' ',' <<< "$(DEPS)") \
		-o $@ $^

clean:
	rm -rf *.cmi *.cmo *.html

deps:
	opam install ocamlfind $(DEPS)

dev-env:
	opam install utop merlin odig

.PHONY: upload validate clean deps
