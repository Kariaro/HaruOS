#include "kbd.h"
#include "pic.h"
#include "idt.h"
#include "terminal.h"

#define PS2_STATUS      0x64
#define PS2_DATA        0x60

uint32_t flags;
uint16_t keyboard_buffer[256];
uint8_t keyboard_head;
uint8_t keyboard_tail;

void process_key(uint8_t scancode);

void kbd_handler(regs_t* a_regs, uint8_t a_index)
{
    uint8_t status;
    while((status = inb(PS2_STATUS)) & 2);
    uint8_t scancode = inb(PS2_DATA);
    // terminal_string("kbd status = ");
    // terminal_bin8(status),
    // terminal_string(" , scancode = ");
    // terminal_hex8(scancode);
    // terminal_char('\n');

    process_key(scancode);

done:
    // Send EOI (End of interrupt)
    outb(0x20, 0x20);
}

void kbd_init()
{
    flags = 0;
    keyboard_head = 0;
    keyboard_tail = 0;

    idt_install_irq(1, kbd_handler);

    // Enable IRQ1
    pic_enable_irq(1);
}

#define none 0

static struct scaninfo {
    uint16_t normal;
    uint16_t shift;
    uint16_t control;
    uint16_t alt;
} scan_to_keycode[] = {
    {   none,   none,   none,   none },
    { 0x011b, 0x011b, 0x011b, 0x01f0 }, /* escape */
    { 0x0231, 0x0221,   none, 0x7800 }, /* 1! */
    { 0x0332, 0x0340, 0x0300, 0x7900 }, /* 2@ */
    { 0x0433, 0x0423,   none, 0x7a00 }, /* 3# */
    { 0x0534, 0x0524,   none, 0x7b00 }, /* 4$ */
    { 0x0635, 0x0625,   none, 0x7c00 }, /* 5% */
    { 0x0736, 0x075e, 0x071e, 0x7d00 }, /* 6^ */
    { 0x0837, 0x0826,   none, 0x7e00 }, /* 7& */
    { 0x0938, 0x092a,   none, 0x7f00 }, /* 8* */
    { 0x0a39, 0x0a28,   none, 0x8000 }, /* 9( */
    { 0x0b30, 0x0b29,   none, 0x8100 }, /* 0) */
    { 0x0c2d, 0x0c5f, 0x0c1f, 0x8200 }, /* -_ */
    { 0x0d3d, 0x0d2b,   none, 0x8300 }, /* =+ */
    { 0x0e08, 0x0e08, 0x0e7f, 0x0ef0 }, /* backspace */
    { 0x0f09, 0x0f00, 0x9400, 0xa5f0 }, /* tab */
    { 0x1071, 0x1051, 0x1011, 0x1000 }, /* Q */
    { 0x1177, 0x1157, 0x1117, 0x1100 }, /* W */
    { 0x1265, 0x1245, 0x1205, 0x1200 }, /* E */
    { 0x1372, 0x1352, 0x1312, 0x1300 }, /* R */
    { 0x1474, 0x1454, 0x1414, 0x1400 }, /* T */
    { 0x1579, 0x1559, 0x1519, 0x1500 }, /* Y */
    { 0x1675, 0x1655, 0x1615, 0x1600 }, /* U */
    { 0x1769, 0x1749, 0x1709, 0x1700 }, /* I */
    { 0x186f, 0x184f, 0x180f, 0x1800 }, /* O */
    { 0x1970, 0x1950, 0x1910, 0x1900 }, /* P */
    { 0x1a5b, 0x1a7b, 0x1a1b, 0x1af0 }, /* [{ */
    { 0x1b5d, 0x1b7d, 0x1b1d, 0x1bf0 }, /* ]} */
    { 0x1c0d, 0x1c0d, 0x1c0a, 0x1cf0 }, /* Enter */
    {   none,   none,   none,   none }, /* L Ctrl */
    { 0x1e61, 0x1e41, 0x1e01, 0x1e00 }, /* A */
    { 0x1f73, 0x1f53, 0x1f13, 0x1f00 }, /* S */
    { 0x2064, 0x2044, 0x2004, 0x2000 }, /* D */
    { 0x2166, 0x2146, 0x2106, 0x2100 }, /* F */
    { 0x2267, 0x2247, 0x2207, 0x2200 }, /* G */
    { 0x2368, 0x2348, 0x2308, 0x2300 }, /* H */
    { 0x246a, 0x244a, 0x240a, 0x2400 }, /* J */
    { 0x256b, 0x254b, 0x250b, 0x2500 }, /* K */
    { 0x266c, 0x264c, 0x260c, 0x2600 }, /* L */
    { 0x273b, 0x273a,   none, 0x27f0 }, /* ;: */
    { 0x2827, 0x2822,   none, 0x28f0 }, /* '" */
    { 0x2960, 0x297e,   none, 0x29f0 }, /* `~ */
    {   none,   none,   none,   none }, /* L shift */
    { 0x2b5c, 0x2b7c, 0x2b1c, 0x2bf0 }, /* |\ */
    { 0x2c7a, 0x2c5a, 0x2c1a, 0x2c00 }, /* Z */
    { 0x2d78, 0x2d58, 0x2d18, 0x2d00 }, /* X */
    { 0x2e63, 0x2e43, 0x2e03, 0x2e00 }, /* C */
    { 0x2f76, 0x2f56, 0x2f16, 0x2f00 }, /* V */
    { 0x3062, 0x3042, 0x3002, 0x3000 }, /* B */
    { 0x316e, 0x314e, 0x310e, 0x3100 }, /* N */
    { 0x326d, 0x324d, 0x320d, 0x3200 }, /* M */
    { 0x332c, 0x333c,   none, 0x33f0 }, /* ,< */
    { 0x342e, 0x343e,   none, 0x34f0 }, /* .> */
    { 0x352f, 0x353f,   none, 0x35f0 }, /* /? */
    {   none,   none,   none,   none }, /* R Shift */
    { 0x372a, 0x372a, 0x9600, 0x37f0 }, /* * */
    {   none,   none,   none,   none }, /* L Alt */
    { 0x3920, 0x3920, 0x3920, 0x3920 }, /* space */
    {   none,   none,   none,   none }, /* caps lock */
    { 0x3b00, 0x5400, 0x5e00, 0x6800 }, /* F1 */
    { 0x3c00, 0x5500, 0x5f00, 0x6900 }, /* F2 */
    { 0x3d00, 0x5600, 0x6000, 0x6a00 }, /* F3 */
    { 0x3e00, 0x5700, 0x6100, 0x6b00 }, /* F4 */
    { 0x3f00, 0x5800, 0x6200, 0x6c00 }, /* F5 */
    { 0x4000, 0x5900, 0x6300, 0x6d00 }, /* F6 */
    { 0x4100, 0x5a00, 0x6400, 0x6e00 }, /* F7 */
    { 0x4200, 0x5b00, 0x6500, 0x6f00 }, /* F8 */
    { 0x4300, 0x5c00, 0x6600, 0x7000 }, /* F9 */
    { 0x4400, 0x5d00, 0x6700, 0x7100 }, /* F10 */
    {   none,   none,   none,   none }, /* Num Lock */
    {   none,   none,   none,   none }, /* Scroll Lock */
    { 0x4700, 0x4737, 0x7700,   none }, /* 7 Home */
    { 0x4800, 0x4838, 0x8d00,   none }, /* 8 UP */
    { 0x4900, 0x4939, 0x8400,   none }, /* 9 PgUp */
    { 0x4a2d, 0x4a2d, 0x8e00, 0x4af0 }, /* - */
    { 0x4b00, 0x4b34, 0x7300,   none }, /* 4 Left */
    { 0x4c00, 0x4c35, 0x8f00,   none }, /* 5 */
    { 0x4d00, 0x4d36, 0x7400,   none }, /* 6 Right */
    { 0x4e2b, 0x4e2b, 0x9000, 0x4ef0 }, /* + */
    { 0x4f00, 0x4f31, 0x7500,   none }, /* 1 End */
    { 0x5000, 0x5032, 0x9100,   none }, /* 2 Down */
    { 0x5100, 0x5133, 0x7600,   none }, /* 3 PgDn */
    { 0x5200, 0x5230, 0x9200,   none }, /* 0 Ins */
    { 0x5300, 0x532e, 0x9300,   none }, /* Del */
    {   none,   none,   none,   none }, /* SysReq */
    {   none,   none,   none,   none },
    { 0x565c, 0x567c,   none,   none }, /* \| */
    { 0x8500, 0x8700, 0x8900, 0x8b00 }, /* F11 */
    { 0x8600, 0x8800, 0x8a00, 0x8c00 }, /* F12 */
};

#define ARRAY_SIZE(x) sizeof(x) / (sizeof(x[0]))

uint16_t poll_key()
{
    while(keyboard_head == keyboard_tail);
    uint16_t key = keyboard_buffer[keyboard_head];
    keyboard_head = (keyboard_head + 1) & 0xff;
    return key;
}

#define KBD_RCTRL        1 << 0
#define KBD_LCTRL        1 << 1
#define KBD_RSHIFT       1 << 2
#define KBD_LSHIFT       1 << 3
#define KBD_ALT          1 << 4

#define KBD_LAST_E0      1 << 8
#define KBD_LAST_E1      1 << 9
#define KBD_CAPSLOCK     1 << 10

#define set_kbd_flag(in_released, in_flags) \
    { if(in_released) flags &= ~in_flags; \
      else            flags |=  in_flags; }

void process_key(uint8_t scancode)
{
    if(scancode == 0xe0 || scancode == 0xe1)
    {
        // we have more bytes
        flags |= (scancode == 0xe0 ? KBD_LAST_E0 : KBD_LAST_E1);
        return;
    }

    int key_release = scancode & 0x80;
    scancode &= ~0x80;

    if(flags & (KBD_LAST_E0 | KBD_LAST_E1))
    {
        if((flags & KBD_LAST_E1) && scancode == 0x1d)
        {
            return;
        }

        flags &= ~(KBD_LAST_E0 | KBD_LAST_E1);
    }

    switch(scancode)
    {
    case 0x3a: /* Caps Lock */
        if(key_release)
        {
            set_kbd_flag(flags & KBD_CAPSLOCK, KBD_CAPSLOCK);
        }
        return;
    case 0x2a: /* L Shift */
        set_kbd_flag(key_release, KBD_LSHIFT);
        return;
    case 0x36: /* R Shift */
        set_kbd_flag(key_release, KBD_RSHIFT);
        return;
    case 0x1d: /* Ctrl */
        if(flags & KBD_LAST_E0)
        {
            set_kbd_flag(key_release, KBD_RCTRL);
        }
        else
        {
            set_kbd_flag(key_release, KBD_LCTRL);
        }
        return;
    case 0x38: /* Alt */
        if(flags & KBD_LAST_E1)
        {
            return;
        }
        set_kbd_flag(key_release, KBD_ALT);
        return;
    default:
        break;
    }

    if(key_release)
    {
        return;
    }

    struct scaninfo *info = &scan_to_keycode[scancode];
    uint16_t keycode;
    if(flags & KBD_ALT)
    {
        keycode = info->alt;
    }
    else if(flags & (KBD_RCTRL | KBD_LCTRL))
    {
        keycode = info->control;
    }
    else
    {
        uint8_t useshift = (flags & (KBD_RSHIFT | KBD_LSHIFT)) ? 1 : 0;
        uint8_t ascii = info->normal & 0xff;
        if((flags & KBD_CAPSLOCK) && ascii >= 'a' && ascii <= 'z')
        {
            useshift ^= 1;
        }

        if(useshift)
        {
            keycode = info->shift;
        }
        else
        {
            keycode = info->normal;
        }
    }

    keyboard_buffer[keyboard_tail] = keycode;
    keyboard_tail = (keyboard_tail + 1) & 0xff;
}