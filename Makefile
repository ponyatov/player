# var
MODULE  = $(notdir $(CURDIR))
module  = $(shell echo $(MODULE) | tr A-Z a-z)
OS      = $(shell uname -o|tr / _)
NOW     = $(shell date +%d%m%y)
REL     = $(shell git rev-parse --short=4 HEAD)
BRANCH  = $(shell git rev-parse --abbrev-ref HEAD)
CORES  ?= $(shell grep processor /proc/cpuinfo | wc -l)

# emLinux
APP         = $(MODULE)
HW          = qemu386
include  all/all.mk
include   hw/$(HW).mk
include  cpu/$(CPU).mk
include arch/$(ARCH).mk
include  app/$(APP).mk

# dir
CWD  = $(CURDIR)
BIN  =  $(CWD)/bin
SRC  =  $(CWD)/src
REF  =  $(CWD)/ref
TMP  =  $(CWD)/tmp
GZ   = $(HOME)/gz
HOST =  $(CWD)/host
ROOT =  $(CWD)/root
FW   =  $(CWD)/fw

# version
LDC_VER      = 1.32.0
## LDC_VER   = 1.34.0 debian 12 libc 2.29 since 1.32.1
BINUTILS_VER = 2.41
GCC_VER      = 13.2.0
GMP_VER      = 6.2.1
MPFR_VER     = 4.2.1
MPC_VER      = 1.3.1
SYSLINUX_VER = 6.03
LINUX_VER    = 6.5.6
UCLIBC_VER   = 1.0.44
BUSYBOX_VER  = 1.36.1

# package
LDC         = ldc2-$(LDC_VER)
LDC_OS      = $(LDC)-linux-x86_64
LDC_GZ      = $(LDC_OS).tar.xz
##
BINUTILS    = binutils-$(BINUTILS_VER)
GCC         = gcc-$(GCC_VER)
GMP         = gmp-$(GMP_VER)
MPFR        = mpfr-$(MPFR_VER)
MPC         = mpc-$(MPC_VER)
SYSLINUX    = syslinux-$(SYSLINUX_VER)
LINUX       = linux-$(LINUX_VER)
UCLIBC      = uClibc-ng-$(UCLIBC_VER)
BUSYBOX     = busybox-$(BUSYBOX_VER)
##
BINUTILS_GZ = $(BINUTILS).tar.xz
GCC_GZ      = $(GCC).tar.xz
GMP_GZ      = $(GMP).tar.gz
MPFR_GZ     = $(MPFR).tar.xz
MPC_GZ      = $(MPC).tar.gz
SYSLINUX_GZ = $(SYSLINUX).tar.xz
LINUX_GZ    = $(LINUX).tar.xz
UCLIBC_GZ   = $(UCLIBC).tar.xz
BUSYBOX_GZ  = $(BUSYBOX).tar.bz2

# tool
CURL = curl -L -o
LLC  = llc-15
LDC2 = /opt/$(LDC_OS)/bin/ldc2

# cfg
XPATH    = PATH=$(HOST)/bin:$(PATH)
CFG_HOST = configure --prefix=$(HOST)

# src
D += $(wildcard src/*.d*)

# all
.PHONY: all
all: $(D)
	dub run -- media/park.mp4 media/dwsample1.mp3

QEMU = qemu-system-$(ARCH)
.PHONY: qemu
qemu: fw/bzImage
	$(QEMU) $(QEMU_CFG) -nographic -kernel $< -append console=ttyS0,115200

# format
format: tmp/format_d
tmp/format_d: $(D)
	dub run dfmt -- -i $? && touch $@

# cross
.PHONY:   gcclibs0 gmp0 mpfr0 mpc0
gcclibs0: gmp0 mpfr0 mpc0

WITH_GCCLIBS = --with-gmp=$(HOST) --with-mpfr=$(HOST) --with-mpc=$(HOST)
CFG_GCCLIBS  = $(WITH_GCCLIBS) --disable-shared
OPT_GCCLIBS  = -O3 -march=native -mtune=native
CFG_GCCLIBS += CFLAGS="$(OPT_GCCLIBS)" CXXFLAGS="$(OPT_GCCLIBS)"

gmp0: $(HOST)/lib/libgmp.a
$(HOST)/lib/libgmp.a: $(REF)/$(GMP)/README
	rm -rf $(TMP)/gmp ; mkdir $(TMP)/gmp ; cd $(TMP)/gmp ;\
	$(REF)/$(GMP)/$(CFG_HOST) $(CFG_GCCLIBS) &&\
	$(MAKE) -j$(CORES) && $(MAKE) install

mpfr0: $(HOST)/lib/libmpfr.a
$(HOST)/lib/libmpfr.a: $(HOST)/lib/libgmp.a $(REF)/$(MPFR)/README.md
	rm -rf $(TMP)/mpfr ; mkdir $(TMP)/mpfr ; cd $(TMP)/mpfr ;\
	$(REF)/$(MPFR)/$(CFG_HOST) $(CFG_GCCLIBS) &&\
	$(MAKE) -j$(CORES) && $(MAKE) install

mpc0: $(HOST)/lib/libmpc.a
$(HOST)/lib/libmpc.a: $(HOST)/lib/libgmp.a $(REF)/$(MPC)/README.md
	rm -rf $(TMP)/mpc ; mkdir $(TMP)/mpc ; cd $(TMP)/mpc ;\
	$(REF)/$(MPC)/$(CFG_HOST) $(CFG_GCCLIBS) &&\
	$(MAKE) -j$(CORES) && $(MAKE) install

# rule
$(REF)/%/README.md: $(GZ)/%.tar.xz
	cd $(REF) ; xzcat $< | tar x && touch $@
$(REF)/%/README.md: $(GZ)/%.tar.gz
	cd $(REF) ;  zcat $< | tar x && touch $@
$(REF)/$(GMP)/README: $(GZ)/$(GMP_GZ)
	cd $(REF) ; tar zx < $< && mv GMP-$(GMP_VER) $(GMP) ; touch $@

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
	$(MAKE) update
update:
	sudo apt update
	sudo apt install -yu `cat apt.txt`
$(APT_SRC)/%: tmp/%
	sudo cp $< $@
tmp/d-apt.list:
	$(CURL) $@ http://master.dl.sourceforge.net/project/d-apt/files/d-apt.list

gz: $(LDC2) \
	$(GZ)/$(GMP_GZ) $(GZ)/$(MPFR_GZ) $(GZ)/$(MPC_GZ)         \
	$(GZ)/$(BINUTILS_GZ) $(GZ)/$(GCC_GZ)                     \
	$(GZ)/$(LINUX_GZ) $(GZ)/$(UCLIBC_GZ) $(GZ)/$(BUSYBOX_GZ) \
	$(GZ)/$(SYSLINUX_GZ)

$(LDC2): $(GZ)/$(LDC_GZ)
	cd /opt ; sudo sh -c "xzcat $< | tar x && touch $@"

$(GZ)/$(LDC_GZ):
	$(CURL) $@ https://github.com/ldc-developers/ldc/releases/download/v$(LDC_VER)/$(LDC_GZ)

# src
.PHONY: src
src: $(REF)/$(GMP)/README $(REF)/$(MPFR)/README.md $(REF)/$(MPC)/README.md

$(GZ)/$(GMP_GZ):
	$(CURL) $@ https://github.com/alisw/GMP/archive/refs/tags/v$(GMP_VER).tar.gz
$(GZ)/$(MPFR_GZ):	
	$(CURL) $@ https://www.mpfr.org/mpfr-current/$(MPFR_GZ)
$(GZ)/$(MPC_GZ):
	$(CURL) $@ https://ftp.gnu.org/gnu/mpc/$(MPC_GZ)

$(GZ)/$(BINUTILS_GZ):
	$(CURL) $@ https://ftp.gnu.org/gnu/binutils/$(BINUTILS_GZ)
$(GZ)/$(GCC_GZ):
	$(CURL) $@ http://mirror.linux-ia64.org/gnu/gcc/releases/$(GCC)/$(GCC_GZ)

$(GZ)/$(LINUX_GZ):
	$(CURL) $@ https://cdn.kernel.org/pub/linux/kernel/v6.x/$(LINUX_GZ)
$(GZ)/$(UCLIBC_GZ):
	$(CURL) $@ https://downloads.uclibc-ng.org/releases/$(UCLIBC_VER)/$(UCLIBC_GZ)
$(GZ)/$(BUSYBOX_GZ):
	$(CURL) $@ https://busybox.net/downloads/$(BUSYBOX_GZ)

$(GZ)/$(SYSLINUX_GZ):
	$(CURL) $@ https://mirrors.edge.kernel.org/pub/linux/utils/boot/syslinux/$(SYSLINUX_GZ)

# merge
MERGE += README.md Makefile apt.Linux
MERGE += .gitignore .gitattributes .stignore .clang-format .editorconfig
MERGE += .vscode bin doc media src tmp dub.json
MERGE += all hw cpu arch app

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
