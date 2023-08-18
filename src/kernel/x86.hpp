#pragma once
#include <stdint.h>
#include <stdbool.h>

extern "C"{
    void x86_outb(uint16_t port, uint8_t value) __attribute__((__cdecl__));  // outputs a value to a certain port
    uint8_t x86_inpb(uint16_t port) __attribute__((__cdecl__));  // gets input from a certain port, used by setcursor
}