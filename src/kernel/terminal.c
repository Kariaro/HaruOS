#include "terminal.h"
#include "common.h"

uint8_t* vga_buffer;
uint16_t vga_row;
uint16_t vga_col;
uint8_t  vga_color;

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
		
		for(size_t i = 0; i < VGA_WIDTH; i++)
		{
			vga_buffer[(i + VGA_WIDTH * (VGA_HEIGHT - 1)) * 2 + 0] = 0x20;
			vga_buffer[(i + VGA_WIDTH * (VGA_HEIGHT - 1)) * 2 + 1] = 0x07;
		}
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
