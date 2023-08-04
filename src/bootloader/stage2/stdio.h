#pragma once
#include "stdint.h"

void putc(char c);
void puts(const char* str);
void putu(uint64_t value, uint32_t base);
void puti(int64_t value, uint32_t base);
