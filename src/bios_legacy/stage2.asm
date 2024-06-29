;;; STAGE2.BIN

bits 16
org 0x0600

jmp entry

%include "lm_pm_code.asm"


[bits 16]
entry:
    mov si, loaded_message_rl
    call print

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

    ; Read kernel to [0xC0000000]
    ; mov edi, 0xC000_0000
    ; call load_kernel


    ; Enter long mode
    ; =======================================

    mov edi, 0x9000

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

%include "read_sectors.asm"

load_kernel_data:
.BPB_SecPerClus:
    db 0
.data_sector:
    dw 0x0000
.size_high:
    dw 0x0000
.size_low:
    dw 0x0000
.lba:
    dw 0x0000
.kernel_file:
    db 'KERNEL  BIN', 0

[bits 32]
load_kernel:
    call pmode_to_real
[bits 16]
    ; Destination [0x10000]
    mov ax, 0x1000 ; destination high
    mov es, ax
    mov bx, 0x0000 ; destination low
    mov dx, 0x0000 ; lba high
    mov ax, 0x0000 ; lba low
    mov di, 1      ; kernel is on drive 1
    mov cx, 1      ; read one sector
    call ReadSectors
    mov bx, 0x0000

    ; calculate root dir
    xor ax, ax
    mov al, BYTE [es:bx]
    call PrintHex16             ; BPB_NumFATs
    mov ax, WORD [es:bx + 0x24]
    call PrintHex16             ; BPB_FATSz32
    mov ax, WORD [es:bx + 0x0E]
    call PrintHex16             ; BPB_RsvdSecCnt

    ; BPB_SecPerClus
    mov al, BYTE [es:bx + 0x0D]
    mov BYTE [load_kernel_data.BPB_SecPerClus], al

    ; calculate data sector
    xor ax, ax
    mov al, BYTE [es:bx + 0x10]      ; BPB_NumFATs    (always 2)
    mul WORD [es:bx + 0x24]          ; BPB_FATSz32
    add ax, WORD [es:bx + 0x0E]      ; BPB_RsvdSecCnt
    mov WORD [load_kernel_data.data_sector], ax
    call PrintHex16

    ; calculate root directory first cluster 
    mov    ax, WORD [es:bx + 0x2C]   ; BPB_RootClus
    sub    ax, 0x0002
    xor    cx, cx
    mov    cl, BYTE [load_kernel_data.BPB_SecPerClus]
    mul    cx
    add    ax, WORD [load_kernel_data.data_sector]
    push   ax

    ; read first root directory cluster
    ; Destination [0x10000]
    mov    ax, 0x1000 ; destination high
    mov    es, ax
    mov    bx, 0x0000 ; destination low
    mov    di, 1      ; kernel is on drive 1
    mov    cx, 1      ; read one sector
    mov    dx, 0x0000 ; lba high
    pop    ax         ; lba low
    call ReadSectors
    mov bx, 0x0000
    
    ; mov dx, 0
    ; mov cx, 0x0200
    ; mov bx, 0x0000
    ; .LOOP:
    ;     mov al, BYTE [es:bx]
    ;     call PrintHex8
    ;     inc bx
    ;     inc dx
    ;     cmp dx, 32
    ;     jnz .END
    ;     mov dx, 0
    ;     mov ax, 0x0e0d
    ;     int 10h
    ;     mov ax, 0x0e0a
    ;     int 10h
    ; .END:
    ;     loop .LOOP

    ; find kernel
    mov cx, 8
    mov di, 0x0000 + 0x20
.FIND_KERNEL:
    push   cx
    push   di
    mov    si, load_kernel_data.kernel_file
    mov    cx, 0x000B ; 11 characters
    repe   cmpsb
    pop    di
    pop    cx
    je     .KERNEL_FOUND
    add    di, 0x0020
    loop   .FIND_KERNEL
    ; Failed to find kernel
    mov ax, 0x0e24 ; '$'
    int 10h
    int 18h
.KERNEL_FOUND:
    ; Read kernel size
    mov    ax, [es:di + 0x1E]
    mov    WORD [load_kernel_data.size_high], ax
    mov    ax, [es:di + 0x1C]
    mov    WORD [load_kernel_data.size_low], ax

    ; Calculate kernel disk lba
    mov    ax, [es:di + 0x1A]
    sub    ax, 0x0002
    xor    cx, cx
    mov    cl, BYTE [load_kernel_data.BPB_SecPerClus]
    mul    cx
    add    ax, WORD [load_kernel_data.data_sector]
    mov    WORD [load_kernel_data.lba], ax
    call   PrintHex16

.READ_LOOP:
    ; Sectors to read (32 kb)
    mov dx, WORD [load_kernel_data.size_high] ; high 16 bits
    mov ax, WORD [load_kernel_data.size_low]  ; low 16 bits
    cmp dx, 0
    jg .SECTOR_LARGE
.SECTOR_SMALL:
    add ax, 0x1FF
    adc dx, 0
    mov cx, 0x200
    div cx
    mov cx, ax
    cmp dx, 0x40
    cmp ax, dx
    cmova cx, dx
    jmp .READ_LOOP_END
.SECTOR_LARGE:
    mov cx, 0x40 ; 64
.READ_LOOP_END:
    mov ax, cx
    call PrintHex16

    ; Destination [0x10000]
    mov    di, 1      ; kernel is on drive 1
    mov    ax, 0x1000 ; destination high
    mov    es, ax
    mov    bx, 0x0000 ; destination low
    mov    dx, 0x0000 ; lba high
    mov    ax, WORD [load_kernel_data.lba]
    call ReadSectors
    mov bx, 0x0000

    call real_to_pmode
[bits 32]
    mov cx,  0x
    mov esi, 0x10000
    mov edi, 0xC000_0000

    


    mov    ax, 0x0e21 ; '!'
    int    10h
    int    18h

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

    call longmode_to_real
[bits 16]
    mov ax, 0x0e24
    int 10h

    mov ax, sp
    call PrintHex16

    mov ax, 0x0000 ; destination high
    mov es, ax
    mov bx, 0x8000 ; destination low
    mov dx, 0x0000 ; lba high
    mov ax, 0x0000 ; lba low
    mov di, 1      ; kernel is on drive 1
    mov cx, 1      ; read one sector
    call ReadSectors

    mov ax, 0x0e24
    int 10h
    call real_to_longmode
[bits 64]
    mov edi, 0x00b8000
    mov rax, 0x0F210F640F6C0F72
    mov [edi + 16], rax


    hlt
    jmp $


loaded_message_rl db 0x0d, 0x0a, 'STAGE2.BIN was executed from memory', 0x0d, 0x0a, 0
loaded_message_pm db 'STAGE2.BIN entered protected mode', 0

times 1024+512-($-$$)   db 0
