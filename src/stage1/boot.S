.section .text.boot
.code16

.global _start
_start:
    cli

    /* Initialize stack */
    xor %ax, %ax
    mov %ax, %ds
    mov %ax, %es
    mov %ax, %ss
    movw $0x7c00, %sp

    sti

    cld

    /* Enable A20 line */
    in $0x92, %al
    test $2, %al
    jnz a20_enabled
    or $2, %al
    and $0xfe, %al
    out %al, $0x92

a20_enabled:
    push %dx
    jmp first_stage
