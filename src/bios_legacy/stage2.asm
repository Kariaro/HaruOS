;;; STAGE2.BIN

bits 16
org 0x0600

%define CODE_SEG_32     0x0008
%define DATA_SEG_32     0x0010
%define CODE_SEG_16     0x0018
%define DATA_SEG_16     0x0020
%define CODE_SEG_64     0x0028
%define DATA_SEG_64     0x0030

%define PAGE_PRESENT    (1 << 0)
%define PAGE_WRITE      (1 << 1)
%define PAGE_SIZE       (1 << 7)

STAGE2_START:
jmp short entry
times 4-($-$$)   db 0x90

; How many sectors to read
dw (STAGE2_END - STAGE2_START + 511) / 512

boot_drive:
    db 0x00

%macro hex_dump_memory 3
	push   ax
	mov    ax, es
	push   ax
	push   bx
	push   cx
	mov    ax, ((%1 >> 16) << 12)
    mov    es, ax
	mov    bx, (%1 & 0xffff)
	mov    cx, ((%2 + %3 - 1) / %3)
%%hex_dump_loop:
	push   cx
    mov    cx, %3
    call   PrintHexDump
	pop    cx
    add    bx, %3
    xor    ax, ax
    int    16h
	loop   %%hex_dump_loop
	pop    cx
	pop    bx
	pop    ax
	mov    es, ax
	pop    ax
%endmacro

[bits 16]
entry:
    ; Save boot drive for later
    mov    BYTE [boot_drive], dl

    ; Print loaded message
    mov    si, loaded_message_rl
    call   print

    mov    si, kernel_file  ; file to read
    mov    dl, 0x80         ; drive to read from
    push   WORD 0x0010      ; 0010 ....
    push   WORD 0x0000      ; .... 0000
    call   LoadFileFAT32
    jnc    .kernel_loaded
    mov    si, could_not_find_kernel
    call   print
    mov    ax, bx
    call   PrintHex16
    jmp    $
.kernel_loaded:
    ; KERNEL.BIN now exists at [1000:0000] 0x10000

    mov    ax, 0x1000
    mov    es, ax
    mov    bx, 0x0000
    call   RemapELF
    xor    ax, ax
    mov    es, ax

    ; KERNEL.BIN now remaped at [2000:0000] 0x10000
    ; Enter protected mode
    call real_to_pmode
[bits 32]
    ; Enter long mode
    ; =======================================

    ; Construct Page Map Level 4 [0x8000]
    ; Boot   mappings [0x8000-0xBFFF]
    mov edi, 0x8000
    push edi
    mov ecx, 0x1000
    xor eax, eax
    cld
    rep stosd
    pop edi

    ; Set PML4[0] -> PML3[0]         (Each entry in PML4 is 512 GB)
    lea eax, [edi + 0x1000]
    or eax, PAGE_PRESENT | PAGE_WRITE
    mov DWORD [edi + 0x0000], eax

    ; Set PML3[0] -> PML2[0]         (Each entry in PML3 is 1 GB)
    lea eax, [edi + 0x2000]
    or eax, PAGE_PRESENT | PAGE_WRITE
    mov DWORD [edi + 0x1000], eax

    ; Set PML2[0] -> PML1[0]         (Each entry in PML2 is 2 MB)
    lea eax, [edi + 0x3000]
    or eax, PAGE_PRESENT | PAGE_WRITE
    mov DWORD [edi + 0x2000], eax
    
    ; Set all values in PML1
    push edi
    mov eax, PAGE_PRESENT | PAGE_WRITE
.LoopPageTable:
    mov DWORD [edi + 0x3000], eax
    add eax, 0x1000
    add edi, 8
    cmp eax, 0x200000
    jb .LoopPageTable
    pop edi

    ; Disable IRQs
    mov al, 0xFF                      ; Out 0xFF to 0xA1 and 0x21 to disable all IRQs
    out 0xA1, al
    out 0x21, al

    nop
    nop

    lidt [idtptr]                     ; Load a zero length IDT so that any NMI causes a triple fault

    ; Enter long mode.
    mov eax, 10100000b                ; Set the PAE and PGE bit
    mov cr4, eax

    mov edx, edi                      ; Point CR3 at the PML4
    mov cr3, edx

    mov ecx, 0xC0000080               ; Read from the EFER MSR
    rdmsr    

    or eax, 0x00000100                ; Set the LME bit
    wrmsr

    mov eax, cr0                      ; Activate long mode
    or eax, 0x80000000
    mov cr0, eax

    jmp CODE_SEG_64:LongMode          ; Load CS with 64 bit segment and flush the instruction cache

[bits 64]
Bit64_PutHex:
    push   rax
    push   rcx
    mov    ecx, eax
    shr    eax, 4
    call   .get_nibble
    mov    BYTE [edi], al
    mov    eax, ecx
    call   .get_nibble
    mov    BYTE [edi + 2], al
    pop    rcx
    pop    rax
    ret
.get_nibble:
    and    al, 0x0f
    add    al, 0x30
    cmp    al, 0x3a
    jc     .hexa
    add    al, 0x07
.hexa:
    ret

[bits 64]
LongMode:
    mov ax, DATA_SEG_64
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    call 0x20000
.hlt:
    hlt
    jmp .hlt

%include "print_util.asm"
%include "lm_pm_code.asm"
%include "read_sectors.asm"
%include "load_file.asm"
%include "load_elf.asm"

kernel_file:
    db 'KERNEL  BIN', 0

could_not_find_kernel db 0x0d, 0x0a, 'Could not find KERNEL.O', 0x0d, 0x0a, 0

loaded_message_rl db 'From STAGE2.BIN : jump was successful', 0x0d, 0x0a, 0x0d, 0x0a, 0
loaded_message_pm db 'STAGE2.BIN entered protected mode', 0

times 1024+512+512+512-($-$$)   db 0

STAGE2_END:
