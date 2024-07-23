#include "kernel.h"
#include "terminal.h"
#include "idt.h"
#include "pic.h"
#include "common.h"

#include "kbd.h"

char* c_helloWorld = "Hello from KERNEL.C elf64 loaded from bootloader\n\0";

// TODO - Get this working
uint8_t getc()
{
    // Read keyboard
    return inb(0x60);
}

void kernel_main(uint8_t a_bootDrive)
{
    // Init the terminal
    terminal_init();

    // Init IDT
    idt_init();

    // Init PIC
    pic_init();

    // Init KBD
    kbd_init();

    // Print boot drive
    terminal_string("BootDrive: \0");
    terminal_color(VGA_LIGHT_CYAN, VGA_BLACK);
    terminal_hex8(a_bootDrive);
    terminal_char('\n');
    terminal_color(VGA_LIGHT_GRAY, VGA_BLACK);
    terminal_string(c_helloWorld);

    // terminal_memory_dump((uint8_t*) 0x20000, 0x100);

    // asm volatile ("mov $0xffee00, %rax");
    // asm volatile ("int $0x0a");
    // asm volatile ("mov $0xdead, %rax");
    // asm volatile ("int $0x0b");

    // *((uint64_t*) 0xdeadbeef) = 1;

    // should be stack pointer
    uint64_t rsp;
    asm volatile ("mov %%rsp, %0" : "=r" (rsp));
    terminal_hex64(rsp);
    terminal_char('\n');
    

    // asm volatile ("mov $0x01, %rax");
    // asm volatile ("mov $0x02, %rcx");
    // asm volatile ("mov $0x03, %rdx");
    // asm volatile ("mov $0x04, %rbx");
    // asm volatile ("int $0x0d");

    // HALT
    while(1)
    {
        asm volatile ("hlt");
    }

    return;
}
