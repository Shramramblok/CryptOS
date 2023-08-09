#include "stdio.h"
#include "x86.hpp"

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

void putn_printf(int* &argp, uint8_t size, bool sign, uint32_t base, int incsize)
{
    if (size < sizeof(int))
        size = sizeof(int);
    switch (size)
    {
    case 1:
    case 2:
        if (sign)
            puti(*(int16_t*)argp, base);
        else
            putu(*(uint16_t*)argp, base);
        break;
    case 4:
        if (sign)
            puti(*(int32_t*)argp, base);
        else
            putu(*(uint32_t*)argp, base);
        break;
    case 8:
        if (sign)
            puti(*(int64_t*)argp, base);
        else
            putu(*(uint64_t*)argp, base);
        break;
    }

    argp += incsize * size / sizeof(int);
}

void _cdecl printf(const char* fmt, ...){
    int* argp = (int*)&fmt;  // stack is aligned to the int datatype
    int incsize = sizeof(int64_t) / sizeof(fmt);
    argp += incsize;  // points to the second argument
    uint8_t size = sizeof(int);

    while (*fmt){
        if (*fmt == '%')
        {
            fmt++;
            switch (*fmt)
            {
            case 'l':
                if (*(fmt + 1) == 'l')
                {
                    size = 8;
                    fmt++;
                }
                else
                {
                    size = 4;
                }
                fmt++;
                break;
                
            case 'h':
                if (*(fmt + 1) == 'h')
                {
                    size = 1;
                    fmt++;
                }
                else
                {
                    size = 2;
                }
                fmt++;
                break;
            }
            
            switch (*fmt)
            {
            
            case 'c':
                putc(*argp);
                argp += incsize;
                break;
            case 's':
                puts((char*)*argp);
                argp += incsize;
                break;
            case 'd':
            case 'i':
                putn_printf(argp, size, true, 10, incsize);
                break;
            case 'u':
                putn_printf(argp, size, false, 10, incsize);
                break;
            case 'p':
            case 'X':
            case 'x':
                putn_printf(argp, size, false, 16, incsize);
                break;
            case 'o':
                putn_printf(argp, size, false, 8, incsize);
                break;
            case '%':
                putc('%');
                break;
            default:
                break;
        }
        fmt += incsize; // move to the next character in the format string
    }
}
