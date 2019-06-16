CC = ocamlc
GEN_DEPS = magic-mime base64 yaml omd yojson calendar

VENV = $(shell pwd)/venv
HOST_PYTHON ?= python3
export PYTHON = $(VENV)/bin/python3
export PIP = $(VENV)/bin/pip

export LOCAL

upload: clean validate
	scp index.html www.rootmos.io:o/

validate: index.html
	tidy -quiet -errors --doctype=html5 index.html
	tidy -quiet -errors --doctype=html5 sounds.html

index.html: gen sounds.json github-activity.rootmos.commits.json
	@./$<

gen: utils.ml gen.ml
	ocamlfind $(CC) -linkpkg \
		-package $(shell tr ' ' ',' <<< "$(GEN_DEPS)") \
		-o $@ $^

clean:
	rm -rf gen github-activity *.cmi *.cmo *.html

fresh:
	rm -rf sounds.json github-activity.*.json

sounds.json: $(VENV)
	$(PYTHON) sounds.py > $@

github-activity.%.commits.json: $(VENV)
	$(PYTHON) github-activity.py $*

deps: $(VENV)
	opam install ocamlfind $(GEN_DEPS)
	$(PIP) install -r requirements.txt

$(VENV):
	$(HOST_PYTHON) -m venv $@

dev-env:
	opam install utop merlin odig

.PHONY: upload validate clean deps
