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

void _cdecl printf(const char* fmt, ...){
    int* argp = (int*)&fmt;  // stack is aligned to the int datatype
    int incsize = sizeof(fmt) / sizeof(int);
    argp += incsize;  // points to the second argument
    int curst = PRINTF_NORMAL;
    int curln = PRINTFLN_DEFAULT;
    int numbase = 10;  // starts of as decimal
    int sign = false;  // starts of as unsigned

    while (*fmt){
        switch (curst){
            case PRINTF_NORMAL: 
                 switch (*fmt){
                    case '%': curst = PRINTF_LENGTH;
                              break;

                    default: putc(*fmt);  // if character != %: print it (normal letter)
                             break;
                 }
                 break;
            
            case PRINTF_LENGTH:
                 switch (*fmt){
                    case 'h': curln = PRINTFLN_SHORT;
                              curst = PRINTF_LNSHORT;
                              break;

                    case 'l': curln = PRINTFLN_LONG;
                              curst = PRINTF_LNLONG;
                              break; 

                    default: goto PRINTF_SPECLBL;
                 }
                 break;

            case PRINTF_LNSHORT:
                 if (*fmt == 'h'){
                    curln = PRINTFLN_SHORT_SHORT;
                    curst = PRINTF_SPECIFIER;
                 }
                 else{
                    goto PRINTF_SPECLBL;
                 }

            case PRINTF_LNLONG:
                 if (*fmt == 'l'){
                    curln = PRINTFLN_LONG_LONG;
                    curst = PRINTF_SPECIFIER;
                 }
                 else{
                    goto PRINTF_SPECLBL;
                 }

            case PRINTF_SPECIFIER:
            PRINTF_SPECLBL:
                switch (*fmt){
                    case 'c': putc((char)*argp);  // specifier "c" = specifies a character
                              argp += incsize;
                              break;

                    case 's': puts(*(char**)argp);  // specifier "s" = specifies a string
                              argp += incsize;
                              break;

                    case '%': putc('%');  // specifier "%" = specifies a '%' character
                              argp += incsize;
                              break;

                    case 'd': 
                    case 'i': numbase = 10;  // specifiers "i/d" = specifies a signed decimal 
                              sign = true;
                              puti(*argp, numbase);
                              argp += incsize;
                              break;

                    case 'u': numbase = 10;  // specifier "u" = specifies an unsigned decimal 
                              sign = false;
                              putu(*argp, numbase);  
                              argp += incsize;
                              break;
                    
                    case 'x':
                    case 'X':
                    case 'p': numbase = 16;  // specifiers "x/X/p" = specifies an unsigned hexadecimal 
                              sign = false;
                              putu(*argp, numbase);
                              argp += incsize;
                              break;

                    case 'o': numbase = 8;  // specifier "o" = specifies an unsigned octal 
                              sign = false;
                              putu(*argp, numbase);
                              argp += incsize;
                              break;
                    
                    default: break;
                }   
                curst = PRINTF_NORMAL;
                curln = PRINTFLN_DEFAULT;  
                numbase = 10;
                sign = false;
                break;
        }
        fmt += incsize; // move to the next character in the format string
    }
}
