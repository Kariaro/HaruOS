#include "kernel.h"
#include "terminal.h"
#include "isr.h"
#include "common.h"

char* c_helloWorld = "Hello from KERNEL.C elf64 loaded from bootloader\n\0";

// TODO - Get this working
uint8_t getc()
{
	// Wait for keyboard
	while(inb(0x64) & 2);

	// Read keyboard
	return inb(0x60);
}

void kernel_main(uint8_t a_bootDrive)
{
	// Init the terminal
	terminal_init();

	// Init IDT
	idt_init();

	// Print boot drive
	terminal_string("BootDrive: \0");
	terminal_color(VGA_LIGHT_CYAN, VGA_BLACK);
	terminal_hex8(a_bootDrive);
	terminal_char('\n');
	terminal_color(VGA_LIGHT_GRAY, VGA_BLACK);

	terminal_string(c_helloWorld);
	// terminal_memory_dump((uint8_t*) 0x20000, 0x100);

	asm volatile ("mov $0xffee00, %rax");
	asm volatile ("int $0x0a");
	asm volatile ("mov $0xdead, %rax");
	asm volatile ("int $0x0b");

	for(size_t i = 0; i < 160000000; i++)
	{
		uint8_t a = getc();
		if(a != 0)
		{
			terminal_char(a);
		}
		if((i % 10000000) == 0)
		{
			terminal_char('!');
		}
	}
}
