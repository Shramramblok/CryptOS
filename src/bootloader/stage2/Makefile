ASMFLAGS += -f elf  # += because it already exists in config.mk
CPPFLAGS += -ffreestanding -nostdlib  # not related to any specific OS, no extended libfiles
LIBS += -lgcc
LDFLAGS += -T linker.ld -nostdlib

SOURCES_CPP=$(wildcard *.cpp)  # get all the .cpp source files
SOURCES_ASM=$(wildcard *.asm)  # get all the .asm source files
OBJECTS_CPP=$(patsubst %.cpp, $(BUILD_DIR)/stage2/cpp/%.obj, $(SOURCES_CPP)) # create .obj files to all .cpp source files
OBJECTS_ASM=$(patsubst %.asm, $(BUILD_DIR)/stage2/asm/%.obj, $(SOURCES_ASM)) # create .obj files to all .asm source files

.PHONY: stage2 clean always

stage2: $(BUILD_DIR)/stage2.bin
$(BUILD_DIR)/stage2.bin: $(OBJECTS_ASM) $(OBJECTS_CPP)  # link all .obj files into stage2.bin 
	$(LD) $(LDFLAGS) -Wl,-Map=$(BUILD_DIR)/stage2.map -o $@ $^

$(BUILD_DIR)/stage2/cpp/%.obj: %.cpp always
	$(CXX) $(CPPFLAGS) -c -o $@ $<  # compile all of the .cpp source files

$(BUILD_DIR)/stage2/asm/%.obj: %.asm always
	$(ASM) $(ASMFLAGS) -o $@ $< # assemble all of the .asm source files

always:
	mkdir -p $(BUILD_DIR)/stage2/cpp
	mkdir -p $(BUILD_DIR)/stage2/asm

clean:
	rm -rf $(BUILD_DIR)/stage2.bin
	rm -rf $(BUILD_DIR)/stage2.map
