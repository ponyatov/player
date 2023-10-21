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
QEMU = qemu-system-$(ARCH)

# cfg
XPATH    = PATH=$(HOST)/bin:$(PATH)
CFG_HOST = configure --prefix=$(HOST)

BZIMAGE  = tmp/linux/arch/x86/boot/bzImage
KERNEL   = $(FW)/$(APP)_$(HW).kernel
INITRD   = $(FW)/$(APP)_$(HW).cpio.gz

# src
D += $(wildcard src/*.d*)
C += $(wildcard src/*.c*)

# all
.PHONY: all
all: $(D)
	dub run -- media/park.mp4 media/dwsample1.mp3

.PHONY: fw
fw: $(KERNEL) $(INITRD)
$(KERNEL): $(BZIMAGE)
	cp $< $@

$(INITRD): $(ROOT)/init
	cd $(ROOT) ; find . -print0 | cpio --null --create --format=newc | gzip -9 > $@

.PHONY: qemu
qemu: $(KERNEL) $(INITRD)
	xterm -e $(QEMU) $(QEMU_CFG) -nographic \
		-kernel $(KERNEL) -initrd $(INITRD) \
		-append "console=ttyS0,115200"

# format
format: tmp/format_c tmp/format_d
tmp/format_c: $(C)
	clang-format -style=file -i $? && touch $@
tmp/format_d: $(D)
	dub run dfmt -- -i $? && touch $@

# cross
OPT_NATIVE = -O3 -march=native -mtune=native
OPT_HOST   = CFLAGS="$(OPT_NATIVE)" CXXFLAGS="$(OPT_NATIVE)"

.PHONY:   gcclibs0 gmp0 mpfr0 mpc0
gcclibs0: gmp0 mpfr0 mpc0

WITH_GCCLIBS = --with-gmp=$(HOST) --with-mpfr=$(HOST) --with-mpc=$(HOST)
CFG_GCCLIBS0 = $(WITH_GCCLIBS) --disable-shared $(OPT_HOST)

gmp0: $(HOST)/lib/libgmp.a
$(HOST)/lib/libgmp.a: $(REF)/$(GMP)/README
	mkdir -p $(TMP)/gmp0 ; cd $(TMP)/gmp0 ;\
	$(REF)/$(GMP)/$(CFG_HOST) $(CFG_GCCLIBS0) &&\
	$(MAKE) -j$(CORES) && $(MAKE) install

mpfr0: $(HOST)/lib/libmpfr.a
$(HOST)/lib/libmpfr.a: $(HOST)/lib/libgmp.a $(REF)/$(MPFR)/README.md
	mkdir -p $(TMP)/mpfr0 ; cd $(TMP)/mpfr0 ;\
	$(REF)/$(MPFR)/$(CFG_HOST) $(CFG_GCCLIBS0) &&\
	$(MAKE) -j$(CORES) && $(MAKE) install

mpc0: $(HOST)/lib/libmpc.a
$(HOST)/lib/libmpc.a: $(HOST)/lib/libgmp.a $(REF)/$(MPC)/README.md
	mkdir -p $(TMP)/mpc0 ; cd $(TMP)/mpc0 ;\
	$(REF)/$(MPC)/$(CFG_HOST) $(CFG_GCCLIBS0) &&\
	$(MAKE) -j$(CORES) && $(MAKE) install

.PHONY: binutils0 gcc0 binutils1 gcc1

CFG_BINUTILS0 = --disable-nls $(OPT_HOST)                 \
                --target=$(TARGET) --with-sysroot=$(ROOT) \
                --disable-multilib --disable-bootstrap
CFG_BINUTILS1 = $(CFG_BINUTILS0) --enable-lto

binutils0: $(HOST)/bin/$(TARGET)-ld
$(HOST)/bin/$(TARGET)-ld: $(REF)/$(BINUTILS)/README.md
	mkdir -p $(TMP)/binutils0 ; cd $(TMP)/binutils0 ;\
	$(XPATH) $(REF)/$(BINUTILS)/$(CFG_HOST) $(CFG_BINUTILS0) &&\
	$(MAKE) -j$(CORES) && $(MAKE) install

binutils1: $(HOST)/bin/$(TARGET)-as
$(HOST)/bin/$(TARGET)-as: $(ROOT)/lib/libc.so.0
	mkdir -p $(TMP)/binutils1 ; cd $(TMP)/binutils1 ;\
	$(XPATH) $(REF)/$(BINUTILS)/$(CFG_HOST) $(CFG_BINUTILS1) &&\
	$(MAKE) -j$(CORES) && $(MAKE) install

CFG_GCC0      = $(CFG_BINUTILS0) $(WITH_GCCLIBS)                            \
                --without-headers --with-newlib --enable-languages="c"      \
                --disable-shared --disable-decimal-float --disable-libgomp  \
                --disable-libmudflap --disable-libssp --disable-libatomic   \
                --disable-libquadmath --disable-threads
CFG_GCC1      = $(CFG_BINUTILS1) $(WITH_GCCLIBS)                            \
                --with-headers=$(ROOT)/usr/include --enable-languages="c,d" \
                --disable-shared --disable-decimal-float --disable-libgomp  \
                --disable-libmudflap --disable-libssp --disable-libatomic   \
                --disable-libquadmath --enable-threads

gcc0: $(HOST)/bin/$(TARGET)-gcc
$(HOST)/bin/$(TARGET)-gcc: $(HOST)/bin/$(TARGET)-ld $(REF)/$(GCC)/README.md \
                           $(HOST)/lib/libmpfr.a $(HOST)/lib/libmpc.a
	mkdir -p $(TMP)/gcc0 ; cd $(TMP)/gcc0                                  ;\
	$(XPATH) $(REF)/$(GCC)/$(CFG_HOST) $(CFG_GCC0)                        &&\
	$(MAKE) -j$(CORES) all-gcc && $(MAKE) install-gcc                     &&\
	$(MAKE) -j$(CORES) all-target-libgcc && $(MAKE) install-target-libgcc &&\
	touch $@

gcc1: $(HOST)/bin/$(TARGET)-gdc
$(HOST)/bin/$(TARGET)-gdc: $(HOST)/bin/$(TARGET)-as $(REF)/$(GCC)/README.md \
                           $(HOST)/lib/libmpfr.a $(HOST)/lib/libmpc.a
	mkdir -p $(TMP)/gcc1 ; cd $(TMP)/gcc1                                  ;\
	$(XPATH) $(REF)/$(GCC)/$(CFG_HOST) $(CFG_GCC1)                        &&\
	$(MAKE) -j$(CORES) all-gcc && $(MAKE) install-gcc                     &&\
	$(MAKE) -j$(CORES) all-target-libgcc && $(MAKE) install-target-libgcc &&\
	touch $@

.PHONY: linux

KMAKE  = $(XPATH) make -C $(REF)/$(LINUX) O=$(TMP)/linux \
         ARCH=$(ARCH) CROSS_COMPILE=$(TARGET)- \
         INSTALL_MOD_PATH=$(ROOT) INSTALL_HDR_PATH=$(ROOT)/usr
KONFIG = $(TMP)/linux/.config

linux: $(REF)/$(LINUX)/README.md
	mkdir -p $(TMP)/linux ; rm $(KONFIG) ; $(KMAKE) allnoconfig &&\
	cat $(CWD)/all/all.kernel $(CWD)/arch/$(ARCH).kernel          \
		$(CWD)/cpu/$(CPU).kernel $(CWD)/hw/$(HW).kernel           \
		$(CWD)/app/$(APP).kernel                   >> $(KONFIG) &&\
	echo CONFIG_LOCALVERSION=\"-$(APP)@$(HW)\"     >> $(KONFIG) &&\
	echo CONFIG_DEFAULT_HOSTNAME=\"$(APP)\"        >> $(KONFIG) &&\
	$(KMAKE)            menuconfig                              &&\
	$(KMAKE) -j$(CORES) bzImage modules                         &&\
	$(KMAKE)            modules_install headers_install && $(MAKE) fw

.PHONY: uclibc

UMAKE  = $(XPATH) make -C $(REF)/$(UCLIBC) O=$(TMP)/uclibc \
         ARCH=$(ARCH) PREFIX=$(ROOT)
UONFIG = $(TMP)/uclibc/.config

uclibc: $(REF)/$(UCLIBC)/README.md
	mkdir -p $(TMP)/uclibc ; cd $(TMP)/uclibc                 ;\
	rm -f $(UONFIG) ; $(UMAKE) allnoconfig                   &&\
	cat $(CWD)/all/all.uclibc $(CWD)/arch/$(ARCH).uclibc       \
	    $(CWD)/cpu/$(CPU).uclibc $(CWD)/hw/$(HW).uclibc        \
	    $(CWD)/app/$(APP).uclibc                >> $(UONFIG) &&\
	echo KERNEL_HEADERS=\"$(ROOT)/usr/include\" >> $(UONFIG) &&\
	echo CROSS_COMPILER_PREFIX=\"$(TARGET)-\"   >> $(UONFIG) &&\
	echo RUNTIME_PREFIX=\"\"                    >> $(UONFIG) &&\
	echo DEVEL_PREFIX=\"/usr\"                  >> $(UONFIG) &&\
	$(UMAKE) menuconfig && $(UMAKE) -j$(CORES) && $(UMAKE) install &&\
	$(UMAKE) -j$(CORES) hostutils &&\
	$(UMAKE) PREFIX=$(HOST) DEVEL_PREFIX=/ RUNTIME_PREFIX=/ install_hostutils &&\
	mv $(HOST)/sbin/* $(HOST)/bin/

.PHONY: init
init: $(ROOT)/init
$(ROOT)/%: src/%.c Makefile
	$(XPATH) $(TARGET)-gcc -o $@ $< && file $@ && $(HOST)/bin/ldd $@

# rule
$(REF)/%/README.md: $(GZ)/%.tar.xz
	cd $(REF) ; xzcat $< | tar x && touch $@
$(REF)/%/README.md: $(GZ)/%.tar.bz2
	cd $(REF) ; bzcat $< | tar x && touch $@
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
src: $(REF)/$(GMP)/README $(REF)/$(MPFR)/README.md $(REF)/$(MPC)/README.md \
     $(REF)/$(BINUTILS)/README.md $(REF)/$(GCC)/README.md                  \
     $(REF)/$(LINUX)/README.md $(REF)/$(UCLIBC)/README.md                  \
     $(REF)/$(BUSYBOX)/README.md $(REF)/$(SYSLINUX)/README.md
	du -csh ref/*

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
MERGE += .vscode bin doc src tmp dub.json
MERGE += all hw cpu arch app fw ref host root

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
