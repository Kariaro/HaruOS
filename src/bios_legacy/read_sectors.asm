[bits 16]

; Reads cx sectors from disk starting at ax into memory location es:bx
; @param cx    - sectors to read from disk
; @param dl    - drive number
; @param ax    - lba
; @param bx    - destination memory
;
; @flags carry - if set an error has occured
ReadSectors:
    mov    BYTE [.DiskDriveNumber], dl
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
    div     WORD [.DiskSectorsPerTrack]         ; calculate
    inc     dl                                  ; adjust for sector 0
    mov     cl, dl  ; sector
    xor     dx, dx                              ; prepare dx:ax for operation
    div     WORD [.DiskSectorsPerHead]          ; calculate
    mov     dh, dl  ; head
    mov     ch, al  ; track

    ; Read one sector from the BIOS
    mov    ah, 0x02    ; BIOS read sector
    mov    al, 0x01    ; read one sector
    mov    dl, BYTE [.DiskDriveNumber]
    int    13h
    jnc    .SUCCESS

    ; Reset floppy
    mov    ax, 0x0000  ; BIOS reset disk
    int    13h
    pop    cx
    pop    bx
    pop    ax
    dec    di
    jnz    .SECTORLOOP
    stc    ; set carry flag for error
    ret
.SUCCESS:
    pop    cx
    pop    bx
    pop    ax
    add    bx, 0x200
    inc    ax
    loop   .MAIN
    clc    ; clear carry flag for success
    ret

.DiskSectorsPerTrack:
    dw 0x00FF
.DiskSectorsPerHead:
    dw 0x0002
.DiskDriveNumber:
    db 0
