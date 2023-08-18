#pragma once
#include <stdint.h>

// state constants:
#define PRINTF_NORMAL 0
#define PRINTF_LENGTH 1
#define PRINTF_LNSHORT 2
#define PRINTF_LNLONG 3
#define PRINTF_SPECIFIER 4

// length constants:
#define PRINTFLN_DEFAULT 0
#define PRINTFLN_SHORT_SHORT 1
#define PRINTFLN_SHORT 2
#define PRINTFLN_LONG 3
#define PRINTFLN_LONG_LONG 4

void putc(char c);
void puts(const char* str);
void putu(uint64_t value, uint32_t base);
void puti(int64_t value, uint32_t base);
void printf(const char* fmt, ...);
void clrscr();
void setcursor(int x, int y);