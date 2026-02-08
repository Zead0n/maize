.section .text.boot
.code16

.global _start
_start:
    jmp after_bpb
    nop

.org 0x03, 0x00
bpb_start:
bpb_end:
.org 0x25, 0x90

after_bpb:
    /* Initialize stack */
    xor %ax, %ax
    mov %ax, %ds
    mov %ax, %es
    mov %ax, %ss
    movw $0x7c00, %sp

    cld

    mov %dl, drive

    push %dx
    jmp first_stage
