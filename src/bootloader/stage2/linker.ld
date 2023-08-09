# note: . = current address
ENTRY(entry)  # specify entry point label (from entry_p.asm)
OUTPUT_FORMAT("binary")
stage2_physaddr = 0x00000500;  # segment 0x0000, offset 0x0500

SECTIONS {
    . = stage2_physaddr;  # starts at this address

    .entry : {__entry_start = .; *(.entry)}  # entry section
    .text : {__text_start = .; *(.text)}  # text section
    .data : {__data_start = .; *(.data)}  # data section
    .rodata : {__rodata_start = .; *(.rodata)}  # read-only data section (constants..)
    .bss : {__bss_start = .; *(.bss)}  # bss section (uninitialized data)

    __end = .;
}   
