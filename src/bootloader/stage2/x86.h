#include "stdint.h"

extern "C"{
    void _cdecl x86_WriteChar(char c, uint8_t page);
    void _cdecl x86_Divide_64_32(uint64_t dividend, uint32_t divisor, uint64_t* quotient, uint32_t* remainder);
}

