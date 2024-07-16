#include "kernel.h"

char* c_helloWorld = "Hello from KERNEL.C elf64 loaded from bootloader\n\0";

#define VGA_WIDTH  80
#define VGA_HEIGHT 25

#define VGA_BLACK          0
#define VGA_BLUE           1
#define VGA_GREEN          2
#define VGA_CYAN           3
#define VGA_RED            4
#define VGA_MAGENTA        5
#define VGA_BROWN          6
#define VGA_LIGHT_GRAY     7
#define VGA_DARK_GRAY      8
#define VGA_LIGHT_BLUE     9
#define VGA_LIGHT_GREEN    10
#define VGA_LIGHT_CYAN     11
#define VGA_LIGHT_RED      12
#define VGA_LIGHT_MAGENTA  13
#define VGA_LIGHT_YELLOW   14
#define VGA_WHITE          15


uint8_t* vga_buffer;
uint16_t vga_row;
uint16_t vga_col;
uint8_t  vga_color;

void terminal_init();
void terminal_color(uint8_t a_foreground, uint8_t a_background);
void terminal_set_position(uint8_t a_row, uint8_t a_col);

void terminal_hex8(uint8_t a_value);
void terminal_hex16(uint16_t a_value);
void terminal_hex32(uint32_t a_value);
void terminal_hex64(uint64_t a_value);
void terminal_char(uint8_t a_character);
void terminal_string(uint8_t* a_buffer);

void terminal_memory_dump(uint8_t* a_address, size_t a_bytes);


static inline void outb(uint16_t a_port, uint8_t a_value)
{
	asm("outb %b0, %w1" : : "a"(a_value), "Nd"(a_port) : "memory");
}

static inline uint8_t inb(uint16_t a_port)
{
	uint8_t ret;
	asm("inb %w1, %b0" : : "a"(ret), "Nd"(a_port) : "memory");
	return ret;
}

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

	// Print boot drive
	terminal_string("BootDrive: \0");
	terminal_color(VGA_LIGHT_CYAN, VGA_BLACK);
	terminal_hex8(a_bootDrive);
	terminal_char('\n');
	terminal_color(VGA_LIGHT_GRAY, VGA_BLACK);

	terminal_string(c_helloWorld);
	terminal_memory_dump((uint8_t*) 0x20000, 0x100);

	for(size_t i = 0; i < 160000000; i++)
	{
		uint8_t a = getc();
		if(a != 0)
		{
			terminal_char(a);
		}
		if((i % 10000000) == 0)
			terminal_char('!');
	}
}

void terminal_init()
{
	vga_buffer = (uint8_t*) 0xb8000;
	terminal_set_position(0, 0);
	terminal_color(VGA_LIGHT_GRAY, VGA_BLACK);
	for(size_t i = 0; i < VGA_WIDTH * VGA_HEIGHT; i++)
	{
		vga_buffer[i * 2 + 0] = 0;
		vga_buffer[i * 2 + 1] = vga_color;
	}
}

void terminal_color(uint8_t a_foreground, uint8_t a_background)
{
	vga_color = (a_foreground & 0xf) | ((a_background & 0xf) << 4);
}

void terminal_set_position(uint8_t a_row, uint8_t a_col)
{
	vga_row = a_row;
	vga_col = a_col;

	size_t position = (vga_row * VGA_WIDTH) + vga_col;
	outb(0x3D4, 0x0F);
	outb(0x3D5, (position & 0xff));
	outb(0x3D4, 0x0E);
	outb(0x3D5, ((position >> 8) & 0xff));
}

void terminal_char(uint8_t a_char)
{
	if(a_char == '\r')
	{
		vga_col = 0;
	}
	else if(a_char == '\n')
	{
		vga_row += 1;
		vga_col = 0;
	}
	else
	{
		size_t index = vga_row * 2 * VGA_WIDTH + vga_col * 2;
		vga_buffer[index + 0] = a_char;
		vga_buffer[index + 1] = vga_color;

		vga_col += 1;
		if(vga_col >= VGA_WIDTH)
		{
			vga_col = 0;
			vga_row += 1;
		}
	}

	if(vga_row >= VGA_HEIGHT)
	{
		for(size_t i = VGA_WIDTH; i < VGA_HEIGHT * VGA_WIDTH; i++)
		{
			vga_buffer[(i - VGA_WIDTH) * 2 + 0] = vga_buffer[i * 2 + 0];
			vga_buffer[(i - VGA_WIDTH) * 2 + 1] = vga_buffer[i * 2 + 1];
		}
		vga_row -= 1;
	}

	// Update cursor position
	terminal_set_position(vga_row, vga_col);
}

void terminal_string(uint8_t* a_buffer)
{
	uint8_t character;
	size_t index = 0;
	while((character = a_buffer[index++]) != 0)
	{
		terminal_char(character);
	}
}

void terminal_hex8(uint8_t a_value)
{
	char* buffer = "0123456789abcdef\0";
	terminal_char(*(buffer + ((a_value & 0xf0) >> 4)));
	terminal_char(*(buffer + (a_value & 0x0f)));
}

void terminal_hex16(uint16_t a_value)
{
	terminal_hex8(a_value >> 8);
	terminal_hex8(a_value);
}

void terminal_hex32(uint32_t a_value)
{
	terminal_hex8(a_value >> 24);
	terminal_hex8(a_value >> 16);
	terminal_hex8(a_value >> 8);
	terminal_hex8(a_value);
}

void terminal_hex64(uint64_t a_value)
{
	terminal_hex8(a_value >> 56);
	terminal_hex8(a_value >> 48);
	terminal_hex8(a_value >> 40);
	terminal_hex8(a_value >> 32);
	terminal_hex8(a_value >> 24);
	terminal_hex8(a_value >> 16);
	terminal_hex8(a_value >> 8);
	terminal_hex8(a_value);
}

void terminal_memory_dump(uint8_t* a_address, size_t a_bytes)
{
	for(size_t index = 0; index < a_bytes; index += 16)
	{
		terminal_hex32((uint32_t) (uintptr_t) (a_address));
		terminal_char(':');
		terminal_char(' ');

		size_t left = a_bytes - index;
		size_t count = (left > 15) ? 16 : left;
		for(size_t i = 0; i < count; i++)
		{
			terminal_hex8(*(a_address + i));
			terminal_char(' ');
		}

		for(size_t i = count; i < 16; i++)
		{
			terminal_char(' ');
			terminal_char(' ');
			terminal_char(' ');
		}

		terminal_char(':');
		terminal_char(' ');

		for(size_t i = 0; i < count; i++)
		{
			uint8_t character = *(a_address + i);
			terminal_char(character < 0x20 ? '.' : character);
		}

		terminal_char('\n');
		a_address += 16;
	}
}
