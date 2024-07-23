#include "kbd.h"
#include "pic.h"
#include "idt.h"
#include "common.h"
#include "terminal.h"

void kbd_handler(regs_t* a_regs, uint8_t a_index)
{
    // a_index is always == 1
    // if(a_index >= 8) outb(0xA0, 0x20);

    // uint8_t control = inb(0x64);
    uint8_t scancode = inb(0x60);
    terminal_string("keyboard -> ");
    // terminal_hex8(control);
    terminal_hex8(scancode);
    terminal_char('\n');

    // Send EOI (End of interrupt)
    outb(0x20, 0x20);
}

void kbd_init()
{
    idt_set_irq(1, kbd_handler);

    // Enable IRQ0
    pic_enable_irq(1);
}


void setup_ps2kbd()
{

    terminal_string("PS/2: setup keyboard\n");

    // (a) do a couple of dummy reads from the data port
    for(size_t i = 0; i < 64; i++) inb(0x60);

    // (b) get the current controller configuration byte
    outb(0x64, 0x20);
    uint8_t ccb = inb(0x60);

    // (c) do another dummy read from the data port
    for(size_t i = 0; i < 64; i++) inb(0x60);

    // (d) set a new configuration byte
    outb(0x60, 0b00110111); // 0x37
    outb(0x64, 0x60);
    io_wait();

    // (e) do another dummy read from the data port
    for(size_t i = 0; i < 64; i++) inb(0x60);

    // (f) send distable device B command to the controller
    outb(0x64, 0xa7);
    io_wait();

    // (g) get the current controller configuration
    outb(0x64, 0x20);
    io_wait();
    ccb = inb(0x60);

    // (h) check if second port is usable
    uint8_t second_port_not_usable = ((ccb & 0xb00100000) == 0);
    terminal_string("PS/2: second port -> ");
    terminal_string(second_port_not_usable ? "(usable)" : "(unusable)");
    terminal_char('\n');

    // (i) send port again to re-enable port
    outb(0x64, 0xa8);

    // (j) create new node ....
    // (k) disable scanning for device a 
    outb(0x64, 0xf5);


    terminal_string("ccb: ");
    terminal_hex8(ccb);
    terminal_char('\n');

    /*

    // disable ps/2 ports
    outb(0x64, 0xad);
    outb(0x64, 0xa7);
    io_wait();
    io_wait();
    io_wait();
    io_wait();
    io_wait();
    io_wait();
    io_wait();
    io_wait();
    io_wait();
    io_wait();
    outb(0x64, 0xae);

    outb(0x64, 0xf5);
    while(inb(0x60) != 0xFA);
    outb(0x64, 0xfa);
    uint8_t a = inb(0x60);
    uint8_t b = inb(0x60);
    terminal_hex8(a);
    terminal_char(' ');
    terminal_hex8(b);
    terminal_char('\n');

    // flush output buffer
    // while((inb(0x64) & 1) == 1)
    // {
    //     inb(0x60);
    // }

    outb(0x64, 0x20);
    io_wait();
    io_wait();
    io_wait();
    io_wait();
    io_wait();
    io_wait();
    io_wait();
    io_wait();
    io_wait();
    io_wait();
    io_wait();
    io_wait();
    io_wait();
    uint8_t ccb = inb(0x60);

    terminal_string("ccb: ");
    terminal_hex8(ccb);
    terminal_char('\n');

    // disable irqs
    ccb &= 0xfc;
    // disable PS/2 port 1 translation (we don't do mode 1 keybs anyway)
    ccb &= 0xbf;
    // actually set
    outb(0x64, 0x60);
    outb(0x60, ccb);

    uint8_t singlechannel = 0;
    if ((ccb & 0x20) > 0) {
        terminal_string("PS/2: might be a two-port ps/2 controller\n");
    } else {
        terminal_string("PS/2: can't be a two-port ps/2 controller\n");
        singlechannel = 1;
    }

    terminal_string("PS/2: controller self test result: ");
    outb(0x64, 0xaa);
    uint8_t response = inb(0x60);
    if(response == 0x55) {
        terminal_string("OK\n");
    } else if(response == 0xfc) {
        terminal_string("Fail\n");
        // TODO: do something here
    } else {
        terminal_hex8(response);
        terminal_string("???\n");
        // TODO: do something here
    }

    terminal_string("PS/2: controller port 1 test: ");
    outb(0x64, 0xab);
    uint8_t port1result = inb(0x60);
    if (port1result != 0x00) {
        terminal_hex8(port1result);
        terminal_string("\n");
    } else {
        terminal_string("OK\n");
    }

    outb(0x64, 0xa8);
    outb(0x64, 0xae);
    */
}
