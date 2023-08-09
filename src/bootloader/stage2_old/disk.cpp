#include "disk.hpp"
#include "x86.hpp"
#include "stdio.h"

Disk::Disk(uint8_t driveNumber) {
    this->driveNumber = driveNumber;

    if (!x86_GetDiskParameters(driveNumber, &this->cylinders, &this->heads, &this->sectors, &this->driveType))
    {
        printf("Error getting disk parameters for drive %d\r\n", driveNumber);
        while (1);
    }

}

bool Disk::read(uint32_t lba, uint8_t* buffer, uint8_t count) {
    uint16_t cylinder;
    uint8_t head;
    uint8_t sector;
    this->lba_to_chs(lba, &cylinder, &head, &sector);
    for (uint8_t i = 0; i < 3; i++)
    {
        if (x86_ReadDisk(this->driveNumber, cylinder, head, sector, count, buffer))
            return true;
        x86_ResetDisk(this->driveNumber);
    }
    return false;
}

void Disk::lba_to_chs(uint32_t lba, uint16_t* cylinder, uint8_t* head, uint8_t* sector)
{
    *sector = (lba % this->sectors) + 1;
    lba /= this->sectors;
    *head = (lba % this->heads);
    *cylinder = (lba / this->heads);
}

uint16_t Disk::getCylinders() {
    return this->cylinders;
}

uint8_t Disk::getHeads() {
    return this->heads;
}

uint8_t Disk::getSectors() {
    return this->sectors;
}