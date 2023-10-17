
# version
# LDC_VER = 1.34.0 debian 12 libc 2.29 since 1.32.1
LDC_VER = 1.32.0

# dir
CWD = $(CURDIR)
BIN = $(CWD)/bin
SRC = $(CWD)/src
TMP = $(CWD)/tmp
GZ  = $(HOME)/gz

# package
LDC    = ldc2-$(LDC_VER)
LDC_OS = $(LDC)-linux-x86_64
LDC_GZ = $(LDC_OS).tar.xz

# tool
CURL = curl -L -o
LLC  = llc-15
LDC2 = /opt/$(LDC_OS)/bin/ldc2

# src
D += $(wildcard src/*.d*)

# all
.PHONY: all
all: $(D)
	dub run -- ~/fx/media/dwsample1.mp3

# format
format: tmp/format_d
tmp/format_d: $(D)
	dub run dfmt -- -i $? && touch $@

# doc
doc: doc/yazyk_programmirovaniya_d.pdf doc/Programming_in_D.pdf

doc/yazyk_programmirovaniya_d.pdf:
	$(CURL) $@ https://www.k0d.cc/storage/books/D/yazyk_programmirovaniya_d.pdf
doc/Programming_in_D.pdf:
	$(CURL) $@ http://ddili.org/ders/d.en/Programming_in_D.pdf


