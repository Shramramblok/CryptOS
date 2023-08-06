#include "stdint.h"
#include "stdio.h"
#include "main.h"

void _cdecl cstart_(uint16_t bootDriveNumber)
{
    puts("Hello, World!\r\n");
    printf("Hello from Crypt %c %% %c %s\r\n", 'O', 'S', "printf!");
    printf("Our Numbers: %d %i %x %p %o %hd %hi %hhu %hhd\r\n",
    5680, -5050, 0xbeeb, 0xeeee, 23421, (short)55, (short)-34,
      (unsigned char)20, (signed char)-10);
    printf("Big Ones: %ld %lx %lld %llx\r\n", -100000001l,
    0xdef88deful, 40300200100ll, 0xbeebeebeebeebeebull);
    while (1){
        
    }
    
}
