PROJECTS_SPEC ?=
META_BIN_PREFIX ?= wwwo-

META =

META += sounds.json sounds.sessions.json sounds.demo.json sounds.practice.json
META += github-activity.rootmos.commits.json
META += twitch.rootmos2.json

META += glenn.json silly.json clips.json

ifneq ($(PROJECTS_SPEC),)
META += projects.json
endif

META += projects/stellar-drift/gallery.json
META += projects/stellar-drift/preamble.md

.PHONY: fetch
fetch: $(META)

sounds.json:
	$(META_BIN_PREFIX)sounds --output="$@"

sounds.%.json:
	$(META_BIN_PREFIX)sounds --prefix="$*" --output="$@"

twitch.%.json:
	$(META_BIN_PREFIX)twitch "$*" --output="$@"

github-activity.%.commits.json:
	$(META_BIN_PREFIX)github "$*" --output="$@"

projects.json: $(PROJECTS_SPEC)
	$(META_BIN_PREFIX)projects "$<" --output="$@"

%.json:
	$(META_BIN_PREFIX)list --prefix="$*" rootmos-static --output="$@"

projects/%/gallery.json:
	@mkdir -p "projects/$*"
	$(META_BIN_PREFIX)project gallery "$*" rootmos-static --output="projects/$*/gallery.json"

projects/%/preamble.md:
	@mkdir -p "projects/$*"
	$(META_BIN_PREFIX)project preamble "$*" rootmos-builds --output="projects/$*/preamble.md"
