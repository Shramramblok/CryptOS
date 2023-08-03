BUILD_DIR?=build
ASM?=nasm

.PHONY: kernel clean

kernel: $(BUILD_DIR)/kernel.bin
$(BUILD_DIR)/kernel.bin:
	$(ASM) kernel.asm -f bin -o $(BUILD_DIR)/kernel.bin

clean:
	rm -rf $(BUILD_DIR)/kernel.bin