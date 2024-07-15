bits 16
org 0x7C00

jmp short boot_start
nop

    OEMName             db  "HARUBOOT"
    BytesPerSector      dw  0x0200
    SectorsPerCluster   db  0x01
    ReservedSectors     dw  0x0020
    TotalFATs           db  0x02
;    MaxRootEntries      dw  0x0000
;    MediaDescriptor     db  0xF8
;    SectorsPerFAT       dw  0x0000
    SectorsPerTrack     dw  0x00FF
    NumberOfHeads      dw  0x0002
;    HiddenSectors       dd  0x00000000
;    TotalSectors        dd  0x00000001
;    Flags               dw  0x0000
    BigSectorsPerFAT    dd  0x021C
;    FSVersion           dw  0x0000
    RootDirectoryStart  dd  0x00000002
;    FileSystem          db  "FAT32  "

boot_start:
    cli
    jmp 0x0000:fix_cs
fix_cs:
    ; Adjust code frame to [0000:0000]
    mov ax, 0x0000
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    ; Create stack at [0000:FFFF]
    mov ax, 0x0000
    mov ss, ax
    mov sp, 0xFFFF
    sti

    ; Save boot drive
    mov BYTE [BootDrive], dl

    ; Get drive geometry
    mov ax, 0x0800
    mov dl, BYTE [BootDrive]
    int 13h
    mov BYTE [NumberOfHeads], dh
    inc WORD [NumberOfHeads]
    mov BYTE [SectorsPerTrack], cl
    and BYTE [SectorsPerTrack], 0x3f
    mov ax, 0x0000
    mov es, ax

    ; Read second sector of bootloader to [0000:0600]
    mov ax, 0x0001
    mov cx, 0x0001
    mov bx, 0x0600
    call ReadSectors

    ; Read stage2.bin to [0000:0600]
    mov bx, 0x0600
    mov ax, 0x0001
    mov cx, WORD [0x0604]
    call ReadSectors

;   mov di, 1
;   mov cx, 256
;   mov bx, 0x0600
;   .test:
;       dec di
;       cmp di, 0
;       jne .test_next
;       mov ax, 0x0e0d
;       int 10h
;       mov ax, 0x0e0a
;       int 10h
;       mov ax, bx
;       call PrintHex16
;       mov di, 16
;   .test_next:
;       mov al, BYTE [es:bx]
;       call PrintHex8
;       mov ax, 0x0e20
;       int 10h
;       inc bx
;       
;       loop .test

    ; enable 20th bit
    in al, 0x93
    or al, 2
    and al, ~1
    out 0x92, al


    mov si, Stage2FileFarJump
    call DisplayMessage

    ; jump into stage2 code located [0000:0600]
    mov dl, BYTE [BootDrive]
    jmp 0x0000:0x0600

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
        div     WORD [SectorsPerTrack]              ; calculate
        inc     dl                                  ; adjust for sector 0
        mov     cl, dl  ; sector
        xor     dx, dx                              ; prepare dx:ax for operation
        div     WORD [NumberOfHeads]               ; calculate
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
    add    bx, WORD [BytesPerSector]
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


; Print a hexadecimal value
; ax value
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

datasector         dw 0

Stage2FileFarJump  db 0x0d, 0x0a, 'jmp 0000:0600', 0x0d, 0x0a, 0
Stage2FileNotFound db 0x0d, 0x0a, 'STAGE2.BIN !',  0x0d, 0x0a, 0
Stage2File         db 'STAGE2  BIN', 0
; NewLine            db 0x0d, 0x0a, 0
DriveNumber        db 1
BootDrive          db 0

times 510-($-$$)   db 0
dw 0xAA55
