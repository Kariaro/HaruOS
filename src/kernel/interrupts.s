[bits 64]

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

%assign index 0
%rep    32
isr_stub_%+index:
    cli
    cld
    pusha
    mov rsi, %+index
    mov rdi, rsp
    mov rax, QWORD [isr_buffer + ((%+index) * 8)]
    call rax
    popa
    sti
    iretq
%assign index index + 1
%endrep

%assign index 0
%rep    16
irq_stub_%+index:
    cli
    cld
    pusha
    mov rsi, %+index
    mov rdi, rsp
    mov rax, QWORD [irq_buffer + ((%+index) * 8)]
    call rax
    popa
    sti
    iretq
%assign index index + 1
%endrep

[extern isr_handler]
[extern irq_handler]

; Modifiable by idt.c
[global isr_buffer]
isr_buffer:
%assign index 0
%rep    32
    dq isr_handler
%assign index index+1
%endrep

; Modifiable by idt.c
[global irq_buffer]
irq_buffer:
%assign index 0
%rep    16
    dq irq_handler
%assign index index+1
%endrep

[global isr_stub_table]
isr_stub_table:
%assign index 0
%rep    32
    dq isr_stub_%+index
%assign index index+1
%endrep

[global irq_stub_table]
irq_stub_table:
%assign index 0
%rep    16
    dq irq_stub_%+index
%assign index index+1
%endrep
