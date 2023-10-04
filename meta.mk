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
	$(META_BIN_PREFIX)sounds > "$@"

sounds.%.json:
	$(META_BIN_PREFIX)sounds --prefix="$*" > "$@"

twitch.%.json:
	$(META_BIN_PREFIX)twitch "$*" > "$@"

github-activity.%.commits.json:
	$(META_BIN_PREFIX)github "$*" > "$@"

projects.json: $(PROJECTS_SPEC)
	$(META_BIN_PREFIX)projects "$<" > "$@"

%.json:
	$(META_BIN_PREFIX)list --prefix="$*" rootmos-static > "$@"

projects/%/gallery.json projects/%/preamble.md:
	@mkdir -p "projects/$*"
	$(META_BIN_PREFIX)project gallery "$*" rootmos-static > "projects/$*/gallery.json"
	$(META_BIN_PREFIX)project preamble "$*" rootmos-builds > "projects/$*/preamble.md"
