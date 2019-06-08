CC=ocamlc

upload: validate
	scp index.html www.rootmos.io:o/

validate: index.html
	tidy -quiet -errors --doctype=html5 $^

index.html: main
	@./$^ | tee $@

main: Main.ml
	$(CC) -o $@ $^

clean:
	rm -rf main *.cmi *.cmo index.html

.PHONY: upload validate clean
