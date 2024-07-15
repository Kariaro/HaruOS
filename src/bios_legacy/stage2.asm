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


[bits 16]
entry:
    mov    ax, 0x0e21 ; '!'
    int    10h

    mov    al, dl
    call   PrintHex8

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
    mov    ax, 0x1000
    mov    es, ax
    mov    bx, 0x0000
.tloop:
    mov    cx, 0x0100
    call   PrintHexDump
    ; xor    ax, ax
    ; int    16h
    add    bx, 0x0100
    cmp    bx, 0x0100
    jb     .tloop
    xor    ax, ax
    mov    es, ax



    ; KERNEL.BIN now exists at [1000:0000] 0x10000

    mov    ax, 0x1000
    mov    es, ax
    mov    bx, 0x0000
    call   RemapELF


    mov ah, 0x00
    int 16h  ; BIOS await keypress
    int 19h  ; BIOS warning / restart

    ; Enter protected mode
    call real_to_pmode
[bits 32]
    ; Enter long mode
    ; =======================================

    ; Construct Page Map Level 4 [0x10000]
    ; Boot   mappings [0x8000-0xBFFF]
    ; Kernel mappings [0xC000-0xFFFF]
    mov edi, 0x10000
    push edi
    mov ecx, 0x2000
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

    ; Setup kernel memory
    ;  last 4 gb is PML4[511][508][0][0]
    ; Set PML4[511] -> [edi + 0x4000] (PML4[511] memory)
    lea eax, [edi + 0x4000]
    or eax, PAGE_PRESENT | PAGE_WRITE
    mov DWORD [edi + 0x0000 + (0x4 * 511)], eax

    ; K_PML3[510 -> 511] [0xffff_ffff_8000_0000 -> 0xffff_ffff_ffff_ffff]
    ; Set K_PML3[510] -> K_PML2[0]
    lea eax, [edi + 0x5000]
    or eax, PAGE_PRESENT | PAGE_WRITE
    mov DWORD [edi + 0x4000 + (0x4 * 510)], eax

    ; Set K_PML2[0] -> K_PML1[0]
    lea eax, [edi + 0x6000]
    or eax, PAGE_PRESENT | PAGE_WRITE
    mov DWORD [edi + 0x5000], eax

    ; Set all values in K_PML1
    push edi
    mov eax, PAGE_PRESENT | PAGE_WRITE
    add eax, 0x80000_000
.LoopPageTable2: ; make it point to physical address 0x8000_0000
    mov DWORD [edi + 0x6000], eax
    add eax, 0x1000
    add edi, 8
    cmp eax, 0x80200_000
    jb .LoopPageTable2
    pop edi ; kernel has 2 mb mapped at 0xffff_ffff_8000_0000 -> 0xffff_ffff_8020_0000


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

    ; Blank out the screen to a blue color.
    ; mov edi, 0xB8000
    ; mov rcx, 500                      ; Since we are clearing uint64_t over here, we put the count as Count/4.
    ; mov rax, 0x1F201F201F201F20       ; Set the value to set the screen to: Blue background, white foreground, blank spaces.
    ; rep stosq                         ; Clear the entire screen.

    ; Display "Hello World!"
    mov edi, 0x00b8000
    mov rax, 0x1F6C1F6C1F651F48
    mov [edi +  0], rax
    mov rax, 0x1F6F1F571F201F6F
    mov [edi +  8], rax
    mov rax, 0x1F211F641F6C1F72
    mov [edi + 16], rax

    mov eax, 0xE2
    mov edi, 0x00b8000
    call Bit64_PutHex
    mov eax, 0x3F
    mov edi, 0x00b8006
    call Bit64_PutHex

    mov al, BYTE [0xffff_ffff_8000_0000]

    ; We should allocate more memory for the kernel
.hlt:
    hlt
    jmp .hlt
    jmp 0x010000

;     call longmode_to_real
; [bits 16]
;     mov ax, 0x0e24
;     int 10h
; 
;     mov ax, sp
;     call PrintHex16
; 
;     mov ax, 0x0000 ; destination high
;     mov es, ax
;     mov bx, 0x8000 ; destination low
;     mov dx, 0x0000 ; lba high
;     mov ax, 0x0000 ; lba low
;     mov di, 1      ; kernel is on drive 1
;     mov cx, 1      ; read one sector
;     call ReadSectors
; 
;     mov ax, 0x0e24
;     int 10h
;     call real_to_longmode
; [bits 64]
    mov edi, 0x00b8000
    mov rax, 0x0F210F640F6C0F72
    mov [edi + 16], rax


    hlt
    jmp $

%include "print_util.asm"
%include "lm_pm_code.asm"
%include "read_sectors.asm"
%include "load_file.asm"
%include "load_elf.asm"

kernel_file:
    db 'KERNEL  BIN', 0

could_not_find_kernel db 0x0d, 0x0a, 'Could not find KERNEL.O', 0x0d, 0x0a, 0

loaded_message_rl db 0x0d, 0x0a, 'STAGE2.BIN was executed from memory', 0x0d, 0x0a, 0
loaded_message_pm db 'STAGE2.BIN entered protected mode', 0

times 1024+512+512+512-($-$$)   db 0

STAGE2_END:
