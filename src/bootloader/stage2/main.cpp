#include <stdint.h>
#include "stdio.h"
#include "main.hpp"
#include "x86.hpp"
#include "disk.hpp"


void PutStrReal(const char* s){
    while (*s){
        x86_RealModePutC(*s);  // put character
    }
}


void cppstart(uint16_t bootDriveNumber)
{
    clrscr();  // clear the screen, also helps to see if printf and following commands work properly
    
    int line_amnt = 1;  // should be above 25 to also test scrollback()
    for (int i = 0; i < line_amnt; i++){
        printf("Hello from Crypt%c%c using a %d%% working %s line %d\r\n", 'O', 'S', 100, "printf!", i);
    }    

    PutStrReal("CryptOS from RealMode!!!\r\n");
    Disk disk(bootDriveNumber);

    printf("Disk %hu parameters: %hu cylinders, %hhu heads, %hhu sectors\r\n", bootDriveNumber, disk.getCylinders(), disk.getHeads(), disk.getSectors());
    uint16_t cylinder;
    uint8_t head;
    uint8_t sector;

    uint32_t lba = 69420;
    
    disk.lba_to_chs(lba, &cylinder, &head, &sector);
    printf("LBA: %lu, CHS: %hu:%hhu:%hhu\r\n", lba, cylinder, head, sector);

    // attempt to read kernel into memory:
    
}
