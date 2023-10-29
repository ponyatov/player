# var
MODULE  = $(notdir $(CURDIR))
module  = $(shell echo $(MODULE) | tr A-Z a-z)
OS      = $(shell uname -s)
NOW     = $(shell date +%d%m%y)
REL     = $(shell git rev-parse --short=4 HEAD)
BRANCH  = $(shell git rev-parse --abbrev-ref HEAD)
CORES  ?= $(shell grep processor /proc/cpuinfo | wc -l)

# cross
APP         = $(module)
HW         ?= qemu386
include  all/all.mk
include   hw/$(HW).mk
include  cpu/$(CPU).mk
include arch/$(ARCH).mk
include  app/$(APP).mk

# dir
CWD  = $(CURDIR)
BIN  =  $(CWD)/bin
REF  =  $(CWD)/ref
SRC  =  $(CWD)/src
TMP  =  $(CWD)/tmp
GZ   = $(HOME)/gz
HOST =  $(CWD)/host
ROOT =  $(CWD)/root
FW   =  $(CWD)/fw

# version
## LDC_VER   = 1.35.0 debian 12 libc 2.29 since 1.32.1
LDC_VER      = 1.32.0
BINUTILS_VER = 2.41
## GCC_VER   = 13.2.0 debian 10 gdc-8 too old for build
GCC_VER      = 12.3.0
GMP_VER      = 6.2.1
MPFR_VER     = 4.2.1
MPC_VER      = 1.3.1
ISL_VER      = 0.24
LINUX_VER    = 6.5.6
ICONV_VER    = 1.17
UCLIBC_VER   = 1.0.44
MUSL_VER     = 1.2.4
BUSYBOX_VER  = 1.36.1
UNWIND_VER   = 1.6.2
SYSLINUX_VER = 6.03

# package
LDC         = ldc2-$(LDC_VER)
LDC_HOST    = $(LDC)-linux-x86_64
LDC_GZ      = $(LDC_OS).tar.xz
LDC_SRC     = ldc-$(LDC_VER)-src.tar.gz
##
BINUTILS    = binutils-$(BINUTILS_VER)
GCC         = gcc-$(GCC_VER)
GMP         = gmp-$(GMP_VER)
MPFR        = mpfr-$(MPFR_VER)
MPC         = mpc-$(MPC_VER)
ISL         = isl-$(ISL_VER)
LINUX       = linux-$(LINUX_VER)
MUSL        = musl-$(MUSL_VER)
BUSYBOX     = busybox-$(BUSYBOX_VER)
ICONV       = libiconv-$(ICONV_VER)
UCLIBC      = uClibc-ng-$(UCLIBC_VER)
UNWIND      = libunwind-$(UNWIND_VER)
SYSLINUX    = syslinux-$(SYSLINUX_VER)
##
BINUTILS_GZ = $(BINUTILS).tar.xz
GCC_GZ      = $(GCC).tar.xz
GMP_GZ      = $(GMP).tar.gz
MPFR_GZ     = $(MPFR).tar.xz
MPC_GZ      = $(MPC).tar.gz
ISL_GZ      = $(ISL).tar.bz2
LINUX_GZ    = $(LINUX).tar.xz
MUSL_GZ     = $(MUSL).tar.gz
BUSYBOX_GZ  = $(BUSYBOX).tar.bz2
UNWIND_GZ   = $(UNWIND).tar.gz
SYSLINUX_GZ = $(SYSLINUX).tar.xz
ICONV_GZ    = $(ICONV).tar.gz
UCLIBC_GZ   = $(UCLIBC).tar.xz

# tool
CURL = curl -L -o
GDCH = /usr/local/bin/gdc-12
CCH  = /usr/local/bin/gcc-12
CXXH = /usr/local/bin/g++-12
LLC  = llc-15
LDC2 = /opt/$(LDC_HOST)/bin/ldc2
LBR  = /opt/$(LDC_HOST)/bin/ldc-build-runtime
QEMU = qemu-system-$(ARCH)

# cfg
XPATH    = PATH=$(HOST)/bin:$(PATH)
GCC_HOST = GDC=$(GDCH) CC=$(CCH) CXX=$(CXXH)
CFG_HOST = configure --prefix=$(HOST) $(GCC_HOST)

BZIMAGE  = tmp/$(LINUX)/arch/x86/boot/bzImage
KERNEL   = $(FW)/$(APP)_$(HW).kernel
INITRD   = $(FW)/$(APP)_$(HW).cpio.gz

# src
D += $(wildcard src/*.d*) $(wildcard init/*.d*) $(wildcard hello/*.d*)
C += $(wildcard src/*.c*) $(wildcard init/*.c*)

# all
.PHONY: all
all: $(D)
	dub run --compiler=dmd -- root/media/park.mp4 root/media/dwsample1.mp3

.PHONY: hello
HELLO_SRC = $(wildcard hello/src/*.d) hello/dub.json dub.json ldc2.conf
hello: $(HELLO_SRC)
	$(DUB) $(RUN) :$@
$(ROOT)/bin/hello: $(HELLO_SRC)
	$(DUB) build --compiler=$(LDC2) --arch=$(TARGET) :hello

.PHONY: root
root: $(ROOT)/bin/hello
	$(MAKE) $(INITRD)

.PHONY: fw $(INITRD)
fw: $(KERNEL) $(INITRD)
$(KERNEL): $(BZIMAGE)
	cp $< $@
$(INITRD):
	cd $(ROOT) ; find . -print0 | cpio --null --create --format=newc | gzip -9 > $@

.PHONY: qemu
qemu: $(KERNEL) $(INITRD)
	xterm -e $(QEMU) $(QEMU_CFG) \
		-kernel $(KERNEL) -initrd $(INITRD) \
		-nographic -append "console=ttyS0,115200 vga=0x318"

# format
format: tmp/format_c tmp/format_d
tmp/format_c: $(C)
	clang-format -style=file -i $? && touch $@
tmp/format_d: $(D)
	$(DUB) $(RUN) dfmt -- -i $? && touch $@

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
