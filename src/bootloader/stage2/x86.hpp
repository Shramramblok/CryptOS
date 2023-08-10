#include <stdint.h>

extern "C"{
    // void _cdecl x86_WriteChar(char c, uint8_t page);
    void _cdecl x86_Divide_64_32(uint64_t dividend, uint32_t divisor, uint64_t* quotient, uint32_t* remainder);
    uint8_t _cdecl x86_inpb(uint16_t port);  // gets input from a certain port, used by setcursor
    void _cdecl x86_outb(uint16_t port, uint8_t value);  // outputs a value to a certain port
    // bool _cdecl x86_ResetDisk(uint8_t drive);
    // bool _cdecl x86_ReadDisk(uint8_t drive, uint16_t cylinder, uint8_t head, uint8_t sector, uint8_t count, uint8_t far * buffer);
    // bool _cdecl x86_GetDiskParameters(uint8_t drive, uint16_t* cylinders, uint8_t* heads, uint8_t* sectors, uint8_t* driveType);
}

