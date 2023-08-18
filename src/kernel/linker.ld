# note: . = current address
ENTRY(cppstart)  # kernel starts in the cppstart() function of the relative main.cpp
OUTPUT_FORMAT("binary")
stage2_physaddr = 0x00100000;  # will give us 1MB for the kernel

SECTIONS {
    . = stage2_physaddr;

    .entry : {__entry_start = .; *(.entry)}  # entry section - set to be cppstart() in kernel
    .text : {__text_start = .; *(.text)}  # text section
    .data : {__data_start = .; *(.data)}  # data section
    .rodata : {__rodata_start = .; *(.rodata)}  # read-only data section (constants..)
    .bss : {__bss_start = .; *(.bss)}  # bss section (uninitialized data)

    __end = .;
}   
