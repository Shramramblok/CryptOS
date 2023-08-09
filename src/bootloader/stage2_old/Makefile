BUILD_DIR?=build/
ASM?=nasm
CC16?=/usr/bin/watcom/binl64/wpp # path to the compiler
LD16?=/usr/bin/watcom/binl64/wlink # path to the linker

CPPFLAGS16?=-4 -d2t -s -wx -ms -zl -zq
# meaning of each .cpp flag:
# -4: make the final file be compatible with 486 machine code (minimum for watcom compiler to work correctly)
# -d3: full symbolic debugging, use as much symbols to debug as possible (useful for debugging)
# -s: disable stack overflow checks (cannot implement the needed checks yet so for now keep them disabled)
# -wx: enable all possible warnings
# -ms: use small memory model (CS and DS are different, pointers for both can only point to "near" ojects to use less memory)
# reason for choosing small model: - easiest to work with and compatible with our "small" bootloader size
# -zl: remove all refrences to library files after linking (not possible to communicate with them after linking)
# -zq: "quiet" output (opposite of verbose, output only warnings, errors..)

ASMFLAGS?=-f obj
SOURCES_CPP=$(wildcard *.cpp)  # get all the .cpp source files
SOURCES_ASM=$(wildcard *.asm)  # get all the .asm source files
OBJECTS_CPP=$(patsubst %.cpp, $(BUILD_DIR)/stage2/cpp/%.obj, $(SOURCES_CPP))  # create .obj files to all .cpp source files
OBJECTS_ASM=$(patsubst %.asm, $(BUILD_DIR)/stage2/asm/%.obj, $(SOURCES_ASM))  # create .obj files to all .asm source files

.PHONY: stage2 clean always

stage2: $(BUILD_DIR)/stage2.bin
$(BUILD_DIR)/stage2.bin: $(OBJECTS_ASM) $(OBJECTS_CPP)  # link all .obj files into stage2.bin 
	$(LD16) NAME $(BUILD_DIR)/stage2.bin FILE \{ $(OBJECTS_ASM) $(OBJECTS_CPP) \} OPTION MAP=$(BUILD_DIR)/stage2.map @linker.lnk

$(BUILD_DIR)/stage2/cpp/%.obj: %.cpp always
	$(CC16) $(CPPFLAGS16) -fo=$@ $< # compile all of the .cpp source files

$(BUILD_DIR)/stage2/asm/%.obj: %.asm always
	$(ASM) $(ASMFLAGS) -o $@ $< # assemble all of the .asm source files

always:
	mkdir -p $(BUILD_DIR)/stage2/cpp
	mkdir -p $(BUILD_DIR)/stage2/asm

clean:
	rm -rf $(BUILD_DIR)/stage2.bin
	rm -rf $(BUILD_DIR)/stage2.map
