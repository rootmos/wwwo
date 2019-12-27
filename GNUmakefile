export ENV ?= dev
export WEBROOT ?= $(shell pwd)/webroot
PORT ?= 8080

BIN = $(shell pwd)/bin
META = $(shell pwd)/meta
VENV ?= $(shell pwd)/venv
HOST_PYTHON ?= $(shell command -v python3)
export PYTHON = $(VENV)/bin/python3
export PIP = $(VENV)/bin/pip

generate: build fa meta
	@mkdir -p $(WEBROOT)/$(ENV)
	GIT_REV=$(shell git rev-parse HEAD) ./src/gen

.PHONY: meta
meta: $(META)/sounds.json \
	$(META)/github-activity.rootmos.commits.json \
	$(META)/glenn.json \
	$(META)/silly.json \
	$(META)/projects.json

.PHONY: validate
validate:
	find $(WEBROOT)/$(ENV) -name "*.html" -exec $(BIN)/validate.sh {} \;

.PHONY: serve
serve:
	$(PYTHON) -m http.server --directory=$(WEBROOT)/$(ENV) $(PORT)

.PHONY: build
build: deps
	$(MAKE) -C src install

.PHONY: upload
upload:
	aws s3 cp --acl=public-read --recursive $(WEBROOT)/$(ENV) s3://rootmos-www

.PHONY: clean
clean:
	$(MAKE) -C src clean
	rm -rf $(WEBROOT) .flag.* $(VENV) $(META)

.PHONY: fresh
fresh:
	rm -rf $(META)

$(META)/sounds.json: .flag.deps $(BIN)/sounds.py
	@mkdir -p "$(dir $@)"
	$(PYTHON) $(BIN)/sounds.py > "$@"

$(META)/github-activity.%.commits.json: .flag.deps $(BIN)/github-activity.py
	@mkdir -p "$(dir $@)"
	$(PYTHON) $(BIN)/github-activity.py $* > "$@"

$(META)/%.json: .flag.deps $(BIN)/list.py
	@mkdir -p "$(dir $@)"
	$(PYTHON) $(BIN)/list.py --profile=do --prefix="$*" rootmos-static > "$@"

$(META)/projects.json: projects.json .flag.deps $(BIN)/projects.py
	@mkdir -p "$(dir $@)"
	$(PYTHON) $(BIN)/projects.py "$<" > "$@"

.PHONY: deps
deps: .flag.deps
.flag.deps: .flag.requirements.txt
	$(MAKE) -C src deps
	@touch $@

.flag.requirements%txt: requirements%txt | $(VENV)
	$(PIP) install -r $<
	@touch $@

$(VENV):
	$(HOST_PYTHON) -m venv $@

.PHONY: dev-env
dev-env:
	opam install utop merlin odig

FA_URL = https://use.fontawesome.com/releases/v5.9.0/fontawesome-free-5.9.0-web.zip
fa.zip:
	wget -qO$@ "$(FA_URL)"

fa: fa.zip
	unzip $<
	rm -rf $@
	mv fontawesome-free-*-web $@
