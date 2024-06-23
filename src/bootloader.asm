bits 16
org 0x0000

jmp short START
nop

    OEMName             db  "HARUBOOT"
    BytesPerSector      dw  0x0200
    SectorsPerCluster   db  0x01
    ReservedSectors     dw  0x0020
    TotalFATs           db  0x02
    MaxRootEntries      dw  0x0000
;    MediaDescriptor     db  0xF8
    SectorsPerFAT       dw  0x0000
    SectorsPerTrack     dw  0x00FF
    SectorsPerHead      dw  0x0002
;    HiddenSectors       dd  0x00000000
;    TotalSectors        dd  0x00000001
;    Flags               dw  0x0000
    BigSectorsPerFAT    dd  0x021C
;    FSVersion           dw  0x0000
    RootDirectoryStart  dd  0x00000002

;    FileSystem          db  "FAT32  "

START:
    cli
    ; adjust code frame to [07C0:0000]
    mov ax, 0x07C0
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    ; create stack
    mov ax, 0x0000
    mov ss, ax
    mov sp, 0xFFFF
    sti

    ; calculate sector where data should start
    mov al, BYTE [TotalFATs]
    mul WORD [BigSectorsPerFAT]
    add ax, WORD [ReservedSectors]
    mov WORD [datasector], ax

    ; read 1st data cluster into memory (7C00:0200)
    ; mov cx, WORD [SectorsPerCluster]
    mov ax, WORD [RootDirectoryStart]
    call ClusterLBA
    mov cx, 0x0001
    mov bx, 0x0200
    call ReadFat32Sectors

    ; find 'KERNEL.BIN' in the root entry
    mov cx, 8
    mov di, 0x0200 + 0x20
    .FIND_KERNEL:
        push cx
        push di
        mov si, BootFile
        mov cx, 0x000B ; 11 characters
        repe cmpsb
        pop di
        pop cx
        je .KERNEL_FOUND
        add di, 0x0020
        loop .FIND_KERNEL
        jmp .ERROR
    .KERNEL_FOUND:
        ; read kernel into code location
        mov ax, WORD [di + 0x1A]
        call ClusterLBA
        mov cx, 0x0008
        mov bx, 0x0200
        call ReadFat32Sectors

        ; enable 20th bit
        in al, 0x93
        or al, 2
        and al, ~1
        out 0x92, al

        ; far jump into kernel
        jmp 0x07c0:0x0200

.ERROR:
    mov si, file_not_found
    call DisplayMessage
    mov ah, 0x00
    int 16h  ; BIOS await keypress
    int 19h


;
; Boot FAT32 reading code
;


; Reads cx sectors from disk starting at ax into memory location es:bx
ReadFat32Sectors:
.MAIN:
    ; 5 retries of reading
    mov    di, 0x0005
.SECTORLOOP:
    push   ax
    push   bx
    push   cx
    call   Convert_LBA_To_CHS
    
    ; Read one sector from the BIOS
    mov    ah, 0x02    ; BIOS read sector
    mov    al, 0x01    ; read one sector
    mov    ch, BYTE [absoluteTrack]
    mov    cl, BYTE [absoluteSector]
    mov    dh, BYTE [absoluteHead]
    mov    dl, BYTE [DriveNumber]
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
; PROCEDURE LBACHS
; convert ax LBA addressing scheme to CHS addressing scheme
; absolute sector = (logical sector / sectors per track) + 1
; absolute head   = (logical sector / sectors per track) MOD number of heads
; absolute track  = logical sector / (sectors per track * number of heads)
;*****************************************************************************
Convert_LBA_To_CHS:
    xor     dx, dx                              ; prepare dx:ax for operation
    div     WORD [SectorsPerTrack]              ; calculate
    inc     dl                                  ; adjust for sector 0
    mov     BYTE [absoluteSector], dl
    xor     dx, dx                              ; prepare dx:ax for operation
    div     WORD [SectorsPerHead]               ; calculate
    mov     BYTE [absoluteHead], dl
    mov     BYTE [absoluteTrack], al
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

file_not_found db 0x0d, 0x0a, 'KERNEL.BIN was not found!', 0dh, 0ah, 0

absoluteTrack           db 0
absoluteSector          db 0
absoluteHead            db 0
datasector              dw 0

BootFile    db 'KERNEL  BIN', 0
DriveNumber db 1

times 510-($-$$) db 0
dw 0xAA55
