BUILD_DIR?=build/
ASM?=nasm
CC16?=/usr/bin/watcom/binl64/wcc # path to the compiler
LD16?=/usr/bin/watcom/binl64/wlink # path to the linker

CFLAGS16?=-4 -d3 -s -wx -ms -zl -zq
# meaning of each C flag:
# -4: make the final file be compatible with 486 machine code (minimum for watcom compiler to work correctly)
# -d3: full symbolic debugging, use as much symbols to debug as possible (useful for debugging)
# -s: disable stack overflow checks (cannot implement the needed checks yet so for now keep them disabled)
# -wx: enable all possible warnings
# -ms: use small memory model (CS and DS are different, pointers for both can only point to "near" ojects to use less memory)
# reason for choosing small model: - easiest to work with and compatible with our "small" bootloader size
# -zl: remove all refrences to library files after linking (not possible to communicate with them after linking)
# -zq: "quiet" output (opposite of verbose, output only warnings, errors..)

ASMFLAGS?=-f obj
SOURCES_C=$(wildcard *.c) # get all the .c source files
SOURCES_ASM=$(wildcard *.asm) # get all the .asm source files
OBJECTS_C=$(patsubst %.c, $(BUILD_DIR)/stage2/c/%.obj, $(SOURCES_C)) # create .obj files to all .c source files
OBJECTS_ASM=$(patsubst %.asm, $(BUILD_DIR)/stage2/asm/%.obj, $(SOURCES_ASM)) # create .obj files to all .asm source files

.PHONY: stage2 clean always

stage2: $(BUILD_DIR)/stage2.bin
$(BUILD_DIR)/stage2.bin: $(OBJECTS_ASM) $(OBJECTS_C) # link all .obj files into stage2.bin 
	$(LD16) NAME $(BUILD_DIR)/stage2.bin FILE \{ $(OBJECTS_ASM) $(OBJECTS_C) \} OPTION MAP=$(BUILD_DIR)/stage2.map @linker.lnk

$(BUILD_DIR)/stage2/c/%.obj: %.c always
	$(CC16) $(CFLAGS16) -fo=$@ $< # compile all of the .c source files

$(BUILD_DIR)/stage2/asm/%.obj: %.asm always
	$(ASM) $(ASMFLAGS) -o $@ $< # assemble all of the .asm source files

always:
	mkdir -p $(BUILD_DIR)/stage2/c
	mkdir -p $(BUILD_DIR)/stage2/asm

clean:
	rm -rf $(BUILD_DIR)/stage2.bin
	rm -rf $(BUILD_DIR)/stage2.map
