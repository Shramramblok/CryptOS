#pragma once
#include "stdint.h"
#include "x86.hpp"
#include "stdio.h"

class Disk
{
public:
    Disk(uint8_t driveNumber);

    bool read(uint32_t lba, uint8_t* buffer, uint8_t count);
    void lba_to_chs(uint32_t lba, uint16_t* cylinder, uint8_t* head, uint8_t* sector);
    
    uint16_t getCylinders();
    uint8_t getHeads();
    uint8_t getSectors();
private:
    uint8_t driveNumber;
    uint16_t cylinders;
    uint8_t heads;
    uint8_t sectors;
    uint8_t driveType;
};

