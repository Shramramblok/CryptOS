Initial README file for the best OS in the world:

languages: c++, assembly x86 16+32 bit, makefile
bootloader: boot sector is set up by legacy booting standards, for now this part is split to 2 parts - bootsector (stage1, first 512 bytes) and stage2 (the rest of the bootloader, transitioning into protected mode, loading kernel)
file system: based on ext2

DEPENDENCIES:
nasm - dissassemblying
gcc - compiling and linking
binutils - dependency for gcc
make - used to configure everything
