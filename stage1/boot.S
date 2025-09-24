.section .text.boot
.code16

.macro print_and_err msg
    mov $msg, %si
    call print

    hlt
    jmp $ - 2
.endm

.global _start
_start:
    jmp skip_bpb
    nop

.space 64

skip_bpb:
    cli
    cld

    xor %ax, %ax
    mov %ax, %ds
    mov %ax, %es
    mov %ax, %ss
    mov %ax, %fs
    mov %ax, %gs
    mov $0x7c00, %sp

    mov $msg, %si
    call print

    cmp $0x80, %dl
    jb finish

    cmp $0x8f, %dl
    ja finish

finish:
    hlt
    jmp finish

floppy_err_msg:
    .asciz "Maize does not support floppy disk"

#include "print.S"
#include "gdt.S"

.space 510 - (. - _start)
.word 0xaa55
