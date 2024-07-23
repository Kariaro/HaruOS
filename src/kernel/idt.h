
#ifndef IDT_H_
#define IDT_H_

#include <stdint.h>

struct data_idt_entry
{
    uint16_t offset_1; // bits 0..15
    uint16_t kernel_cs;
    uint8_t  ist;
    uint8_t  attributes;
    uint16_t offset_2; // bits 16..31
    uint32_t offset_3; // bits 32..63
    uint32_t reserved;
} __attribute__((packed));
typedef struct data_idt_entry idt_entry_t;

struct data_idtr
{
    uint16_t limit;
    uint64_t base;
} __attribute__((packed));
typedef struct data_idtr idtr_t;


struct data_regs
{
    // uint64_t p_rss, p_rsp, rflags, rcs, rip;
    // uint64_t return_call;
    uint64_t rax, rcx, rdx, rbx, rsp, rbp, rsi, rdi;
};
typedef struct data_regs regs_t;


#ifdef __cplusplus
extern "C"
{
#endif

typedef void (*IRQ_Handler)(regs_t* a_regs, uint8_t a_index);
typedef void (*ISR_Handler)(regs_t* a_regs, uint8_t a_index);

extern void isr_handler(regs_t* a_regs, uint8_t a_index);
extern void irq_handler(regs_t* a_regs, uint8_t a_index);

void idt_init();
void idt_set_irq(uint8_t a_irq, IRQ_Handler a_function);
void idt_set_isr(uint8_t a_isr, ISR_Handler a_function);

#ifdef __cplusplus
}
#endif

#endif  // ISR_H_
