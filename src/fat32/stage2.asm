;;; STAGE2.BIN

bits 16
ORG 0x0200

entry:
    mov si, loaded_message_rl
    call print

    call real_to_pmode
[bits 32]
    
    mov esi, loaded_message_pm
    mov ebx, 0xb8000 + (160 * 2)
    .loop1:
        lodsb     
        mov BYTE [ebx], al
        cmp al, 0
        je .end1
        add ebx, 2
        jmp .loop1
    .end1:

    call pmode_to_real
[bits 16]
    mov ah, 0eh
    mov al, '#'
    int 10h

    call real_to_pmode
[bits 32]
    mov esi, loaded_message_pm
    mov ebx, 0xb8000 + (160 * 4)
    .loop2:
        lodsb     
        mov BYTE [ebx], al
        cmp al, 0
        je .end2
        add ebx, 2
        jmp .loop2
    .end2:


    hlt
	jmp $

; jump from real to protected mode
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
    jmp 0x08:.in_pmode
[bits 32]
.in_pmode:
    mov ax, 0x10
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
    jmp 0x18:.pm16
[bits 16]
.pm16:
    ; Use 16-bit data selectors
    mov ax, 0x20
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

    ; Pop the first sixteen bits of the return address, then skip
    ; over the next sixteen.
    pop ax
    add sp, 2
    sti
    jmp ax


[bits 16]
print:
    push ax
    mov ah, 0eh
.rep:
    lodsb
    cmp al, 0
    je .done
    int 10h
    jmp .rep
.done:
    pop ax
    ret

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
.END:

loaded_message_rl db 0x0d, 0x0a, 'STAGE2.BIN was executed from memory', 0x0d, 0x0a, 0
loaded_message_pm db 'STAGE2.BIN entered protected mode', 0

times 512-($-$$)   db 0
