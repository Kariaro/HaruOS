
[bits 16]

%define FILE_ERROR_ROOT_SECTOR        1
%define FILE_ERROR_ROOT_DIRECTORY     2
%define FILE_ERROR_FILE_NOT_FOUND     3
%define FILE_ERROR_SECTOR_READ        4
%define FILE_ERROR_NO_EXTENDED_MODE   5
%define FILE_ERROR_READ_FAILED        6
%define FILE_ERROR_NO_BIOS_SUPPORT    7


; @param si      - pointer to file name
; @param dl      - drive to read from
; @stack DWORD   - memory offset
;
; @flag carry    - set if file failed to load
; @return bx     - error code or pointer to sectors
LoadFileFAT32:
    pop    ax    ; pop return address
    mov    BYTE [.drive], dl
    mov    WORD [.file_name_ptr], si
    pop    WORD [.memory_offset + 0]
    pop    WORD [.memory_offset + 2]
    push   ax

    ; Clear lba
    mov    WORD [.d_lba + 0], 0
    mov    WORD [.d_lba + 2], 0
    mov    WORD [.d_lba + 4], 0
    mov    WORD [.d_lba + 6], 0

    ; Clear db_add [0000:8000]
    mov    WORD [.db_add + 0], 0x8000
    mov    WORD [.db_add + 2], 0

    mov    ah, 0x41
    mov    bx, 0x55aa
    int    13h
    jc     .error_no_extended_mode
    cmp    bx, 0xaa55
    jnz    .error_no_bios_support
    jmp    .has_support
.error_no_extended_mode:
    mov    bx, FILE_ERROR_NO_EXTENDED_MODE
    stc
    ret
.error_no_bios_support:
    mov    bx, FILE_ERROR_NO_BIOS_SUPPORT
    stc
    ret
.error_sector_read:
    mov    bx, FILE_ERROR_SECTOR_READ
    stc
    ret
.has_support:
    mov    ax, es
    push   ax
    xor    ax, ax
    mov    es, ax
    call   .load_internal
    pop    ax
    mov    es, ax
    ret

.read_error:
    stc
    ret
.read_extended:
    mov    si, .dapack
    mov    WORD [.blkcnt], 1
    mov    dl, BYTE [.drive]
    mov    ah, 0x42
    int    13h
    ret

.load_internal:
    ; Read the first lba
    call   .read_extended
    mov    bx, FILE_ERROR_ROOT_SECTOR
    jc     .read_error

    ; Get sectors per cluster
    mov    al, BYTE [0x800D]      ; BPB_SecPerClus
    mov    BYTE [.BPB_SecPerClus], al

    ; Calculate data sector
    xor    ax, ax
    mov    al, BYTE [0x8010]      ; BPB_NumFATs    (always 2)
    mul    WORD [0x8024]          ; BPB_FATSz32
    add    ax, WORD [0x800E]      ; BPB_RsvdSecCnt (usually 32)
    mov    WORD [.data_sector], ax
 
    ; Calculate root directory first cluster 
    mov    ax, WORD [0x802C]      ; BPB_RootClus
    sub    ax, 0x0002
    xor    cx, cx
    mov    cl, BYTE [.BPB_SecPerClus]
    mul    cx
    add    ax, WORD [.data_sector]

    ; Read first root directory cluster
    mov    WORD [.d_lba], ax
    call   .read_extended
    mov    bx, FILE_ERROR_ROOT_DIRECTORY
    jc     .read_error

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
    mov    bx, FILE_ERROR_FILE_NOT_FOUND
    jmp    .read_error
.file_found:
    ; Save size of file
    mov    ax, WORD [di + 0x1C]
    mov    WORD [.size + 0], ax
    mov    ax, WORD [di + 0x1E]
    mov    WORD [.size + 2], ax

    ; Calculate file LBA
    mov    ax, WORD [di + 0x1A]
    sub    ax, 0x0002
    xor    cx, cx
    mov    cl, BYTE [.BPB_SecPerClus]
    mul    cx
    add    ax, WORD [.data_sector]
    mov    WORD [.d_lba], ax

    ; Update db_add to read into memory offset [0000:8000]
    mov    ax, WORD [.memory_offset + 0]
    mov    dx, WORD [.memory_offset + 2]
    shl    dx, 8

    mov    WORD [.db_add + 0], ax
    mov    WORD [.db_add + 2], dx
    mov    bx, 0
.read:
    call   .read_extended
    jc     .error_sector_read

    ; Increment LBA
    add    WORD [.d_lba + 0], 1
    adc    WORD [.d_lba + 2], 0

    ; Increment write code (increment segment for ease)
    add    WORD [.db_add + 2], 0x20
    
    ; Increment read sectors counter
    inc    bx

    mov    ax, WORD [.size + 2]
    call   PrintHex16_nospace
    mov    ax, WORD [.size + 0]
    call   PrintHex16

    ; Decrement size (add -0x200 = 0xfffffe00)
    add    WORD [.size + 0], 0xFE00
    adc    WORD [.size + 2], 0xFFFF
    
    jc     .read
    clc    ; Clear carry flag for success
    ret


.drive:          db 0x00
.BPB_SecPerClus: db 0x00
.file_name_ptr:  dw 0x0000
.data_sector:    dw 0x0000
.lba:            dw 0x0000
.memory_offset:  dd 0
.size:           dd 0

.dapack:
    db   0x10        ; Packet Size
    db   0x00        ; Always 0
.blkcnt:
    dw   0x01        ; Sectors Count
.db_add:
    dw   0x8000      ; Transfer Offset
    dw   0x0000      ; Transfer Segment
.d_lba:
    dd   0x00000000  ; Starting LBA
    dd   0x00000000  ; Bios 48 bit LBA
