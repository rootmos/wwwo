PROJECTS_SPEC ?=
TASKS_EXE_PREFIX ?= wwwo-

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
	$(TASKS_EXE_PREFIX)sounds --output="$@"

sounds.%.json:
	$(TASKS_EXE_PREFIX)sounds --prefix="$*" --output="$@"

twitch.%.json:
	$(TASKS_EXE_PREFIX)twitch "$*" --output="$@"

github-activity.%.commits.json:
	$(TASKS_EXE_PREFIX)github "$*" --output="$@"

projects.json: $(PROJECTS_SPEC)
	$(TASKS_EXE_PREFIX)projects "$<" --output="$@"

%.json:
	$(TASKS_EXE_PREFIX)gallery list --generate-thumbnails --embed-thumbnails rootmos-static "$*" --output="$@"

projects/%/gallery.json:
	@mkdir -p "projects/$*"
	$(TASKS_EXE_PREFIX)project gallery "$*" rootmos-static --output="projects/$*/gallery.json"

projects/%/preamble.md:
	@mkdir -p "projects/$*"
	$(TASKS_EXE_PREFIX)project preamble "$*" rootmos-builds --output="projects/$*/preamble.md"
