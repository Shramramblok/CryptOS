#include "stdint.h"

extern "C"{
    void _cdecl x86_WriteChar(char c, uint8_t page);
    void _cdecl x86_Divide_64_32(uint64_t dividend, uint32_t divisor, uint64_t* quotient, uint32_t* remainder);
    bool _cdecl x86_ResetDisk(uint8_t drive);
    bool _cdecl x86_ReadDisk(uint8_t drive, uint16_t cylinder, uint8_t head, uint8_t sector, uint8_t count, uint8_t* buffer);
    bool _cdecl x86_GetDiskParameters(uint8_t drive, uint16_t* cylinders, uint8_t* heads, uint8_t* sectors, uint8_t* driveType);
}

