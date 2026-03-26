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

.extern drive

.extern firstStage
.type firstStage, @function
after_bpb:
    cli

    /* Initialize stack */
    xor %ax, %ax
    mov %ax, %ds
    mov %ax, %es
    mov %ax, %ss
    movw $0x7c00, %sp

    sti

    cld

    mov %dl, drive
    call firstStage
