

[bits 16]
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

PrintHex16_nospace:
    push   ax
    push   cx
    mov    cx, ax
    shr    ax, 8
    call   PrintHex8
    mov    ax, cx
    call   PrintHex8
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

%define HEX_DUMP_WIDTH 16

; @param es:bx    - data start
; @param cx       - how many bytes to print
PrintHexDump:
	push   ax
	push   bx
	push   dx
	push   cx

	; save es
	mov    ax, es
	push   ax

; Print address "01234567: "
.print_row:
	xor    ax, ax
	mov    dx, es
	shld   ax, dx, 4
	shl    dx, 4
	add    dx, bx
	adc    ax, 0x0000
	call   PrintHex16_nospace
	mov    ax, dx
	call   PrintHex16_nospace
	mov    ax, 0x0e3a ; ':'
	int    10h
	mov    ax, 0x0e20 ; ' '
	int    10h

	cmp    cx, 0
	je     .print_end

; Print hex values "xy xy xy xy xy xy xy xy"
	mov    ax, es   ; save es
	push   ax
	push   bx
	push   cx
	cmp    cx, HEX_DUMP_WIDTH - 1
	mov    ax, HEX_DUMP_WIDTH
	cmova  cx, ax
.loop_print_bytes:
	mov    al, BYTE [es:bx]
	call   PrintHex8
	mov    ax, 0x0e20
	int    10h
	call   .increment
	loop   .loop_print_bytes
	pop    cx
	pop    bx
	pop    ax
	mov    es, ax   ; get es back

	push   cx
; if cx is less than HEX_DUMP_WIDTH
	cmp    cx, HEX_DUMP_WIDTH - 1
	ja     .loop_fill_end
	; cx = (-cx + 16) = 16 - cx
	neg    cx
	add    cx, HEX_DUMP_WIDTH
.loop_fill:
	mov    ax, 0x0e20
	int    10h
	mov    ax, 0x0e20
	int    10h
	mov    ax, 0x0e20
	int    10h
	loop   .loop_fill
.loop_fill_end:
	pop    cx

	mov    ax, 0x0e3a ; ':'
	int    10h
	mov    ax, 0x0e20 ; ' '
	int    10h

; Print char values "........"
	push   cx
	cmp    cx, HEX_DUMP_WIDTH - 1
	mov    ax, HEX_DUMP_WIDTH
	cmova  cx, ax
.loop_print_chars:
	mov    al, BYTE [es:bx]
	call   .printable_char
	mov    ah, 0x0e
	int    10h
	call   .increment
	loop   .loop_print_chars
	pop    cx

.print_end:
	mov    ax, 0x0e0d
	int    10h
	mov    ax, 0x0e0a
	int    10h

	sub    cx, HEX_DUMP_WIDTH
	ja     .print_row

	; fix es
	pop    ax
	mov    es, ax

	pop    dx
	pop    cx
	pop    bx
	pop    ax
	ret

; increment buffer
.increment:
	add    bx, 1
	jnc    .increment_skip
	sub    bx, 16
	mov    ax, es
	inc    ax
	mov    es, ax
.increment_skip:
	ret

; set al to printable char
.printable_char:
	push   bx
	mov    bx, 0x2e 
	cmp    al, 32
	cmovl  ax, bx
	pop    bx
	ret
