bits 16
org 0x7C00

boot:
    jmp main
    TIMES 3-($-$$)      db 0x90

    BS_OEMName          db  "HARUBOOT"
    BPB_BytsPerSec      dw  0x0200
    BPB_SecPerClus      db  0x01
    BPB_RsvdSecCnt      dw  0x0020
    BPB_NumFATs         db  0x02
    BPB_RootEntCnt      dw  0x0000
    BPB_TotSec16        dw  0x0002
    BPB_Media           db  0xF8
    BPB_FATSz16         dw  0x0000
    BPB_SecPerTrk       dw  0x0000
    BPB_NumHeads        dw  0x0000
    BPB_HiddSec         dd  0x00000000
    BPB_TotSec32        dd  0x00000002
    BPB_FATSz32         dd  0x00000000
    BPB_ExtFlags        dw  0x0000
    BPB_FSVer           dw  0x0000
    BPB_RootClus        dd  0x00000002
    BPB_FSInfo          dw  0x0000
    BPB_BkBootSec       dw  0x0000
    TIMES 12            db  0
    BS_DrvNum           db  0
    TIMES 1             db  0
    BS_BootSig          db  0x28
    BS_VolID            dd  0x00000000
    BS_VolLab           db  "HARUBOOT   "
    BS_FilSysType       db  "FAT32  "

main:
    cli
    jmp    0x0000:fix_cs
fix_cs:
    ; Adjust code frame to [0000:0000]
    mov    ax, 0x0000
    mov    ds, ax
    mov    es, ax
    mov    fs, ax
    mov    gs, ax

    ; Create stack at [0000:FFFF]
    mov    ax, 0x0000
    mov    ss, ax
    mov    sp, 0xFFFF
    sti

    ; Save boot drive
    mov    BYTE [BootDrive], dl

    ; Get drive geometry
    mov    ax, 0x0800
    int    13h
    mov    BYTE [BPB_NumHeads], dh
    inc    WORD [BPB_NumHeads]
    mov    BYTE [BPB_SecPerTrk], cl
    and    BYTE [BPB_SecPerTrk], 0x3f
    mov    ax, 0x0000
    mov    es, ax

    ; Read first sector of stage2.bin to [0000:0600]
    mov    ax, 0x0001
    mov    cx, 0x0001
    mov    bx, 0x0600
    call   ReadSectors

    ; Read all of stage2.bin to [0000:0600]
    mov    bx, 0x0600
    mov    ax, 0x0001
    mov    cx, WORD [0x0604]
    call   ReadSectors

    ; Enable 20th bit
    in     al, 0x93
    or     al, 2
    and    al, ~1
    out    0x92, al

    mov    si, Stage2FileFarJump
    call   DisplayMessage

    ; Jump into stage2 code located [0000:0600]
    mov    dl, BYTE [BootDrive]
    jmp    0x0000:0x0600

; Reads cx sectors from disk starting at ax into memory location es:bx
ReadSectors:
    cmp    cx, 0
    jne    .MAIN
    mov    ax, 0
    int    16h
    jmp    $
.MAIN:
    ; 5 retries of reading
    mov    di, 0x0005
.SECTORLOOP:
    push   ax
    push   bx
    push   cx
    ; .Convert_LBA_To_CHS:
        ; convert ax LBA addressing scheme to CHS addressing scheme
        ; absolute sector = (logical sector / sectors per track) + 1
        ; absoulute head  = (logical sector / sectors per track) MOD number of heads
        ; absolte track   = logical sector / (sectors per track * number of heads)
        xor     dx, dx                              ; prepare dx:ax for operation
        div     WORD [BPB_SecPerTrk]                ; calculate
        inc     dl                                  ; adjust for sector 0
        mov     cl, dl  ; sector
        xor     dx, dx                              ; prepare dx:ax for operation
        div     WORD [BPB_NumHeads]                 ; calculate
        mov     dh, dl  ; head
        mov     ch, al  ; track

    ; Read one sector from the BIOS
    mov    ax, 0x0201  ; BIOS read sector
    mov    dl, BYTE [BootDrive]
    int    13h
    jnc    .SUCCESS

    ; Reset floppy
    mov    ax, 0x0e21  ; Print '!'
    int    10h
    mov    ax, 0x0000  ; BIOS reset disk
    int    13h
    pop    cx
    pop    bx
    pop    ax
    dec    di
    jnz    .SECTORLOOP
    int    18h
.SUCCESS:
    ; Print loading progress '.'
    mov    ax, 0x0e2e
    int    10h

    ; Loop again
    pop    cx
    pop    bx
    pop    ax
    add    bx, WORD [BPB_BytsPerSec]
    inc    ax
    loop   .MAIN
    ret


DisplayMessage:
    push   ax
    mov    ah, 0eh
.rep:
    lodsb
    cmp    al, 0
    je     .done
    int    10h
    jmp    .rep
.done:
    pop    ax
    ret


Stage2FileFarJump  db 0x0d, 0x0a, 'From STAGE1.BIN : jmp 0000:0600', 0x0d, 0x0a, 0
BootDrive          db 0

TIMES 510-($-$$)   db 0
dw 0xAA55
