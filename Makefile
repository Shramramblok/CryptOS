ASM=nasm

SRC_DIR=src
BUILD_DIR=build

.PHONY: all floopy_image bootloader kernel clean always

#floopy image
floopy_image: $(BUILD_DIR)/main_f.img
$(BUILD_DIR)/main_f.img: bootloader kernel
	dd if=/dev/zero of=$(BUILD_DIR)/main_f.img bs=512 count=2880
	mkfs.fat -F 12 $(BUILD_DIR)/main_f.img
	dd if=$(BUILD_DIR)/bootloader.bin of=$(BUILD_DIR)/main_f.img conv=notrunc
	mcopy -i $(BUILD_DIR)/main_f.img $(BUILD_DIR)/kernel.bin "::kernel.bin"

#bootloader
bootloader: $(BUILD_DIR)/bootloader.bin
$(BUILD_DIR)/bootloader.bin: always
	$(ASM) $(SRC_DIR)/bootloader/boot.asm -f bin -o $(BUILD_DIR)/bootloader.bin


#kernel
kernel: $(BUILD_DIR)/kernel.bin
$(BUILD_DIR)/kernel.bin: always
	$(ASM) $(SRC_DIR)/kernel/kernel.asm -f bin -o $(BUILD_DIR)/kernel.bin

#always
always:
	mkdir -p $(BUILD_DIR)

#clean
clean:
	rm -rf $(BUILD_DIR)/*
