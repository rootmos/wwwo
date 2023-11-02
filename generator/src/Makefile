.DEFAULT_GOAL := build
include buildml.mk

.PHONY: build
build: gen.exe

.PHONY: all
all: gen.exe top.exe

COMMON = lenient_iso8601.ml common.ml utils.ml html.ml
ATDs = \
	$(call atd, sounds) $(call atd, twitch) \
	$(call atd, github) $(call atd, practice) \
	$(call atd, gallery) $(call atd, project) \

gen.exe: $(COMMON) $(ATDs) gen.ml
	$(BUILDML_OCAMLC) -o $@ $^

top.exe: $(COMMON)
	$(BUILDML_OCAMLMKTOP) -o $@ $^
