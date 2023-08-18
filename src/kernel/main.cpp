#include <stdint.h>
#include "stdio.h"


extern uint8_t __bss_start;  // need to empty BSS
extern uint8_t __end;


void __attribute__((section(".entry"))) cppstart(uint16_t bootDriveNumber)
{
    clrscr();
    printf("CryptOS kernel\n");
end:
    for (;;);
}