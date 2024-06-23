;;; KERNEL.BIN

bits 16
ORG 0x0200

%macro __print_hex 0
	and ax, 0x000f
	mov bx, 0x0030
	mov cx, 0x0037
	cmp ax, 0x0009
	cmovg bx, cx
	add ax, bx
	mov ah, 0eh
	int 10h
%endmacro

%macro print_hex_8 0
	mov dx, ax
	shr ax, 4
	__print_hex
	mov ax, dx
	__print_hex
	mov ah, 0x0e
	mov al, 0x20
	int 10h
%endmacro

%macro print_hex_16 0
	mov dx, ax
	shr ax, 12
	__print_hex
	mov ax, dx
	shr ax, 8
	__print_hex
	mov ax, dx
	shr ax, 4
	__print_hex
	mov ax, dx
	__print_hex
	mov ah, 0x0e
	mov al, 0x20
	int 10h
%endmacro


start:

mov ax, start
print_hex_16

mov ax, test
print_hex_16

xor ax, ax
mov al, BYTE [test + 0]
print_hex_8
mov al, BYTE [test + 1]
print_hex_8
mov al, BYTE [test + 2]
print_hex_8
mov al, BYTE [test + 3]
print_hex_8



test:
jmp Main

buffer   dd 2000h


Main:
    mov si, loaded_message
    call print
    
    ; Enter x86 32 bit mode
    ; call EnterProtectedMode
    
    call COMMAND_LINE
    
    ; mov bx, 512
    ; mov cx, 128
    ; call printhexdata
    ; mov bx, [buffer] ; output
    ; mov dx, 1        ; fragid
    ; call READ_FILE_FROM_FRAGID
    
    ; mov si, [buffer]
    ; call print
    
    hlt
    jmp $

MOVE_CURSOR_LEFT:
    pusha
        mov bx, 0
        mov ah, 03h
        int 10h ; get cursor pos
        cmp dl, 0 ; check if we are at the first pos
        jnz .done
        mov dl, 80
        dec dh
    .done:
        dec dl
        mov ah, 02h
        int 10h
        popa
    ret

MOVE_CURSOR_RIGHT:
    pusha
        mov bx, 0
        mov ah, 03h
        int 10h ; get cursor pos
        cmp dl, 79 ; check if we are at last pos
        jnz .done
        mov dl, -1
        inc dh
    .done:
        inc dl
        mov ah, 02h
        int 10h
        popa
    ret

; si: Chars
; cx: String length
WRITE_AT_CURSOR:
    cmp cx, 0
    jz .done
    
    push si
    push cx
    push ax
    push bx
    
    mov bx, 0
    mov ah, 0eh
    .loop:
        lodsb
        int 10h
        loop .loop
    pop bx
    pop ax
    pop cx
    pop si
    
    .loop2:
        call MOVE_CURSOR_LEFT
        loop .loop2
    
    .done:
    ret

FETCH_KEY:
    xor ax, ax
    int 16h
    ret
    
; READ_KEYBOARD_LINE
%define key_buffer 0x4000 ; 512 bytes

READ_KEYBOARD_LINE:
    push bx
    push dx
    push ax
    
    ; Reset keyboard buffer
    mov cx, 64
    mov bx, 0
    .zero:
        mov dword [bx + key_buffer], 0
        add bx, 4
        loop .zero
    
    mov bx, 0
    mov dx, 0
    .loop:
        ; Prevent flicker
            mov cx, 0607h
            mov ax, 0100h
            int 10h ; Show cursor
        
        xor ax, ax
        int 16h ; Wait for next keypress
        
        ; Prevent flicker
            push ax
            mov cx, 2607h
            mov ax, 0100h
            int 10h ; Hide cursor
            pop ax
        
        cmp al, 0x0D ; Enter Key
        jz .enter
        cmp al, 0x08 ; Backspace
        jz .backspace
        cmp ah, 0x53 ; Delete
        jz .delete
        cmp ah, 0x4B ; Left arrow
        jz .arrow_left
        cmp ah, 0x4D ; Right Arrow
        jz .arrow_right
        cmp dx, 0xFE ; Max 256 characters
        ja .loop
        cmp al, 0x1F ; Control character
        jb .loop
        
        inc dx
        mov cx, dx
        sub cx, bx
        
        push bx
        mov bx, dx
        std ; direction = 1
        lea si, [bx + key_buffer - 1]
        lea di, [bx + key_buffer]
        rep movsb
        cld ; direction = 0
        
        mov bx, 0
        mov ah, 0eh
        int 10h
        pop bx
        
        mov byte [bx + key_buffer], al
        inc bx
        
        mov cx, dx
        sub cx, bx
        lea si, [bx + key_buffer]
        call WRITE_AT_CURSOR
        jmp .loop
    .arrow_left:
        cmp bx, 0
        jbe .loop
        call MOVE_CURSOR_LEFT
        dec bx
        jmp .loop
    .arrow_right:
        cmp bx, dx
        jnb .loop
        call MOVE_CURSOR_RIGHT
        inc bx
        jmp .loop
    .delete:
        cmp bx, dx
        jz .loop
        inc bx
        call MOVE_CURSOR_RIGHT
    .backspace:
        cmp bx, 0
        jbe .loop
        
        mov cx, dx
        sub cx, bx
        lea si, [bx + key_buffer]
        lea di, [bx + key_buffer - 1]
        rep movsb
        
        push bx
        mov bx, dx
        mov byte [bx + key_buffer - 1], 0
        pop bx
        
        CALL MOVE_CURSOR_LEFT
        dec bx
        
        mov cx, dx
        sub cx, bx
        lea si, [bx + key_buffer]
        call WRITE_AT_CURSOR
        
        dec dx
        jmp .loop
    .enter:
        mov cx, dx
        sub cx, bx
        
        cmp cx, 0
        jz .enter_end
        .enter_loop:
            call MOVE_CURSOR_RIGHT
            loop .enter_loop
        .enter_end:
    
    mov bx, dx
    mov byte [bx + key_buffer], 0
    
    mov cx, 0607h
    mov ax, 0100h
    int 10h ; Show cursor
    
    mov cx, dx
    pop ax
    pop dx
    pop bx
    ret

%macro test_command 2
    mov si, key_buffer
    mov di, %1
    repe cmpsb
    jz %2
%endmacro

COMMANDS:
    .STARTMESSAGE db 'HC Operative System (Version 0.1) (Copyright HardCoded 2020)', 0dh, 0ah, 0
    .LINEFEED     db 0dh, 0ah, 0
    .PROMPT       db '/:', 0
    
    .EMPTY        db 'Nothing', 0
    .CMD_HELP     db 'HELP', 0
    .HELP_MESSAGE db 'HELP        Shows this help message.', 0dh, 0ah
                  db 'SYSINFO     Show information about the current system.', 0dh, 0ah
                  db 'CD          Navigate the filesystem.', 0dh, 0ah
                  db 'LS          Show the current files and directory.', 0dh, 0ah
                  db 0
    
    .CMD_SYSINFO  db 'SYSINFO', 0
    .CMD_LS       db 'LS', 0
    .CMD_CD       db 'CD', 0

COMMAND_LINE:
    mov si, COMMANDS.STARTMESSAGE
    call print
        
    .loop:
        mov si, COMMANDS.LINEFEED
        call print
        mov si, COMMANDS.PROMPT
        call print
        
        call READ_KEYBOARD_LINE
        mov dx, cx
        mov si, COMMANDS.LINEFEED
        call print
        
        test_command  COMMANDS.CMD_HELP,    .HELP
        test_command  COMMANDS.CMD_SYSINFO, .SYSINFO
        
        mov si, key_buffer
        call print
        call psps
        mov ax, dx
        call printhex
        
        jmp .loop
    .HELP:
        mov si, COMMANDS.HELP_MESSAGE
        call print
        jmp .loop
    .SYSINFO: ; TODO: More information
        mov si, COMMANDS.STARTMESSAGE
        call print
        jmp .loop


loaded_message db 'KERNEL.BIN was executed from memory', 0dh, 0ah, 0dh, 0ah, 0

psps:
    push ax
    mov ax, 0e20h
    int 10h
    pop ax
    ret

pln:
    push ax
    mov ax, 0e0dh
    int 10h
    mov ax, 0e0ah
    int 10h
    pop ax
    ret

; Print a hexadecimal number 32 bit
printhex4:
    push eax
    push ecx
    mov cx, 8
    call printnhex
    pop ecx
    pop eax
    ret

; Print a hexadecimal number 16 bit
printhex2:
    push ax
    push cx
    mov cx, 4
    call printnhex
    pop cx
    pop ax
    ret

; Print a hexadecimal number 8 bit
printhex:
    push ax
    push cx
    mov cx, 2
    call printnhex
    pop cx
    pop ax
    ret

phex:
    and al, 15
    cmp al, 10
    jc .hexa
    add al, 37h
    jmp .hexr
    .hexa:
    add al, 30h
    .hexr:
    mov ah, 0eh
    int 10h
    ret

; cx is bytes
; eax is input
printnhex:
    push dx
    mov dx, cx
    .l:
        push ax
        shr eax, 4
    loop .l
    mov cx, dx
    
    .l2:
        pop ax
        call phex
    loop .l2
    pop dx
    ret

    
printhexdata:
    pusha
    mov ah, 0eh
    test cx, cx
    jz .phr
    
    push ebx
    push cx
    .phdh:
        mov al, byte [ebx]
        inc ebx
        call printhex
        loop .phdh
    
    ; mov al, 3ah
    ; int 10h
    ; mov al, 20h
    ; int 10h
    
    pop cx
    pop ebx
    ; .phds:
        ; mov al, byte [ebx]
        ; call pchr
        ; int 10h
        ; mov al, 20h
        ; int 10h
        ; inc ebx
        ; loop .phds
    .phr:
        mov al, 0ah
        int 10h
        mov al, 0dh
        int 10h
        popa
        ret

pchr:
    cmp al, 0ah
    jz .pcf
    cmp al, 0dh
    jz .pcf
    cmp al, 0h
    jz .pcf
    jmp .pcr
    .pcf:
    mov al, 2eh
    .pcr:
    ret

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

printcx:
    push ax
    push cx
    test cx, cx
    jz .done
    mov ah, 0eh
.rep:
    lodsb
    int 10h
    loop .rep
.done:
    pop ax
    pop cx
    ret



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
