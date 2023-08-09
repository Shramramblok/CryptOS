toolchain: toolchain_binutils toolchain_gcc

TOOLCHAIN_PREFIX = $(abspath toolchain/$(TARGET))

BINUTILS_SRC = toolchain/binutils-$(BINUTILS_VRS)
BINUTILS_BUILDDIR = toolchain/build-binutils-$(BINUTILS_VRS)
GCC_SRC = toolchain/gcc-$(GCC_VRS)
GCC_BUILDDIR = toolchain/build-gcc-$(GCC_VRS)

export PATH := $(TOOLCHAIN_PREFIX)/bin:$(PATH)


# install and activate the binutils dependency of the GCC compiler:
toolchain_binutils: $(BINUTILS_SRC).tar.xz 
	cd toolchain && tar -xf binutils-$(BINUTILS_VRS).tar.xz
	mkdir $(BINUTILS_BUILDDIR)
	cd $(BINUTILS_BUILDDIR) &&  ../binutils-$(BINUTILS_VRS)/configure 
		--prefix="$(TOOLCHAIN_PREFIX)"
		--prefix=$(TARGET)
		--with-sysroot
		--disable-nls
		--disable-werror

	$(MAKE) -j8 -C $(BINUTILS_BUILDDIR)  # check if C is the driver or just a flag
	$(MAKE) -C $(BINUTILS_BUILDDIR) install  # check if C is the driver or just a flag

$(BINUTILS_SRC).tar.xz:
	mkdir -p toolchain
	cd toolchain && wget $(BINUTILS_URL)


# install and activate the GCC compiler:
toolchain_gcc: toolchain_binutils $(GCC_SRC).tar.xz
	cd toolchain && tar -xf gcc-$(GCC_VRS).tar.xz
	mkdir $(GCC_BUILDDIR)
	cd $(GCC_BUILDDIR) &&  ../gcc-$(GCC_VRS)/configure 
		--prefix="$(TOOLCHAIN_PREFIX)"
		--prefix=$(TARGET)
		--disable-nls
		--enable-languages=c,c++
		--without-headers

	$(MAKE) -j8 -C $(GCC_BUILDDIR) all-gcc all-target-libgcc  # check if C is the driver or just a flag
	$(MAKE) -C $(GCC_BUILDDIR) install-gcc install-target-libgcc  # check if C is the driver or j

$(GCC_SRC).tar.xz:
	mkdir -p toolchain  # if binutils could not create this directory correctly
	cd toolchain && wget $(GCC_URL)


# clean:
clean-tccontent:  # content of toolchain (files)
	rm -rf toolchain/*

clean-tcdirs:  # toolchain subdirectories that are used in the Makefile
	rm -rf $(BINUTILS_SRC) $(BINUTILS_BUILDDIR) $(GCC_SRC) $(GCC_BUILDDIR)

.PHONY: toolchain toolchain_binutils toolchain_gcc clean-tcdirs clean-tccontent