toolchain: toolchain_binutils gdb toolchain_gcc clean_toolchain

TARGET = i686-elf
TARGET_NAME = i686  # actually used for getting binutils, the prefix..
TOOLCHAIN_PREFIX = $(abspath toolchain/$(TARGET))
CONST_CONFFLGS = --target=$(TARGET) --prefix=$(TOOLCHAIN_PREFIX)

BINUTILS_WORKDIR = toolchain/build-binutils/binutils$(TARGET_NAME)
BINUTILS_CONFFLGS = $(CONST_CONFFLGS) --with-sysroot --disable-nls --disable-werror
GDB_CONFFLGS = $(CONST_CONFFLGS) --disable-werror

GCC_WORKDIR = toolchain/build-gcc/gcc$(TARGET_NAME)
GCC_CONFFLGS = $(CONST_CONFFLGS) --disable-nls --enable-languages=c,c++ --without-headers


# install and activate the binutils dependency of the GCC compiler:
.PHONY: toolchain_binutils

toolchain_binutils: get-binutils 
	cd $(BINUTILS_WORKDIR)/ && sudo ./configure $(BINUTILS_CONFFLGS)
	cd $(BINUTILS_WORKDIR)/ && sudo make && sudo make install
	cd $(BINUTILS_WORKDIR)/gdb && sudo ./configure $(GDB_CONFFLGS)
	cd $(BINUTILS_WORKDIR)/gdb && sudo make all-gdb && sudo make install-gdb

get-binutils:
	sudo mkdir -p toolchain
	cd toolchain && sudo mkdir -p build-binutils
	cd toolchain/build-binutils && sudo git clone https://github.com/bminor/binutils-gdb.git ./binutils$(TARGET_NAME)


# install and activate the GCC compiler:
.PHONY: toolchain_gcc

toolchain_gcc: toolchain_binutils get-gcc
	cd $(GCC_WORKDIR) && sudo toolchain/build-gcc/gcc/configure $(GCC_CONFFLGS)
	cd $(GCC_WORKDIR) && sudo make all-gcc && sudo make all-target-libgcc
	cd $(GCC_WORKDIR) && sudo make install-gcc && sudo make install-target-libgcc

get-gcc:
	sudo mkdir -p toolchain  # if binutils could not create this directory correctly
	cd toolchain && sudo mkdir -p build-gcc
	git clone git://gcc.gnu.org/git/gcc.git ./gcc$(TARGET_NAME)


# clean:
.PHONY: clean-toolchain

clean_toolchain:
	sudo rm -rf toolchain/*
	sudo rmdir toolchain