export ENV ?= dev
export WEBROOT ?= $(shell pwd)/webroot
PORT ?= 8080

VENV = $(shell pwd)/venv
HOST_PYTHON ?= python3
export PYTHON = $(VENV)/bin/python3
export PIP = $(VENV)/bin/pip

.PHONY: generate
generate: build fa sounds.json github-activity.rootmos.commits.json
	@mkdir -p $(WEBROOT)/$(ENV)
	./src/gen

.PHONY: validate
validate:
	find $(WEBROOT)/$(ENV) -name "*.html" -exec ./validate.sh {} \;

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
	rm -rf $(WEBROOT) .flag.* $(VENV)

.PHONY: fresh
fresh:
	rm -rf sounds.json github-activity.*.json

sounds.json: .flag.deps
	$(PYTHON) sounds.py > $@

github-activity.%.commits.json: .flag.deps
	$(PYTHON) github-activity.py $*

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
	rm -rf fa
	mv fontawesome-free-*-web $@
