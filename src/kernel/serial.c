
#include "common.h"
#include "terminal.h"
#include "idt.h"

#define COM1     0x3F8
#define COM2     0x2F8
#define COM3     0x3E8
#define COM4     0x2E8
#define COM5     0x5F8
#define COM6     0x4F8
#define COM7     0x5E8
#define COM8     0x4E8

struct serial
{
    uint16_t port;
};

int serial_init(struct serial a_serial)
{
    outb(a_serial.port + 1, 0x00);    // Disable all interrupts
    outb(a_serial.port + 3, 0x80);    // Enable DLAB (set baud rate divisor)
    outb(a_serial.port + 0, 0x03);    // Set divisor to 3 (lo byte) 38400 baud
    outb(a_serial.port + 1, 0x00);    //                  (hi byte)
    outb(a_serial.port + 3, 0x03);    // 8 bits, no parity, one stop bit
    outb(a_serial.port + 2, 0xC7);    // Enable FIFO, clear them, with 14-byte threshold
    outb(a_serial.port + 4, 0x0B);    // IRQs enabled, RTS/DSR set

    outb(a_serial.port + 4, 0x1E);    // Set in loopback mode, test the serial chip
    outb(a_serial.port + 0, 0xAE);    // Test serial chip (send byte 0xAE and check if serial returns same byte)
    // Check if serial is faulty (i.e: not same byte as sent)
    if(inb(a_serial.port + 0) != 0xAE) {
        return 1;
    }
    // If serial is not faulty set it in normal operation mode
    // (not-loopback with IRQs enabled and OUT#1 and OUT#2 bits enabled)
    outb(a_serial.port + 4, 0x0F);
    return 0;
}

int serial_rcvd(struct serial a_serial) {
    return inb(a_serial.port + 5) & 1;
}

char serial_recv(struct serial a_serial) {
    while(serial_rcvd(a_serial) == 0);
    return inb(a_serial.port);
}

int serial_transmit_empty(struct serial a_serial)
{
    return inb(a_serial.port + 5) & 0x20;
}

void serial_send(struct serial a_serial, uint8_t a_data) {
    while(serial_transmit_empty(a_serial) == 0);
    outb(a_serial.port, a_data);
}

void serial_handler_a(regs_t* a_regs, uint8_t a_index)
{
    terminal_string("serial_handler_a\n");
    struct serial com1 = { COM1 };

    uint8_t serial = serial_recv(com1);
    terminal_hex8(serial);
    terminal_string("SERIAL A\n");

    outb(0x20, 0x20);
}