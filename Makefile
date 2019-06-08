CC=ocamlc
export LOCAL

upload: clean validate
	scp index.html www.rootmos.io:o/

validate: index.html
	tidy -quiet -errors --doctype=html5 $^

index.html: main
	@./$^

main: Main.ml
	ocamlfind $(CC) -linkpkg \
		-package magic-mime,base64 \
		-o $@ $^

clean:
	rm -rf *.cmi *.cmo index.html

.PHONY: upload validate clean
