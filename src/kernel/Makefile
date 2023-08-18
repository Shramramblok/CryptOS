ASMFLAGS += -f elf  # += because it already exists in config.mk
CPPFLAGS += -ffreestanding -nostdlib  # not related to any specific OS, no extended libfiles
LIBS += -lgcc
LDFLAGS += -T linker.ld -nostdlib

SOURCES_CPP=$(wildcard *.cpp)  # get all the .cpp source files
SOURCES_ASM=$(wildcard *.asm)  # get all the .asm source files
OBJECTS_CPP=$(patsubst %.cpp, $(BUILD_DIR)/kernel/cpp/%.obj, $(SOURCES_CPP)) # create .obj files to all .cpp source files
OBJECTS_ASM=$(patsubst %.asm, $(BUILD_DIR)/kernel/asm/%.obj, $(SOURCES_ASM)) # create .obj files to all .asm source files

.PHONY: kernel clean always

kernel: $(BUILD_DIR)/kernel.bin
$(BUILD_DIR)/kernel.bin: $(OBJECTS_ASM) $(OBJECTS_CPP)  # link all .obj files into kernel.bin 
	$(LD) $(LDFLAGS) -Wl,-Map=$(BUILD_DIR)/kernel.map -o $@ $^

$(BUILD_DIR)/kernel/cpp/%.obj: %.cpp always
	$(CXX) $(CPPFLAGS) -c -o $@ $<  # compile all of the .cpp source files

$(BUILD_DIR)/kernel/asm/%.obj: %.asm always
	$(ASM) $(ASMFLAGS) -o $@ $< # assemble all of the .asm source files

always:
	mkdir -p $(BUILD_DIR)/kernel/cpp
	mkdir -p $(BUILD_DIR)/kernel/asm

clean:
	rm -rf $(BUILD_DIR)/kernel.bin
	rm -rf $(BUILD_DIR)/kernel.map
