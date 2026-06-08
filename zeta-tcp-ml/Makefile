# Zeta-TCP Makefile (High-Performance Version)

obj-m += zeta_tcp.o
zeta_tcp-objs := zeta_main.o zeta_conn.o zeta_learning.o zeta_ack_control.o \
                 zeta_hooks.o zeta_proc.o zeta_percpu.o zeta_batch.o

KERNEL_RELEASE ?= $(shell uname -r)
KDIR ?= /lib/modules/$(KERNEL_RELEASE)/build
PWD := $(shell pwd)

KERNEL_COMPILE_H := $(KDIR)/include/generated/compile.h
KERNEL_CONFIG    := $(KDIR)/.config
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

# 优化选项
ccflags-y := -O2 -std=gnu99 \
              -Wno-error=unused-variable \
              -DZETA_VERSION=\"2.0.0\"

all:
	$(MAKE) -C $(KDIR) M=$(PWD) modules CC=$(AUTO_BUILD_CC) $(if $(AUTO_BUILD_LLVM),LLVM=$(AUTO_BUILD_LLVM))

clean:
	$(MAKE) -C $(KDIR) M=$(PWD) clean
	rm -f *.o *.ko *.mod.c *.order *.symvers

install:
	sudo insmod zeta_tcp.ko verbose=1 ack_split=1

uninstall:
	sudo rmmod zeta_tcp

reload: uninstall install

test:
	@echo "=== Zeta-TCP Stats ==="
	@cat /proc/zeta_tcp/stats
	@echo ""
	@echo "=== Per-CPU Stats ==="
	@cat /proc/zeta_tcp/percpu

.PHONY: all clean install uninstall reload test
