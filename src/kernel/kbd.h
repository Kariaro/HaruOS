
#ifndef KBD_H_
#define KBD_H_

#include "common.h"

#define KEY_ESCAPE   0x0001

#define KEY_F1       0x003b
#define KEY_F2       0x003c
#define KEY_F3       0x003d
#define KEY_F4       0x003e
#define KEY_F5       0x003f
#define KEY_F6       0x0040
#define KEY_F7       0x0041
#define KEY_F8       0x0042
#define KEY_F9       0x0043
#define KEY_F10      0x0044


uint16_t poll_key();
void kbd_init();

#endif  // KBD_H_
