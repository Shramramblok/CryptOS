toolchain: toolchain_binutils toolchain_gcc

TOOLCHAIN_PREFIX = $(abspath toolchain/$(TARGET))

BINUTILS_SRC = toolchain/binutils-$(BINUTILS_VRS)
BINUTILS_BUILDDIR = toolchain/build-binutils-$(BINUTILS_VRS)
GCC_SRC = toolchain/gcc-$(GCC_VRS)
GCC_BUILDDIR = toolchain/build-gcc-$(GCC_VRS)

export PATH := $(TOOLCHAIN_PREFIX)/bin:$(PATH)


# install and activate the binutils dependency of the GCC compiler:
toolchain_binutils: $(BINUTILS_SRC).tar.xz 
	cd $(BINUTILS_BUILDDIR) && tar -xf binutils-$(BINUTILS_VRS).tar.xz
	cd $(BINUTILS_BUILDDIR) &&  ../binutils-$(BINUTILS_VRS)/configure --prefix="$(TOOLCHAIN_PREFIX)" --target=$(TARGET) --with-sysroot --disable-nls --disable-werror
	$(MAKE) -j8 -C $(BINUTILS_BUILDDIR)
	$(MAKE) -C $(BINUTILS_BUILDDIR) install

$(BINUTILS_SRC).tar.xz:
	rm -rf toolchain
	mkdir -p toolchain
	cd toolchain && wget $(BINUTILS_URL)


# install and activate the GCC compiler:
toolchain_gcc: toolchain_binutils $(GCC_SRC).tar.xz
	cd $(GCC_BUILDDIR) && tar -xf gcc-$(GCC_VRS).tar.xz
	cd $(GCC_BUILDDIR) &&  ../gcc-$(GCC_VRS)/configure --prefix="$(TOOLCHAIN_PREFIX)" --prefix=$(TARGET) --disable-nls --enable-languages=c,c++ --without-headers
	$(MAKE) -j8 -C $(GCC_BUILDDIR) all-gcc all-target-libgcc
	$(MAKE) -C $(GCC_BUILDDIR) install-gcc install-target-libgcc

$(GCC_SRC).tar.xz:
	mkdir -p toolchain  # if binutils could not create this directory correctly
	mkdir -p $(GCC_BUILDDIR)
	cd $(GCC_BUILDDIR) && wget $(GCC_URL)


# clean:
clean_toolchain:  # content of toolchain (files) and directory itself
	rm -rf toolchain/*
	rmdir toolchain

.PHONY: toolchain toolchain_binutils toolchain_gcc clean_toolchain