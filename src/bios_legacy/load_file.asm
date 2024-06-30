
[bits 16]

; @param si      - pointer to file name
; @param dl      - drive to read from
; @stack DWORD   - memory offset
;
; @flag carry    - set if file failed to load
; @return bx     - pointer to sectors read
LoadFileFAT32:
    jmp .start
.drive:          dw 0
.file_name_ptr:  dw 0
.memory_offset:  dd 0
.write_offset:   dd 0
.BPB_SecPerClus: db 0
.data_sector:    dw 0x0000
.lba:            dw 0x0000
.size:           dd 0
.start:
    ; assume es = 0x0000
    pop    ax
    mov    BYTE [.drive], dl
    mov    WORD [.file_name_ptr], si
    pop    WORD [.memory_offset + 0]
    pop    WORD [.memory_offset + 2]
    mov    WORD [.write_offset + 0], 0
    mov    WORD [.write_offset + 2], 0
    push   ax

    ; read fat32 root sector
    mov    bx, 0x8000 ; dst low
    mov    dx, 0x0000 ; lba high
    mov    ax, 0x0000 ; lba low
    mov    cx, 1      ; read one sector
    mov    di, WORD [.drive]
    call   ReadSectors
    mov    bx, 0x0000

    ; get sectors per cluster
    mov    al, BYTE [0x800D]      ; BPB_SecPerClus
    mov    BYTE [.BPB_SecPerClus], al

    ; calculate data sector
    xor    ax, ax
    mov    al, BYTE [0x8010]      ; BPB_NumFATs    (always 2)
    mul    WORD [0x8024]          ; BPB_FATSz32
    add    ax, WORD [0x800E]      ; BPB_RsvdSecCnt (usually 32)
    mov    WORD [.data_sector], ax
 
    ; calculate root directory first cluster 
    mov    ax, WORD [0x802C]      ; BPB_RootClus
    sub    ax, 0x0002
    xor    cx, cx
    mov    cl, BYTE [.BPB_SecPerClus]
    mul    cx
    add    ax, WORD [.data_sector]
    push   ax

    ; read first root directory cluster
    mov    bx, 0x8000 ; dst low
    mov    dx, 0x0000 ; lba high
    pop    ax         ; lba low
    mov    cx, 1      ; read one sector
    mov    di, WORD [.drive]
    call   ReadSectors

    ; mov    dx, 0
    ; mov    cx, 0x0200
    ; mov    bx, 0x8000
    ; .LOOP:
    ;     mov    al, BYTE [bx]
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

    ; find file
    mov    cx, 8
    mov    di, 0x8020
.find_file:
    push   cx
    push   di
    mov    si, WORD [.file_name_ptr]
    mov    cx, 0x000B ; 11 characters
    repe   cmpsb
    pop    di
    pop    cx
    je     .file_found
    add    di, 0x0020
    loop   .find_file
    ; failed to find file, (set carry flag to for error)
    stc
    ret
.file_found:
    ; save size of file
    mov    ax, WORD [di + 0x1C]
    mov    WORD [.size + 0], ax
    mov    ax, WORD [di + 0x1E]
    mov    WORD [.size + 2], ax

    ; Calculate file lba
    mov    ax, WORD [di + 0x1A]
    sub    ax, 0x0002
    xor    cx, cx
    mov    cl, BYTE [.BPB_SecPerClus]
    mul    cx
    add    ax, WORD [.data_sector]
    mov    WORD [.lba], ax
.READ:
    mov    bx, 0x8000      ; destination low
    mov    dx, 0x0000      ; lba high
    mov    ax, WORD [.lba] ; lba low
    mov    cx, 1           ; read one sector
    mov    di, WORD [.drive]
    call   ReadSectors

    ; mov    ax, WORD [.size + 2]
    ; call   PrintHex16
    ; mov    ax, WORD [.size + 0]
    ; call   PrintHex16
    ; mov    ax, 0x0e0d
    ; int    10h
    ; mov    ax, 0x0e0a
    ; int    10h
    call   real_to_pmode
[bits 32]
    inc    WORD [.lba]
    ; Copy to data [0x00100000 + (0x200 * di)]
    mov    eax, DWORD [.write_offset]
    shl    eax, 9
    add    eax, DWORD [.memory_offset]
    mov    edi, eax
    mov    esi, 0x8000
    mov    ecx, (0x200 >> 2) ; 4 byte moves
    rep movsd ; // 4 bytes a time
    inc    DWORD [.write_offset]
    sub    DWORD [.size], 0x200
    jc     .READ_DONE
    call   pmode_to_real
[bits 16]
    jmp    .READ
[bits 32]
.READ_DONE:
    call   pmode_to_real
[bits 16]
    clc    ; clear carry flag
    mov    bx, .write_offset
    ret
