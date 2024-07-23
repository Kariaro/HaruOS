// 8259 Programmable Interrupt Controller (PIC)

#include "pic.h"

#define PIC1_CMD   0x20  // master command
#define PIC1_DATA  0x21  // master data
#define PIC2_CMD   0xA0  // slave command
#define PIC2_DATA  0xA1  // slave data

uint16_t masks;

void pic_init()
{
    // remap IRQ table
    outb(PIC1_CMD,  0x11); io_wait(); // initialize master IRQ
    outb(PIC2_CMD,  0x11); io_wait(); // initialize slave IRQ
    outb(PIC1_DATA, 0x20); io_wait(); // vector offset
    outb(PIC2_DATA, 0x28); io_wait(); // vector offset
    outb(PIC1_DATA, 0x04); io_wait(); // tell there's slave IRQ at  (0000 0100)
    outb(PIC2_DATA, 0x02); io_wait(); // tell it's cascade identity (0000 0010)
    outb(PIC1_DATA, 0x01); io_wait(); // 8086 mode
    outb(PIC2_DATA, 0x01); io_wait(); // 8086 mode

    // clear masks
    masks = 0xffff;
    outb(PIC1_DATA, 0xff);
    outb(PIC2_DATA, 0xff);
}

void pic_disable()
{
    masks = 0xffff;
    outb(PIC1_DATA, 0xff);
    outb(PIC2_DATA, 0xff);
}

void pic_disable_irq(uint8_t a_irq)
{
    masks |= (1 << a_irq);
    outb(PIC1_DATA, (masks >> 0) & 0xff);
    outb(PIC2_DATA, (masks >> 8) & 0xff);
}

void pic_enable_irq(uint8_t a_irq)
{
    masks &= ~(1 << a_irq);
    outb(PIC1_DATA, (masks >> 0) & 0xff);
    outb(PIC2_DATA, (masks >> 8) & 0xff);
}
