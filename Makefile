-include .github/local/Makefile.local
PROJECT ?= radxa-profiles
PREFIX ?= /usr
ETCDIR ?= /etc
BINDIR ?= $(PREFIX)/bin
LIBDIR ?= $(PREFIX)/lib
SHAREDIR ?= $(PREFIX)/share
MANDIR ?= $(SHAREDIR)/man

.DEFAULT_GOAL := all
.PHONY: all
all: build

.PHONY: devcontainer_setup
devcontainer_setup:
	sudo dpkg --add-architecture arm64
	sudo apt-get update
	sudo apt-get build-dep . -y

#
# Test
#
.PHONY: test
test:

#
# Build
#
.PHONY: build
build: build-man

SRC-MAN		:=	man
SRCS-MAN	:=	$(wildcard $(SRC-MAN)/*.md)
MANS		:=	$(SRCS-MAN:.md=)
.PHONY: build-man
build-man: $(MANS)

$(SRC-MAN)/%: $(SRC-MAN)/%.md
	pandoc "$<" -o "$@" --from markdown --to man -s

#
# Clean
#
.PHONY: distclean
distclean: clean

.PHONY: clean
clean: clean-man clean-deb

.PHONY: clean-man
clean-man:
	rm -rf $(MANS)

.PHONY: clean-deb
clean-deb:
	rm -rf debian/.debhelper debian/${PROJECT} debian/task-*/ debian/tmp debian/debhelper-build-stamp debian/files debian/*.debhelper.log debian/*.postrm.debhelper debian/*.substvars

#
# Release
#
.PHONY: dch
dch: debian/changelog
	EDITOR=true gbp dch --ignore-branch --multimaint-merge --commit --git-log='--no-merges --perl-regexp --author ^((?!github-actions\[bot\]).*)$$' --release --dch-opt=--upstream

.PHONY: deb
deb: debian
	debuild --no-lintian --lintian-hook "lintian --fail-on error,warning --suppress-tags bad-distribution-in-changes-file -- %p_%v_*.changes" --no-sign -b

.PHONY: release
release:
	gh workflow run .github/workflows/new_version.yaml --ref $(shell git branch --show-current)
