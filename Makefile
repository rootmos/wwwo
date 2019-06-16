CC = ocamlc
GEN_DEPS = magic-mime base64 yaml omd yojson calendar

export ENV ?= dev
export WEBROOT ?= $(shell pwd)/webroot
PORT ?= 8080

VENV = $(shell pwd)/venv
HOST_PYTHON ?= python3
export PYTHON = $(VENV)/bin/python3
export PIP = $(VENV)/bin/pip

.PHONY: generate
generate: gen sounds.json github-activity.rootmos.commits.json
	@mkdir -p $(WEBROOT)/$(ENV)
	./$<
	tidy -quiet -errors --doctype=html5 $(wildcard $(WEBROOT)/$(ENV)/*.html)

.PHONY: serve
serve:
	$(PYTHON) -m http.server --directory=$(WEBROOT)/$(ENV) $(PORT)

gen: utils.ml gen.ml
	ocamlfind $(CC) -linkpkg \
		-package $(shell tr ' ' ',' <<< "$(GEN_DEPS)") \
		-o $@ $^

.PHONY: clean
clean:
	rm -rf gen github-activity *.cmi *.cmo *.html $(WEBROOT)

.PHONY: fresh
fresh:
	rm -rf sounds.json github-activity.*.json

sounds.json: $(VENV)
	$(PYTHON) sounds.py > $@

github-activity.%.commits.json: $(VENV)
	$(PYTHON) github-activity.py $*

.PHONY: deps
deps: $(VENV)
	opam install ocamlfind $(GEN_DEPS)
	$(PIP) install -r requirements.txt

$(VENV):
	$(HOST_PYTHON) -m venv $@

.PHONY: dev-env
dev-env:
	opam install utop merlin odig
