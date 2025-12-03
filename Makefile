# Environment
SHELL = /bin/bash

.SUFFIXES: .rb .gemspec .zip
.PHONY: test
.SILENT:

# Commands
grep = $(shell command -v grep)
cut = $(shell command -v cut)
git = $(shell command -v git)
ruby = $(shell command -v ruby)
ruby.test = $(ruby) -Ilib:test -rpry-byebug
gem = $(shell command -v gem)

# Variables
file ?= test/.*_test.*

help:
#?$ make help
#?  Show this message to help use
	$(grep) -e '^#?' Makefile | $(cut) -c3-

test:
#?$ make test file=<FILE>
#?  Test a single file FILE.
	$(ruby.test) ${file}

build: test
#?$ make build
#?  Building anything
	$(start) Build ${file}
	#: build
	$(done)

