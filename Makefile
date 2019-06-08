CC=ocamlc

index.html: main
	@./$^ | tee $@

main: Main.ml
	$(CC) -o $@ $^

clean:
	rm -rf main *.cmi *.cmo index.html

.PHONY: clean
