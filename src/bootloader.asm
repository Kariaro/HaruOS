BITS 16

jmp main

OEMLabel			db "HCFSBOOT"
BytesPerSector		dw 512
RootDirEntries		dw 32 ; (32 * 256 = 8196 = 16 sectors to read)
SectorsPerTrack		dw 18
Sides				dw 2
FileSystem			db "HCFS 1.0"

reset_floppy:
	mov ah, 0
	
	mov dl, byte [BootDrive]
	int 13h
	ret

clsector:
	push bx
	push ax
	
	mov bx, ax
	
	mov dx, 0
	div word [SectorsPerTrack]
	inc dl
	mov cl, dl ; [Sector is done]
	mov ax, bx
	mov dx, 0
	div word [SectorsPerTrack]
	mov dx, 0
	div word [Sides]
	mov dh, dl
	mov ch, al
	
	pop ax
	pop bx
	
	; mov dl, byte [BootDrive]
	ret
	
; 
; DX - fragId
; 
; sector = 18 + (fragId * 2)
;  fragId = 0   <=>  [INVALID]
;  fragId = 1   <=>  sector 20
;  fragId = 2   <=>  sector 22
read_fragment:
	push bx
	.rfl:
	mov cx, dx
	xor dx, dx
	mov ax, 2
	mul cx
	add ax, 17
	
	call clsector
	
	mov dl, byte [BootDrive]
	mov ax, 0202h ; Copy 2 segments [1 KB]
	int 13h
	
	mov edx, dword [bx + 1020]
	cmp edx, 0
	jz .rfd
	add bx, 1020
	jmp .rfl
	.rfd:
	pop bx
	ret

; Enable the 20:th bit of a register to be written
enable_a20:
    in al, 0x93
    or al, 2
    and al, ~1
    out 0x92, al
    ret

main:
	cli
	xor ax, ax
	mov ss, ax
	mov sp, 0xFFFF
	sti
	
	; mov ax, 0x2401
	; int 15h ; Enable A20 bit
	; mov ax, 0x3
	; int 10h ; Set VGA Text mode
	
	call enable_a20
	
	mov ax, 07C0h
	mov ds, ax
	mov es, ax
	
	; Read floppy into memory
	; Write 8K to address: 7C00h
	mov dh, 0
	mov dl, [BootDrive]
	mov bx, buffer
	mov ah, 2
	mov cl, 2
	mov al, 1 ; Load 32 * 256 bytes [8 KB]
	int 13h
	
	load_root:
		call reset_floppy
		jc load_root
	loaded_root:
		mov di, buffer
		mov cx, 32 ; RootDirEntries
		
		; Move pointer to 0
		mov ax, 0
	search_root:
		push cx
		pop dx
		mov si, BootFile
		mov cx, 12
		
		; push si
		; mov si, di
		; call print
		; pop si
		
		rep cmpsb
		je found_file
		
		add ax, 100h
		mov di, buffer
		add di, ax
		
		push dx
		pop cx
		loop search_root
		
		mov si, file_not_found
		call print
		int 18h
	found_file:
		mov bx, buffer
		add bx, ax
	read_file:
		mov ecx, dword [bx + 128] ; size
		mov edx, dword [bx + 133] ; firstSegment
		
		; Load KERNEL.BIN into memory 
		mov bx, buffer
		call read_fragment
		
		; xor ax, ax
		; int 16h ; Read key
		
		; Enter protected mode
		; cli ; Clear interupt
		; mov eax,cr0
		; or eax,1
		; mov cr0,eax
		
		; Jump to KERNEL.BIN
		jmp 0x07c0:0x0200
		
	jmp $

print:
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


file_not_found db 'KERNEL.BIN was not found!', 0dh, 0ah, 0

BootFile  db 0ah, 'KERNEL.BIN', 0
BootDrive db 1

times 510-($-$$) db 0
dw 0xAA55

buffer: