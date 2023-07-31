ASM=nasm

SRC_DIR=src
BUILD_DIR=build

.PHONY: all floopy_image bootloader kernel clean always

#floopy image
floopy_image: $(BUILD_DIR)/main_f.img
$(BUILD_DIR)/main_f.img: clean bootloader kernel
	dd if=/dev/zero of=$(BUILD_DIR)/main_f.img bs=512 count=2880
	mkfs.ext2 $(BUILD_DIR)/main_f.img
	dd if=$(BUILD_DIR)/stage1.bin of=$(BUILD_DIR)/main_f.img conv=notrunc
	e2cp $(BUILD_DIR)/stage2.bin $(BUILD_DIR)/main_f.img:stage2.bin
	e2cp $(BUILD_DIR)/kernel.bin $(BUILD_DIR)/main_f.img:kernel.bin
	

#bootloader
bootloader: stage1 stage2

stage1: $(BUILD_DIR)/stage1.bin
$(BUILD_DIR)/stage1.bin: always
	$(MAKE) -C $(SRC_DIR)/bootloader/stage1 BUILD_DIR=$(abspath $(BUILD_DIR)) ASM=$(ASM)

stage2: $(BUILD_DIR)/stage2.bin
$(BUILD_DIR)/stage2.bin: always
	$(MAKE) -C $(SRC_DIR)/bootloader/stage2 BUILD_DIR=$(abspath $(BUILD_DIR)) ASM=$(ASM)


#kernel
kernel: $(BUILD_DIR)/kernel.bin
$(BUILD_DIR)/kernel.bin: always
	$(MAKE) -C $(SRC_DIR)/kernel BUILD_DIR=$(abspath $(BUILD_DIR)) ASM=$(ASM)

#always
always:
	mkdir -p $(BUILD_DIR)

#clean
clean:
	$(MAKE) -C $(SRC_DIR)/bootloader/stage1 BUILD_DIR=$(abspath $(BUILD_DIR)) ASM=$(ASM) clean
	$(MAKE) -C $(SRC_DIR)/bootloader/stage2 BUILD_DIR=$(abspath $(BUILD_DIR)) ASM=$(ASM) clean
	$(MAKE) -C $(SRC_DIR)/kernel BUILD_DIR=$(abspath $(BUILD_DIR)) ASM=$(ASM) clean
	rm -rf $(BUILD_DIR)/*
