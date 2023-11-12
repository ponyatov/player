# var
MODULE  = $(notdir $(CURDIR))
module  = $(shell echo $(MODULE) | tr A-Z a-z)
OS      = $(shell uname -s)
NOW     = $(shell date +%d%m%y)
REL     = $(shell git rev-parse --short=4 HEAD)
BRANCH  = $(shell git rev-parse --abbrev-ref HEAD)
CORES  ?= $(shell grep processor /proc/cpuinfo | wc -l)

# dir
CWD  = $(CURDIR)
BIN  =  $(CWD)/bin
REF  =  $(CWD)/ref
SRC  =  $(CWD)/src
TMP  =  $(CWD)/tmp
GZ   = $(HOME)/gz
HOST = $(HOME)/Dilang/host
ROOT = $(HOME)/Dilang/root
FW   = $(HOME)/Dilang/fw

# version
## LDC_VER   = 1.35.0 debian 12 libc 2.29 since 1.32.1
LDC_VER      = 1.32.0

# package
LDC         = ldc2-$(LDC_VER)
LDC_HOST    = $(LDC)-linux-x86_64
LDC_GZ      = $(LDC_OS).tar.xz
LDC_SRC     = ldc-$(LDC_VER)-src.tar.gz

# tool
CURL = curl -L -o
DC   = dmd
RUN  = dub run   --compiler=$(DC)
BLD  = dub build --compiler=$(DC)
GDC  = /usr/local/bin/gdc-12
GCC  = /usr/local/bin/gcc-12
GXX  = /usr/local/bin/g++-12
LLC  = llc-15
LDC2 = /opt/$(LDC_HOST)/bin/ldc2
LBR  = /opt/$(LDC_HOST)/bin/ldc-build-runtime

# src
D += $(wildcard src/*.d*) $(wildcard init/*.d*) $(wildcard hello/*.d*)
C += $(wildcard src/*.c*) $(wildcard init/*.c*)

# all
.PHONY: all
all: bin/$(MODULE)
bin/$(MODULE): $(D)
	$(BLD)

.PHONY: run
run: bin/$(MODULE) media/park.mp4 media/dwsample1.mp3
	$^

# format
format: tmp/format_c tmp/format_d
tmp/format_c: $(C)
	clang-format -style=file -i $? && touch $@
tmp/format_d: $(D)
	$(RUN) dfmt -- -i $? && touch $@

# https://wiki.dlang.org/Building_LDC_runtime_libraries
# https://gist.github.com/denizzzka/a48f70e5e698ebdf6fb031a751bc528b
.PHONY: ldc ldc_src
ldc: $(TMP)/ldc_$(TARGET)/lib/ldc_rt.dso.o
$(TMP)/ldc_$(TARGET)/lib/ldc_rt.dso.o: $(LBR) $(TMP)/ldc-$(LDC_VER)-src/README.md
	$(XPATH) CC=$(TARGET)-gcc $< -j$(CORES) --ldc $(LDC2)                      \
	--buildDir $(TMP)/ldc_$(TARGET) --ldcSrcDir $(TMP)/ldc-$(LDC_VER)-src      \
	--targetSystem='Linux;UNIX' CMAKE_SYSTEM_NAME=Linux BUILD_SHARED_LIBS=ON   \
	--dFlags="-mtriple=$(TARGET);-mcpu=$(CPU)" --cFlags="$(OPT_TARGET)"      &&\
	touch $@

ldc_src: $(TMP)/ldc-$(LDC_VER)-src/README.md
$(TMP)/ldc-$(LDC_VER)-src/README.md: $(GZ)/$(LDC_SRC)
	cd $(TMP) ; tar zx < $< && touch $@

# rule
$(REF)/$(GMP)/README: $(GZ)/$(GMP_GZ)
	cd $(REF) ; tar zx < $< && mv GMP-$(GMP_VER) $(GMP) ; touch $@
$(REF)/%/README.md: $(GZ)/%.tar.gz
	cd $(REF) ;  zcat $< | tar x && touch $@
$(REF)/%/README.md: $(GZ)/%.tar.xz
	cd $(REF) ; xzcat $< | tar x && touch $@
$(REF)/%/README.md: $(GZ)/%.tar.bz2
	cd $(REF) ; bzcat $< | tar x && touch $@

# doc
doc: doc/yazyk_programmirovaniya_d.pdf doc/Programming_in_D.pdf

doc/yazyk_programmirovaniya_d.pdf:
	$(CURL) $@ https://www.k0d.cc/storage/books/D/yazyk_programmirovaniya_d.pdf
doc/Programming_in_D.pdf:
	$(CURL) $@ http://ddili.org/ders/d.en/Programming_in_D.pdf

# install
APT_SRC = /etc/apt/sources.list.d
ETC_APT = $(APT_SRC)/d-apt.list $(APT_SRC)/llvm.list
.PHONY: install update doc gz
install: doc gz $(ETC_APT)
	sudo apt update && sudo apt --allow-unauthenticated install -yu d-apt-keyring
	dub fetch dfmt
	$(MAKE) update
update:
	sudo apt update
	sudo apt install -yu `cat apt.$(OS)`
$(APT_SRC)/%: tmp/%
	sudo cp $< $@
tmp/d-apt.list:
	$(CURL) $@ http://master.dl.sourceforge.net/project/d-apt/files/d-apt.list

gz: $(LDC2) $(GZ)/$(LDC_SRC) \
	$(GZ)/$(GMP_GZ) $(GZ)/$(MPFR_GZ) $(GZ)/$(MPC_GZ)       \
	$(GZ)/$(BINUTILS_GZ) $(GZ)/$(GCC_GZ) $(GZ)/$(ISL_GZ)   \
	$(GZ)/$(LINUX_GZ) $(GZ)/$(MUSL_GZ) $(GZ)/$(BUSYBOX_GZ)

$(LDC2): $(GZ)/$(LDC_GZ)
	cd /opt ; sudo sh -c "xzcat $< | tar x && touch $@"
$(GZ)/$(LDC_GZ):
	$(CURL) $@ https://github.com/ldc-developers/ldc/releases/download/v$(LDC_VER)/$(LDC_GZ)
$(GZ)/$(LDC_SRC):
	$(CURL) $@ https://github.com/ldc-developers/ldc/releases/download/v$(LDC_VER)/$(LDC_SRC)

# merge
MERGE += README.md Makefile apt.Linux
MERGE += .gitignore .gitattributes .stignore .clang-format .editorconfig
MERGE += .vscode bin doc lib ref src tmp dub.json ldc2.conf

.PHONY: dev
dev:
	git push -v
	git checkout $@
	git pull -v
	git checkout shadow -- $(MERGE)

.PHONY: shadow
shadow:
	git push -v
	git checkout $@
	git pull -v

.PHONY: release
release:
	git tag $(NOW)-$(REL)
	git push -v --tags
