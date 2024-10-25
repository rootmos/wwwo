.DEFAULT_GOAL := build
include buildml.mk

.PHONY: build
build: gen.exe gen_post.exe

.PHONY: all
all: gen.exe top.exe

COMMON = common.ml utils.ml env.ml
COMMON += lenient_iso8601.ml strict_iso8601.ml
COMMON += html.ml path.ml page.ml post.ml
ATDs = \
	$(call atd, sounds) $(call atd, twitch) \
	$(call atd, git_activity) $(call atd, practice) \
	$(call atd, gallery) $(call atd, project) \
	$(call atd, resume)

gen.exe: $(COMMON) $(ATDs) activity.ml gen.ml
	$(BUILDML_OCAMLC) -o $@ $^

top.exe: $(COMMON)
	$(BUILDML_OCAMLMKTOP) -o $@ $^

gen_post.exe: $(COMMON) gen_post.ml
	$(BUILDML_OCAMLC) -o $@ $^
