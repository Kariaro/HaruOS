bits 16
org 0x7C00

jmp short boot_start
times 3-($-$$) db 0x90

boot_start:
    cli
    jmp 0x0000:fix_cs
fix_cs:
    ; adjust code frame to [0000:0000]
    mov ax, 0x0000
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    ; create stack at [0000:FFFF]
    mov ax, 0x0000
    mov ss, ax
    mov sp, 0xFFFF
    sti

    ; save boot drive
    mov BYTE [BootDrive], dl

    ; enable a20
    in al, 0x93
    or al, 2
    and al, ~1
    out 0x92, al

    ; load stage2 at [0000:0600]
    push 0x0000 ; 0000 ....
    push 0x0600 ; .... 0600
    mov dl, 1
    mov si, Stage2File
    call LoadFileFAT32

    ; jump to stage2
    jmp 0x0000:0x0600

a:
%include "read_sectors.asm"
b:
%include "load_file.asm"
c:
%include "lm_pm_code.asm"
d:

TIMES ($a-$b) db 0
TIMES ($b-$c) db 0
TIMES ($c-$d) db 0

BootDrive:
    db 0
Stage2File:
    db 'STAGE2  BIN', 0

times 510-($-$$)   db 0
dw 0xAA55
