.DEFAULT_GOAL := build
include buildml.mk

.PHONY: build
build: gen.exe

gen.exe: lenient_iso8601.ml \
	$(call atd, sounds) $(call atd, twitch) \
	$(call atd, github) $(call atd, practice) \
	$(call atd, gallery) $(call atd, project) \
	common.ml utils.ml html.ml gen.ml
	$(BUILDML_OCAMLC) -o $@ $^
