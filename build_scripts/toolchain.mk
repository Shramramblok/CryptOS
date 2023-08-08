toolchain: toolchain_binutils toolchain_gcc

TOOLCHAIN_PREFIX = toolchain/i686-elf
TARGET = i686-elf

BINUTILS_VRS = 2.37
BINUTILS_URL = https://ftp.gnu.org/gnu/binutils/binutils-$(BINUTILS_VRS).tar.xz
BINUTILS_BUILDDIR = toolchain/build-binutils-$(BINUTILS_VRS)

GCC_VRS = 13.2.0
GCC_URL = https://ftp.gnu.org/gnu/gcc/gcc-$(GCC_VRS)/gcc-$(GCC_VRS).tar.xz
GCC_BUILDDIR = toolchain/build-gcc-$(GCC_VRS)


toolchain_binutils:
	mkdir toolchain
	cd toolchain && wget $(BINUTILS_URL)
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


toolchain_gcc: toolchain_binutils
	cd toolchain && wget $(GCC_URL)
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
