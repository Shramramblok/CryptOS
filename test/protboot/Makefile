ASM = nasm
SRC_DIR = src
BUILD_DIR = build

image: $(BUILD_DIR)/test.img

$(BUILD_DIR)/test.img: $(BUILD_DIR)/protboot.bin always
	cp $(BUILD_DIR)/protboot.bin $(BUILD_DIR)/test.img  # copy into image
	truncate -s 1440k $(BUILD_DIR)/test.bin  # extend file to 1.44MB 

$(BUILD_DIR)/protboot.bin: $(SRC_DIR)/protboot.asm always
	$(ASM) $(SRC_DIR)/protboot.asm -f bin -o $(BUILD_DIR)/protboot.bin

always:
	mkdir -p $(BUILD_DIR)
run:
	qemu-systemi386 -fda $(BUILD_DIR)/test.img

debug:
	bochs -f bochs_config

.PHONY: image run debug