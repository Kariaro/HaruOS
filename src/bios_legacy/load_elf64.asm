
[bits 64]

; @param rax    - pointer of ELF data
; @param rbx    - pointer to entry
RemapELF64:
    push   rax
    push   rcx
    push   rdi
    push   rsi

    xor    rcx, rcx
    mov    cx, WORD [rax + 0x3C]    ; e_shnum
    mov    rbx, QWORD [rax + 0x28]  ; e_shoff
    add    rbx, rax

.write_segment_header:
    push   rcx
    mov    cl, BYTE [rbx + 0x08]    ; sh_flags
    and    cl, 2
    cmp    cl, 2
    jne    .skip_segment_header

    ; setup destination
    mov    rdi, QWORD [rbx + 0x10]  ; sh_addr
    mov    rsi, QWORD [rbx + 0x18]  ; sh_offset
    add    rsi, rax
    mov    rcx, QWORD [rbx + 0x20]  ; sh_size
    rep    movsb
.skip_segment_header:
    xor    rcx, rcx
    mov    cx, WORD [rax + 0x3A]
    add    rbx, rcx
    pop    rcx
    sub    rcx, 1
    jnc    .write_segment_header

    mov    rbx, QWORD [rax + 0x18] ; e_entry

    pop    rsi
    pop    rdi
    pop    rcx
    pop    rax
    ret
