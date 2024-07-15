
[bits 16]

%macro print_16_bit_es_bx 2
    jmp %%after_data
%%string:
    db %1, 0
%%after_data:
    mov    si, %%string
    call   print
    mov    ax, WORD [es:bx + %2 + 0]
    call   PrintHex16
    mov    ax, 0x0e0d
    int    10h
    mov    ax, 0x0e0a
    int    10h
%endmacro

%macro print_32_bit_es_bx 2
    jmp %%after_data
%%string:
    db %1, 0
%%after_data:
    mov    si, %%string
    call   print
    mov    ax, WORD [es:bx + %2 + 2]
    call   PrintHex16_nospace
    mov    ax, WORD [es:bx + %2 + 0]
    call   PrintHex16
    mov    ax, 0x0e0d
    int    10h
    mov    ax, 0x0e0a
    int    10h
%endmacro

%macro print_64_bit_es_bx 2
    jmp %%after_data
%%string:
    db %1, 0
%%after_data:
    mov    si, %%string
    call   print
    mov    ax, WORD [es:bx + %2 + 6]
    call   PrintHex16_nospace
    mov    ax, WORD [es:bx + %2 + 4]
    call   PrintHex16_nospace
    mov    ax, WORD [es:bx + %2 + 2]
    call   PrintHex16_nospace
    mov    ax, WORD [es:bx + %2 + 0]
    call   PrintHex16
    mov    ax, 0x0e0d
    int    10h
    mov    ax, 0x0e0a
    int    10h
%endmacro


; @param es:bx    - ELF data
RemapELF:
    push   bx
    print_64_bit_es_bx 'e_entry  : ', 0x18
    print_64_bit_es_bx 'e_phoff  : ', 0x20
    print_64_bit_es_bx 'e_shoff  : ', 0x28
    print_16_bit_es_bx 'e_phnum  : ', 0x38
    print_16_bit_es_bx 'e_shnum  : ', 0x3C

    push   bx
    mov    cx, WORD [es:bx + 0x38]
    mov    dx, WORD [es:bx + 0x36]
    add    bx, WORD [es:bx + 0x20]
.print_pheader:
    call   __print_pheader
    add    bx, dx
    loop   .print_pheader
    pop    bx


    push   bx
    mov    cx, WORD [es:bx + 0x3C]
    mov    dx, WORD [es:bx + 0x3A]
    add    bx, WORD [es:bx + 0x28]
.print_sheader:
    call   __print_sheader
    add    bx, dx
    mov    ah, 0x00
    int    16h
    loop   .print_sheader
    pop    bx

    pop    bx
    ret

__print_pheader:
    print_64_bit_es_bx ' .p_offset  : ', 0x08
    print_64_bit_es_bx ' .p_vaddr   : ', 0x10
    print_64_bit_es_bx ' .p_paddr   : ', 0x18
    print_64_bit_es_bx ' .p_filesz  : ', 0x20
    ret

__print_sheader:
    print_32_bit_es_bx ' .sh_type   : ', 0x04
    print_64_bit_es_bx ' .sh_addr   : ', 0x10
    print_64_bit_es_bx ' .sh_offset : ', 0x18
    print_64_bit_es_bx ' .sh_size   : ', 0x20
    ret
