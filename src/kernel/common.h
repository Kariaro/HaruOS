
#ifndef COMMON_H
#define COMMON_H

#include <stdint.h>

static inline __attribute__((always_inline)) void outb(uint16_t a_port, uint8_t a_value)
{
    asm volatile ("outb %b0, %w1" : : "a"(a_value), "Nd"(a_port) : "memory");
}

static inline __attribute__((always_inline)) uint8_t inb(uint16_t a_port)
{
    uint8_t ret;
    asm volatile ("inb %w1, %b0" : : "a"(ret), "Nd"(a_port) : "memory");
    return ret;
}

static inline __attribute__((always_inline)) uint16_t inw(uint16_t port)
{
    uint16_t ret;
    asm volatile ("inw %1, %0" : "=a" (ret) : "dN" (port));
    return ret;
}

static inline __attribute__((always_inline)) void io_wait()
{
    outb(0x80, 0);
}

static inline __attribute((always_inline)) void software_wait()
{
    for(size_t i = 0; i < 100000; i++)
    {
        asm volatile ("nop");
    }
}


#endif  // COMMON_H
