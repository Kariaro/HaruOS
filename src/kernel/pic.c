// 8259 Programmable Interrupt Controller (PIC)

#include "pic.h"
#include "common.h"
#include "terminal.h"

#define PIC1_COMMAND      0x20  // master command
#define PIC1_DATA         0x21  // master data
#define PIC2_COMMAND      0xA0  // slave command
#define PIC2_DATA         0xA1  // slave data

void pic_init()
{
    // remap IRQ table
    outb(PIC1_COMMAND,  0x11); io_wait(); // initialize master IRQ
    outb(PIC2_COMMAND,  0x11); io_wait(); // initialize slave IRQ
    outb(PIC1_DATA,     0x20); io_wait(); // vector offset
    outb(PIC2_DATA,     0x28); io_wait(); // vector offset
    outb(PIC1_DATA,     0x04); io_wait(); // tell there's slave IRQ at  (0000 0100)
    outb(PIC2_DATA,     0x02); io_wait(); // tell it's cascade identity (0000 0010)
    outb(PIC1_DATA,     0x01); io_wait(); // 8086 mode
    outb(PIC2_DATA,     0x01); io_wait(); // 8086 mode

    // clear masks
    outb(PIC1_DATA,     0xff);
    outb(PIC2_DATA,     0xff);
}

void pic_disable()
{
    outb(PIC1_DATA, 0xff);
    outb(PIC2_DATA, 0xff);
}

void pic_disable_irq(uint8_t a_irq)
{
    uint16_t port;
    uint8_t value;

    if(a_irq < 8)
    {
        port = PIC1_DATA;
    }
    else
    {
        port = PIC2_DATA;
        a_irq -= 8;
    }
    value = inb(port) | (1 << a_irq);
    outb(port, value);
}

void pic_enable_irq(uint8_t a_irq)
{
    uint16_t port;
    uint8_t value;

    if(a_irq < 8)
    {
        port = PIC1_DATA;
    }
    else
    {
        port = PIC2_DATA;
        a_irq -= 8;
    }
    value = inb(port) & ~(1 << a_irq);
    outb(port, value);
}
