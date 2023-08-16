#pragma once
#include <stdint.h>
#include <stdbool.h>

extern "C"{
    void x86_RealModePutC(char c) __attribute__((__cdecl__));  // test macros for entering pmode/rmode, just like the old WriteChar
    bool x86_GetDiskParamsProt(uint8_t drive, uint16_t* cylinders, uint8_t* heads, uint8_t* sectors, uint8_t* driveType) __attribute__((__cdecl__));
    bool x86_ResetDiskProt(uint8_t drive) __attribute__((__cdecl__));
    bool x86_ReadDiskProt(uint8_t drive, uint16_t cylinder, uint8_t head, uint8_t sector, uint8_t count, uint8_t* buffer) __attribute__((__cdecl__));
    void x86_Divide_64_32_Prot(uint64_t dividend, uint32_t divisor, uint64_t* quotient, uint32_t* remainder) __attribute__((__cdecl__));
    void x86_outb(uint16_t port, uint8_t value) __attribute__((__cdecl__));  // outputs a value to a certain port
    uint8_t x86_inpb(uint16_t port) __attribute__((__cdecl__));  // gets input from a certain port, used by setcursor
}

