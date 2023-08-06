#include "stdint.h"
#include "stdio.h"
#include "main.hpp"
#include "disk.hpp"

void _cdecl cstart_(uint16_t bootDriveNumber)
{
    printf("Hello from Crypt%c%c using a %d%% working %s\r\n", 'O', 'S', 100, "printf!");
    
    Disk disk(bootDriveNumber);

    printf("Disk %hu parameters: %hu cylinders, %hhu heads, %hhu sectors\r\n", bootDriveNumber, disk.getCylinders(), disk.getHeads(), disk.getSectors());
    uint16_t cylinder;
    uint8_t head;
    uint8_t sector;

    uint32_t lba = 69420;
    
    disk.lba_to_chs(lba, &cylinder, &head, &sector);
    printf("LBA: %lu, CHS: %hu:%hhu:%hhu\r\n", lba, cylinder, head, sector);
}
