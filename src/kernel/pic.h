
#ifndef PIC_H_
#define PIC_H_

#include "common.h"

void pic_init();
void pic_disable();

void pic_disable_irq(uint8_t a_irq);
void pic_enable_irq(uint8_t a_irq);

#endif  // PIC_H_
