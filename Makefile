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
ruby.run = $(ruby) -Ilib run.rb
gem = $(shell command -v gem)

# Variables
file =

help:
#?$ make help
#?  	Show this message to help use.
	$(grep) -e '^#?' Makefile | $(cut) -c3-

test:
#?$ make test [file=<FILE>]
#?  Run all tests or a single file FILE.
	$(ruby.run) ${@} ${file}

versioning:
#?$ make versioning [file=<FILE>]
#?  Creates version file. Default is lib/drawght/version.rb.
#?  The version information is in the CHANGELOG.yaml file.
	$(ruby.run) ${@} ${file}

package: versioning
#?$ make package
#?  Creates Gem package.
	$(gem) build

release: package
#?$ make release
#?  Packages and pushes the Gem file to the RubyGems server.
	$(gem) push
