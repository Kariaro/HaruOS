#include "idt.h"
#include "terminal.h"
#include "common.h"

__attribute__((aligned(0x10)))
static idt_entry_t idt[256];
static idtr_t idtr;

#define PRINT_REG(var, name) terminal_string(#name ": "); terminal_hex64(var->name); terminal_char('\n');
#define PRINT_REGS_T(var) \
    PRINT_REG(var, rax) \
    PRINT_REG(var, rcx) \
    PRINT_REG(var, rdx) \
    PRINT_REG(var, rbx) \
    PRINT_REG(var, rsp) \
    PRINT_REG(var, rbp) \
    PRINT_REG(var, rsi) \
    PRINT_REG(var, rdi)
//  PRINT_REG(var, rip) \
//  PRINT_REG(var, rcs) \
//  PRINT_REG(var, rflags) \
//  PRINT_REG(var, p_rsp) \
//  PRINT_REG(var, p_rss) \
    
void isr_handler(regs_t* a_regs, uint8_t a_index)
{
    int halt = 0;
    switch (a_index)
    {
    case 0x00: terminal_string("(0x00) Division by zero\n");            halt = 1; break;
    case 0x01: terminal_string("(0x01) Single-step interrupt\n");       break;
    case 0x02: terminal_string("(0x02) NMI\n");                         break;
    case 0x03: terminal_string("(0x03) Breakpoint\n");                  break;
    case 0x04: terminal_string("(0x04) Overflow\n");                    break;
    case 0x05: terminal_string("(0x05) Bound range exceeded\n");        break;
    case 0x06: terminal_string("(0x06) Invalid opcode\n");              break;
    case 0x07: terminal_string("(0x07) Coprocessor not available\n");   break;
    case 0x08: terminal_string("(0x08) Double Fault\n");                break;
    // ...
    case 0x0A: terminal_string("(0x0A) Invalid Task State Segment\n");  break;
    case 0x0B: terminal_string("(0x0B) Segment not present\n");         break;
    case 0x0C: terminal_string("(0x0C) Stack Segment Fault\n");         break;
    case 0x0D: terminal_string("(0x0D) General Protection Fault\n");    halt = 1; break;
    case 0x0E: terminal_string("(0x0E) Page Fault\n");                  break;

    default:
        terminal_string("(0x");
        terminal_hex8(a_index);
        terminal_string(") Unknown\n");
        break;
    }

    // terminal_hex64(*((uint64_t*) (a_regs) + 8)); terminal_char('\n');
    // terminal_hex64(*((uint64_t*) (a_regs) + 8)); terminal_char('\n');
    // terminal_hex64(*((uint64_t*) (a_regs) + 9)); terminal_char('\n');
    // terminal_string("rcs: ");
    // terminal_hex64(*((uint64_t*) (a_regs) + 10)); terminal_char('\n');
    // terminal_string("rsp: ");
    // terminal_hex64(*((uint64_t*) (a_regs) + 11)); terminal_char('\n');
    // terminal_string("rss: ");
    // terminal_hex64(*((uint64_t*) (a_regs) + 12)); terminal_char('\n');
    // terminal_string("rcs: ");
    // terminal_hex64(*((uint64_t*) (a_regs) + 13)); terminal_char('\n');
    // terminal_string("rflags: ");
    // terminal_hex64(*((uint64_t*) (a_regs) + 14)); terminal_char('\n');
    // terminal_string("rip: ");
    // terminal_hex64(*((uint64_t*) (a_regs) + 15)); terminal_char('\n');
    // terminal_hex64(*((uint64_t*) (a_regs) + 16)); terminal_char('\n');
    // terminal_hex64(*((uint64_t*) (a_regs) + 17)); terminal_char('\n');
    // terminal_hex64(*((uint64_t*) (a_regs) + 18)); terminal_char('\n');
    // terminal_hex64(*((uint64_t*) (a_regs) + 19)); terminal_char('\n');

    // TODO - Print interrupt return address for debugging
    PRINT_REGS_T(a_regs);

    // Halt if we have a serious error
    if(halt == 1)
    {
        terminal_string("PANIC!");
        for(;;);
    }
}

void irq_handler(regs_t* a_regs, uint8_t a_index)
{
    // terminal_string("call to (IRQ handler) index=");
    // terminal_hex8(a_index);
    // terminal_char('\n');
    // PRINT_REGS_T(a_regs);

    if(a_index >= 8) outb(0xA0, 0x20);
    outb(0x20, 0x20);
}

// 32 + 16 + 1
#define IDT_MAX_DESCRIPTORS     256 + 1
#define GDT_OFFSET_KERNEL_CODE  0x0028

#define MASTER_IRQ_COMMAND      0x20
#define MASTER_IRQ_DATA         0x21
#define SLAVE_IRQ_COMMAND       0xA0
#define SLAVE_IRQ_DATA          0xA1

extern void* isr_stub_table[];
extern void* irq_stub_table[];
extern ISR_Handler isr_buffer[];
extern IRQ_Handler irq_buffer[];

void idt_set_descriptor(uint8_t a_vector, void* a_offset, uint16_t a_selector, uint8_t a_flags) {
    idt_entry_t* descriptor = &idt[a_vector];

    descriptor->offset_1       = (uint64_t) a_offset & 0xFFFF;
    descriptor->kernel_cs      = a_selector;
    descriptor->ist            = 0;
    descriptor->attributes     = a_flags;
    descriptor->offset_2       = ((uint64_t) a_offset >> 16) & 0xFFFF;
    descriptor->offset_3       = ((uint64_t) a_offset >> 32) & 0xFFFFFFFF;
    descriptor->reserved       = 0;
}

void idt_init() {
    terminal_string("[Init ISR.O]\n");
    idtr.base = (uintptr_t) &idt[0];
    idtr.limit = (uint16_t) sizeof(idt_entry_t) * IDT_MAX_DESCRIPTORS - 1;
    
    for(uint8_t index = 0; index < 32; index++)
    {
        idt_set_descriptor(index, isr_stub_table[index], GDT_OFFSET_KERNEL_CODE, 0x8E);
    }

    for(uint8_t index = 0; index < 16; index++)
    {
        idt_set_descriptor(index + 32, irq_stub_table[index], GDT_OFFSET_KERNEL_CODE, 0x8E);
    }

    asm volatile ("lidt %0" : : "m"(idtr)); // load the new IDT
    asm volatile ("sti"); // set the interrupt flag
}

void idt_set_irq(uint8_t a_irq, IRQ_Handler a_function)
{
    irq_buffer[a_irq] = a_function;
}

void idt_set_isr(uint8_t a_isr, ISR_Handler a_function)
{
    isr_buffer[a_isr] = a_function;
}
