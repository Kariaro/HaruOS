; Code for jumping into and from protected mode

%define CODE_SEG_32     0x0008
%define DATA_SEG_32     0x0010
%define CODE_SEG_16     0x0018
%define DATA_SEG_16     0x0020
%define CODE_SEG_64     0x0028
%define DATA_SEG_64     0x0030

%define PAGE_PRESENT    (1 << 0)
%define PAGE_WRITE      (1 << 1)
%define PAGE_SIZE       (1 << 7)

[bits 16]
real_to_pmode:
    pop ax
    push 0x0000
    push ax
    cli

    ; load gdt
    lgdt [gdtptr]

    ; enable pe bit in cr0
    mov eax, cr0
    or eax, 1
    mov cr0, eax

    ; jump to protected mode
    jmp CODE_SEG_32:.in_pmode
[bits 32]
.in_pmode:
    mov ax, DATA_SEG_32
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    ret


; enter real mode
[bits 32]
pmode_to_real:
    cli
    jmp CODE_SEG_16:.pm16
[bits 16]
.pm16:
    ; Use 16-bit data selectors
    mov ax, DATA_SEG_16
    mov ds,ax
    mov es,ax
    mov fs,ax
    mov gs,ax
    mov ss,ax

    ; Load IVT
    lidt [idtptr]

    ; Disable PE bit in CR0
    mov eax, cr0
    and eax, ~1
    mov cr0, eax

    jmp 0x00:.in_rmode
.in_rmode:
    ; Set data segment registers to zero
    xor ax,ax
    mov ds,ax
    mov es,ax
    mov fs,ax
    mov gs,ax
    mov ss,ax

    ; Pop the first 16 bits of the return address, then skip over the next 16 bits
    pop ax
    add sp, 2
    sti
    jmp ax

; [bits 64]
; longmode_to_real:
;     cli
; 
;     ; Disable long mode
;     mov rbx, cr0
;     and ebx, ~0x80000000
;     mov cr0, rbx
; 
;     ; mov rax, CODE_SEG_32
;     ; mov rdx, .pm32
;     push DWORD CODE_SEG_32
;     push DWORD .pm32
;     retf
;     ; jmp CODE_SEG_32:.pm32
; [bits 32]
; .pm32:
;     call pmode_to_real
; [bits 16]
;     ; Pop the first 16 bits of the return address, then skip over the next 48 bits
;     pop ax
;     add sp, 6
;     sti
;     jmp ax
; 
; [bits 16]
; real_to_longmode:
;     call real_to_pmode
; [bits 32]
;     pop ax
;     push WORD 0x0000
;     push WORD 0x0000
;     push WORD 0x0000
;     push ax
;     cli
; 
;     ; Activate long mode
;     mov ebx, cr0
;     or ebx, 0x80000001
;     mov cr0, ebx
; 
;     jmp CODE_SEG_64:.in_longmode
; [bits 64]
; .in_longmode:
;     mov ax, DATA_SEG_64
;     mov ds, ax
;     mov es, ax
;     mov fs, ax
;     mov gs, ax
;     mov ss, ax
;     ret



idtptr:
    .size: dw 0x3ff
    .offset: dd 0

gdtptr:
    .size: dw gdt.END - gdt.NULL + 1
    .offset: dd gdt

; %define gdt_entry(limit, base, access, flags) \
;     dq (limit & 0xFFFF) \
;      | ((base & 0xFFFFFF) << 16) \
;      | ((access & 0xFF) << 40) \
;      | ((((limit >> 16) & 0xF) | ((flags & 0xF) << 4)) << 48) \
;      | (((base >> 24) & 0xFF) << 56)

gdt:
.NULL: ; offset 0x00
    ; gdt_entry(0x00000, 0x00000000, 00000000b, 0000b)
    dw 0x0000
    dw 0x0000
    db 0x00
    db 0x00
    db 0x00
    db 0x00
.CODE_32: ; offset 0x08
    ; gdt_entry(0xFFFFF, 0x00000000, 10011010b, 1100b)
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 10011010b
    db 11001111b
    db 0x00
.DATA_32: ; offset 0x10
    ; gdt_entry(0xFFFFF, 0x00000000, 10010010b, 1100b)
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 10010010b
    db 11001111b
    db 0x00
.CODE_16: ; offset 0x18
    ; gdt_entry(0xFFFFF, 0x00000000, 10011010b, 1000b)
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 10011010b
    db 10001111b
    db 0x00
.DATA_16: ; offset 0x20
    ; gdt_entry(0xFFFFF, 0x00000000, 10010010b, 1000b)
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 10010010b
    db 10001111b
    db 0x00
.CODE_64: ; offset 0x28
    ; gdt_entry(0xFFFFF, 0x00000000, 10011010b, 1010b)
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 10011010b
    db 10101111b
    db 0x00
.DATA_64: ; offset 0x30
    ; gdt_entry(0xFFFFF, 0x00000000, 10010010b, 1010b)
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 10010010b
    db 10101111b
    db 0x00
.END:
