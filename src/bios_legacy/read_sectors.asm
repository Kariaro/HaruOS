[bits 16]

; Reads cx sectors from disk starting at ax into memory location es:bx
; @param cx      - sectors to read from disk
; @param di      - disk
; @param [dx:ax] - lba
; @param [es:bx] - destination memory
;
; @return cx     - read sectors
ReadSectors:
	push   ax
	push   bx
	push   dx

    mov    ax, 0x4100  ; BIOS check if extended mode is enabled
    mov    bx, 0x55AA
	mov    dx, di
	; mov    dl, 0x80
	int    13h

	pop    dx
	pop    bx
	pop    ax
	jnc    __ReadSectorsExtended
	jmp    __ReadSectorsCHS

; Read sectors using CHS format
__ReadSectorsCHS:
	push   dx
	mov    dx, di
	mov    BYTE [DiskDriveNumber], dl
	pop    dx

	; push   ax
    ; mov    ax, 0x0e25  ; Print '%'
    ; int    10h
	; pop    ax
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
        div     WORD [DiskSectorsPerTrack]          ; calculate
        inc     dl                                  ; adjust for sector 0
        mov     cl, dl  ; sector
        xor     dx, dx                              ; prepare dx:ax for operation
        div     WORD [DiskSectorsPerHead]           ; calculate
        mov     dh, dl  ; head
        mov     ch, al  ; track
	
	; mov al, cl
	; call PrintHex8
	; mov al, dh
	; call PrintHex8
	; mov al, ch
	; call PrintHex8
	; mov al, BYTE [DiskDriveNumber]
	; call PrintHex8

    ; Read one sector from the BIOS
    mov    ah, 0x02    ; BIOS read sector
    mov    al, 0x01    ; read one sector
    mov    dl, BYTE [DiskDriveNumber]
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
    ; Loop again
    pop    cx
    pop    bx
    pop    ax
    add    bx, 0x200
    inc    ax
    loop   .MAIN
    ret

; Read sectors using the disk extension protocol
__ReadSectorsExtended:
.MAIN:
	; Fill packet
	mov    WORD [DiskPacket.sectors_to_read], cx
	mov    WORD [DiskPacket.lba_high], dx
	mov    WORD [DiskPacket.lba_low], ax
	mov    WORD [DiskPacket.lba_high], es
	mov    WORD [DiskPacket.lba_low], bx
	
	; Set drive to read from
	mov    dx, di
	mov    si, DiskPacket

    ; 5 retries of reading
    mov    di, 0x0005
.READ:
    mov    ax, 0x4200  ; BIOS read sectors (extended mode)
    int    13h
    jnc    .SUCCESS
	dec    di
	jnz    .READ
.FAIL:
    mov    ax, 0x0e24  ; Print '$'
    int    10h
    int    18h         ; BIOS failure (Failed to read)
.SUCCESS:
	mov cx, WORD [DiskPacket.read_count]
    ret

DiskSectorsPerTrack:
	dw 0x00FF
DiskSectorsPerHead:
	dw 0x0002
DiskDriveNumber:
	db 0

DiskPacket:
	db 16      ; size of packet
	db 0       ; always 0
.sectors_to_read:
.read_count:
	dw 16      ; sectors to transfer
.dst_low:
	dw 0x0000
.dst_high:
	dw 0x0000
.lba_low:
    dw 0x0000
.lba_high:
	dw 0x0000

