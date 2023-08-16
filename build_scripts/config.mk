# to run something not related (directly) to the operating system on the host machine:
export ASM = nasm  # assembler
export ASMFLAGS = 
export CPPFLAGS = -std=c++03 -g -m32 -fno-pie  # flags for the C++ compiler: c++03 standard for compiling, generate debugging symbols
export CXX = g++  # C++ compiler
export LD = g++  # linker, can also use gcc
export LDFLAGS = -m32
export LIBS = 

export BUILD_DIR = $(abspath build)


BINUTILS_VRS = 2.41
BINUTILS_URL = https://ftp.gnu.org/gnu/binutils/binutils-$(BINUTILS_VRS).tar.xz
GCC_VRS = 13.2.0
GCC_URL = https://ftp.gnu.org/gnu/gcc/gcc-$(GCC_VRS)/gcc-$(GCC_VRS).tar.xz