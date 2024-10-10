.DEFAULT_GOAL := build
include buildml.mk

.PHONY: build
build: gen.exe gen_post.exe

.PHONY: all
all: gen.exe top.exe

COMMON = common.ml
COMMON += lenient_iso8601.ml utils.ml env.ml
COMMON += html.ml path.ml page.ml post.ml
ATDs = \
	$(call atd, sounds) $(call atd, twitch) \
	$(call atd, github) $(call atd, practice) \
	$(call atd, gallery) $(call atd, project) \
	$(call atd, resume)

gen.exe: $(COMMON) $(ATDs) gen.ml
	$(BUILDML_OCAMLC) -o $@ $^

top.exe: $(COMMON)
	$(BUILDML_OCAMLMKTOP) -o $@ $^

gen_post.exe: $(COMMON) gen_post.ml
	$(BUILDML_OCAMLC) -o $@ $^
