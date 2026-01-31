.section .text.boot
.code16

.global _start
_start:
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
