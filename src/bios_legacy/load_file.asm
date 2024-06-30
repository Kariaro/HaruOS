
[bits 16]

%define FILE_ERROR_ROOT_SECTOR    1
%define FILE_ERROR_ROOT_DIRECTORY 2
%define FILE_ERROR_FILE_NOT_FOUND 3
%define FILE_ERROR_SECTOR_READ    4

; @param si      - pointer to file name
; @param dl      - drive to read from
; @stack DWORD   - memory offset
;
; @flag carry    - set if file failed to load
; @return bx     - error code or pointer to sectors
LoadFileFAT32:
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
    mov    ax, 0x0000 ; lba
    mov    cx, 1      ; read one sector
    mov    dl, BYTE [.drive]
    call   ReadSectors
    mov    bx, FILE_ERROR_ROOT_SECTOR
    jc     .read_fail

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
    pop    ax         ; lba
    mov    cx, 1      ; read one sector
    mov    dl, BYTE [.drive]
    call   ReadSectors
    mov    bx, FILE_ERROR_ROOT_DIRECTORY
    jc     .read_fail

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
    jmp    .read_fail
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
    mov    ax, WORD [.lba] ; lba
    mov    cx, 1           ; read one sector
    mov    dl, BYTE [.drive]
    call   ReadSectors
    mov    bx, FILE_ERROR_SECTOR_READ
    jc     .read_fail
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
    mov    bx, .write_offset
    clc    ; clear carry flag for success
    ret
.read_fail:
    stc    ; set carry flag for error
    ret

.drive:          db 0x00
.BPB_SecPerClus: db 0x00
.file_name_ptr:  dw 0x0000
.data_sector:    dw 0x0000
.lba:            dw 0x0000
.memory_offset:  dd 0
.write_offset:   dd 0
.size:           dd 0
