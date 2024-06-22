;;; FILESYS.BIN

BITS 64
	


GDT:
	.NULL_DESC:
		dd 0            ; null descriptor
		dd 0

	.CODE_DESC:
		dw 0xFFFF       ; limit low
		dw 0            ; base low
		db 0            ; base middle
		db 10011010b    ; access
		db 11001111b    ; granularity
		db 0            ; base high

	.DATA_DESC:
		dw 0xFFFF       ; data descriptor
		dw 0            ; limit low
		db 0            ; base low
		db 10010010b    ; access
		db 11001111b    ; granularity
		db 0            ; base high

GDTR:
    .Limit dw (GDTR - GDT.NULL_DESC - 1) ; length of GDT
    .Base  dd GDT.NULL_DESC              ; base of GDT

%macro PAUSE_STEP 1
	push eax
	mov ah, 0eh
	mov al, %1
	int 10h
	xor eax, eax
	int 16h
	pop eax
%endmacro

EnterProtectedMode:
	cli
	lgdt [GDTR]
	PAUSE_STEP '0'
	
	mov eax, cr0
	PAUSE_STEP '1'
	
	or eax, 1
	PAUSE_STEP '2'
	
	mov cr0, eax
	; PAUSE_STEP '3'
	int3
	
	.halt:
		hlt
		jmp .halt
	; jmp (GDT.CODE_DESC - GDT.NULL_DESC) : ProtectedMode

BITS 32

ProtectedMode:
	mov ax, GDT.DATA_DESC - GDT.NULL_DESC
	mov ds, ax
	
	; This should crash
	
	mov si, loaded_message
	call print
	
	.halt:
		hlt
		jmp .halt