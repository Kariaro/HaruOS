%macro pusha 0
    mov QWORD [rsp - 64], rax
    mov QWORD [rsp - 56], rcx
    mov QWORD [rsp - 48], rdx
    mov QWORD [rsp - 40], rbx
    mov QWORD [rsp - 32], rsp
    mov QWORD [rsp - 24], rbp
    mov QWORD [rsp - 16], rsi
    mov QWORD [rsp -  8], rdi
    sub rsp, 64
%endmacro

%macro popa 0
    add rsp, 64
    mov rax, QWORD [rsp - 64]
    mov rcx, QWORD [rsp - 56]
    mov rdx, QWORD [rsp - 48]
    mov rbx, QWORD [rsp - 40]
    mov rbp, QWORD [rsp - 24]
    mov rsi, QWORD [rsp - 16]
    mov rdi, QWORD [rsp -  8]
    mov rsp, QWORD [rsp - 32]
%endmacro

%macro ISR_ERR 1
isr_stub_%+%1:
    pusha
    mov rsi, %1
    mov rdi, rsp
    call isr_handler
    popa
    iretq
%endmacro

%macro ISR_NO_ERR 1
    ISR_ERR %1
%endmacro

%macro IRQ 2
irq_stub_%+%1:
    pusha
    mov rsi, %1
    mov rdi, rsp
    call irq_handler
    popa
    iretq
%endmacro

; Setup ISR stubs
[extern isr_handler]
ISR_NO_ERR   0
ISR_NO_ERR   1
ISR_NO_ERR   2
ISR_NO_ERR   3
ISR_NO_ERR   4
ISR_NO_ERR   5
ISR_NO_ERR   6
ISR_NO_ERR   7
ISR_ERR      8
ISR_NO_ERR   9
ISR_ERR      10
ISR_ERR      11
ISR_ERR      12
ISR_ERR      13
ISR_ERR      14
ISR_NO_ERR   15
ISR_NO_ERR   16
ISR_ERR      17
ISR_NO_ERR   18
ISR_NO_ERR   19
ISR_NO_ERR   20
ISR_NO_ERR   21
ISR_NO_ERR   22
ISR_NO_ERR   23
ISR_NO_ERR   24
ISR_NO_ERR   25
ISR_NO_ERR   26
ISR_NO_ERR   27
ISR_NO_ERR   28
ISR_NO_ERR   29
ISR_ERR      30
ISR_NO_ERR   31


; Setup IRQ stubs
[extern irq_handler]
IRQ   0,   32
IRQ   1,   33
IRQ   2,   34
IRQ   3,   35
IRQ   4,   36
IRQ   5,   37
IRQ   6,   38
IRQ   7,   39
IRQ   8,   40
IRQ   9,   41
IRQ   10,  42
IRQ   11,  43
IRQ   12,  44
IRQ   13,  45
IRQ   14,  46
IRQ   15,  47


[global isr_stub_table]
isr_stub_table:
%assign isr_i 0
%rep    32
    dq isr_stub_%+isr_i
%assign isr_i isr_i+1
%endrep

[global irq_stub_table]
irq_stub_table:
%assign irq_i 0
%rep    16
    dq irq_stub_%+irq_i
%assign irq_i irq_i+1
%endrep
