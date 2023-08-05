#include "stdio.h"
#include "x86.h"

void putc(char c)
{
    x86_WriteChar(c, 0);
}

void puts(const char* str)
{
    while (*str)
    {
        putc(*str++);
    }
}

char* hexDigits = "0123456789ABCDEF";

void putu(uint64_t value, uint32_t base)
{
    uint32_t remainder;
    char buffer[64];
    uint64_t quotient = 0;
    char* p = buffer;
    do
    {
        x86_Divide_64_32(value, base, &quotient, &remainder);
        value = quotient;
        *p++ = hexDigits[remainder];
    } while (value);
    while (p > buffer)
    {
        
        putc(*--p);
    }
}

void puti(int64_t value, uint32_t base)
{
    if (value < 0)
    {
        putc('-');
        value = -value;
    }
    putu(value, base);
}
