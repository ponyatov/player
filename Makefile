# var
MODULE  = $(notdir $(CURDIR))
module  = $(shell echo $(MODULE) | tr A-Z a-z)
OS      = $(shell uname -s)
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
# GCC_VER      = 13.2.0
GCC_VER      = 12.3.0
GMP_VER      = 6.2.1
MPFR_VER     = 4.2.1
MPC_VER      = 1.3.1
ISL_VER      = 0.24
SYSLINUX_VER = 6.03
LINUX_VER    = 6.5.6
ICONV_VER    = 1.17
UCLIBC_VER   = 1.0.44
MUSL_VER     = 1.2.4
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
ISL         = isl-$(ISL_VER)
SYSLINUX    = syslinux-$(SYSLINUX_VER)
LINUX       = linux-$(LINUX_VER)
ICONV       = libiconv-$(ICONV_VER)
UCLIBC      = uClibc-ng-$(UCLIBC_VER)
MUSL        = musl-$(MUSL_VER)
BUSYBOX     = busybox-$(BUSYBOX_VER)
##
BINUTILS_GZ = $(BINUTILS).tar.xz
GCC_GZ      = $(GCC).tar.xz
GMP_GZ      = $(GMP).tar.gz
MPFR_GZ     = $(MPFR).tar.xz
MPC_GZ      = $(MPC).tar.gz
ISL_GZ      = $(ISL).tar.bz2
SYSLINUX_GZ = $(SYSLINUX).tar.xz
LINUX_GZ    = $(LINUX).tar.xz
ICONV_GZ    = $(ICONV).tar.gz
UCLIBC_GZ   = $(UCLIBC).tar.xz
MUSL_GZ     = $(MUSL).tar.gz
BUSYBOX_GZ  = $(BUSYBOX).tar.bz2

# tool
CURL = curl -L -o
GDCH = /usr/local/bin/gdc-12
CCH  = /usr/local/bin/gcc-12
CXXH = /usr/local/bin/g++-12
LLC  = llc-15
LDC2 = /opt/$(LDC_OS)/bin/ldc2
QEMU = qemu-system-$(ARCH)

# cfg
XPATH    = PATH=$(HOST)/bin:$(PATH)
GCC_HOST = GDC=$(GDCH) CC=$(CCH) CXX=$(CXXH)
CFG_HOST = configure --prefix=$(HOST) $(GCC_HOST)

BZIMAGE  = tmp/$(LINUX)/arch/x86/boot/bzImage
KERNEL   = $(FW)/$(APP)_$(HW).kernel
INITRD   = $(FW)/$(APP)_$(HW).cpio.gz

# src
D += $(wildcard src/*.d*)
C += $(wildcard src/*.c*)

# all
.PHONY: all
all: $(D)
	dub run -- root/media/park.mp4 root/media/dwsample1.mp3

.PHONY: fw
fw: $(KERNEL) $(INITRD)
$(KERNEL): $(BZIMAGE)
	cp $< $@

$(INITRD):
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

# clean
.PHONY: clean
clean:
	rm -rf host root ; git checkout host root
	rm -rf $(TMP)/$(BINUTILS)-* $(TMP)/$(GCC)-*
	rm -rf $(TMP)/$(GMP)-* $(TMP)/$(MPFR)-* $(TMP)/$(MPC)-*
	rm -rf $(TMP)/$(LINUX) $(TMP)/$(MUSL) $(TMP)/$(UCLIBC) $(TMP)/$(ICONV)

# cross
OPT_NATIVE = -O3 -march=native -mtune=native
OPT_HOST   = CFLAGS="$(OPT_NATIVE)" CXXFLAGS="$(OPT_NATIVE)"

.PHONY:   gcclibs0 gmp0 mpfr0 mpc0
gcclibs0: gmp0 mpfr0 mpc0

WITH_GCCLIBS = --with-gmp=$(HOST) --with-mpfr=$(HOST) --with-mpc=$(HOST)
CFG_GCCLIBS0 = $(WITH_GCCLIBS) --disable-shared $(OPT_HOST)

gmp0: $(HOST)/lib/libgmp.a
$(HOST)/lib/libgmp.a: $(REF)/$(GMP)/README
	mkdir -p $(TMP)/$(GMP)-0 ; cd $(TMP)/$(GMP)-0 ;\
	$(REF)/$(GMP)/$(CFG_HOST) $(CFG_GCCLIBS0) &&\
	$(MAKE) -j$(CORES) && $(MAKE) install

mpfr0: $(HOST)/lib/libmpfr.a
$(HOST)/lib/libmpfr.a: $(HOST)/lib/libgmp.a $(REF)/$(MPFR)/README.md
	mkdir -p $(TMP)/$(MPFR)-0 ; cd $(TMP)/$(MPFR)-0 ;\
	$(REF)/$(MPFR)/$(CFG_HOST) $(CFG_GCCLIBS0) &&\
	$(MAKE) -j$(CORES) && $(MAKE) install

mpc0: $(HOST)/lib/libmpc.a
$(HOST)/lib/libmpc.a: $(HOST)/lib/libgmp.a $(REF)/$(MPC)/README.md
	mkdir -p $(TMP)/$(MPC)-0 ; cd $(TMP)/$(MPC)-0 ;\
	$(REF)/$(MPC)/$(CFG_HOST) $(CFG_GCCLIBS0) &&\
	$(MAKE) -j$(CORES) && $(MAKE) install

isl0: $(HOST)/lib/libisl.a
$(HOST)/lib/libisl.a: $(HOST)/lib/libgmp.a $(REF)/$(ISL)/README.md
	mkdir -p $(TMP)/$(ISL)-0 ; cd $(TMP)/$(ISL)-0 ;\
	$(REF)/$(ISL)/$(CFG_HOST) $(CFG_GCCLIBS0) --with-gmp=system --with-gmp-prefix=$(HOST) &&\
	$(MAKE) -j$(CORES) && $(MAKE) install

.PHONY: binutils0 gcc0 binutils1 gcc1

CFG_BINUTILS0 = --disable-nls $(OPT_HOST)                 \
                --target=$(TARGET) --with-sysroot=$(ROOT) \
                --disable-multilib --disable-bootstrap
CFG_BINUTILS1 = $(CFG_BINUTILS0) --enable-lto

binutils0: $(HOST)/bin/$(TARGET)-ld
$(HOST)/bin/$(TARGET)-ld: $(REF)/$(BINUTILS)/README.md
	mkdir -p $(TMP)/$(BINUTILS)-0 ; cd $(TMP)/$(BINUTILS)-0 ;\
	$(XPATH) $(REF)/$(BINUTILS)/$(CFG_HOST) $(CFG_BINUTILS0) &&\
	$(MAKE) -j$(CORES) && $(MAKE) install

binutils1: $(HOST)/bin/$(TARGET)-as
$(HOST)/bin/$(TARGET)-as: $(ROOT)/lib/libc.so.0
	mkdir -p $(TMP)/$(BINUTILS)-1 ; cd $(TMP)/$(BINUTILS)-1 ;\
	$(XPATH) $(REF)/$(BINUTILS)/$(CFG_HOST) $(CFG_BINUTILS1) &&\
	$(MAKE) -j$(CORES) && $(MAKE) install

GCC_DISABLE = --disable-shared --disable-decimal-float --disable-libgomp   \
              --disable-libmudflap --disable-libssp --disable-libatomic    \
              --disable-multilib --disable-bootstrap --disable-libquadmath \
			  --disable-nls --disable-libstdcxx-pch --disable-clocale
GCC_ENABLE  = --enable-threads --enable-tls

CFG_GCC0 = $(CFG_BINUTILS0)    $(WITH_GCCLIBS) --enable-languages="c"       \
           --without-headers --with-newlib --disable-threads $(GCC_HOST)    \
		   $(GCC_DISABLE)
CFG_GCC1 = $(CFG_BINUTILS1)    $(WITH_GCCLIBS) --enable-languages="c,c++,d" \
           --with-headers=$(ROOT)/usr/include                $(GCC_HOST)    \
           $(GCC_DISABLE) $(GCC_ENABLE)
CFG_GCCH = --prefix=/usr/local $(WITH_GCCLIBS) --enable-languages="c,c++,d" \
           --program-suffix="-12"                            $(OPT_HOST)    \
		   $(GCC_DISABLE) $(GCC_ENABLE)

gcch: $(GDCH)
$(GDCH):
	$(MAKE) $(REF)/$(GCC)/README.md
	mkdir -p $(TMP)/$(GCC)-host ; cd $(TMP)/$(GCC)-host  ;\
	$(REF)/$(GCC)/configure $(CFG_GCCH)                 &&\
	$(MAKE) -j$(CORES) && sudo $(MAKE) install

gcc0: $(HOST)/bin/$(TARGET)-gcc
$(HOST)/bin/$(TARGET)-gcc: $(HOST)/bin/$(TARGET)-ld $(REF)/$(GCC)/README.md \
                           $(HOST)/lib/libmpfr.a $(HOST)/lib/libmpc.a
	mkdir -p $(TMP)/$(GCC)-0 ; cd $(TMP)/$(GCC)-0                          ;\
	$(XPATH) $(REF)/$(GCC)/$(CFG_HOST) $(CFG_GCC0)                        &&\
	$(MAKE) -j$(CORES) all-gcc           && $(MAKE) install-gcc           &&\
	$(MAKE) -j$(CORES) all-target-libgcc && $(MAKE) install-target-libgcc &&\
	touch $@

gcc1: $(HOST)/bin/$(TARGET)-as $(REF)/$(GCC)/README.md    \
      $(HOST)/lib/libmpfr.a $(HOST)/lib/libmpc.a $(GDCH)
	mkdir -p $(TMP)/$(GCC)-1 ; cd $(TMP)/$(GCC)-1                             ;\
	$(XPATH) $(REF)/$(GCC)/$(CFG_HOST) $(CFG_GCC1)                           &&\
	$(MAKE) -j$(CORES)     all-target-libphobos
# $(MAKE) -j$(CORES) all-gcc              && $(MAKE) install-gcc           &&\
# $(MAKE) -j$(CORES) all-target-libgcc    && $(MAKE) install-target-libgcc &&\
# $(MAKE) -j$(CORES)     all-target-libstdc++-v3                           &&\
# $(MAKE)            install-target-libstdc++-v3                           &&\
# $(MAKE) -j$(CORES)     all-target-libphobos                              &&\
# $(MAKE)            install-target-libphobos

.PHONY: linux

KMAKE  = $(XPATH) make -C $(REF)/$(LINUX) O=$(TMP)/$(LINUX) \
         ARCH=$(ARCH) CROSS_COMPILE=$(TARGET)- \
         INSTALL_MOD_PATH=$(ROOT) INSTALL_HDR_PATH=$(ROOT)/usr
KONFIG = $(TMP)/$(LINUX)/.config

linux: $(REF)/$(LINUX)/README.md
	mkdir -p $(TMP)/$(LINUX) ; rm $(KONFIG) ; $(KMAKE) allnoconfig &&\
	cat $(CWD)/all/all.kernel $(CWD)/arch/$(ARCH).kernel             \
		$(CWD)/cpu/$(CPU).kernel $(CWD)/hw/$(HW).kernel              \
		$(CWD)/app/$(APP).kernel                   >> $(KONFIG)    &&\
	echo CONFIG_LOCALVERSION=\"-$(APP)@$(HW)\"     >> $(KONFIG)    &&\
	echo CONFIG_DEFAULT_HOSTNAME=\"$(APP)\"        >> $(KONFIG)    &&\
	$(KMAKE)            menuconfig                                 &&\
	$(KMAKE) -j$(CORES) bzImage modules                            &&\
	$(KMAKE)            modules_install headers_install && $(MAKE) fw

.PHONY: iconv

iconv: $(HOST)/bin/iconv
$(HOST)/bin/iconv: $(REF)/$(ICONV)/configure
	mkdir -p $(TMP)/$(ICONV) ; cd $(TMP)/$(ICONV)           ;\
	$(REF)/$(ICONV)/$(CFG_HOST) && $(MAKE) -j$(CORES) && $(MAKE) install
$(REF)/$(ICONV)/configure: $(REF)/$(ICONV)/gnulib/README
	cd $(REF)/$(ICONV) ; ./autogen.sh
$(REF)/$(ICONV)/gnulib/README: $(REF)/$(ICONV)/README.md
	cd $(REF)/$(ICONV) ; ./gitsub.sh pull --depth 1

.PHONY: musl

MMAKE    = $(XPATH) make -C $(REF)/$(MUSL) O=$(TMP)/$(MUSL) \
           ARCH=$(ARCH) PREFIX=$(ROOT)
CFG_MUSL = --prefix=$(ROOT) --exec-prefix=$(ROOT)/musl/exec \
		   --includedir=$(ROOT)/include --syslibdir=$(ROOT)/lib \
           --target=$(TARGET) CROSS_COMPILE=$(TARGET)- \
		   --enable-optimize CFLAGS="-I$(ROOT)/usr/include -O3 -march=$(CPU) -mtune=generic"

musl: $(REF)/$(MUSL)/README.md
	mkdir -p $(TMP)/$(MUSL) ; cd $(TMP)/$(MUSL)              ;\
	$(XPATH) $(REF)/$(MUSL)/configure $(CFG_MUSL)           &&\
	$(XPATH) $(MAKE) -j$(CORES) && $(XPATH) $(MAKE) install

.PHONY: uclibc

UMAKE  = $(XPATH) make -C $(REF)/$(UCLIBC) O=$(TMP)/$(UCLIBC) \
         ARCH=$(ARCH) PREFIX=$(ROOT)
UONFIG = $(TMP)/$(UCLIBC)/.config

uclibc: $(REF)/$(UCLIBC)/README.md
	mkdir -p $(TMP)/$(UCLIBC) ; cd $(TMP)/$(UCLIBC)           ;\
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
# $(ROOT)/%: src/%.c Makefile
# 	$(XPATH) $(TARGET)-gcc -o $@ $< && file $@ && $(HOST)/bin/ldd $@
$(ROOT)/%: src/%.d Makefile
	$(XPATH) $(TARGET)-gdc -o $@ $< && file $@ && $(HOST)/bin/ldd $@

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
	sudo apt install -yu `cat apt.$(OS)`
$(APT_SRC)/%: tmp/%
	sudo cp $< $@
tmp/d-apt.list:
	$(CURL) $@ http://master.dl.sourceforge.net/project/d-apt/files/d-apt.list

gz: $(LDC2) \
	$(GZ)/$(GMP_GZ) $(GZ)/$(MPFR_GZ) $(GZ)/$(MPC_GZ)         \
	$(GZ)/$(BINUTILS_GZ) $(GZ)/$(GCC_GZ) $(GZ)/$(ISL_GZ)     \
	$(GZ)/$(LINUX_GZ) $(GZ)/$(UCLIBC_GZ) $(GZ)/$(MUSL_GZ)    \
	$(GZ)/$(SYSLINUX_GZ) $(GZ)/$(ICONV_GZ) $(GZ)/$(BUSYBOX_GZ)

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
$(GZ)/$(ISL_GZ):
	$(CURL) $@ https://gcc.gnu.org/pub/gcc/infrastructure/$(ISL_GZ)

$(GZ)/$(BINUTILS_GZ):
	$(CURL) $@ https://ftp.gnu.org/gnu/binutils/$(BINUTILS_GZ)
$(GZ)/$(GCC_GZ):
	$(CURL) $@ http://mirror.linux-ia64.org/gnu/gcc/releases/$(GCC)/$(GCC_GZ)

$(GZ)/$(LINUX_GZ):
	$(CURL) $@ https://cdn.kernel.org/pub/linux/kernel/v6.x/$(LINUX_GZ)
$(GZ)/$(UCLIBC_GZ):
	$(CURL) $@ https://downloads.uclibc-ng.org/releases/$(UCLIBC_VER)/$(UCLIBC_GZ)
$(GZ)/$(MUSL_GZ):
	$(CURL) $@ https://musl.libc.org/releases/$(MUSL_GZ)
$(GZ)/$(BUSYBOX_GZ):
	$(CURL) $@ https://busybox.net/downloads/$(BUSYBOX_GZ)

$(GZ)/$(SYSLINUX_GZ):
	$(CURL) $@ https://mirrors.edge.kernel.org/pub/linux/utils/boot/syslinux/$(SYSLINUX_GZ)

$(GZ)/$(ICONV_GZ):
	$(CURL) $@ https://github.com/roboticslibrary/libiconv/archive/refs/tags/v$(ICONV_VER).tar.gz

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
