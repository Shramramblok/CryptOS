BUILD_DIR?=build
ASM?=nasm

.PHONY: stage1 clean

stage1: $(BUILD_DIR)/stage1.bin
$(BUILD_DIR)/stage1.bin:
	$(ASM) stage1.asm -f bin -o $(BUILD_DIR)/stage1.bin

clean:
	rm -rf $(BUILD_DIR)/stage1.bin