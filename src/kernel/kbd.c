#include "kbd.h"
#include "pic.h"
#include "idt.h"
#include "common.h"
#include "terminal.h"

#define PS2_STATUS      0x64
#define PS2_DATA        0x60
#define PS2_STAT_KDB    1<<0
#define PS2_STAT_MOUSE  1<<1

void kbd_handler(regs_t* a_regs, uint8_t a_index)
{
    uint8_t status = inb(PS2_STATUS);
    // if((status & PS2_STAT_MOUSE) != 0)
    // {
    //     goto done;
    // }
    
    uint8_t scancode = inb(PS2_DATA);
    uint8_t press = 0;
    
    terminal_string("kbd status = ");
    terminal_bin8(status),
    terminal_string(" , scancode = ");
    terminal_hex8(scancode);
    terminal_string(" , press ");
    terminal_bin8(press);
    terminal_char('\n');
    // while(inb(PS2_STATUS) & 1)
    // {
    //     inb(PS2_DATA);
    // }

done:
    // Send EOI (End of interrupt)
    outb(0x20, 0x20);
}

uint8_t setup_ps2();

uint8_t get_ps2_cmd(uint8_t a_cmd);
void send_ps2_cmd(uint8_t a_cmd);
void send_ps2_cmd_ex(uint8_t a_cmd, uint8_t a_data);

void kbd_init()
{
    // setup_ps2();

    idt_install_irq(1, kbd_handler);

    // Enable IRQ0
    pic_enable_irq(1);

    // // disable ports
    // outb(0x64, 0xa7);
    // outb(0x64, 0xad);
    // // enable keyboard
    // outb(0x64, 0xae);
    // // send command to port 1
    // outb(0x64, 0xd2);
    // outb(0x60, 0xf4);
    // io_wait();
    // outb(0x64, 0xd2);
    // outb(0x60, 0xff);
    // io_wait();
    // outb(0x64, 0xd0);
    // terminal_bin8(inb(0x60));
}

void flush_kbd()
{
    while((inb(0x64) & 1) != 0)
    {
        inb(0x60);
    }
}

void send_ps2_cmd(uint8_t a_cmd)
{
    uint32_t max_loops;

    // flush output buffer
    max_loops = 0x100000;
    uint8_t status;
    // while(((status = inb(PS2_STATUS)) & 3) != 0)
    // {
    //     // clear read status
    //     if((status & 1) != 0) inb(0x60);
    //     io_wait();
    //     if(max_loops-- == 1)
    //     {
    //         terminal_string("[PS/2]: failed to flush input and output buffer ");
    //         terminal_bin8(status);
    //         panic();
    //     }
    // }

    // issue command
    outb(0x64, a_cmd);

    // wait for command to finish
    max_loops = 0x10000;
    // while((inb(PS2_STATUS) & 2) != 0)
    // {
    //     io_wait();
    //     if(max_loops-- == 1)
    //     {
    //         terminal_string("[PS/2]: failed to wait for command");
    //         panic();
    //     }
    // }
}

uint8_t get_ps2_cmd(uint8_t a_cmd)
{
    send_ps2_cmd(a_cmd);
    uint32_t max_loops = 0x100000;
    // while((inb(PS2_STATUS) & 1) != 0)
    // {
    //     io_wait();
    //     if(max_loops-- == 1)
    //     {
    //         terminal_string("[PS/2]: failed to read data PS/2");
    //         panic();
    //     }
    // }
    return inb(PS2_DATA);
}

void send_ps2_cmd_ex(uint8_t a_cmd, uint8_t a_data)
{
    uint32_t max_loops;

    // flush output buffer
    max_loops = 0x100000;
    uint8_t status;
    // while(((status = inb(PS2_STATUS)) & 3) != 0)
    // {
    //     // clear read status
    //     if((status & 1) != 0) inb(PS2_DATA);
    //     io_wait();
    //     if(max_loops-- == 1)
    //     {
    //         terminal_string("[PS/2]: failed to flush input and output buffer");
    //         panic();
    //     }
    // }

    // issue command
    outb(0x64, a_cmd);
    outb(PS2_DATA, a_data);

    // wait for command to finish
    max_loops = 0x100000;
    // while((inb(PS2_STATUS) & 2) != 0)
    // {
    //     io_wait();
    //     if(max_loops-- == 1)
    //     {
    //         terminal_string("[PS/2]: failed to wait for command");
    //         panic();
    //     }
    // }
}

uint8_t setup_ps2()
{
    terminal_string("[PS/2]: setup keyboard\n");

    uint8_t port1 = 0;
    uint8_t port2 = 0;

    // disable ps/2 ports
    send_ps2_cmd(0xad);
    send_ps2_cmd(0xa7);

    flush_kbd();

    // check if second PS/2 port is usable
    uint8_t ccb = get_ps2_cmd(0x20);
    terminal_string("[PS/2]: ccb = ");
    terminal_bin8(ccb);
    terminal_char('\n');

    if((ccb & 1) == 0) port1 |= 1;
    if((ccb & 2) == 0) port2 |= 1;

    // control if port 1 is set
    send_ps2_cmd(0xa8);
    ccb = get_ps2_cmd(0x20);
    if((ccb & 1) == 0) port1 |= 2;

    // control if port 2 is set
    send_ps2_cmd(0xae);
    ccb = get_ps2_cmd(0x20);
    if((ccb & 2) == 0) port2 |= 2;

    // disable ps/2 ports
    send_ps2_cmd(0xad);
    send_ps2_cmd(0xa7);

    // information about ports
    terminal_string("[PS/2]: ");
    terminal_string("port1 = ");
    terminal_string(port1 == 3 ? "OK" : "BAD");
    terminal_string(" , port2 = ");
    terminal_string(port2 == 3 ? "OK" : "BAD");
    terminal_char('\n');

    ccb = get_ps2_cmd(0x20);
    terminal_string("[PS/2]: ccb = ");
    terminal_bin8(ccb);
    terminal_char('\n');

    terminal_string("[PS/2]: controller port 1 test: ");
    uint8_t port1result = get_ps2_cmd(0xab);
    if(port1result != 0x00) {
        terminal_hex8(port1result);
        terminal_string("\n");
    } else {
        terminal_string("OK\n");
    }
    
    terminal_string("[PS/2]: controller port 2 test: ");
    uint8_t port2result = get_ps2_cmd(0xa9);
    if(port2result != 0x00) {
        terminal_hex8(port2result);
        terminal_string("\n");
    } else {
        terminal_string("OK\n");
    }

    terminal_string("[PS/2]: controller self test result: ");
    uint8_t response = get_ps2_cmd(0xaa);
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

    // enable ps/2 ports
    send_ps2_cmd(0xa8);
    send_ps2_cmd(0xae);

    return 1;
}
