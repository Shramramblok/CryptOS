#pragma once
#include <stdint.h>
#include <stdbool.h>

extern "C"{
    void _cdecl x86_RealModePutC(char c);  // test macros for entering pmode/rmode, just like the old WriteChar
    bool _cdecl x86_GetDiskParamsProt(uint8_t drive, uint16_t* cylinders, uint8_t* heads, uint8_t* sectors, uint8_t* driveType);
    bool _cdecl x86_ResetDiskProt(uint8_t drive);
    bool _cdecl x86_ReadDiskProt(uint8_t drive, uint16_t cylinder, uint8_t head, uint8_t sector, uint8_t count, uint8_t* buffer);
    void _cdecl x86_Divide_64_32_Prot(uint64_t dividend, uint32_t divisor, uint64_t* quotient, uint32_t* remainder);
    void _cdecl x86_outb(uint16_t port, uint8_t value);  // outputs a value to a certain port
    uint8_t _cdecl x86_inpb(uint16_t port);  // gets input from a certain port, used by setcursor
}

