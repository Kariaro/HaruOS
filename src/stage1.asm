bits 16
org 0x0000

;  http://skelix.net/skelixos/tutorial02_en.html

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
    SectorsPerHead      dw  0x0002
;    HiddenSectors       dd  0x00000000
;    TotalSectors        dd  0x00000001
;    Flags               dw  0x0000
    BigSectorsPerFAT    dd  0x021C
;    FSVersion           dw  0x0000
    RootDirectoryStart  dd  0x00000002
;    FileSystem          db  "FAT32  "

boot_start:
    cli
    ; adjust code frame to [07C0:0000]
    mov ax, 0x07C0
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    ; create stack at [9000:FFFF]
    mov ax, 0x0000
    mov ss, ax
    mov sp, 0xFFFF
    sti

    ; calculate sector where data should start
    mov al, BYTE [TotalFATs]
    mul WORD [BigSectorsPerFAT]
    add ax, WORD [ReservedSectors]
    mov WORD [datasector], ax

    ; read root directory cluster into memory [7C00:0200]
    mov ax, WORD [RootDirectoryStart]
    call ClusterLBA
    mov cx, 0x0001
    mov bx, 0x0200
    call ReadFat32Sectors

    ; find 'STAGE2.BIN' in the root entry
    mov cx, 8
    mov di, 0x0200 + 0x20
    .FIND_STAGE2:
        push cx
        push di
        mov si, Stage2File
        mov cx, 0x000B ; 11 characters
        repe cmpsb
        pop di
        pop cx
        je .STAGE2_FOUND
        add di, 0x0020
        loop .FIND_STAGE2
        jmp .STAGE2_NOT_FOUND
    .STAGE2_FOUND:
        ; enable 20th bit
        in al, 0x93
        or al, 2
        and al, ~1
        out 0x92, al

        ; get size of file
        call CalculateFileSize
        mov cx, ax
        push cx

        ; read stage2 into code location [0000:0200]
        mov ax, 0x0000
        ; mov ds, ax
        mov es, ax

        mov ax, WORD [di + 0x1A]
        call ClusterLBA
        pop cx
        mov bx, 0x0200
        call ReadFat32Sectors

        ; move data segment to 0000
        mov ax, 0x0000
        mov ds, ax

        ; mov dx, 0
        ; mov cx, 0x0300 - 0x20
        ; mov bx, 0x0200
        ; .LOOP:
        ;     mov al, BYTE [bx]
        ;     call PrintHex8
        ;     inc bx
        ;     inc dx
        ;     cmp dx, 32
        ;     jnz .END
        ;     mov dx, 0
        ;     mov si, NewLine
        ;     call DisplayMessage
        ; .END:
        ;     loop .LOOP

        ; jump into stage2 code located [0000:0200]
        jmp 0x0000:0x0200
        int 18h
    .STAGE2_NOT_FOUND:
        mov si, Stage2FileNotFound
        call DisplayMessage
        mov ah, 0x00
        int 16h  ; BIOS await keypress
        int 19h  ; BIOS warning / restart

PrintHex8:
    push ax
    push cx
    mov cx, ax
    mov ax, cx
    shr ax, 4
    call .DIGIT
    mov ax, cx
    call .DIGIT
    pop cx
    pop ax
    ret
.DIGIT:
    and al, 15
    cmp al, 10
    jc .hexa
    add al, 0x07
    .hexa:
    add al, 0x30
    .hexr:
    mov ah, 0eh
    int 10h
    ret

; @param  di    contains the address of the fat32 file struct
; @return ax    the amount of sectors the file is
;CalculateFileSize16: ; todo - write this in 16 bit code
;    ; (size + BytesPerSector - 1) / BytesPerSector
;    push cx
;    push bx
;
;    ; low 16 bits
;    mov ax, WORD [di + 0x1C]
;    mov cx, WORD [BytesPerSector] ; cx = (BytesPerSector - 1)
;    dec cx
;    add ax, cx
;    xor cx, cx
;    setc cl ; set cx = carry flag if (low 16 bytes + cx) > 0xffff
;
;    ; high 16 bits
;    mov bx, WORD [di + 0x1C + 2]
;    add bx, cx
;
;    ; hard coded division by 512
;    shr ax, 9
;    shl bx, 7
;    add ax, bx
;
;    pop bx
;    pop cx
;    ret


; @param  di    contains the address of the fat32 file struct
; @return ax    the amount of sectors the file is
CalculateFileSize: ; todo - write this in 16 bit code
    ; (size + BytesPerSector - 1) / BytesPerSector
    push cx
    mov eax, DWORD [di + 0x1C]
    xor ecx, ecx
    add cx, WORD [BytesPerSector]
    add eax, ecx
    add eax, -1
    mov cx, WORD [BytesPerSector]
    div ecx
    pop cx
    ret

; Reads cx sectors from disk starting at ax into memory location es:bx
ReadFat32Sectors:
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
        div     WORD [SectorsPerHead]               ; calculate
        mov     dh, dl  ; head
        mov     ch, al  ; track

    ; Read one sector from the BIOS
    mov    ah, 0x02    ; BIOS read sector
    mov    al, 0x01    ; read one sector
    mov    dl, BYTE [DriveNumber]
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


;*************************************************************************
; PROCEDURE ClusterLBA
; convert FAT cluster into LBA addressing scheme
; FileStartSector = ((X − 2) * SectorsPerCluster(0x08))
;*************************************************************************
ClusterLBA:
    sub     ax, 0x0002                          ; zero base cluster number
    xor     cx, cx
    mov     cl, BYTE [SectorsPerCluster]        ; convert byte to word
    mul     cx
    add     ax, WORD [datasector]               ; base data sector
    ret


DisplayMessage:
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

datasector         dw 0

; Stage2FileTooLarge db 0x0d, 0x0a, 'STAGE2.BIN file too large!', 0x0d, 0x0a, 0
Stage2FileNotFound db 0x0d, 0x0a, 'STAGE2.BIN was not found!',  0x0d, 0x0a, 0
Stage2File         db 'STAGE2  BIN', 0
NewLine            db 0x0d, 0x0a, 0
DriveNumber        db 1

times 510-($-$$)   db 0
dw 0xAA55
