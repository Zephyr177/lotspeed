KERNEL_RELEASE  ?= $(shell uname -r)
KERNEL_DIR      ?= /lib/modules/$(KERNEL_RELEASE)/build
DKMS_TARBALL    ?= dkms.tar.gz
TAR             ?= tar
obj-m           += lotspeed.o

KERNEL_COMPILE_H := $(KERNEL_DIR)/include/generated/compile.h
KERNEL_CONFIG    := $(KERNEL_DIR)/.config
KERNEL_COMPILER  := $(shell \
	if grep -qs '^CONFIG_CC_IS_CLANG=y' $(KERNEL_CONFIG) 2>/dev/null; then \
		echo clang; \
	elif grep -qs '^CONFIG_CC_IS_GCC=y' $(KERNEL_CONFIG) 2>/dev/null; then \
		echo gcc; \
	elif grep -qi 'clang' $(KERNEL_COMPILE_H) 2>/dev/null; then \
		echo clang; \
	elif grep -qi 'gcc' $(KERNEL_COMPILE_H) 2>/dev/null; then \
		echo gcc; \
	elif grep -qi 'clang' /proc/version 2>/dev/null; then \
		echo clang; \
	elif grep -qi 'gcc' /proc/version 2>/dev/null; then \
		echo gcc; \
	fi)

AUTO_BUILD_CC := gcc
AUTO_BUILD_LLVM :=
ifneq ($(findstring clang,$(KERNEL_COMPILER)),)
AUTO_BUILD_CC := clang
AUTO_BUILD_LLVM := 1
endif

ccflags-y := -std=gnu99 \
	-Wno-error=int-in-bool-context \
	-Wno-error=unused-variable

.PHONY: all clean load unload
.PHONY: .always-make

all:
	$(MAKE) -C $(KERNEL_DIR) M=$(PWD) modules CC=$(AUTO_BUILD_CC) $(if $(AUTO_BUILD_LLVM),LLVM=$(AUTO_BUILD_LLVM))

clean: clean-dkms.conf clean-dkms-tarball
	$(MAKE) -C $(KERNEL_DIR) M=$(PWD) clean

load:
	sudo insmod lotspeed.ko

unload:
	sudo rmmod lotspeed

.PHONY: dkms-tarball clean-dkms-tarball clean-dkms.conf

.always.make:

dkms.conf: ./scripts/mkdkmsconf.sh .always-make
	./scripts/mkdkmsconf.sh > dkms.conf

clean-dkms.conf:
	$(RM) dkms.conf

$(DKMS_TARBALL): dkms.conf Makefile lotspeed.c
	$(TAR) zcf $(DKMS_TARBALL) \
		--transform 's,^,./dkms_source_tree/,' \
		dkms.conf \
		Makefile \
		lotspeed.c

dkms-tarball: $(DKMS_TARBALL)

clean-dkms-tarball:
	$(RM) $(DKMS_TARBALL)
