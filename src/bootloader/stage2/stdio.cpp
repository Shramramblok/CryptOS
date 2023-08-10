#include "stdio.h"
#include "x86.hpp"
#include <stdarg.h>
#include <stdbool.h>

const unsigned SCREEN_WIDTH = 80;  // standard width
const unsigned SCREEN_HEIGHT = 25;  // standard height
const uint8_t DEFAULT_COLOR = 0x7;  // default color to print chars to screen
uint8_t* g_ScreenBuffer = (uint8_t*)0xB8000;  // protected mode - no BIOS ints
int g_ScreenX = 0, g_ScreenY = 0;


void putchr(int x, int y, char c){
    g_ScreenBuffer[2 * (y * SCREEN_WIDTH + x)] = c;  // every second byte is printed -> *2
}


void putclr(int x, int y, uint8_t color){
    g_ScreenBuffer[2 * (g_ScreenY * SCREEN_WIDTH + g_ScreenX) + 1] = color;  // every second byte is printed -> *2
}


void clrscr(){
    for (int y = 0; y < SCREEN_HEIGHT; y++){
        for (int x = 0; x < SCREEN_WIDTH; x++){
            putchr(x, y, '\0');
            putclr(x, y, DEFAULT_COLOR);
        }
    }
    
    g_ScreenX = 0 ; g_ScreenY = 0;
    setcursor(g_ScreenX, g_ScreenY);
}


void setcursor(int x, int y){
    int pos = y * SCREEN_WIDTH + x;  // position on screen to set cursor to

    x86_outb(0x3D4, 0x0F);  // write into VGA command register, lower byte
    x86_outb(0x3D4, (uint8_t)(pos & 0xFF));  // write into VGA command register, higher byte
    x86_outb(0x3D5, 0x0E);  // write into VGA port data register, lower byte
    x86_outb(0x3D5, (uint8_t)((pos >> 8) & 0xFF));  // write into VGA port data register, higher byte
}


void putc(char c){
    switch (c){
        case '\n':
            g_ScreenX = 0;
            g_ScreenY++;
            break;

        case '\r':
            g_ScreenX = 0;
            break;

        case '\t':
            for (int i = 0; i < 4 - (g_ScreenX % 4); i++){
                putc(' ');
            }
            break;

        default:
            putchr(g_ScreenX, g_ScreenY, c);
            putclr(g_ScreenX, g_ScreenY, DEFAULT_COLOR);
            g_ScreenX++; 
            break;

    setcursor(g_ScreenX, g_ScreenY);
    }
    
    if (g_ScreenX >= SCREEN_WIDTH){
        g_ScreenY++;
        g_ScreenX = 0;
    }
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


void printf(const char* fmt, ...){
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
