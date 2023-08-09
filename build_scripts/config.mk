# to run something not related (directly) to the operating system on the host machine:
export ASM = nasm  # assembler
export ASMFLAGS = 
export CPPFLAGS = -std=c++03 -g  # flags for the C++ compiler: c++03 standard for compiling, generate debugging symbols
export CXX = g++  # C++ compiler
export LD = g++  # linker, can also use gcc
export LDFLAGS =
export LIBS = 

# to run something related/on the operating system:
export TARGET = i686-elf
export TARGET_ASM = nasm  # assembler
export TAGET_ASMFLAGS =
export TARGET_CPPFLAGS = -std=c++03 -g
export TARGET_CXX = $(TARGET)-$(CXX)  # target compiler for c++
export TARGET_LD = $(TARGET)-$(CXX)  # target linker, can use gcc if g++ does not work
export TARGET_LDFLAGS = 
export TARGET_LIBS = 

export BUILD_DIR = $(abspath build)


BINUTILS_VRS = 2.37
BINUTILS_URL = https://ftp.gnu.org/gnu/binutils/binutils-$(BINUTILS_VRS).tar.xz
GCC_VRS = 13.2.0
GCC_URL = https://ftp.gnu.org/gnu/gcc/gcc-$(GCC_VRS)/gcc-$(GCC_VRS).tar.xz