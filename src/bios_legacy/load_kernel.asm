
[bits 16]
KERNEL_SECTORS:
    dd 0x00000000

LOAD_KERNEL_ASM:
    jmp .start
.BPB_SecPerClus:
    db 0
.data_sector:
    dw 0x0000
.size:
.size_low:
    dw 0x0000
.size_high:
    dw 0x0000
.lba:
    dw 0x0000
.kernel_file:
    db 'KERNEL  BIN', 0
.start:
    mov    WORD [KERNEL_SECTORS + 0], 0
    mov    WORD [KERNEL_SECTORS + 2], 0

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
    mov    ax, WORD [es:bx + 0x2C]      ; BPB_RootClus
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

    mov    di, -1
.READ:
    inc    di

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
    pop    di

    inc    WORD [.lba]
    call   real_to_pmode
[bits 32]
    ; Copy to data [0x00100000 + (0x200 * di)]
    push   edi
    lea    edi, [(0x00100000 >> 9) + di] ; (0x100000 + di * 0x200)
    shl    edi, 9
    mov    esi, 0x0001_0000
    mov    ecx, (0x200 >> 2) ; 4 byte moves
    rep movsd ; // 4 bytes a time
    pop    edi

    inc    DWORD [KERNEL_SECTORS]

    ; Check if there is more data to read
    sub    DWORD [.size], 0x200
    jc     .READ_DONE
    call   pmode_to_real
[bits 16]
    jmp    .READ
.READ_DONE:
[bits 32]
    call   pmode_to_real
[bits 16]
    ret
