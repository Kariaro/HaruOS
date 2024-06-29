
[bits 16]
LOAD_KERNEL_ASM:
    jmp .start
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
; .failed_to_find_kernel: db 'Failed to find KERNEL.BIN', 0
.start:
    ; read fat32 root sector
    mov    ax, 0x1000 ; destination high
    mov    es, ax
    mov    bx, 0x0000 ; destination low
    mov    dx, 0x0000 ; lba high
    mov    ax, 0x0000 ; lba low
    mov    di, 1      ; kernel is on drive 1
    mov    cx, 1      ; read one sector
    call   ReadSectors
    mov    bx, 0x0000

    ; get sectors per cluster
    mov    al, BYTE [es:bx + 0x0D]      ; BPB_SecPerClus
    mov    BYTE [.BPB_SecPerClus], al

    ; calculate data sector
    xor    ax, ax
    mov    al, BYTE [es:bx + 0x10]      ; BPB_NumFATs    (always 2)
    mul    WORD [es:bx + 0x24]          ; BPB_FATSz32
    add    ax, WORD [es:bx + 0x0E]      ; BPB_RsvdSecCnt (usually 32)
    mov    WORD [.data_sector], ax
 
    ; calculate root directory first cluster 
    mov    ax, WORD [es:bx + 0x2C]   ; BPB_RootClus
    sub    ax, 0x0002
    xor    cx, cx
    mov    cl, BYTE [.BPB_SecPerClus]
    mul    cx
    add    ax, WORD [.data_sector]
    push   ax

    ; read first root directory cluster
    mov    ax, 0x1000 ; destination high
    mov    es, ax
    mov    bx, 0x0000 ; destination low
    mov    di, 1      ; kernel is on drive 1
    mov    cx, 1      ; read one sector
    mov    dx, 0x0000 ; lba high
    pop    ax         ; lba low
    call   ReadSectors
    mov    bx, 0x0000
    
    ; mov    dx, 0
    ; mov    cx, 0x0200
    ; mov    bx, 0x0000
    ; .LOOP:
    ;     mov    al, BYTE [es:bx]
    ;     call   PrintHex8
    ;     inc    bx
    ;     inc    dx
    ;     cmp    dx, 32
    ;     jnz    .END
    ;     mov    dx, 0
    ;     mov    ax, 0x0e0d
    ;     int    10h
    ;     mov    ax, 0x0e0a
    ;     int    10h
    ; .END:
    ;     loop   .LOOP

    ; find kernel
    mov    cx, 8
    mov    di, 0x0000 + 0x20
.FIND_KERNEL:
    push   cx
    push   di
    mov    si, .kernel_file
    mov    cx, 0x000B ; 11 characters
    repe   cmpsb
    pop    di
    pop    cx
    je     .KERNEL_FOUND
    add    di, 0x0020
    loop   .FIND_KERNEL
    ; Failed to find kernel
    mov    ax, 0x0e24 ; '$'
    int    10h
    int    18h
.KERNEL_FOUND:
    ; Read kernel size
    mov    ax, WORD [es:di + 0x1E]
    mov    WORD [.size_high], ax
    mov    ax, WORD [es:di + 0x1C]
    mov    WORD [.size_low], ax

    ; Calculate kernel disk lba
    mov    ax, WORD [es:di + 0x1A]
    sub    ax, 0x0002
    xor    cx, cx
    mov    cl, BYTE [.BPB_SecPerClus]
    mul    cx
    add    ax, WORD [.data_sector]
    mov    WORD [.lba], ax

    mov    di, 0
    
    mov    ax, 0x0e0d
    int    10h
    mov    ax, 0x0e0a
    int    10h
.READ:
    mov    dx, WORD [.size_high] ; high 16 bits
    mov    ax, WORD [.size_low]  ; low 16 bits
    cmp    dx, 0
    jnz    .MORE_SKIP
    cmp    ax, 0
    jnz    .MORE
    jmp    .DONE
.MORE:
    cmp    ax, 0x200
    jae    .MORE_SKIP
    ; Ax is below 0x200 set it to 0x200 to allow reading one more sector
    mov    ax, 0x200
.MORE_SKIP:
    sub    ax, 0x200
    jnc    .SKIP_DEC
    cmp    dx, 0
    je     .DONE
    dec    dx
.SKIP_DEC:
    mov    WORD [.size_high], dx
    mov    WORD [.size_low], ax
    ; mov    ax, WORD [.size_high]
    ; call   PrintHex16
    ; mov    ax, WORD [.size_low]
    ; call   PrintHex16
    ; inc    di
    ; mov    ax, di
    ; call   PrintHex16
    ; mov    ax, 0x0e0d
    ; int    10h
    ; mov    ax, 0x0e0a
    ; int    10h
    ; mov    ah, 0x00
    ; int    16h  ; BIOS await keypress

    ; Read sector to [0x10000]
    push   di
    mov    ax, 0x1000      ; destination high
    mov    es, ax
    mov    bx, 0x0000      ; destination low
    mov    di, 1           ; kernel is on drive 1
    mov    cx, 1           ; read one sector
    mov    dx, 0x0000      ; lba high
    mov    ax, WORD [.lba] ; lba low
    call   ReadSectors
    mov    ax, 0x0000
    mov    es, ax
    pop    di

    mov    ax, WORD [.lba]
    inc    ax
    mov    WORD [.lba], ax

    call   real_to_pmode
[bits 32]
    ; Copy to data [0x00100000 + (0x200 * di)]
    movzx  eax, di
    mov    edx, 0x0000_0000
    mov    ecx, 0x0000_0200
    mul    ecx
    mov    esi, 0x0001_0000
    mov    edi, eax
    add    edi, 0x0010_0000
    mov    ecx, 0x0000_0200
    rep movsb

    call   pmode_to_real
[bits 16]

    jmp    .READ
.DONE:
    ret
