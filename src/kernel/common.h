
#ifndef COMMON_H
#define COMMON_H

#include <stdint.h>

static inline void outb(uint16_t a_port, uint8_t a_value)
{
    asm volatile ("outb %1, %0" : : "dN"(a_port), "a"(a_value));
}

static inline uint8_t inb(uint16_t a_port)
{
    uint8_t ret;
    asm volatile ("inb %1, %0" : "=a"(ret) : "dN"(a_port));
    return ret;
}

static inline __attribute__((always_inline)) void io_wait()
{
    outb(0x80, 0);
}

static inline __attribute((always_inline)) void software_wait()
{
    for(size_t i = 0; i < 200000000; i++)
    {
        asm volatile ("nop");
    }
}

static inline __attribute((always_inline)) void panic()
{
    asm volatile ("int $0x0d");
}


#endif  // COMMON_H
