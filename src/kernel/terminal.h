
#ifndef TERMINAL_H
#define TERMINAL_H

#include <stdint.h>

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

void terminal_init();
void terminal_color(uint8_t a_foreground, uint8_t a_background);
void terminal_set_position(uint8_t a_row, uint8_t a_col);

void terminal_hex8(uint8_t a_value);
void terminal_hex16(uint16_t a_value);
void terminal_hex32(uint32_t a_value);
void terminal_hex64(uint64_t a_value);

void terminal_bin8(uint8_t a_value);

void terminal_char(uint8_t a_character);
void terminal_string(uint8_t* a_buffer);

void terminal_memory_dump(uint8_t* a_address, size_t a_bytes);

#endif  // TERMINAL_H
