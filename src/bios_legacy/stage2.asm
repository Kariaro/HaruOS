;;; STAGE2.BIN

bits 16
org 0x0600

jmp entry

%include "lm_pm_code.asm"
%include "read_sectors.asm"
%include "load_file.asm"

kernel_file:
    db 'KERNEL  BIN', 0

[bits 16]
entry:
    mov si, loaded_message_rl
    call print

    mov si, kernel_file  ; file to read
    mov dl, 1            ; drive to read from
    push WORD 0xC000     ; 0010 ....
    push WORD 0x0000     ; .... 0000
    call LoadFileFAT32
    jnc .load_kernel
    mov ax, 0x0e24 ; '$'
    int 10h
    int 18h
.load_kernel:

    ; Read KERNEL.BIN at [0x0010_0000]
    ; call LOAD_KERNEL_ASM

    mov al, BYTE [bx + 3]
    call PrintHex8
    mov al, BYTE [bx + 2]
    call PrintHex8
    mov al, BYTE [bx + 1]
    call PrintHex8
    mov al, BYTE [bx + 0]
    call PrintHex8
    
    mov ax, 0x0e24
    int 10h
    mov ah, 0x00
    int    16h  ; BIOS await keypress

    ; Enter protected mode
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

    ; Enter long mode
    ; =======================================

    mov edi, 0x90000

    push edi
    mov ecx, 0x1000
    xor eax, eax
    cld
    rep stosd
    pop edi

    ; Build the Page Map Level 4
    ; es:di points to the Page Map Level 4 table
    lea eax, [es:edi + 0x1000]              ; Put the address of the Page Directory Pointer Table in to EAX
    or eax, PAGE_PRESENT | PAGE_WRITE       ; Or EAX with the flags - present flag, writable flag
    mov DWORD [es:edi + 0x000], eax         ; Store the value of EAX as the first PML4E

    ; Build the Page Directory Pointer Table
    lea eax, [es:edi + 0x2000]              ; Put the address of the Page Directory in to EAX
    or eax, PAGE_PRESENT | PAGE_WRITE       ; Or EAX with the flags - present flag, writable flag
    mov DWORD [es:edi + 0x1000], eax        ; Store the value of EAX as the first PDPTE
    
    ; Build the Page Directory
    lea eax, [es:edi + 0x3000]              ; Put the address of the Page Table in to EAX
    or eax, PAGE_PRESENT | PAGE_WRITE       ; Or EAX with the flags - present flag, writeable flag
    mov DWORD [es:edi + 0x2000], eax        ; Store to value of EAX as the first PDE

    push edi                                ; Save DI for the time being
    lea edi, [edi + 0x3000]                 ; Point DI to the page table
    mov eax, PAGE_PRESENT | PAGE_WRITE      ; Move the flags into EAX - and point it to 0x0000

    ; Build the Page Table
.LoopPageTable:
    mov DWORD [es:edi], eax
    add eax, 0x1000
    add edi, 8
    cmp eax, 0x200000                 ; If we did all 2MiB, end
    jb .LoopPageTable

    pop edi                            ; Restore DI

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

    mov ebx, cr0                      ; Activate long mode -
    or ebx, 0x80000001                ; - by enabling paging and protection simultaneously
    mov cr0, ebx

    ;lgdt [gdtptr]                     ; Load GDT.Pointer defined below
    jmp CODE_SEG_64:LongMode          ; Load CS with 64 bit segment and flush the instruction cache

[bits 64]
; @param rdi  - start of code
; @param rcx  - amount of pages
BuildKernelPage:
    ; kernel is loaded at 0x10_0000

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

    ; We should allocate more memory for the kernel 
    jmp 0x0100000

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

[bits 16]
PrintHex16:
    push   ax
    push   cx
    mov    cx, ax
    shr    ax, 8
    call   PrintHex8
    mov    ax, cx
    call   PrintHex8
    mov    al, 0x20
    mov    ah, 0eh
    int    10h
    pop    cx
    pop    ax
    ret
PrintHex8:
    push   ax
    push   cx
    mov    cx, ax
    mov    ax, cx
    shr    ax, 4
    call   .DIGIT
    mov    ax, cx
    call   .DIGIT
    pop    cx
    pop    ax
    ret
.DIGIT:
    and    al, 0x0f
    add    al, 0x30
    cmp    al, 0x3a
    jc     .hexa
    add    al, 0x07
.hexa:
    mov    ah, 0eh
    int    10h
    ret


loaded_message_rl db 0x0d, 0x0a, 'STAGE2.BIN was executed from memory', 0x0d, 0x0a, 0
loaded_message_pm db 'STAGE2.BIN entered protected mode', 0

times 1024+512-($-$$)   db 0
